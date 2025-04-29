import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/serializers/literal_term_serializer.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';

abstract class BaseRdfLiteralTermSerializer<T>
    implements LiteralTermSerializer<T> {
  final IriTerm _datatype;
  final String Function(T value) _convertToString;

  BaseRdfLiteralTermSerializer({
    required IriTerm datatype,
    String Function(T value)? convertToString,
  }) : _datatype = datatype,
       _convertToString = convertToString ?? ((value) => value.toString());

  @override
  LiteralTerm toRdfTerm(T value, SerializationContext context) {
    return LiteralTerm(_convertToString(value), datatype: _datatype);
  }
}
