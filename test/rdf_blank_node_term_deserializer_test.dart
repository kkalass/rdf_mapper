import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/deserialization_context.dart';
import 'package:rdf_mapper/rdf_blank_node_term_deserializer.dart';
import 'package:test/test.dart';

import 'mocks/mock_deserialization_context.dart';

void main() {
  group('RdfBlankNodeTermDeserializer', () {
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
        var term = BlankNodeTerm('node1');
        var result = deserializer.fromBlankNodeTerm(term, context);

        // Verify conversion
        expect(result.label, equals('node1'));
      },
    );

    test(
      'custom blank node deserializer handles special characters in labels',
      () {
        // Create a custom deserializer
        final deserializer = TestBlankNodeDeserializer();

        // Test with blank node containing special characters
        var term = BlankNodeTerm('node-with_special.chars');
        var result = deserializer.fromBlankNodeTerm(term, context);

        // Verify conversion
        expect(result.label, equals('node-with_special.chars'));
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
    implements RdfBlankNodeTermDeserializer<BlankNodeValue> {
  @override
  BlankNodeValue fromBlankNodeTerm(
    BlankNodeTerm term,
    DeserializationContext context,
  ) {
    return BlankNodeValue(term.label);
  }
}
