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

// Use generated query + types
let found = try await Query.SearchTracksByName.execute(on: conn, input: .init(p1: "Love", p2: 5))
print(found.map { "\($0.trackid): \($0.name)" })

try await conn.close().get()
