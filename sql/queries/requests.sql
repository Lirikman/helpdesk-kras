-- name: CreateRequest :one
INSERT INTO requests (
    plot_id,
    routers_id,
    executor_id,
    employee_name,
    ip_address,
    mac_address,
    access_id,
    queue_id
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8
) RETURNING
    id,
    plot_id,
    routers_id,
    executor_id,
    employee_name,
    ip_address,
    mac_address,
    access_id,
    queue_id,
    status,
    created_at;

-- name: ListRequests :many
SELECT 
    id,
    plot_id,
    routers_id,
    executor_id,
    employee_name,
    ip_address,
    mac_address,
    access_id,
    queue_id,
    status,
    created_at
FROM requests
WHERE 
    ($3::text IS NULL OR employee_name ILIKE '%' || $3 || '%')
    AND ($4::timestamp IS NULL OR created_at >= $4)
    AND ($5::timestamp IS NULL OR created_at <= $5)
ORDER BY id DESC
LIMIT $1 OFFSET $2;
