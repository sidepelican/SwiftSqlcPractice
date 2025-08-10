import SQLiteNIO
import Foundation

let exampleDBPath = Bundle.module.path(forResource: "chinook", ofType: "db")!
let tmpDBPath = NSTemporaryDirectory() + "\(UUID()).sqlite"
try FileManager.default.copyItem(atPath: exampleDBPath, toPath: tmpDBPath)
defer {
    try! FileManager.default.removeItem(atPath: tmpDBPath)
    print("cleanup finished.")
}

let conn = try await SQLiteConnection.open(
    storage: .file(path: tmpDBPath)
).get()

// 1) GetTracksByAlbum
let tracksByAlbum = try await conn.execute(Query.GetTracksByAlbum(album_id: 1))
print("GetTracksByAlbum(1):", tracksByAlbum.prefix(3).map { "\($0.trackid): \($0.name) [\($0.milliseconds)ms]" })

// 2) SearchTracksByName
let found = try await conn.execute(Query.SearchTracksByName(pattern: "Love", limit: 5))
print("SearchTracksByName('Love',5):", found.map { "\($0.trackid): \($0.name)" })

// 3) GetAlbumsByArtist
let albumsByArtist = try await conn.execute(Query.GetAlbumsByArtist(artist_id: 1))
print("GetAlbumsByArtist(1):", albumsByArtist.prefix(3).map { "\($0.albumid): \($0.title)" })

// create and delete
let newArtistName = "sqlc_test_\(UUID().uuidString.prefix(8))"
let newID = try await conn.execute(Query.CreateArtist(name: newArtistName))!.artistid
print("CreateArtist(): id=\(newID), name=\(newArtistName)")

var created = try await conn.execute(Query.GetArtistByID(id: newID))
print("GetArtistByID(\(newID)):", created.map { "\($0.artistid): \($0.name)" } ?? "nil")

try await conn.execute(Query.DeleteArtist(id: newID))
print("DeleteArtist(\(newID)): ok")

created = try await conn.execute(Query.GetArtistByID(id: newID))
print("GetArtistByID(\(newID)):", created.map { "\($0.artistid): \($0.name)" } ?? "nil")

try await conn.close().get()
