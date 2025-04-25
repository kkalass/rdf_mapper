import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/rdf_blank_node_term_deserializer.dart';
import 'package:rdf_mapper/rdf_iri_term_deserializer.dart';
import 'package:rdf_mapper/rdf_literal_term_deserializer.dart';
import 'package:rdf_mapper/rdf_subject_deserializer.dart';

/// Context for deserialization operations
///
/// Provides access to services and state needed during RDF deserialization.
/// Used to delegate complex type reconstruction to the parent service.
abstract class DeserializationContext {
  /// Gets a property value from the RDF graph
  ///
  /// In RDF, we have triples of "subject", "predicate", "object".
  /// Translated to pure dart, the subject is the object we are working with,
  /// the predicate is the property we are looking for, and the object is
  /// the value we are looking for.
  ///
  /// @param subject The subject IRI of the object we are working with
  /// @param predicate The predicate IRI of the property
  /// @param failOnMultivalue If true, we will throw an exception if there is more than one matching term.
  /// @return The object value of the property
  T getRequiredPropertyValue<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    RdfSubjectDeserializer<T>? subjectDeserializer,
    RdfIriTermDeserializer<T>? iriDeserializer,
    RdfLiteralTermDeserializer<T>? literalDeserializer,
    RdfBlankNodeTermDeserializer<T>? blankNodeDeserializer,
  });

  T? getPropertyValue<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    RdfIriTermDeserializer<T>? iriDeserializer,
    RdfSubjectDeserializer<T>? subjectDeserializer,
    RdfLiteralTermDeserializer<T>? literalDeserializer,
    RdfBlankNodeTermDeserializer<T>? blankNodeDeserializer,
  });

  R getPropertyValues<T, R>(
    RdfSubject subject,
    RdfPredicate predicate,
    R Function(Iterable<T>) collector, {
    RdfIriTermDeserializer<T>? iriDeserializer,
    RdfSubjectDeserializer<T>? subjectDeserializer,
    RdfLiteralTermDeserializer<T>? literalDeserializer,
    RdfBlankNodeTermDeserializer<T>? blankNodeDeserializer,
  });

  List<T> getPropertyValueList<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    RdfIriTermDeserializer<T>? iriDeserializer,
    RdfSubjectDeserializer<T>? subjectDeserializer,
    RdfLiteralTermDeserializer<T>? literalDeserializer,
    RdfBlankNodeTermDeserializer<T>? blankNodeDeserializer,
  }) => getPropertyValues<T, List<T>>(
    subject,
    predicate,
    (it) => it.toList(),
    iriDeserializer: iriDeserializer,
    subjectDeserializer: subjectDeserializer,
    literalDeserializer: literalDeserializer,
    blankNodeDeserializer: blankNodeDeserializer,
  );

  Map<K, V> getPropertyValueMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate, {
    RdfIriTermDeserializer<MapEntry<K, V>>? iriDeserializer,
    RdfSubjectDeserializer<MapEntry<K, V>>? subjectDeserializer,
    RdfLiteralTermDeserializer<MapEntry<K, V>>? literalDeserializer,
    RdfBlankNodeTermDeserializer<MapEntry<K, V>>? blankNodeDeserializer,
  }) => getPropertyValues<MapEntry<K, V>, Map<K, V>>(
    subject,
    predicate,
    (it) => Map<K, V>.fromEntries(it),
    iriDeserializer: iriDeserializer,
    subjectDeserializer: subjectDeserializer,
    literalDeserializer: literalDeserializer,
    blankNodeDeserializer: blankNodeDeserializer,
  );
}
