-- name: CreateRouterAccess :one
INSERT INTO router_access (
    router_id,
    name,
    is_active
) VALUES ($1, $2, $3)
RETURNING
    id,
    router_id,
    name,
    is_active;

-- name: ListRouterAccess :many
SELECT id, name
FROM router_access
WHERE router_id = $1 AND 
    is_active = TRUE;

-- name: DeactivateRouterAccess :one
UPDATE router_access
SET is_active = FALSE
WHERE id = $1 
AND is_active = TRUE
RETURNING
    id,
    router_id
    name,
    is_active;

-- name: DeleteRouterAccess :one
DELETE FROM router_access
WHERE id = $1
RETURNING
    id,
    router_id
    name;
