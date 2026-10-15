-- name: CreateUserPlots :one
INSERT INTO user_plots (
    user_id,
    plot_id
) VALUES ($1, $2)
RETURNING
   user_id,
   plot_id;

-- name: UpdateUserPlotsByUserID :one
UPDATE user_plots
SET plot_id = $2
WHERE user_id = $1;

-- name: DeleteUserPlotsByUserID :one
DELETE FROM user_plots
WHERE user_id=$1
RETURNING
    user_id,
    plot_id;

-- name: ListUserPlots :many
SELECT id, user_id, plot_id
FROM user_plots
ORDER BY id
LIMIT $1 OFFSET $2;
