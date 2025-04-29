import 'package:mockito/annotations.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/deserializers/blank_node_term_deserializer.dart';
import 'package:test/test.dart';

@GenerateMocks([DeserializationContext])
import 'blank_node_term_deserializer_test.mocks.dart';

void main() {
  group('BlankNodeTermDeserializer', () {
    late DeserializationContext context;

    setUp(() {
      context = MockDeserializationContext();
    });

    test(
      'custom blank node deserializer correctly converts blank node terms',
      () {
        // Create a custom deserializer
        final deserializer = TestBlankNodeDeserializer();

        // Test with a regular blank node
        var term = BlankNodeTerm();
        var result = deserializer.fromRdfTerm(term, context);

        // Verify conversion
        expect(
          result.label,
          equals(
            'not very useful by itself, but in combination with other parts it can be useful',
          ),
        );
      },
    );
  });
}

/// Test blank node type for deserialization
class BlankNodeValue {
  final String label;

  BlankNodeValue(this.label);
}

/// Test implementation of RdfBlankNodeTermDeserializer
class TestBlankNodeDeserializer
    implements BlankNodeTermDeserializer<BlankNodeValue> {
  @override
  BlankNodeValue fromRdfTerm(
    BlankNodeTerm term,
    DeserializationContext context,
  ) {
    return BlankNodeValue(
      "not very useful by itself, but in combination with other parts it can be useful",
    );
  }
}
