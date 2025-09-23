import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/util/namespace.dart';
import 'package:test/test.dart';

void main() {
  group('Namespace', () {
    test('creates IRI terms with call method', () {
      final foaf = Namespace('http://xmlns.com/foaf/0.1/');
      final schema = Namespace('http://schema.org/');

      expect(foaf('Person').value, equals('http://xmlns.com/foaf/0.1/Person'));
      expect(schema('address').value, equals('http://schema.org/address'));
    });

    test('handles various namespace formats', () {
      // With trailing slash
      final ns1 = Namespace('http://example.org/ns/');
      expect(ns1('test').value, equals('http://example.org/ns/test'));

      // With trailing hash
      final ns2 = Namespace('http://example.org/ns#');
      expect(ns2('test').value, equals('http://example.org/ns#test'));

      // Without trailing delimiter
      final ns3 = Namespace('http://example.org/ns');
      expect(ns3('test').value, equals('http://example.org/nstest'));
    });

    test('provides access to base URI', () {
      final ns = Namespace('http://example.org/ns/');
      expect(ns.uri, equals('http://example.org/ns/'));
    });

    test('has proper equality implementation', () {
      final ns1 = Namespace('http://example.org/ns/');
      final ns2 = Namespace('http://example.org/ns/');
      final ns3 = Namespace('http://different.org/ns/');

      expect(ns1 == ns2, isTrue);
      expect(ns1 == ns3, isFalse);

      // Hash code consistency
      expect(ns1.hashCode == ns2.hashCode, isTrue);
    });

    test('provides string representation', () {
      final ns = Namespace('http://example.org/ns/');
      expect(ns.toString(), equals('http://example.org/ns/'));
    });

    test('works in complex RDF builder scenarios', () {
      // Mock a simple node builder for testing
      final mockSubject = const IriTerm('http://example.org/subject');
      final triples = <Triple>[];

      void addTriple(RdfPredicate predicate, RdfObject object) {
        triples.add(Triple(mockSubject, predicate, object));
      }

      // Define namespaces
      final ex = Namespace('http://example.org/');
      final foaf = Namespace('http://xmlns.com/foaf/0.1/');

      // Use namespaces to create triples
      addTriple(ex('name'), LiteralTerm.string('Test Subject'));
      addTriple(
        foaf('age'),
        LiteralTerm(
          '25',
          datatype: const IriTerm('http://www.w3.org/2001/XMLSchema#integer'),
        ),
      );

      // Verify triples were created correctly
      expect(triples.length, equals(2));
      expect(
        (triples[0].predicate as IriTerm).value,
        equals('http://example.org/name'),
      );
      expect(
        (triples[1].predicate as IriTerm).value,
        equals('http://xmlns.com/foaf/0.1/age'),
      );
    });
  });
}
