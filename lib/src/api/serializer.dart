/// Base marker interface for all RDF serializers.
///
/// This serves as a semantic marker to group all serializers in the system.
/// It doesn't define any methods itself but acts as a common ancestor.
///
/// This allows for type-safety when managing collections of serializers.
abstract interface class Serializer<T> {}
