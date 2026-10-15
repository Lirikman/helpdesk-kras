-- name: CreateRouter :one
INSERT INTO routers (
    plot_id,
    name,
    host,
    port,
    username,
    password,
    is_active
) VALUES ($1, $2, $3, $4, $5, %6, $7)
RETURNING
    plot_id,
    name,
    is_active;

-- name: UpdateRouterByID :one
UPDATE routers
SET name = $2,
host = $3,
port = $4,
username = $5,
password = $6,
WHERE id = $1 AND
is_active = TRUE
RETURNIN
    id,
    plot_id,
    name;

-- name: DeleteRouterByID :one
DELETE FROM routers
WHERE id=$1
RETURNING
    id,
    plot_id,
    name;

-- name: DeactivateRouterByID :one
UPDATE routers
SET is_active = FALSE
WHERE id = $1 
AND is_active = TRUE
RETURNING
    id,
    plot_id,
    name,
    is_active;

-- name: ListActiveRouters :many
SELECT
    id,
    plot_id,
    name,
    host,
    port
FROM routers
WHERE is_active = TRUE
ORDER BY id
LIMIT $1 OFFSET $2;

-- name: ListActiveRoutersByPlotID :many
SELECT
    id,
    name,
    host,
    port
FROM routers
WHERE plot_id = $1 AND is_active = TRUE
ORDER BY id;
