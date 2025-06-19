import 'package:mockito/annotations.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_vocabularies/xsd.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';

import 'package:test/test.dart';

import 'package:rdf_mapper/src/api/deserialization_context.dart';

@GenerateMocks([DeserializationContext])
import 'literal_term_deserializer_test.mocks.dart';

void main() {
  group('LiteralTermDeserializer', () {
    late MockDeserializationContext context;

    setUp(() {
      context = MockDeserializationContext();
    });

    test('string deserializer correctly converts string literals', () {
      final deserializer = StringLiteralDeserializer();

      // Test with simple string literal
      final term = LiteralTerm.string('Hello World');
      final result = deserializer.fromRdfTerm(term, context);

      expect(result, equals('Hello World'));
    });

    test('string deserializer handles language-tagged literals', () {
      final deserializer = StringLiteralDeserializer();

      // Test with language-tagged literal
      final term = LiteralTerm.withLanguage('Hello World', 'en');
      final result = deserializer.fromRdfTerm(term, context);

      expect(result, equals('Hello World'));
    });

    test('integer deserializer correctly converts integer literals', () {
      final deserializer = IntegerLiteralDeserializer();

      // Test with integer literal
      final term = LiteralTerm('42', datatype: Xsd.integer);
      final result = deserializer.fromRdfTerm(term, context);

      expect(result, equals(42));
    });

    test('integer deserializer handles invalid input', () {
      final deserializer = IntegerLiteralDeserializer();

      // Test with non-integer literal
      final term = LiteralTerm('not-a-number', datatype: Xsd.integer);

      expect(
        () => deserializer.fromRdfTerm(term, context),
        throwsA(isA<FormatException>()),
      );
    });

    test('boolean deserializer correctly converts boolean literals', () {
      final deserializer = BooleanLiteralDeserializer();

      // Test with boolean literals
      final trueTerm = LiteralTerm('true', datatype: Xsd.boolean);
      final falseTerm = LiteralTerm('false', datatype: Xsd.boolean);

      expect(deserializer.fromRdfTerm(trueTerm, context), isTrue);
      expect(deserializer.fromRdfTerm(falseTerm, context), isFalse);
    });

    test('boolean deserializer handles case-insensitive values', () {
      final deserializer = BooleanLiteralDeserializer();

      // Test with different casing
      final trueTerm = LiteralTerm('TRUE', datatype: Xsd.boolean);
      final falseTerm = LiteralTerm('False', datatype: Xsd.boolean);

      expect(deserializer.fromRdfTerm(trueTerm, context), isTrue);
      expect(deserializer.fromRdfTerm(falseTerm, context), isFalse);
    });

    test('double deserializer correctly converts double literals', () {
      final deserializer = DoubleLiteralDeserializer();

      // Test with double literal
      final term = LiteralTerm('3.14159', datatype: Xsd.double);
      final result = deserializer.fromRdfTerm(term, context);

      expect(result, equals(3.14159));
    });

    test('custom literal deserializer handles complex types', () {
      // Create a custom deserializer
      final deserializer = CustomLiteralDeserializer();

      // Test with a custom literal format
      final term = LiteralTerm(
        'x:10,y:20',
        datatype: IriTerm('http://example.org/Point'),
      );
      final result = deserializer.fromRdfTerm(term, context);

      expect(result.x, equals(10));
      expect(result.y, equals(20));
    });
  });
}

/// Test implementation of a custom RdfLiteralTermDeserializer for Point objects
class CustomLiteralDeserializer implements LiteralTermDeserializer<Point> {
  const CustomLiteralDeserializer();
  @override
  Point fromRdfTerm(
    LiteralTerm term,
    covariant MockDeserializationContext context,
  ) {
    // Simple parsing logic for a string like "x:10,y:20"
    final parts = term.value.split(',');
    final x = int.parse(parts[0].split(':')[1]);
    final y = int.parse(parts[1].split(':')[1]);
    return Point(x, y);
  }
}

/// Simple Point class for testing custom deserialization
class Point {
  final int x;
  final int y;

  Point(this.x, this.y);
}

/// Implementation of the standard string deserializer for testing
class StringLiteralDeserializer implements LiteralTermDeserializer<String> {
  const StringLiteralDeserializer();
  @override
  String fromRdfTerm(
    LiteralTerm term,
    covariant MockDeserializationContext context,
  ) {
    return term.value;
  }
}

/// Implementation of the standard integer deserializer for testing
class IntegerLiteralDeserializer implements LiteralTermDeserializer<int> {
  const IntegerLiteralDeserializer();
  @override
  int fromRdfTerm(
    LiteralTerm term,
    covariant MockDeserializationContext context,
  ) {
    return int.parse(term.value);
  }
}

/// Implementation of the standard boolean deserializer for testing
class BooleanLiteralDeserializer implements LiteralTermDeserializer<bool> {
  const BooleanLiteralDeserializer();
  @override
  bool fromRdfTerm(
    LiteralTerm term,
    covariant MockDeserializationContext context,
  ) {
    return term.value.toLowerCase() == 'true';
  }
}

/// Implementation of the standard double deserializer for testing
class DoubleLiteralDeserializer implements LiteralTermDeserializer<double> {
  const DoubleLiteralDeserializer();
  @override
  double fromRdfTerm(
    LiteralTerm term,
    covariant MockDeserializationContext context,
  ) {
    return double.parse(term.value);
  }
}
