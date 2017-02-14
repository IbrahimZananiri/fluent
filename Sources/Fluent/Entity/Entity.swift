/// Represents an entity that can be
/// stored and retrieved from the `Database`.
public protocol Entity: Preparation, NodeConvertible {
    // DELETE ME
    var id: Node? { get set }
    var exists: Bool { get set }

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
    public mutating func save() throws {
        try Self.query().save(&self)
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

    /// Finds the entity with the given `id`.
    public static func find(_ id: NodeRepresentable) throws -> Self? {
        guard let _ = database else { return nil }
        return try Self.query().filter(Self.idKey, .equals, id).first()
    }

    //// Creates a `Query` instance for this `Model`.
    public static func query() throws -> Query<Self> {
        guard let db = database else {
            throw EntityError.noDatabase(self)
        }
        return Query(db)
    }
}

// MARK: Deprecated
extension Entity {
    public var exists: Bool {
        // TODO: Implement me
        get { return false }
        set { }
    }
}

// MARK: Relatable

extension Entity {
    /// See Entity.entity
    public static var entity: String {
        return name + "s"
    }

    /// See Entity.name
    public static var name: String {
        return String(describing: self).lowercased()
    }

    /// See Entity.idType
    public static var idType: IdentifierType {
        return database?.driver.idType ?? .uuid
    }

    /// See Entity.idKey
    public static var idKey: String {
        return database?.driver.idKey ?? "id"
    }

    /// See Entity.foreignIdKey
    public static var foreignIdKey: String {
        return "\(name)_\(idKey)"
    }
}

// MARK: Database

extension Entity {
    /// Fetches or sets the `Database` for this
    /// relatable object from the static database map.
    public static var database: Database? {
        get {
            if let db = Database.map[Self.name] {
                return db
            } else {
                return Database.default
            }
        }
        set {
            Database.map[Self.name] = newValue
        }
    }
}
