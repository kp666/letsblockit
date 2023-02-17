-- name: CreateListForUser :one
INSERT INTO filter_lists (user_id)
VALUES ($1)
RETURNING token;

-- name: GetListForUser :one
SELECT token,
       downloaded_at,
       (SELECT COUNT(*) FROM filter_instances WHERE filter_instances.user_id = $1) AS instance_count
FROM filter_lists
WHERE filter_lists.user_id = $1
LIMIT 1;

-- name: CountListsForUser :one
SELECT COUNT(*)
FROM filter_lists
WHERE user_id = $1;

-- name: RotateListToken :exec
UPDATE filter_lists
SET token      = gen_random_uuid(),
    downloaded_at = NULL
WHERE user_id = $1
  AND token = $2;

-- name: GetListForToken :one
SELECT fl.id,
       fl.user_id,
       fl.downloaded_at,
       (SELECT max(coalesce(fi.updated_at, fi.created_at))
        from filter_instances fi
        where fi.list_id = fl.id) as last_updated
FROM filter_lists fl
WHERE token = $1
LIMIT 1;

-- name: MarkListDownloaded :exec
UPDATE filter_lists
SET downloaded_at = NOW()
WHERE token = $1;
