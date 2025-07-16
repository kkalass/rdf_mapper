import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/api/resource_reader.dart';

/// Context for deserialization operations in the RDF mapping process.
///
/// The deserialization context provides a unified access point to all services and state
/// needed during the conversion of RDF representations to Dart objects. It maintains
/// references to the current graph being processed and offers utility methods for
/// extracting structured information from RDF data.
///
/// Key responsibilities:
/// - Provide access to the RDF graph being deserialized
/// - Track already deserialized objects to handle circular references
/// - Offer utility methods for navigating and interpreting the graph structure
/// - Enable a consistent environment for deserializer implementations
///
/// The context follows the Ambient Context pattern, providing relevant services
/// to deserializers without requiring explicit passing of dependencies through
/// deep call hierarchies.
///
/// This abstraction is particularly valuable when deserializing complex RDF graphs
/// that may contain circular references or shared resources.
abstract class DeserializationContext {
  /// Creates a reader for fluent access to resource properties.
  ///
  /// The resource reader provides a convenient API for reading properties from an RDF
  /// subject, handling common patterns like retrieving single values, collections,
  /// or related objects. It encapsulates the complexity of traversing the RDF graph
  /// and extracting structured data.
  ///
  /// The reader pattern simplifies the process of accessing multiple properties
  /// of a subject, especially when dealing with complex nested structures.
  ///
  /// Example usage:
  /// ```dart
  /// final reader = context.reader(subject);
  /// final name = reader.require<String>(foaf.name);
  /// final age = reader.require<int>(foaf.age);
  /// final friends = reader.getList<Person>(foaf.knows);
  /// ```
  ///
  /// Creates a reader for fluent access to resource properties.
  ///
  /// [subject] is the subject term (IRI or blank node) to read properties from.
  ///
  /// Returns a [ResourceReader] instance for fluent property access.
  ResourceReader reader(RdfSubject subject);

  /// Deserializes an RDF term into a typed Dart object.
  ///
  /// This method serves as the core deserialization mechanism, transforming any RDF term
  /// into its corresponding Dart representation. It handles both literal values and
  /// complex objects by leveraging the registry of deserializers or using a custom
  /// deserializer when provided.
  ///
  /// The method supports multiple RDF term types:
  /// - **Literal terms**: Converted to primitive Dart types (String, int, DateTime, etc.)
  /// - **IRI terms**: Processed as references to other resources or enum values
  /// - **Blank nodes**: Handled as anonymous objects or collection elements
  ///
  /// Example usage:
  /// ```dart
  /// final person = context.deserialize<Person>(personIri, deserializer: PersonDeserializer());
  /// final name = context.deserialize<String>(nameLiteral);
  /// final age = context.deserialize<int>(ageLiteral);
  /// ```
  ///
  /// [term] The RDF term to deserialize (IRI, blank node, or literal).
  /// [deserializer] Optional custom deserializer. If null, uses the registered deserializer for type T.
  ///
  /// Returns the deserialized object of type T.
  ///
  /// Throws [DeserializerNotFoundException] if no suitable deserializer is found or deserialization fails.
  T deserialize<T>(
    RdfTerm term, {
    Deserializer<T>? deserializer,
  });

  /// Retrieves all RDF triples where the given subject is the subject of the triple.
  ///
  /// This method provides direct access to the raw RDF graph data for a specific subject,
  /// enabling fine-grained control over the deserialization process. It's particularly
  /// useful when implementing custom deserializers that need to examine all properties
  /// of a resource or when performing complex graph traversals.
  ///
  /// The method supports filtering and tracking options to control the scope of
  /// retrieved triples and their impact on the completeness tracking system.
  ///
  /// **Blank Node Handling**: When `includeBlankNodes` is true, the method will also
  /// return triples where blank nodes that appear as objects in the original subject's
  /// triples are themselves used as subjects. This process continues recursively,
  /// following the entire chain of blank node references to enable complete traversal
  /// of deeply nested anonymous structures.
  ///
  /// **Tracking Integration**: The `trackRead` parameter controls whether the retrieved
  /// triples are automatically marked as processed in the completeness tracking system.
  /// Set to false when you need to examine triples without affecting tracking state.
  /// When `trackRead` is false, the caller is responsible for manually calling
  /// `trackTriplesRead` with the appropriate selection of triples to maintain
  /// completeness tracking accuracy.
  ///
  /// Example usage:
  /// ```dart
  /// // Get all triples for a person, including nested blank nodes
  /// final triples = context.getTriplesForSubject(personIri);
  ///
  /// // Examine triples without marking them as read
  /// final untracked = context.getTriplesForSubject(
  ///   personIri,
  ///   trackRead: false
  /// );
  /// ```
  ///
  /// [subject] The RDF subject (IRI or blank node) to retrieve triples for.
  /// [includeBlankNodes] Whether to include triples from referenced blank nodes (default: true).
  /// [trackRead] Whether to mark retrieved triples as read in the tracking system (default: true).
  ///
  /// Returns a list of triples where the subject matches the given parameter.
  Iterable<Triple> getTriplesForSubject(RdfSubject subject,
      {bool includeBlankNodes = true, bool trackRead = true});

  /// Manually tracks triples as being read/processed for a given subject.
  ///
  /// **Background**: The tracking system monitors which RDF triples have been
  /// consumed during deserialization to ensure complete mapping coverage.
  /// This enables detection of unmapped triples and validation that all RDF
  /// data has been correctly transformed into Dart objects. When serialization
  /// and deserialization code are consistent, this tracking mechanism helps
  /// verify that round-trip mapping (RDF → Dart → RDF) is complete and lossless.
  ///
  /// This method is typically used when automatic tracking has been suppressed,
  /// for example when calling `getTriplesForSubject(subject, trackRead=false)`,
  /// and you want to selectively mark specific triples as read/processed.
  ///
  /// [subject] The RDF subject for which the triples are being tracked.
  /// [triples] The list of triples to mark as read/processed.
  void trackTriplesRead(RdfSubject subject, Iterable<Triple> triples);

  /// Converts an RDF literal term into a typed Dart value.
  ///
  /// This method transforms an RDF literal (a data value in the RDF graph) into
  /// its corresponding Dart type. It leverages a registered deserializer for the
  /// specific target type or uses the provided custom deserializer if specified.
  ///
  /// This is a core utility for extracting primitive values like strings, numbers,
  /// dates, and booleans from RDF literals, handling datatype conversions and
  /// validation automatically.
  ///
  /// Example usage:
  /// ```dart
  /// final stringValue = context.fromLiteralTerm<String>(stringLiteral);
  /// final dateValue = context.fromLiteralTerm<DateTime>(dateLiteral);
  /// final customValue = context.fromLiteralTerm<MyType>(
  ///   literal,
  ///   deserializer: MyCustomDeserializer(),
  /// );
  /// ```
  ///
  /// The [term] parameter is the RDF literal term to be converted.
  /// An optional [deserializer] can be provided to use instead of the registered one.
  ///
  /// Returns the converted value of type T.
  ///
  /// Throws a [DeserializationException] if conversion fails or no suitable deserializer exists.
  T fromLiteralTerm<T>(LiteralTerm term,
      {LiteralTermDeserializer<T>? deserializer,
      bool bypassDatatypeCheck = false});
}
