import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/api/resource_reader.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

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

  List<Triple> getTriplesForSubject(RdfSubject subject,
      {bool includeBlankNodes = true});

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
