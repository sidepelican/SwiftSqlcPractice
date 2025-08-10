-- Minimal Chinook-like schema for sqlite
CREATE TABLE artists (
  ArtistId   INTEGER PRIMARY KEY,
  Name       TEXT NOT NULL
);

CREATE TABLE albums (
  AlbumId    INTEGER PRIMARY KEY,
  Title      TEXT NOT NULL,
  ArtistId   INTEGER NOT NULL REFERENCES artists(ArtistId)
);

CREATE TABLE tracks (
  TrackId      INTEGER PRIMARY KEY,
  Name         TEXT NOT NULL,
  AlbumId      INTEGER NOT NULL REFERENCES albums(AlbumId),
  Composer     TEXT,
  Milliseconds INTEGER NOT NULL,
  Bytes        INTEGER,
  UnitPrice    REAL NOT NULL
);

