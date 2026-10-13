-- name: CreatePlot :one
INSERT INTO plots (
    name,
    is_active
) VALUES ($1, $2)
RETURNING
    name,
    is_active;