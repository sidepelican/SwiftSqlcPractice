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

struct SqlcRawQueryBuilder {
    var sql: String
    init(sql: String) {
        self.sql = sql
    }

    private var indexBinds: [(Int16, SQLiteData)] = []
    private var sliceBinds: [(String, [SQLiteData])] = []

    mutating func bind(value: some SQLiteDataConvertible, atParamIndex index: Int16) {
        indexBinds.append((index, value.sqliteData ?? .null))
    }

    mutating func bind(values: [some SQLiteDataConvertible], atSliceName name: String) {
        sliceBinds.append((name, !values.isEmpty ? values.map { $0.sqliteData ?? .null } : [.null]))
    }

    mutating func build() -> (String, [SQLiteData]) {
        var sql = sql
        var binds: [SQLiteData?] = .init(
            repeating: nil,
            count: indexBinds.count + sliceBinds.reduce(0) { $0 + $1.1.count }
        )

        // 1st, assign fixed index binds
        for (paramIndex, value) in indexBinds {
            binds[Int(paramIndex - 1)] = value
        }

        // 2nd, assign slice parameters into unused binds slot.
        var bindIndex = binds.startIndex
        for (sliceName, values) in sliceBinds {
            var usedParamIndices: [Int16] = []
            for value in values {
                // find empty slot and keep that index
                while binds[bindIndex] != nil {
                    bindIndex = binds.index(after: bindIndex)
                }
                binds[bindIndex] = value
                usedParamIndices.append(Int16(bindIndex + 1))
                bindIndex = binds.index(after: bindIndex)
            }

            let sliceRe = Regex { "/*SLICE:"; sliceName; "*/?" }
            let placeholder = usedParamIndices.map { "?\($0)" }.joined(separator: ", ")
            sql.replace(sliceRe) { _ in
                placeholder
            }
        }

        assert(binds.allSatisfy({ $0 != nil }))
        return (sql, binds.map { $0! })
    }
}
