import 'package:rdf_mapper/src/exceptions/rdf_mapping_exception.dart';

class SerializerNotFoundException extends RdfMappingException {
  final Type _t;
  final String _serializerType;
  SerializerNotFoundException(this._serializerType, this._t);

  @override
  String toString() =>
      'SerializerNotFoundException: (No $_serializerType Serializer found for ${_t.toString()})';
}
