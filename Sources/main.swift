// The Swift Programming Language
// https://docs.swift.org/swift-book

print("Hello, world!")

import SQLiteKit
import Logging
import Foundation

let exampleDBPath = Bundle.module.path(forResource: "chinook", ofType: "db")!
let tmpDBPath = NSTemporaryDirectory() + "\(UUID()).sqlite"
try FileManager.default.copyItem(atPath: exampleDBPath, toPath: tmpDBPath)
defer {
    try! FileManager.default.removeItem(atPath: tmpDBPath)
    print("cleanup finished.")
}

let source = SQLiteConnectionSource(
    configuration: .init(storage: .file(path: tmpDBPath))
)
let logger = Logger(label: "chinook")

let conn = try await source.makeConnection(logger: logger, on: MultiThreadedEventLoopGroup.singleton.next()).get()
let sql = conn.sql(queryLogLevel: .info)

// Use generated query + types
let found = try await Query.SearchTracksByName.execute(on: sql, input: .init(p1: "Love", p2: 5))
print(found.map { "\($0.trackid): \($0.name)" })

try await conn.close().get()
