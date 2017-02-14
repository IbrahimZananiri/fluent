/// Sorts results based on a field
/// and direction.
public struct Sort {

    /// The types of directions
    /// fields can be sorted.
    public enum Direction {
        case ascending, descending
    }

    /// The entity to sort.
    public let entity: Entity.Type

    /// The name of the field to sort.
    public let field: String

    /// The direction to sort by.
    public let direction: Direction

    public init(_ entity: Entity.Type, _ field: String, _ direction: Direction) {
        self.entity = entity
        self.field = field
        self.direction = direction
    }
}

extension QueryRepresentable {
    /// Add a Sort to the Query.
    /// See Sort for more information.
    public func sort(_ field: String, _ direction: Sort.Direction) throws -> Query<T> {
        let query = try makeQuery()
        let sort = Sort(T.self, field, direction)
        query.sorts.append(sort)
        return query
    }
}
