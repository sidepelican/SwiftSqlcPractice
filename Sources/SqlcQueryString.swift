import SQLiteNIO

struct SqlcQueryBuilder {
    var sql: String
    var binds: [SQLiteData] = []
    init(_ string: String) {
        self.sql = string
    }

    mutating func bind(_ value: (some SQLiteDataConvertible)?) {
        binds.append(value?.sqliteData ?? .null)
    }
}

extension SQLiteConnection {
    func execute(_ builder: SqlcQueryBuilder) async throws -> [SQLiteRow] {
        return try await query(builder.sql, builder.binds)
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
