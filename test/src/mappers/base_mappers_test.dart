import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/exceptions/deserialization_exception.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_deserializer.dart';
import 'package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_serializer.dart';
import 'package:rdf_vocabularies_core/xsd.dart';
import 'package:test/test.dart';

import '../deserializers/mock_deserialization_context.dart';
import '../serializers/mock_serialization_context.dart';

// Concrete implementation for testing BaseRdfLiteralTermSerializer
class TestPointSerializer extends BaseRdfLiteralTermSerializer<Point> {
  const TestPointSerializer({IriTerm? datatype})
      : super(
          datatype: datatype ?? Xsd.string,
        );
  @override
  convertToString(point) => '${point.x},${point.y}';
}

// Custom language tag serializer implementation
class LangTaggedSerializer extends BaseRdfLiteralTermSerializer<String> {
  final String langTag;

  const LangTaggedSerializer(this.langTag) : super(datatype: Xsd.string);

  @override
  convertToString(value) => value;

  @override
  LiteralTerm toRdfTerm(String value, SerializationContext context) {
    return LiteralTerm.withLanguage(value, langTag);
  }
}

// Concrete implementation for testing BaseRdfLiteralTermDeserializer
class TestPointDeserializer extends BaseRdfLiteralTermDeserializer<Point> {
  const TestPointDeserializer({IriTerm? datatype})
      : super(
          datatype: datatype ?? Xsd.string,
        );

  @override
  convertFromLiteral(term, _) {
    final parts = term.value.split(',');
    return Point(int.parse(parts[0]), int.parse(parts[1]));
  }
}

// Deserializer that accepts language-tagged literals
class LangTagTestDeserializer extends BaseRdfLiteralTermDeserializer<String> {
  const LangTagTestDeserializer()
      : super(
          datatype: Xsd.string,
        );

  @override
  convertFromLiteral(term, _) => term.value;

  @override
  String fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    if (term.language != null) {
      return term.value;
    }
    return super.fromRdfTerm(term, context);
  }
}

