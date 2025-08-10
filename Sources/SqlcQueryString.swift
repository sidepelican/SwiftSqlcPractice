import SQLKit

public struct SqlcQueryString: SQLExpression {
    @usableFromInline
    var sql: String

    @usableFromInline
    var binds: [Encodable & Sendable] = []

    /// Create a query string from a plain string containing raw SQL.
    @inlinable
    public init(_ string: String) {
        self.sql = string

    }

    @inlinable
    public mutating func bind(_ value: Encodable & Sendable) {
        binds.append(value)
    }

    @inlinable
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.write(sql)
        for bind in binds {
            serializer.write(bind: bind)
        }
    }
}
