import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies/xsd.dart';

/// Exception thrown when a deserializer encounters a datatype in the RDF graph which does not match the expected type.
///
class DeserializerDatatypeMismatchException extends DeserializationException {
  final IriTerm actual;
  final IriTerm expected;
  final String message;
  final Type? mapperRuntimeType;
  final Type targetType;
  DeserializerDatatypeMismatchException(
    this.message, {
    required this.actual,
    required this.expected,
    required this.targetType,
    this.mapperRuntimeType,
  });

  @override
  String toString() {
    final isActualXsd = actual.iri.startsWith(Xsd.namespace);
    final isExpectedXsd = expected.iri.startsWith(Xsd.namespace);
    final shortActual = isActualXsd
        ? 'xsd:${actual.iri.substring(Xsd.namespace.length)}'
        : actual.iri;
    final shortExpected = isExpectedXsd
        ? 'xsd:${expected.iri.substring(Xsd.namespace.length)}'
        : expected.iri;
    final dartActual = isActualXsd
        ? 'Xsd.${actual.iri.substring(Xsd.namespace.length)}'
        : actual.iri;

    return '''
RDF Datatype Mismatch: Cannot deserialize ${shortActual} to Dart ${targetType} (expected ${shortExpected})

The RDF term has datatype '${actual.iri}' 
but the ${mapperRuntimeType} deserializer expects '${expected.iri}'.

Solutions:
1. Use a custom mapper on your property:
   @RdfProperty(iri: IriTerm.prevalidated('http://example.com/your-property-iri'),
       literal: LiteralMapping.mapperInstance(${mapperRuntimeType}(${dartActual})))

2. If you are delegating to `context.fromLiteralTerm` in a custom mapper use bypassDatatypeCheck: true

3. Consider if your RDF data or Dart model needs adjustment for consistency
''';
  }
}
