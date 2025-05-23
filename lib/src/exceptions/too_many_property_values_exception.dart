import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/exceptions/rdf_mapping_exception.dart';

/// Exception thrown when multiple values are found for a single-valued property.
///
/// This exception occurs during deserialization when a property is expected to have
/// at most one value, but multiple values are found in the RDF graph. This typically
/// happens when using methods like `ResourceReader.require` or `ResourceReader.get` with
/// the default enforceSingleValue parameter set to true.
///
/// The exception contains detailed information about the subject, predicate, and
/// the list of object values that were found, which can be useful for diagnosing
/// data inconsistencies.
class TooManyPropertyValuesException extends RdfMappingException {
  /// The RDF subject where the property was found
  final RdfSubject subject;

  /// The predicate representing the property
  final RdfPredicate predicate;

  /// The list of object values found for the property
  final List<RdfObject> objects;

  /// Creates a new exception for when too many values are found for a property.
  ///
  /// @param subject The subject where the property was found
  /// @param predicate The predicate representing the property
  /// @param objects The list of object values found
  TooManyPropertyValuesException({
    required this.subject,
    required this.predicate,
    required this.objects,
  });

  @override
  String toString() =>
      'TooManyPropertyValuesException: Found ${objects.length} Objects, but expected only one. (Subject: $subject, Predicate: $predicate)';
}
