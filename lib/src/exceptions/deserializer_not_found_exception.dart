import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/src/exceptions/rdf_mapping_exception.dart';

class DeserializerNotFoundException extends RdfMappingException {
  final String _t;
  final String _serializerType;

  DeserializerNotFoundException(this._serializerType, Type type)
    : _t = type.toString();

  DeserializerNotFoundException.forTypeIri(this._serializerType, IriTerm type)
    : _t = type.iri;

  @override
  String toString() =>
      'DeserializerNotFoundException: (No $_serializerType Deserializer found for $_t)';
}
