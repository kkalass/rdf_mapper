import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/xsd.dart';

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
    final isActualXsd = actual.value.startsWith(Xsd.namespace);
    final isExpectedXsd = expected.value.startsWith(Xsd.namespace);
    final shortActual = isActualXsd
        ? 'xsd:${actual.value.substring(Xsd.namespace.length)}'
        : actual.value;
    final shortExpected = isExpectedXsd
        ? 'xsd:${expected.value.substring(Xsd.namespace.length)}'
        : expected.value;
    final dartActual = isActualXsd
        ? 'Xsd.${actual.value.substring(Xsd.namespace.length)}'
        : "const IriTerm('${actual.value}')";
    final dartActualConstContext = isActualXsd
        ? 'Xsd.${actual.value.substring(Xsd.namespace.length)}'
        : "const IriTerm('${actual.value}')";
    final targetTypeCapitalized =
        '${targetType.toString()[0].toUpperCase()}${targetType.toString().substring(1)}';
    return '''
RDF Datatype Mismatch: Cannot deserialize ${shortActual} to ${targetType} (expected ${shortExpected})

Quick Fix during initialization (affects ALL ${targetType} instances):

final rdfMapper = RdfMapper.withMappers((registry) => registry.registerMapper<${targetType}>(${mapperRuntimeType}(${dartActual})))

Other Solutions:

1. Create a custom wrapper type (recommended for type safety):
   • Annotations library:

     @RdfLiteral(${dartActualConstContext})
     class MyCustom${targetTypeCapitalized} {
       @RdfValue()
       final ${targetType} value;
       const MyCustom${targetTypeCapitalized}(this.value);
     }
   
   • Manual:

     class MyCustom${targetTypeCapitalized} {
       final ${targetType} value;
       const MyCustom${targetTypeCapitalized}(this.value);
     }
     class MyCustom${mapperRuntimeType} extends DelegatingRdfLiteralTermMapper<MyCustom${targetTypeCapitalized}, double> {
       const MyCustom${mapperRuntimeType}() : super(const ${mapperRuntimeType}(), ${dartActual});
       @override
       MyCustom${targetTypeCapitalized} convertFrom(${targetType} value) => MyCustom${targetTypeCapitalized}(value);
       @override
       ${targetType} convertTo(MyCustom${targetTypeCapitalized} value) => value.value;
     }
     final rdfMapper = RdfMapper.withMappers((registry) => registry.registerMapper<MyCustom${targetTypeCapitalized}>(MyCustom${mapperRuntimeType}()));

2. Local scope for a specific predicate:
   • Annotations library (simpler option):

     @RdfProperty(myPredicate, literal: const LiteralMapping.withType(${dartActualConstContext}))

   • Annotations library (mapper instance):

     @RdfProperty(myPredicate,
         literal: LiteralMapping.mapperInstance(${mapperRuntimeType}(${dartActualConstContext})))

   • Manual (Custom resource mapper):

     reader.require(myPredicate, deserializer: ${mapperRuntimeType}(${dartActual}))
     builder.addValue(myPredicate, myValue, serializer: ${mapperRuntimeType}(${dartActual}))

3. Custom mapper bypass:
   Use bypassDatatypeCheck: true when calling context.fromLiteralTerm

Why this check exists:
Datatype strictness ensures roundtrip consistency - your ${targetType} will serialize back 
to the same RDF datatype (${shortExpected}), preserving semantic meaning and preventing data corruption.
''';
  }
}
