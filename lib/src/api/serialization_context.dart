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
/// This is typically used by [ResourceMapper] implementations to convert
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
}
