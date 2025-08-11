import SQLiteNIO
import RegexBuilder

protocol SqlcQuery: Sendable {
    var sql: String { get }
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
        _ = try await self.query(query.sql, query.binds)
    }

    func execute<Q: SqlcQueryOne>(_ query: Q) async throws -> Q.Row? {
        return try await self.query(query.sql, query.binds).first.map { row in
            try Q.Row.decode(from: row)
        }
    }

    func execute<Q: SqlcQueryMany>(_ query: Q) async throws -> [Q.Row] {
        return try await self.query(query.sql, query.binds).map { row in
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

    mutating func binds(_ values: some Sequence<some SQLiteDataConvertible>) {
        append(contentsOf: values.map { $0.sqliteData ?? .null })
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

func replaceSliceParameterToPlaceholders(sql: inout String, paramName: String, bindCount: Int) {
    // Locate the slice marker: /*SLICE:<paramName>*/?
    let marker = Regex { "/*SLICE:"; paramName; "*/?" }
    guard let r = sql.firstRange(of: marker) else { return }

    let prefix = sql[..<r.lowerBound]
    let suffix = sql[r.upperBound...]

    // Find max numbered placeholder in the prefix to determine base index
    let numbered = Regex {
        "?"
        TryCapture { OneOrMore(.digit) } transform: { Int($0) }
    }
    let maxIndex = prefix.matches(of: numbered).map(\.1).max() ?? 0
    let base = maxIndex + 1

    let replacement: String = if bindCount <= 0 {
        "NULL"
    } else {
        (0..<bindCount).map { "?\(base + $0)" }.joined(separator: ", ")
    }

    // Renumber only placeholders whose index is greater than the slice base
    let delta = bindCount - 1
    let renumberedSuffix: Substring = if delta == 0 {
        suffix
    } else {
        suffix.replacing(numbered) { match in
            let n = match.1
            if n > base {
                return "?\(n + delta)"[...]
            } else {
                return match.0
            }
        }
    }

    sql = prefix + replacement + renumberedSuffix
}
