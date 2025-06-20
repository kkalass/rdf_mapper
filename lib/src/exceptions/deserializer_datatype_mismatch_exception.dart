import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies/xsd.dart';

/// Exception thrown when a deserializer encounters a datatype in the RDF graph which does not match the expected type.
///
/// This exception enforces datatype strictness to ensure roundtrip consistency - when a Dart object
/// is serialized back to RDF, it maintains the same datatype as the original RDF literal. This preserves
/// semantic meaning and prevents data corruption in RDF stores.
///
/// The exception can be bypassed by setting `bypassDatatypeCheck: true` in scenarios where flexible
/// datatype handling is required, but this should be used carefully as it may break roundtrip guarantees.
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
        : "IriTerm('${actual.iri}')";
    final dartActualConstContext = isActualXsd
        ? 'Xsd.${actual.iri.substring(Xsd.namespace.length)}'
        : "IriTerm.prevalidated('${actual.iri}')";

    return '''
RDF Datatype Mismatch: Cannot deserialize ${shortActual} to ${targetType} (expected ${shortExpected})

Quick Fix during initialization (affects ALL ${targetType} instances):
final rdfMapper = RdfMapper.withMappers((registry) => registry.registerMapper(${mapperRuntimeType}(${dartActual})))

Other Solutions:
1. Custom resource mapper (local scope for a specific predicate):
   reader.require(myPredicate, literalTermDeserializer: ${mapperRuntimeType}(${dartActual}))

2. Annotations library (local scope for a specific predicate):
   @RdfProperty(iri: myPredicate, literal: LiteralMapping.mapperInstance(${mapperRuntimeType}(${dartActualConstContext})))

3. Custom mapper bypass:
   Use bypassDatatypeCheck: true when calling context.fromLiteralTerm

Why this check exists:
Datatype strictness ensures roundtrip consistency - your ${targetType} will serialize back 
to the same RDF datatype (${shortExpected}), preserving semantic meaning and preventing data corruption.
''';
  }
}
