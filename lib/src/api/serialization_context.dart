import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Core interface for serializing Dart objects to RDF.
///
/// The [SerializationContext] provides methods to convert Dart objects into RDF
/// terms and resources. It manages the serialization process and maintains
/// necessary state to handle complex object graphs.
///
/// This is typically used by [GlobalResourceMapper] or [LocalResourceMapper] implementations to convert
/// domain objects to their RDF representation.
abstract class SerializationContext {
  /// Creates a [ResourceBuilder] for constructing RDF resources.
  ///
  /// The [subject] is the RDF subject (IRI or blank node) that will be used as
  /// the subject for all triples created by the builder.
  ///
  /// Example usage in a [GlobalResourceMapper] or [LocalResourceMapper]:
  /// ```dart
  /// final builder = context.resourceBuilder(bookIri);
  /// builder.addValue(SchemaBook.name, book.title);
  /// builder.addValue(SchemaBook.author, book.author);
  /// final (subject, triples) = builder.build();
  /// ```
  ///
  /// The returned [ResourceBuilder] instance provides a fluent API for adding
  /// properties to the RDF subject.
  ResourceBuilder<S> resourceBuilder<S extends RdfSubject>(S subject);

  /// Converts a Dart value to an RDF literal term.
  ///
  /// If [serializer] is provided, it will be used to convert the value.
  /// Otherwise, looks up a serializer based on the runtime type of [value].
  ///
  /// Throws [ArgumentError] if [value] is null.
  ///
  /// This is a low-level method typically used by [LiteralTermMapper] implementations
  /// to delegate to existing serializers.
  LiteralTerm toLiteralTerm<T>(T value, {LiteralTermSerializer<T>? serializer});

  /// Creates an IRI term from a string value.
  ///
  /// This method provides a centralized way to create IRI terms, allowing
  /// the serialization context to apply any necessary processing, validation,
  /// or factory patterns to IRI creation.
  ///
  /// Example usage:
  /// ```dart
  /// final personIri = context.createIriTerm('http://example.org/person/123');
  /// final namespaceIri = context.createIriTerm('http://schema.org/name');
  /// ```
  ///
  /// [value] The string representation of the IRI.
  ///
  /// Returns an [IriTerm] instance representing the given IRI string.
  IriTerm createIriTerm(String value);

  /// Serializes a Dart object to RDF triples as a resource.
  ///
  /// This method converts a domain object into a collection of RDF triples that
  /// describe the object's properties and relationships. It's primarily used for
  /// objects that are represented as RDF resources (subjects with properties).
  ///
  /// The method leverages resource serializers to handle the conversion process,
  /// either using a provided custom serializer or looking up an appropriate
  /// serializer from the registry based on the object's runtime type.
  ///
  /// **Resource vs. Value Serialization**: This method is for objects that become
  /// RDF subjects with properties, not simple values that become literals or IRIs.
  ///
  /// Example usage:
  /// ```dart
  /// final person = Person(name: 'John', age: 30);
  /// final triples = context.resource(person);
  /// // Produces triples like:
  /// // _:b1 <name> "John" .
  /// // _:b1 <age> "30"^^xsd:int .
  /// ```
  ///
  /// [instance] The Dart object to serialize as an RDF resource.
  /// [serializer] Optional custom serializer. If null, uses registry-based lookup.
  ///
  /// Returns an iterable of triples representing the object's properties.
  ///
  /// Throws [SerializerNotFoundException] if no suitable serializer is found or serialization fails.
  Iterable<Triple> resource<T>(T instance, {ResourceSerializer<T>? serializer});

  /// Serializes any Dart value to its RDF representation.
  ///
  /// This is the core serialization method that can handle any type of Dart object,
  /// converting it to the appropriate RDF term (literal, IRI, or blank node) along
  /// with any associated triples needed to fully represent the object.
  ///
  /// The method automatically determines the appropriate serialization strategy based
  /// on the value type and available serializers:
  /// - **Primitives**: Become literal terms (strings, numbers, booleans, dates)
  /// - **Objects**: Become subjects with property triples
  /// - **Collections**: May use specialized collection serializers
  ///
  /// **Parent Subject Context**: The `parentSubject` parameter provides context
  /// for nested serialization, allowing child objects to reference their parent
  /// in the RDF graph structure.
  ///
  /// Example usage:
  /// ```dart
  /// // Simple value
  /// final (term, triples) = context.serialize("Hello");
  /// // Returns: (LiteralTerm("Hello"), [])
  ///
  /// // Complex object
  /// final person = Person(name: 'John');
  /// final (term, triples) = context.serialize(person, parentSubject: parentIri);
  /// // Returns: (BlankNodeTerm() or const IriTerm(...), [triples for person properties])
  /// ```
  ///
  /// [value] The Dart value to serialize.
  /// [serializer] Optional custom serializer. If null, uses registry-based lookup.
  /// [parentSubject] Optional parent subject for nested serialization context.
  ///
  /// Returns a tuple containing:
  /// - The RDF term representing the value
  /// - An iterable of triples needed to fully represent the value
  ///
  /// Throws [SerializerNotFoundException] if no suitable serializer is found or serialization fails.
  (Iterable<RdfTerm>, Iterable<Triple>) serialize<T>(
    T value, {
    Serializer<T>? serializer,
    RdfSubject? parentSubject,
  });
}
