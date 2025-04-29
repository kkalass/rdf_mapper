/// Base marker interface for all RDF deserializers.
///
/// This serves as a semantic marker to group all deserializers in the system.
/// It doesn't define any methods itself but acts as a common ancestor.
///
/// This allows for type-safety when managing collections of deserializers.
abstract interface class Deserializer<T> {}
