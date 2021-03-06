/// Represents an entity that can be
/// stored and retrieved from the `Database`.
public protocol Entity: class, RowConvertible, Storable {
    /// The entity's primary identifier
    /// used for updating, filtering, deleting, etc.
    /// - note: automatically implemented by Storable
    ///         only override for custom use cases
    var id: Identifier? { get set }

    /// The plural relational name of this model.
    /// Used as the collection or table name.
    static var entity: String { get }

    /// The singular relational name of this model.
    /// Also used for internal storage.
    static var name: String { get }

    /// The type of identifier used for both
    /// the local and foreign id keys.
    /// ex: uuid, integer, etc
    static var idType: IdentifierType { get }

    /// The naming convetion to use for foreign
    /// id keys, table names, etc.
    /// ex: snake_case vs. camelCase.
    static var keyNamingConvention: KeyNamingConvention { get }

    /// The name of the column that corresponds
    /// to this entity's identifying key.
    /// The default is 'database.driver.idKey',
    /// and then "id"
    static var idKey: String { get }

    /// The name of the column that points
    /// to this entity's id when referenced
    /// from other tables or collections.
    /// ex: "foo_id".
    static var foreignIdKey: String { get }

    /// Used for internal storage of the type
    /// Uses `String(describing: self)` by default,
    /// but types with Left/Right generics (like pivots)
    /// must implement a custom identifier.
    static var identifier: String { get }

    /// Called before the entity will be created.
    /// Throwing will cancel the creation.
    func willCreate() throws

    /// Called after the entity has been created.
    func didCreate()

    /// Called before the entity will be updated.
    /// Throwing will cancel the update.
    func willUpdate() throws

    /// Called after the entity has been updated.
    func didUpdate()

    /// Called before the entity will be deleted.
    /// Throwing will cancel the deletion.
    func willDelete() throws

    /// Called after the entity has been deleted.
    func didDelete()
}

// MARK: Optional

extension Entity {
    public func willCreate() {}
    public func didCreate() {}
    public func willUpdate() {}
    public func didUpdate() {}
    public func willDelete() {}
    public func didDelete() {}
}

// MARK: CRUD

extension Entity {
    /// Persists the entity into the
    /// data store and sets the `id` property.
    public func save() throws {
        try Self.query().save(self)
    }

    /// Deletes the entity from the data
    /// store if the `id` property is set.
    public func delete() throws {
        try Self.query().delete(self)
    }

    /// Returns all entities for this `Model`.
    public static func all() throws -> [Self] {
        return try Self.query().all()
    }

    /// Returns all entities for this `Model`.
    public static func count() throws -> Int {
        return try Self.query().count()
    }

    /// Finds the entity with the given `id`.
    public static func find(_ id: NodeRepresentable) throws -> Self? {
        return try Self.query().find(id)
    }

    //// Creates a `Query` instance for this `Model`.
    public static func query() throws -> Query<Self> {
        guard let db = database else {
            throw EntityError.noDatabase(self)
        }
        return Query(db)
    }
}

// MARK: Relatable

extension Storable where Self: Entity {
    /// See Entity.idKey -- instance implementation of static var
    public var idKey: String {
        return Self.idKey
    }
}

extension Entity {
    /// See Entity.entity
    public static var entity: String {
        return name + "s"
    }

    // See Entity.identifier
    public static var identifier: String {
        return String(describing: self)
    }

    /// See Entity.name
    public static var name: String {
        let typeName = String(describing: self)
        switch keyNamingConvention {
        case .snake_case:
            return typeName.snake_case()
        case .camelCase:
            return typeName.camelCase()
        }
    }

    /// See Entity.idType
    public static var idType: IdentifierType {
        return database?.idType ?? .int
    }

    /// See Entity.idKey
    public static var idKey: String {
        return database?.idKey ?? "id"
    }

    /// See Entity.foreignIdKey
    public static var foreignIdKey: String {
        switch keyNamingConvention {
        case .snake_case:
            return "\(name)_\(idKey)"
        case .camelCase:
            return "\(name)\(idKey.capitalized)"
        }

    }

    public static var keyNamingConvention: KeyNamingConvention {
        return database?.keyNamingConvention ?? .snake_case
    }
}


// MARK: Database

extension Entity {
    /// Fetches or sets the `Database` for this
    /// relatable object from the static database map.
    public static var database: Database? {
        get {
            if let db = Database.map[Self.identifier] {
                return db
            } else {
                return Database.default
            }
        }
        set {
            Database.map[Self.identifier] = newValue
        }
    }
}

// MARK: Convenience

extension Entity {
    /// Asserts that the entity exists and returns
    /// its identifier.
    @discardableResult
    public func assertExists() throws -> Identifier {
        guard let id = self.id else {
            throw EntityError.noId(Self.self)
        }

        guard exists else {
            throw EntityError.doesntExist(Self.self)
        }

        return id
    }
}
