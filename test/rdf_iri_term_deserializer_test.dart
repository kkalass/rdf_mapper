import 'package:mockito/annotations.dart';
import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/rdf_iri_term_deserializer.dart';
import 'package:test/test.dart';
import 'package:rdf_mapper/deserialization_context.dart';

@GenerateMocks([DeserializationContext])
import 'rdf_iri_term_deserializer_test.mocks.dart';

void main() {
  group('RdfIriTermDeserializer', () {
    late MockDeserializationContext context;

    setUp(() {
      context = MockDeserializationContext();
    });

    test('string deserializer correctly converts IRI terms to strings', () {
      final deserializer = StringIriDeserializer();

      // Test with simple IRI
      final term = IriTerm('http://example.org/resource');
      final result = deserializer.fromIriTerm(term, context);

      expect(result, equals('http://example.org/resource'));
    });

    test('URI deserializer correctly converts IRI terms to URIs', () {
      final deserializer = UriIriDeserializer();

      // Test with valid URI
      final term = IriTerm('http://example.org/resource');
      final result = deserializer.fromIriTerm(term, context);

      expect(result.toString(), equals('http://example.org/resource'));
      expect(result.scheme, equals('http'));
      expect(result.host, equals('example.org'));
      expect(result.path, equals('/resource'));
    });

    test('URI deserializer handles encoded characters', () {
      final deserializer = UriIriDeserializer();

      // Test with URI containing encoded characters
      final term = IriTerm('http://example.org/resource%20with%20spaces');
      final result = deserializer.fromIriTerm(term, context);

      expect(
        result.toString(),
        equals('http://example.org/resource%20with%20spaces'),
      );
      // Die uncodierte Version des Pfades sollte Leerzeichen enthalten
      expect(Uri.decodeFull(result.path), equals('/resource with spaces'));
    });

    test('enum deserializer maps IRIs to enum values', () {
      final deserializer = ResourceTypeDeserializer();

      // Test mapping IRIs to enum values
      final personTerm = IriTerm('http://example.org/Person');
      final organizationTerm = IriTerm('http://example.org/Organization');
      final unknownTerm = IriTerm('http://example.org/Unknown');

      expect(
        deserializer.fromIriTerm(personTerm, context),
        equals(ResourceType.person),
      );
      expect(
        deserializer.fromIriTerm(organizationTerm, context),
        equals(ResourceType.organization),
      );
      expect(
        () => deserializer.fromIriTerm(unknownTerm, context),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('custom IRI deserializer handles complex type mappings', () {
      final deserializer = ResourceDeserializer();

      // Test custom deserialization logic
      final term = IriTerm('http://example.org/resources/123');
      final result = deserializer.fromIriTerm(term, context);

      expect(result.id, equals('123'));
      expect(result.namespace, equals('http://example.org/resources/'));
    });
  });
}

/// Implementation of a string deserializer for IRI terms
class StringIriDeserializer implements RdfIriTermDeserializer<String> {
  @override
  String fromIriTerm(
    IriTerm term,
    covariant MockDeserializationContext context,
  ) {
    return term.iri;
  }
}

/// Implementation of a URI deserializer for IRI terms
class UriIriDeserializer implements RdfIriTermDeserializer<Uri> {
  @override
  Uri fromIriTerm(IriTerm term, covariant MockDeserializationContext context) {
    return Uri.parse(term.iri);
  }
}

/// Example enum for testing enum mapping
enum ResourceType { person, organization }

/// Implementation of an enum deserializer for IRI terms
class ResourceTypeDeserializer implements RdfIriTermDeserializer<ResourceType> {
  static final _mapping = {
    'http://example.org/Person': ResourceType.person,
    'http://example.org/Organization': ResourceType.organization,
  };

  @override
  ResourceType fromIriTerm(
    IriTerm term,
    covariant MockDeserializationContext context,
  ) {
    final type = _mapping[term.iri];
    if (type == null) {
      throw ArgumentError('Unknown resource type: ${term.iri}');
    }
    return type;
  }
}

/// Simple resource class for testing custom deserialization
class Resource {
  final String id;
  final String namespace;

  Resource({required this.id, required this.namespace});
}

/// Implementation of a custom resource deserializer for IRI terms
class ResourceDeserializer implements RdfIriTermDeserializer<Resource> {
  @override
  Resource fromIriTerm(
    IriTerm term,
    covariant MockDeserializationContext context,
  ) {
    // Extract ID from IRI pattern like http://example.org/resources/{id}
    final uri = Uri.parse(term.iri);
    final segments = uri.pathSegments;

    if (segments.isEmpty) {
      throw ArgumentError('Invalid resource IRI: ${term.iri}');
    }

    final id = segments.last;
    final namespace = term.iri.substring(0, term.iri.length - id.length);

    return Resource(id: id, namespace: namespace);
  }
}
