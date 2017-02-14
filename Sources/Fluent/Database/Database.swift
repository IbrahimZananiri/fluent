/// References a database with a single `Driver`.
/// Statically maps `Model`s to `Database`s.
public final class Database: Executor {
    /// Maps `Model` names to their respective
    /// `Database`. This allows multiple models
    /// in the same application to use different
    /// methods of data persistence.
    public static var map: [String: Database] = [:]

    /// The default database for all `Model` types.
    public static var `default`: Database?

    /// The `Driver` powering this database.
    /// Responsible for executing queries.
    public let driver: Driver
    
    /// Maintains a pool of connections
    /// one for each thread
    public let threadConnectionPool: ThreadConnectionPool

    /// Creates a `Database` with the supplied
    /// `Driver`. This cannot be changed later.
    public init(_ driver: Driver, maxConnections: Int = 128) {
        threadConnectionPool = ThreadConnectionPool(
            makeConnection: driver.makeConnection,
            maxConnections: maxConnections // some number larger than the max threads
        )
        self.driver = driver
    }
}

// MARK: Executor

extension Database {
    /// See Executor protocol.
    @discardableResult
    public func query<T: Entity>(_ query: Query<T>) throws -> Node {
        return try threadConnectionPool.connection().query(query)
    }
    
    /// Seeee Executor protocol.
    public func schema(_ schema: Schema) throws {
        try threadConnectionPool.connection().schema(schema)
    }
    
    /// Seeee Executor protocol.
    @discardableResult
    public func raw(_ raw: String, _ values: [Node]) throws -> Node {
        return try threadConnectionPool.connection().raw(raw, values)
    }
}

