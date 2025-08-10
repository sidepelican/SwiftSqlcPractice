-- name: GetTracksByAlbum :many
SELECT t.TrackId, t.Name, t.Milliseconds
FROM tracks AS t
WHERE t.AlbumId = sqlc.arg(album_id)
ORDER BY t.TrackId;

-- name: SearchTracksByName :many
SELECT TrackId, Name
FROM tracks
WHERE Name LIKE '%' || sqlc.arg(pattern) || '%'
ORDER BY Name
LIMIT sqlc.arg(limit);

-- name: GetAlbumsByArtist :many
SELECT a.AlbumId, a.Title
FROM albums AS a
WHERE a.ArtistId = sqlc.arg(artist_id)
ORDER BY a.AlbumId;

-- name: GetArtistByID :one
SELECT ArtistId, Name
FROM artists
WHERE ArtistId = sqlc.arg(id);

-- name: CreateArtist :one
INSERT INTO artists (Name)
VALUES (sqlc.arg(name))
RETURNING ArtistId;

-- name: DeleteArtist :exec
DELETE FROM artists
WHERE ArtistId = sqlc.arg(id);

