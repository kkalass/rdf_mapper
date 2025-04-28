import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/exceptions/rdf_mapping_exception.dart';

/// Exception thrown when a required property value is not found in the RDF graph
///
/// Used during deserialization when a required property is missing from the data.
class PropertyValueNotFoundException extends RdfMappingException {
  final RdfSubject subject;
  final RdfPredicate predicate;

  /// Creates a new PropertyValueNotFoundException
  ///
  /// @param message Description of the error
  /// @param subject The subject IRI where the property was expected
  /// @param predicate The predicate IRI of the missing property
  PropertyValueNotFoundException({
    required this.subject,
    required this.predicate,
  });

  @override
  String toString() =>
      'PropertyValueNotFoundException: (Subject: $subject, Predicate: $predicate)';
}
