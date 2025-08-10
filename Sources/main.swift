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
let tracksByAlbum = try await Query.GetTracksByAlbum(album_id: 1).execute(on: conn)
print("GetTracksByAlbum(1):", tracksByAlbum.prefix(3).map { "\($0.trackid): \($0.name) [\($0.milliseconds)ms]" })

// 2) SearchTracksByName
let found = try await Query.SearchTracksByName(pattern: "Love", limit: 5).execute(on: conn)
print("SearchTracksByName('Love',5):", found.map { "\($0.trackid): \($0.name)" })

// 3) GetAlbumsByArtist
let albumsByArtist = try await Query.GetAlbumsByArtist(artist_id: 1).execute(on: conn)
print("GetAlbumsByArtist(1):", albumsByArtist.prefix(3).map { "\($0.albumid): \($0.title)" })

// 4) CreateArtist
let newArtistName = "sqlc_test_\(UUID().uuidString.prefix(8))"
try await Query.CreateArtist(name: newArtistName).execute(on: conn)
let newID = try await conn.lastAutoincrementID().get()
print("CreateArtist -> id=\(newID), name=\(newArtistName)")

// 5) GetArtistByID
let created = try await Query.GetArtistByID(id: newID).execute(on: conn)
print("GetArtistByID(\(newID)):", created.map { "\($0.artistid): \($0.name)" } ?? "nil")

// 6) DeleteArtist
try await Query.DeleteArtist(id: newID).execute(on: conn)
print("DeleteArtist(\(newID)): ok")

try await conn.close().get()
