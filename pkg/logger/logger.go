package logger

import (
	"context"
	"encoding/json"
	"io"
	"log"
	"log/slog"
	"os"
	"strings"

	"github.com/fatih/color"
)

type CustomHandlerOptions struct {
	SlogOpts slog.HandlerOptions
}

type CustomHandler struct {
	slog.Handler
	l *log.Logger
}

func (h *CustomHandler) Handle(ctx context.Context, r slog.Record) error {
	level := r.Level.String() + ":"

	switch r.Level {
	case slog.LevelDebug:
		level = color.MagentaString(level)
	case slog.LevelInfo:
		level = color.BlueString(level)
	case slog.LevelWarn:
		level = color.YellowString(level)
	case slog.LevelError:
		level = color.RedString(level)
	}

	fields := make(map[string]any, r.NumAttrs())
	r.Attrs(func(a slog.Attr) bool {
		fields[a.Key] = a.Value.Any()

		return true
	})

	b, err := json.MarshalIndent(fields, "", "  ")
	if err != nil {
		return err
	}

	timeStr := r.Time.Format("[15:05:05.000]")
	msg := color.CyanString(r.Message)

	h.l.Println(timeStr, level, msg, color.WhiteString(string(b)))

	return nil
}

func NewCustomHandler(out io.Writer, opts CustomHandlerOptions) *CustomHandler {
	h := &CustomHandler{
		Handler: slog.NewJSONHandler(out, &opts.SlogOpts),
		l:       log.New(out, "", 0),
	}

	return h
}

func NewLogger(level string) *slog.Logger {
	var logLevel slog.Level

	switch strings.ToUpper(level) {
	case "DEBUG":
		logLevel = slog.LevelDebug
	case "WARN":
		logLevel = slog.LevelWarn
	case "ERROR":
		logLevel = slog.LevelError
	default:
		logLevel = slog.LevelInfo
	}

	opts := CustomHandlerOptions{
		SlogOpts: slog.HandlerOptions{
			Level: logLevel,
		},
	}

	handler := NewCustomHandler(os.Stdout, opts)

	return slog.New(handler)
}
