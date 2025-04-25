import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/deserialization_context.dart';
import 'package:rdf_mapper/exceptions/property_value_not_found_exception.dart';
import 'package:rdf_mapper/exceptions/too_many_property_values_exception.dart';
import 'package:rdf_mapper/rdf_blank_node_term_deserializer.dart';
import 'package:rdf_mapper/rdf_iri_term_deserializer.dart';
import 'package:rdf_mapper/rdf_literal_term_deserializer.dart';
import 'package:rdf_mapper/rdf_subject_deserializer.dart';

/// Mock implementation of DeserializationContext for testing
class MockDeserializationContext implements DeserializationContext {
  final Map<String, Map<String, List<Object?>>> _propertyValues = {};

  void addPropertyValue(RdfTerm subject, RdfTerm property, Object? value) {
    final subjectKey = _getTermKey(subject);
    final propertyKey = _getTermKey(property);

    _propertyValues.putIfAbsent(subjectKey, () => {});
    _propertyValues[subjectKey]!.putIfAbsent(propertyKey, () => []);
    _propertyValues[subjectKey]![propertyKey]!.add(value);
  }

  @override
  T? getPropertyValue<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    RdfIriTermDeserializer<T>? iriDeserializer,
    RdfSubjectDeserializer<T>? subjectDeserializer,
    RdfLiteralTermDeserializer<T>? literalDeserializer,
    RdfBlankNodeTermDeserializer<T>? blankNodeDeserializer,
  }) {
    final subjectKey = _getTermKey(subject);
    final propertyKey = _getTermKey(predicate);

    if (!_propertyValues.containsKey(subjectKey)) {
      return null;
    }

    if (!_propertyValues[subjectKey]!.containsKey(propertyKey)) {
      return null;
    }

    final values = _propertyValues[subjectKey]![propertyKey]!;
    if (values.isEmpty) {
      return null;
    }

    if (enforceSingleValue && values.length > 1) {
      // Konvertieren zu RdfObject-Liste, indem wir nur RdfObject-Instanzen behalten
      final objectTerms = values.whereType<RdfObject>().toList();

      throw TooManyPropertyValuesException(
        subject: subject,
        predicate: predicate,
        objects: objectTerms,
      );
    }

    final value = values.first;
    return value as T?;
  }

  @override
  T getRequiredPropertyValue<T>(
    RdfSubject subject,
    RdfPredicate predicate, {
    bool enforceSingleValue = true,
    RdfSubjectDeserializer<T>? subjectDeserializer,
    RdfIriTermDeserializer<T>? iriDeserializer,
    RdfLiteralTermDeserializer<T>? literalDeserializer,
    RdfBlankNodeTermDeserializer<T>? blankNodeDeserializer,
  }) {
    final value = getPropertyValue<T>(
      subject,
      predicate,
      enforceSingleValue: enforceSingleValue,
      subjectDeserializer: subjectDeserializer,
      iriDeserializer: iriDeserializer,
      literalDeserializer: literalDeserializer,
      blankNodeDeserializer: blankNodeDeserializer,
    );

    if (value == null) {
      throw PropertyValueNotFoundException(
        subject: subject,
        predicate: predicate,
      );
    }

    return value;
  }

  @override
  R getPropertyValues<T, R>(
    RdfSubject subject,
    RdfPredicate predicate,
    R Function(Iterable<T>) collector, {
    RdfIriTermDeserializer<T>? iriDeserializer,
    RdfSubjectDeserializer<T>? subjectDeserializer,
    RdfLiteralTermDeserializer<T>? literalDeserializer,
    RdfBlankNodeTermDeserializer<T>? blankNodeDeserializer,
  }) {
    final subjectKey = _getTermKey(subject);
    final propertyKey = _getTermKey(predicate);

    if (!_propertyValues.containsKey(subjectKey)) {
      return collector([]);
    }

    if (!_propertyValues[subjectKey]!.containsKey(propertyKey)) {
      return collector([]);
    }

    final values = _propertyValues[subjectKey]![propertyKey]!;
    return collector(values.map((value) => value as T));
  }

  @override
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

  @override
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

  // Helper method to get a unique key for a term
  String _getTermKey(RdfTerm term) {
    if (term is IriTerm) {
      return 'iri:${term.iri}';
    } else if (term is BlankNodeTerm) {
      return 'blank:${term.label}';
    } else if (term is LiteralTerm) {
      return 'literal:${term.value}:${term.datatype.iri}:${term.language ?? ''}';
    }
    return term.toString();
  }
}
