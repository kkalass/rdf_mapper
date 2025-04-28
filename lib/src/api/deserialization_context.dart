import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/src/deserializers/rdf_blank_node_term_deserializer.dart';
import 'package:rdf_mapper/src/deserializers/rdf_iri_term_deserializer.dart';
import 'package:rdf_mapper/src/deserializers/rdf_literal_term_deserializer.dart';
import 'package:rdf_mapper/src/deserializers/rdf_subject_deserializer.dart';

/// Context for deserialization operations
///
/// Provides access to services and state needed during RDF deserialization.
/// Used to delegate complex type reconstruction to the parent service.
abstract class DeserializationContext {
  /// Gets a required property value from the RDF graph
  ///
  /// In RDF, we have triples of "subject", "predicate", "object".
  /// This method retrieves the object value for the given subject-predicate pair
  /// and throws an exception if the value cannot be found.
  ///
  /// @param subject The subject IRI of the object we are working with
  /// @param predicate The predicate IRI of the property
  /// @param enforceSingleValue If true, we will throw an exception if there is more than one matching term.
  /// @return The object value of the property
  T require<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    RdfSubjectDeserializer<T>? subjectDeserializer,
    RdfIriTermDeserializer<T>? iriDeserializer,
    RdfLiteralTermDeserializer<T>? literalDeserializer,
    RdfBlankNodeTermDeserializer<T>? blankNodeDeserializer,
  });

  /// Gets an optional property value from the RDF graph
  ///
  /// Similar to [require], but returns null if the property is not found
  /// instead of throwing an exception.
  T? get<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    RdfIriTermDeserializer<T>? iriDeserializer,
    RdfSubjectDeserializer<T>? subjectDeserializer,
    RdfLiteralTermDeserializer<T>? literalDeserializer,
    RdfBlankNodeTermDeserializer<T>? blankNodeDeserializer,
  });

  /// Gets multiple property values and collects them with a custom collector function
  R getMany<T, R>(
    RdfSubject subject,
    RdfPredicate predicate,
    R Function(Iterable<T>) collector, {
    RdfIriTermDeserializer<T>? iriDeserializer,
    RdfSubjectDeserializer<T>? subjectDeserializer,
    RdfLiteralTermDeserializer<T>? literalDeserializer,
    RdfBlankNodeTermDeserializer<T>? blankNodeDeserializer,
  });

  /// Gets a list of property values
  ///
  /// Convenience method that collects multiple property values into a List.
  List<T> getList<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    RdfIriTermDeserializer<T>? iriDeserializer,
    RdfSubjectDeserializer<T>? subjectDeserializer,
    RdfLiteralTermDeserializer<T>? literalDeserializer,
    RdfBlankNodeTermDeserializer<T>? blankNodeDeserializer,
  }) => getMany<T, List<T>>(
    subject,
    predicate,
    (it) => it.toList(),
    iriDeserializer: iriDeserializer,
    subjectDeserializer: subjectDeserializer,
    literalDeserializer: literalDeserializer,
    blankNodeDeserializer: blankNodeDeserializer,
  );

  /// Gets a map of property values
  ///
  /// Convenience method that collects multiple property values into a Map.
  Map<K, V> getMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate, {
    RdfIriTermDeserializer<MapEntry<K, V>>? iriDeserializer,
    RdfSubjectDeserializer<MapEntry<K, V>>? subjectDeserializer,
    RdfLiteralTermDeserializer<MapEntry<K, V>>? literalDeserializer,
    RdfBlankNodeTermDeserializer<MapEntry<K, V>>? blankNodeDeserializer,
  }) => getMany<MapEntry<K, V>, Map<K, V>>(
    subject,
    predicate,
    (it) => Map<K, V>.fromEntries(it),
    iriDeserializer: iriDeserializer,
    subjectDeserializer: subjectDeserializer,
    literalDeserializer: literalDeserializer,
    blankNodeDeserializer: blankNodeDeserializer,
  );
}