void main() {
  late SerializationContext serializationContext;
  late DeserializationContext deserializationContext;

  setUp(() {
    serializationContext = MockSerializationContext();
    deserializationContext = MockDeserializationContext();
  });

  group('Base Mapper Classes', () {
    group('BaseRdfLiteralTermSerializer', () {
      test('serializes values using conversion function', () {
        // Create a custom serializer for a complex type
        final serializer = TestPointSerializer();

        final point = Point(10, 20);
        final term = serializer.toRdfTerm(point, serializationContext);

        expect(term, isA<LiteralTerm>());
        expect(term.value, equals('10,20'));
        expect(term.datatype, equals(Xsd.string));
      });

      test('uses custom datatype when provided', () {
        final customDatatype = const IriTerm('http://example.org/point');
        final serializer = TestPointSerializer(datatype: customDatatype);

        final term = serializer.toRdfTerm(Point(10, 20), serializationContext);

        expect(term, isA<LiteralTerm>());
        expect(term.value, equals('10,20'));
        expect(term.datatype, equals(customDatatype));
      });

      test('can be extended to support language tags', () {
        final serializer = LangTaggedSerializer('de');

        final term = serializer.toRdfTerm('Hallo Welt', serializationContext);

        expect(term, isA<LiteralTerm>());
        expect(term.value, equals('Hallo Welt'));
        expect(term.language, equals('de'));
      });

      test('can be extended for custom type handling', () {
        // A custom serializer for color values
        final colorSerializer = ColorSerializer();

        final color = Color(255, 0, 128);
        final term = colorSerializer.toRdfTerm(color, serializationContext);

        expect(term, isA<LiteralTerm>());
        expect(term.value.toLowerCase(), equals('#ff0080'));
        expect(
            term.datatype, equals(const IriTerm('http://example.org/color')));
      });
    });

    group('BaseRdfLiteralTermDeserializer', () {
      test('deserializes values using conversion function', () {
        // Create a custom deserializer for a complex type
        final deserializer = TestPointDeserializer();

        final term = LiteralTerm.string('10,20');
        final point = deserializer.fromRdfTerm(term, deserializationContext);

        expect(point, isA<Point>());
        expect(point.x, equals(10));
        expect(point.y, equals(20));
      });

      test('validates datatype against required datatype', () {
        final customDatatype = const IriTerm('http://example.org/point');
        final deserializer = TestPointDeserializer(datatype: customDatatype);

        // Valid datatype
        final validTerm = LiteralTerm('10,20', datatype: customDatatype);
        final point = deserializer.fromRdfTerm(
          validTerm,
          deserializationContext,
        );
        expect(point, isA<Point>());

        // Invalid datatype
        final invalidTerm = LiteralTerm.string('10,20');

        expect(
          () => deserializer.fromRdfTerm(invalidTerm, deserializationContext),
          throwsA(isA<DeserializationException>()),
        );
      });

      test('rejects language-tagged literals by default', () {
        final deserializer = TestPointDeserializer();

        final languageTerm = LiteralTerm.withLanguage('10,20', 'de');

        expect(
          () => deserializer.fromRdfTerm(languageTerm, deserializationContext),
          throwsA(isA<DeserializationException>()),
        );
      });

      test('can be extended to handle language-tagged literals', () {
        final deserializer = LangTagTestDeserializer();

        final languageTerm = LiteralTerm.withLanguage('Hallo Welt', 'de');
        final result = deserializer.fromRdfTerm(
          languageTerm,
          deserializationContext,
        );

        expect(result, equals('Hallo Welt'));
      });

      test('can be extended for custom type handling', () {
        // A custom deserializer for color values
        final colorDeserializer = ColorDeserializer();

        final term = LiteralTerm(
          '#FF0080',
          datatype: const IriTerm('http://example.org/color'),
        );

        final color = colorDeserializer.fromRdfTerm(
          term,
          deserializationContext,
        );

        expect(color, isA<Color>());
        expect(color.red, equals(255));
        expect(color.green, equals(0));
        expect(color.blue, equals(128));
      });

      test('handles non-standard datatypes', () {
        final customDatatype = const IriTerm('http://example.org/customType');
        final term = LiteralTerm('10,20', datatype: customDatatype);

        final deserializer = TestPointDeserializer(datatype: customDatatype);
        final point = deserializer.fromRdfTerm(term, deserializationContext);

        expect(point, isA<Point>());
        expect(point.x, equals(10));
        expect(point.y, equals(20));
      });
    });
  });
}

// Helper classes for testing

class Point {
  final int x;
  final int y;

  Point(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class Color {
  final int red;
  final int green;
  final int blue;

  Color(this.red, this.green, this.blue);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Color &&
          runtimeType == other.runtimeType &&
          red == other.red &&
          green == other.green &&
          blue == other.blue;

  @override
  int get hashCode => red.hashCode ^ green.hashCode ^ blue.hashCode;
}

class ColorSerializer extends BaseRdfLiteralTermSerializer<Color> {
  const ColorSerializer()
      : super(
          datatype: const IriTerm('http://example.org/color'),
        );

  @override
  convertToString(color) => '#${color.red.toRadixString(16).padLeft(2, '0')}'
      '${color.green.toRadixString(16).padLeft(2, '0')}'
      '${color.blue.toRadixString(16).padLeft(2, '0')}';
}

class ColorDeserializer extends BaseRdfLiteralTermDeserializer<Color> {
  const ColorDeserializer()
      : super(
          datatype: const IriTerm('http://example.org/color'),
        );

  @override
  convertFromLiteral(term, _) {
    // Parse hex color (e.g., #FF0080)
    final hexStr = term.value.substring(1); // Remove # prefix
    final red = int.parse(hexStr.substring(0, 2), radix: 16);
    final green = int.parse(hexStr.substring(2, 4), radix: 16);
    final blue = int.parse(hexStr.substring(4, 6), radix: 16);
    return Color(red, green, blue);
  }
}
