import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

abstract class DelegatingRdfLiteralTermMapper<T, V>
    implements LiteralTermMapper<T> {
  final LiteralTermMapper<V> mapper;
  final IriTerm datatype;

  const DelegatingRdfLiteralTermMapper(this.mapper, this.datatype);

  T convertFrom(V value);

  V convertTo(T value);

  @override
  T fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    if (!bypassDatatypeCheck && term.datatype != datatype) {
      throw DeserializerDatatypeMismatchException(
          'Failed to parse ${T.toString()}: ${term.value}. ',
          actual: term.datatype,
          expected: datatype,
          targetType: T,
          mapperRuntimeType: this.runtimeType);
    }
    try {
      // we handle the datatype ourselves
      var value = mapper.fromRdfTerm(term, context, bypassDatatypeCheck: true);
      return convertFrom(value);
    } catch (e) {
      throw DeserializationException(
        'Failed to parse ${T.toString()}: ${term.value}. Error: $e',
      );
    }
  }

  LiteralTerm toRdfTerm(T value, SerializationContext context) {
    var term = mapper.toRdfTerm(convertTo(value), context);
    return LiteralTerm(term.value, datatype: datatype);
  }
}
