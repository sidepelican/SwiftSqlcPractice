import SQLiteNIO

protocol SqlcQuery: Sendable {
    static var sql: String { get }
    var binds: [SQLiteData] { get }
}

protocol SqlcQueryExec: SqlcQuery {}

protocol SqlcQueryOne: SqlcQuery {
    associatedtype Row: DecodableFromSQLiteRow
}

protocol SqlcQueryMany: SqlcQuery {
    associatedtype Row: DecodableFromSQLiteRow
}

extension SQLiteConnection {
    func execute<Q: SqlcQueryExec>(_ query: Q) async throws {
        _ = try await self.query(Q.sql, query.binds)
    }

    func execute<Q: SqlcQueryOne>(_ query: Q) async throws -> Q.Row? {
        return try await self.query(Q.sql, query.binds).first.map { row in
            try Q.Row.decode(from: row)
        }
    }

    func execute<Q: SqlcQueryMany>(_ query: Q) async throws -> [Q.Row] {
        return try await self.query(Q.sql, query.binds).map { row in
            try Q.Row.decode(from: row)
        }
    }
}

protocol DecodableFromSQLiteRow {
    static func decode(from row: SQLiteRow) throws -> Self
}

extension [SQLiteData] {
    mutating func bind(_ value: (some SQLiteDataConvertible)?) {
        append(value?.sqliteData ?? .null)
    }
}

fileprivate struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    init(stringValue: String) {
        self.stringValue = stringValue
    }
    init?(intValue: Int) {
        return nil
    }
}

extension SQLiteDataConvertible {
    static func decode(from column: SQLiteColumn) throws -> Self {
        if let value = self.init(sqliteData: column.data) {
            return value
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [AnyCodingKey(stringValue: column.name)],
                debugDescription: "Decode failed. column=\(column.name)",
                underlyingError: nil
            )
        )
    }
}
