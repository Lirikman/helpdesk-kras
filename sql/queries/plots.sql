-- name: CreatePlot :one
INSERT INTO plots (
    name,
    is_active
) VALUES ($1, $2)
RETURNING
    name,
    is_active;

-- name: DeletePlotByID :one
DELETE FROM plots
WHERE id=$1
RETURNING
    id,
    name;

-- name: DeactivatePlotByID :one
UPDATE plots
SET is_active = FALSE
WHERE id = $1 
AND is_active = TRUE
RETURNING
    id,
    name,
    is_active;




