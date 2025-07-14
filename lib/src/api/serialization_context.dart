import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/mapper.dart';
import 'package:rdf_mapper/src/api/resource_builder.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

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
  /// Returns a list of triples representing the object's properties.
  ///
  /// Throws [SerializationException] if no suitable serializer is found or serialization fails.
  List<Triple> resource<T>(T instance, {ResourceSerializer<T>? serializer});

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
  /// // Returns: (BlankNodeTerm() or IriTerm(...), [triples for person properties])
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
  /// Throws [SerializationException] if no suitable serializer is found or serialization fails.
  (RdfTerm, Iterable<Triple>) serialize<T>(
    T value, {
    Serializer<T>? serializer,
    RdfSubject? parentSubject,
  });

  /// Builds an RDF list structure from a Dart iterable.
  ///
  /// This method creates the standard RDF list representation using `rdf:first` and
  /// `rdf:rest` properties to form a linked list structure. RDF lists are commonly
  /// used to represent ordered collections in RDF graphs while maintaining order
  /// information that is not guaranteed by RDF's set-based triple model.
  ///
  /// **RDF List Structure**: Each list node contains:
  /// - `rdf:first`: Points to the current element's serialized form
  /// - `rdf:rest`: Points to the next list node, or `rdf:nil` for the last element
  ///
  /// **Lazy Processing**: The method processes the iterable lazily, generating
  /// triples on-demand. This enables efficient handling of large collections
  /// without loading everything into memory at once.
  ///
  /// **Element Serialization**: Each element in the iterable is serialized using
  /// the provided serializer or registry-based lookup, allowing complex objects
  /// to be embedded within lists.
  ///
  /// **Head Node Control**: The optional `headNode` parameter allows reusing an
  /// existing subject as the list head, useful for integrating lists into larger
  /// RDF structures.
  ///
  /// Example usage:
  /// ```dart
  /// final names = ['Alice', 'Bob', 'Charlie'];
  /// final (head, triples) = context.buildRdfList(names);
  /// // Creates: head rdf:first "Alice" ; rdf:rest [ rdf:first "Bob" ; rdf:rest [ ... ] ]
  ///
  /// // With custom serializer
  /// final persons = [person1, person2];
  /// final (head, triples) = context.buildRdfList(persons, serializer: PersonSerializer());
  /// ```
  ///
  /// [values] The iterable of values to convert into an RDF list.
  /// [headNode] Optional existing subject to use as the list head. If null, creates a new blank node.
  /// [serializer] Optional custom serializer for list elements. If null, uses registry-based lookup.
  ///
  /// Returns a tuple containing:
  /// - The RDF subject representing the head of the list (`rdf:nil` for empty lists)
  /// - An iterable of triples that form the complete list structure
  ///
  /// Throws [SerializationException] if element serialization fails.
  (RdfSubject, Iterable<Triple>) buildRdfList<V>(Iterable<V> values,
      {RdfSubject? headNode, Serializer<V>? serializer});
}
