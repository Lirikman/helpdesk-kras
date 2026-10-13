-- name: CreateUser :one
INSERT INTO users (
    full_name,
    username,
    password_hash,
    role,
    is_active
) VALUES ($1, $2, $3, $4, $5)
RETURNING
    id,
    full_name,
    username,
    role,
    is_active;

-- name: UpdateUserByID :one
UPDATE users
SET full_name = $2,
    username =  $3,
    password_hash = $4,
    role = $5,
    is_active = $6
WHERE id = $1
RETURNING
    id,
    full_name,
    username,
    role,
    is_active;

-- name: DeleteUserByID :one
DELETE FROM users
WHERE id = $1
RETURNING
    id,
    full_name,
    username,
    role;

-- name: DeactivateUserByID :one
UPDATE users
SET is_active = FALSE
WHERE id = $1
  AND is_active = TRUE
RETURNING
    id,
    full_name,
    username,
    role,
    is_active;

-- name: GetUserByID :one
SELECT
    id,
    full_name,
    username,
    password_hash,
    role,
    is_active
FROM users
WHERE id = $1;

-- name: GetUserByUsername :one
SELECT
    id,
    full_name,
    username,
    password_hash,
    role,
    is_active
FROM users
WHERE LOWER(username) = LOWER($1);

-- name: ListActiveUsers :many
SELECT
    id,
    username,
    full_name,
    role,
    is_active
FROM users
WHERE is_active = TRUE
ORDER BY id
LIMIT $1 OFFSET $2;