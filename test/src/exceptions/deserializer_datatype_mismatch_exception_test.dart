import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/xsd.dart';
import 'package:test/test.dart';

import '../deserializers/mock_deserialization_context.dart';

void main() {
  group('DeserializerDatatypeMismatchException', () {
    late MockDeserializationContext context;

    setUp(() {
      context = MockDeserializationContext();
    });

    group('datatype mismatch error handling', () {
      test(
          'DoubleMapper throws DeserializerDatatypeMismatchException on wrong datatype',
          () {
        const mapper = DoubleMapper();

        // Create a term with wrong datatype (string instead of decimal)
        final wrongTypeTerm = LiteralTerm('3.14', datatype: Xsd.string);

        expect(
          () => mapper.fromRdfTerm(wrongTypeTerm, context),
          throwsA(
            allOf(
              isA<DeserializerDatatypeMismatchException>(),
              predicate<DeserializerDatatypeMismatchException>((e) =>
                  e.actual == Xsd.string &&
                  e.expected == Xsd.decimal &&
                  e.targetType == double &&
                  e.mapperRuntimeType == DoubleMapper),
            ),
          ),
        );
      });

      test(
          'IntMapper throws DeserializerDatatypeMismatchException on wrong datatype',
          () {
        const mapper = IntMapper();

        // Create a term with wrong datatype (string instead of integer)
        final wrongTypeTerm = LiteralTerm('42', datatype: Xsd.string);

        expect(
          () => mapper.fromRdfTerm(wrongTypeTerm, context),
          throwsA(
            allOf(
              isA<DeserializerDatatypeMismatchException>(),
              predicate<DeserializerDatatypeMismatchException>((e) =>
                  e.actual == Xsd.string &&
                  e.expected == Xsd.integer &&
                  e.targetType == int &&
                  e.mapperRuntimeType == IntMapper),
            ),
          ),
        );
      });

      test(
          'StringMapper throws DeserializerDatatypeMismatchException on wrong datatype',
          () {
        const mapper = StringMapper();

        // Create a term with wrong datatype (integer instead of string)
        final wrongTypeTerm = LiteralTerm('hello', datatype: Xsd.integer);

        expect(
          () => mapper.fromRdfTerm(wrongTypeTerm, context),
          throwsA(
            allOf(
              isA<DeserializerDatatypeMismatchException>(),
              predicate<DeserializerDatatypeMismatchException>((e) =>
                  e.actual == Xsd.integer &&
                  e.expected == Xsd.string &&
                  e.targetType == String),
            ),
          ),
        );
      });

      test(
          'BoolMapper throws DeserializerDatatypeMismatchException on wrong datatype',
          () {
        const mapper = BoolMapper();

        // Create a term with wrong datatype (string instead of boolean)
        final wrongTypeTerm = LiteralTerm('true', datatype: Xsd.string);

        expect(
          () => mapper.fromRdfTerm(wrongTypeTerm, context),
          throwsA(
            allOf(
              isA<DeserializerDatatypeMismatchException>(),
              predicate<DeserializerDatatypeMismatchException>((e) =>
                  e.actual == Xsd.string &&
                  e.expected == Xsd.boolean &&
                  e.targetType == bool &&
                  e.mapperRuntimeType == BoolMapper),
            ),
          ),
        );
      });
    });

    group('bypassDatatypeCheck parameter functionality', () {
      test('DoubleMapper bypasses datatype check when bypassDatatypeCheck=true',
          () {
        const mapper = DoubleMapper();

        // Create a term with wrong datatype
        final wrongTypeTerm = LiteralTerm('3.14', datatype: Xsd.string);

        // Should not throw when bypassing datatype check
        expect(
          () => mapper.fromRdfTerm(wrongTypeTerm, context,
              bypassDatatypeCheck: true),
          returnsNormally,
        );

        // Should return the parsed value
        final result = mapper.fromRdfTerm(wrongTypeTerm, context,
            bypassDatatypeCheck: true);
        expect(result, equals(3.14));
      });

      test('IntMapper bypasses datatype check when bypassDatatypeCheck=true',
          () {
        const mapper = IntMapper();

        // Create a term with wrong datatype
        final wrongTypeTerm = LiteralTerm('42', datatype: Xsd.string);

        // Should not throw when bypassing datatype check
        expect(
          () => mapper.fromRdfTerm(wrongTypeTerm, context,
              bypassDatatypeCheck: true),
          returnsNormally,
        );

        // Should return the parsed value
        final result = mapper.fromRdfTerm(wrongTypeTerm, context,
            bypassDatatypeCheck: true);
        expect(result, equals(42));
      });

      test('StringMapper bypasses datatype check when bypassDatatypeCheck=true',
          () {
        const mapper = StringMapper();

        // Create a term with wrong datatype
        final wrongTypeTerm = LiteralTerm('hello', datatype: Xsd.integer);

        // Should not throw when bypassing datatype check
        expect(
          () => mapper.fromRdfTerm(wrongTypeTerm, context,
              bypassDatatypeCheck: true),
          returnsNormally,
        );

        // Should return the value
        final result = mapper.fromRdfTerm(wrongTypeTerm, context,
            bypassDatatypeCheck: true);
        expect(result, equals('hello'));
      });

      test('BoolMapper bypasses datatype check when bypassDatatypeCheck=true',
          () {
        const mapper = BoolMapper();

        // Create a term with wrong datatype
        final wrongTypeTerm = LiteralTerm('true', datatype: Xsd.string);

        // Should not throw when bypassing datatype check
        expect(
          () => mapper.fromRdfTerm(wrongTypeTerm, context,
              bypassDatatypeCheck: true),
          returnsNormally,
        );

        // Should return the parsed value
        final result = mapper.fromRdfTerm(wrongTypeTerm, context,
            bypassDatatypeCheck: true);
        expect(result, isTrue);
      });
    });

    group('exception message formatting', () {
      test('provides helpful error message with XSD datatypes', () {
        const mapper = DoubleMapper();
        final wrongTypeTerm = LiteralTerm('3.14', datatype: Xsd.double);

        try {
          mapper.fromRdfTerm(wrongTypeTerm, context);
          fail('Expected DeserializerDatatypeMismatchException');
        } catch (e) {
          expect(e, isA<DeserializerDatatypeMismatchException>());
          final exception = e as DeserializerDatatypeMismatchException;
          final message = exception.toString();

          expect(
              message.trim(),
              equals('''
RDF Datatype Mismatch: Cannot deserialize xsd:double to double (expected xsd:decimal)

Quick Fix during initialization (affects ALL double instances):

final rdfMapper = RdfMapper.withMappers((registry) => registry.registerMapper<double>(DoubleMapper(Xsd.double)))

Other Solutions:

1. Create a custom wrapper type (recommended for type safety):
   • Annotations library:

     @RdfLiteral(Xsd.double)
     class MyCustomDouble {
       @RdfValue()
       final double value;
       const MyCustomDouble(this.value);
     }
   
   • Manual:

     class MyCustomDouble {
       final double value;
       const MyCustomDouble(this.value);
     }
     class MyCustomDoubleMapper extends DelegatingRdfLiteralTermMapper<MyCustomDouble, double> {
       const MyCustomDoubleMapper() : super(const DoubleMapper(), Xsd.double);
       @override
       MyCustomDouble convertFrom(double value) => MyCustomDouble(value);
       @override
       double convertTo(MyCustomDouble value) => value.value;
     }
     final rdfMapper = RdfMapper.withMappers((registry) => registry.registerMapper<MyCustomDouble>(MyCustomDoubleMapper()));

2. Local scope for a specific predicate:
   • Annotations library (simpler option):

     @RdfProperty(myPredicate, literal: const LiteralMapping.withType(Xsd.double))

   • Annotations library (mapper instance):

     @RdfProperty(myPredicate,
         literal: LiteralMapping.mapperInstance(DoubleMapper(Xsd.double)))

   • Manual (Custom resource mapper):

     reader.require(myPredicate, deserializer: DoubleMapper(Xsd.double))
     builder.addValue(myPredicate, myValue, serializer: DoubleMapper(Xsd.double))

3. Custom mapper bypass:
   Use bypassDatatypeCheck: true when calling context.fromLiteralTerm

Why this check exists:
Datatype strictness ensures roundtrip consistency - your double will serialize back 
to the same RDF datatype (xsd:decimal), preserving semantic meaning and preventing data corruption.
'''
                  .trim()));
        }
      });

      test('provides helpful error message with custom datatypes', () {
        final customDatatype =
            const IriTerm('http://example.org/custom-number-type');
        final mapper = DoubleMapper(customDatatype);
        final wrongTypeTerm = LiteralTerm('3.14',
            datatype: const IriTerm('http://example.org/other-number-type'));

        try {
          mapper.fromRdfTerm(wrongTypeTerm, context);
          fail('Expected DeserializerDatatypeMismatchException');
        } catch (e) {
          expect(e, isA<DeserializerDatatypeMismatchException>());
          final exception = e as DeserializerDatatypeMismatchException;
          final message = exception.toString();
          expect(
              message.trim(),
              equals('''
RDF Datatype Mismatch: Cannot deserialize http://example.org/other-number-type to double (expected http://example.org/custom-number-type)

Quick Fix during initialization (affects ALL double instances):

final rdfMapper = RdfMapper.withMappers((registry) => registry.registerMapper<double>(DoubleMapper(const IriTerm('http://example.org/other-number-type'))))

Other Solutions:

1. Create a custom wrapper type (recommended for type safety):
   • Annotations library:

     @RdfLiteral(const IriTerm('http://example.org/other-number-type'))
     class MyCustomDouble {
       @RdfValue()
       final double value;
       const MyCustomDouble(this.value);
     }
   
   • Manual:

     class MyCustomDouble {
       final double value;
       const MyCustomDouble(this.value);
     }
     class MyCustomDoubleMapper extends DelegatingRdfLiteralTermMapper<MyCustomDouble, double> {
       const MyCustomDoubleMapper() : super(const DoubleMapper(), const IriTerm('http://example.org/other-number-type'));
       @override
       MyCustomDouble convertFrom(double value) => MyCustomDouble(value);
       @override
       double convertTo(MyCustomDouble value) => value.value;
     }
     final rdfMapper = RdfMapper.withMappers((registry) => registry.registerMapper<MyCustomDouble>(MyCustomDoubleMapper()));

2. Local scope for a specific predicate:
   • Annotations library (simpler option):

     @RdfProperty(myPredicate, literal: const LiteralMapping.withType(const IriTerm('http://example.org/other-number-type')))

   • Annotations library (mapper instance):

     @RdfProperty(myPredicate,
         literal: LiteralMapping.mapperInstance(DoubleMapper(const IriTerm('http://example.org/other-number-type'))))

   • Manual (Custom resource mapper):

     reader.require(myPredicate, deserializer: DoubleMapper(const IriTerm('http://example.org/other-number-type')))
     builder.addValue(myPredicate, myValue, serializer: DoubleMapper(const IriTerm('http://example.org/other-number-type')))

3. Custom mapper bypass:
   Use bypassDatatypeCheck: true when calling context.fromLiteralTerm

Why this check exists:
Datatype strictness ensures roundtrip consistency - your double will serialize back 
to the same RDF datatype (http://example.org/custom-number-type), preserving semantic meaning and preventing data corruption.
'''
                  .trim()));
        }
      });

      test('exception includes all required properties', () {
        const mapper = IntMapper();
        final wrongTypeTerm = LiteralTerm('42', datatype: Xsd.string);

        try {
          mapper.fromRdfTerm(wrongTypeTerm, context);
          fail('Expected DeserializerDatatypeMismatchException');
        } catch (e) {
          expect(e, isA<DeserializerDatatypeMismatchException>());
          final exception = e as DeserializerDatatypeMismatchException;

          expect(exception.actual, equals(Xsd.string));
          expect(exception.expected, equals(Xsd.integer));
          expect(exception.targetType, equals(int));
          expect(exception.mapperRuntimeType, equals(IntMapper));
          expect(exception.message, isNotEmpty);
        }
      });
    });

    group('successful deserialization with correct datatypes', () {
      test('DoubleMapper deserializes correctly with xsd:decimal', () {
        const mapper = DoubleMapper();
        final correctTerm = LiteralTerm('3.14159', datatype: Xsd.decimal);

        final result = mapper.fromRdfTerm(correctTerm, context);
        expect(result, equals(3.14159));
      });

      test('IntMapper deserializes correctly with xsd:integer', () {
        const mapper = IntMapper();
        final correctTerm = LiteralTerm('42', datatype: Xsd.integer);

        final result = mapper.fromRdfTerm(correctTerm, context);
        expect(result, equals(42));
      });

      test('StringMapper deserializes correctly with xsd:string', () {
        const mapper = StringMapper();
        final correctTerm = LiteralTerm('hello world', datatype: Xsd.string);

        final result = mapper.fromRdfTerm(correctTerm, context);
        expect(result, equals('hello world'));
      });

      test('BoolMapper deserializes correctly with xsd:boolean', () {
        const mapper = BoolMapper();
        final trueTerm = LiteralTerm('true', datatype: Xsd.boolean);
        final falseTerm = LiteralTerm('false', datatype: Xsd.boolean);

        final trueResult = mapper.fromRdfTerm(trueTerm, context);
        final falseResult = mapper.fromRdfTerm(falseTerm, context);

        expect(trueResult, isTrue);
        expect(falseResult, isFalse);
      });
    });

    group('custom datatype mappers', () {
      test('DoubleMapper with custom datatype throws on mismatch', () {
        final customDatatype = const IriTerm('http://example.org/my-decimal');
        final mapper = DoubleMapper(customDatatype);
        final wrongTypeTerm = LiteralTerm('3.14', datatype: Xsd.decimal);

        expect(
          () => mapper.fromRdfTerm(wrongTypeTerm, context),
          throwsA(
            allOf(
              isA<DeserializerDatatypeMismatchException>(),
              predicate<DeserializerDatatypeMismatchException>((e) =>
                  e.actual == Xsd.decimal &&
                  e.expected == customDatatype &&
                  e.targetType == double),
            ),
          ),
        );
      });

      test('DoubleMapper with custom datatype works with correct type', () {
        final customDatatype = const IriTerm('http://example.org/my-decimal');
        final mapper = DoubleMapper(customDatatype);
        final correctTerm = LiteralTerm('3.14', datatype: customDatatype);

        final result = mapper.fromRdfTerm(correctTerm, context);
        expect(result, equals(3.14));
      });
    });
  });
}
