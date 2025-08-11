-- name: GetTracksByAlbum :many
SELECT t.TrackId, t.Name, t.Milliseconds
FROM tracks AS t
WHERE t.AlbumId = sqlc.arg(album_id)
ORDER BY t.TrackId;

-- name: GetTracksWithAlbumTitle :many
SELECT t.TrackId, t.Name, a.Title
FROM tracks AS t
JOIN albums AS a ON t.AlbumId = a.AlbumId
ORDER BY t.TrackId;

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
