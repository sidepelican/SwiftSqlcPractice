import SQLiteNIO

public struct SqlcQueryBuilder {
    @usableFromInline
    var sql: String

    @usableFromInline
    var binds: [SQLiteData] = []

    /// Create a query string from a plain string containing raw SQL.
    @inlinable
    public init(_ string: String) {
        self.sql = string
    }

    @inlinable
    public mutating func bind(_ value: some SQLiteBindable) {
        binds.append(value.asSQLiteData)
    }
}

extension SQLiteConnection {
    public func execute(_ builder: SqlcQueryBuilder) async throws -> [SQLiteRow] {
        return try await query(builder.sql, builder.binds)
    }
}

public protocol SQLiteBindable {
    var asSQLiteData: SQLiteData { get }
}

extension Optional: SQLiteBindable where Wrapped: SQLiteBindable {
    public var asSQLiteData: SQLiteData {
        if let value = self {
            value.asSQLiteData
        } else {
            .null
        }
    }
}

extension String: SQLiteBindable {
    public var asSQLiteData: SQLiteData {
        .text(self)
    }
}

extension Int: SQLiteBindable {
    public var asSQLiteData: SQLiteData {
        .integer(self)
    }
}
