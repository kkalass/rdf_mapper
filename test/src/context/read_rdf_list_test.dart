import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserialization_context.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_vocabularies/rdf.dart';
import 'package:rdf_vocabularies/xsd.dart';
import 'package:test/test.dart';

/// Custom deserializer for testing purposes
class UpperCaseStringDeserializer implements LiteralTermDeserializer<String> {
  final IriTerm datatype;

  UpperCaseStringDeserializer([this.datatype = Xsd.string]);

  @override
  String fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    return term.value.toUpperCase();
  }
}

/// Test classes for resource deserialization
class TestPerson {
  final String iri;
  TestPerson(this.iri);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestPerson &&
          runtimeType == other.runtimeType &&
          iri == other.iri;

  @override
  int get hashCode => iri.hashCode;

  @override
  String toString() => 'TestPerson($iri)';
}

class TestAddress {
  final String city;
  TestAddress({required this.city});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestAddress &&
          runtimeType == other.runtimeType &&
          city == other.city;

  @override
  int get hashCode => city.hashCode;

  @override
  String toString() => 'TestAddress(city: $city)';
}

/// Custom deserializers for testing
class TestPersonDeserializer implements GlobalResourceDeserializer<TestPerson> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/Person');

  @override
  TestPerson fromRdfResource(IriTerm term, DeserializationContext context) {
    return TestPerson(term.iri);
  }
}

class TestAddressDeserializer
    implements LocalResourceDeserializer<TestAddress> {
  @override
  IriTerm? get typeIri => IriTerm('http://example.org/Address');

  @override
  TestAddress fromRdfResource(
      BlankNodeTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    final city = reader.require<String>(IriTerm('http://example.org/city'));
    return TestAddress(city: city);
  }
}

/// Custom IRI-based types and deserializers
class Country {
  final String code;
  final String name;

  Country(this.code, this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          name == other.name;

  @override
  int get hashCode => Object.hash(code, name);

  @override
  String toString() => 'Country($code, $name)';
}

/// Deserializer that extracts string values from IRIs
class IriToStringDeserializer implements IriTermDeserializer<String> {
  @override
  String fromRdfTerm(IriTerm term, DeserializationContext context) {
    // Extract the fragment or last part of the IRI as string value
    final uri = Uri.parse(term.iri);
    return uri.fragment.isNotEmpty ? uri.fragment : uri.pathSegments.last;
  }
}

/// Deserializer that converts country IRIs to Country objects
class CountryIriDeserializer implements IriTermDeserializer<Country> {
  static const Map<String, String> _countryNames = {
    'DE': 'Germany',
    'FR': 'France',
    'IT': 'Italy',
    'ES': 'Spain',
    'AT': 'Austria',
  };

  @override
  Country fromRdfTerm(IriTerm term, DeserializationContext context) {
    // Extract country code from IRI like http://example.org/country/DE
    final uri = Uri.parse(term.iri);
    final countryCode = uri.pathSegments.last;
    final countryName = _countryNames[countryCode] ?? 'Unknown';
    return Country(countryCode, countryName);
  }
}

void main() {
  late RdfMapperRegistry registry;
  late RdfGraph graph;
  late DeserializationContextImpl context;

  setUp(() {
    registry = RdfMapperRegistry();
  });

  group('readRdfList', () {
    test('reads empty list (rdf:nil)', () {
      graph = RdfGraph(triples: []);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<String>(Rdf.nil);

      expect(result, isEmpty);
      expect(result.toList(), equals([]));
    });

    test('reads single element list', () {
      final listHead = BlankNodeTerm();

      graph = RdfGraph(triples: [
        Triple(listHead, Rdf.first, LiteralTerm.string('hello')),
        Triple(listHead, Rdf.rest, Rdf.nil),
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<String>(listHead);

      expect(result.toList(), equals(['hello']));
    });

    test('reads multi-element string list', () {
      final node1 = BlankNodeTerm();
      final node2 = BlankNodeTerm();
      final node3 = BlankNodeTerm();

      graph = RdfGraph(triples: [
        // First element: "apple"
        Triple(node1, Rdf.first, LiteralTerm.string('apple')),
        Triple(node1, Rdf.rest, node2),

        // Second element: "banana"
        Triple(node2, Rdf.first, LiteralTerm.string('banana')),
        Triple(node2, Rdf.rest, node3),

        // Third element: "cherry"
        Triple(node3, Rdf.first, LiteralTerm.string('cherry')),
        Triple(node3, Rdf.rest, Rdf.nil),
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<String>(node1);

      expect(result.toList(), equals(['apple', 'banana', 'cherry']));
    });

    test('reads integer list', () {
      final node1 = BlankNodeTerm();
      final node2 = BlankNodeTerm();

      graph = RdfGraph(triples: [
        Triple(node1, Rdf.first, LiteralTerm.typed('42', 'integer')),
        Triple(node1, Rdf.rest, node2),
        Triple(node2, Rdf.first, LiteralTerm.typed('99', 'integer')),
        Triple(node2, Rdf.rest, Rdf.nil),
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<int>(node1);

      expect(result.toList(), equals([42, 99]));
    });

    test('reads list with custom deserializer', () {
      final node1 = BlankNodeTerm();
      final node2 = BlankNodeTerm();

      graph = RdfGraph(triples: [
        Triple(node1, Rdf.first, LiteralTerm.string('hello')),
        Triple(node1, Rdf.rest, node2),
        Triple(node2, Rdf.first, LiteralTerm.string('world')),
        Triple(node2, Rdf.rest, Rdf.nil),
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<String>(node1,
          deserializer: UpperCaseStringDeserializer());

      expect(result.toList(), equals(['HELLO', 'WORLD']));
    });

    test('processes list lazily', () {
      final node1 = BlankNodeTerm();
      final node2 = BlankNodeTerm();
      final node3 = BlankNodeTerm();

      graph = RdfGraph(triples: [
        Triple(node1, Rdf.first, LiteralTerm.string('first')),
        Triple(node1, Rdf.rest, node2),
        Triple(node2, Rdf.first, LiteralTerm.string('second')),
        Triple(node2, Rdf.rest, node3),
        Triple(node3, Rdf.first, LiteralTerm.string('third')),
        Triple(node3, Rdf.rest, Rdf.nil),
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<String>(node1);

      // Test lazy evaluation by taking only first element
      final firstElement = result.take(1).single;
      expect(firstElement, equals('first'));

      // Test that we can still get all elements
      final allElements = result.toList();
      expect(allElements, equals(['first', 'second', 'third']));
    });

    test('handles malformed list - missing rdf:first', () {
      final listHead = BlankNodeTerm();

      graph = RdfGraph(triples: [
        // Missing rdf:first triple
        Triple(listHead, Rdf.rest, Rdf.nil),
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      expect(
        () => context.readRdfList<String>(listHead).toList(),
        throwsA(isA<StateError>()),
      );
    });

    test('handles malformed list - missing rdf:rest', () {
      final listHead = BlankNodeTerm();

      graph = RdfGraph(triples: [
        Triple(listHead, Rdf.first, LiteralTerm.string('value')),
        // Missing rdf:rest triple
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      expect(
        () => context.readRdfList<String>(listHead).toList(),
        throwsA(isA<StateError>()),
      );
    });

    test('handles list with boolean values', () {
      final node1 = BlankNodeTerm();
      final node2 = BlankNodeTerm();

      graph = RdfGraph(triples: [
        Triple(node1, Rdf.first, LiteralTerm.typed('true', 'boolean')),
        Triple(node1, Rdf.rest, node2),
        Triple(node2, Rdf.first, LiteralTerm.boolean(false)),
        Triple(node2, Rdf.rest, Rdf.nil),
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<bool>(node1);

      expect(result.toList(), equals([true, false]));
    });

    test('reads list of global resources (IRIs)', () {
      final node1 = BlankNodeTerm();
      final node2 = BlankNodeTerm();
      final node3 = BlankNodeTerm();

      final person1Iri = IriTerm('http://example.org/person1');
      final person2Iri = IriTerm('http://example.org/person2');
      final person3Iri = IriTerm('http://example.org/person3');

      graph = RdfGraph(triples: [
        // RDF List structure
        Triple(node1, Rdf.first, person1Iri),
        Triple(node1, Rdf.rest, node2),
        Triple(node2, Rdf.first, person2Iri),
        Triple(node2, Rdf.rest, node3),
        Triple(node3, Rdf.first, person3Iri),
        Triple(node3, Rdf.rest, Rdf.nil),

        // Type declarations for the persons (optional, but good practice)
        Triple(
            person1Iri,
            IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            IriTerm('http://example.org/Person')),
        Triple(
            person2Iri,
            IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            IriTerm('http://example.org/Person')),
        Triple(
            person3Iri,
            IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            IriTerm('http://example.org/Person')),
      ]);

      // Register the deserializer

      context = DeserializationContextImpl(
          graph: graph,
          registry: registry.clone()
            ..registerDeserializer(TestPersonDeserializer()));

      final result = context.readRdfList<TestPerson>(node1);
      final list = result.toList();

      expect(list.length, equals(3));
      expect(list[0], equals(TestPerson('http://example.org/person1')));
      expect(list[1], equals(TestPerson('http://example.org/person2')));
      expect(list[2], equals(TestPerson('http://example.org/person3')));
    });

    test('reads list of local resources (blank nodes)', () {
      final listNode1 = BlankNodeTerm();
      final listNode2 = BlankNodeTerm();

      final address1 = BlankNodeTerm();
      final address2 = BlankNodeTerm();

      graph = RdfGraph(triples: [
        // RDF List structure
        Triple(listNode1, Rdf.first, address1),
        Triple(listNode1, Rdf.rest, listNode2),
        Triple(listNode2, Rdf.first, address2),
        Triple(listNode2, Rdf.rest, Rdf.nil),

        // Address 1 properties
        Triple(
            address1,
            IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            IriTerm('http://example.org/Address')),
        Triple(address1, IriTerm('http://example.org/city'),
            LiteralTerm.string('Hamburg')),

        // Address 2 properties
        Triple(
            address2,
            IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            IriTerm('http://example.org/Address')),
        Triple(address2, IriTerm('http://example.org/city'),
            LiteralTerm.string('Berlin')),
      ]);

      // Register the deserializer
      context = DeserializationContextImpl(
          graph: graph,
          registry: registry.clone()
            ..registerDeserializer(TestAddressDeserializer()));

      final result = context.readRdfList<TestAddress>(listNode1);
      final list = result.toList();

      expect(list.length, equals(2));
      expect(list[0], equals(TestAddress(city: 'Hamburg')));
      expect(list[1], equals(TestAddress(city: 'Berlin')));
    });

    test('reads list using specific custom deserializers', () {
      final listNode1 = BlankNodeTerm();
      final listNode2 = BlankNodeTerm();

      final personIri1 = IriTerm('http://example.org/person1');
      final personIri2 = IriTerm('http://example.org/person2');

      graph = RdfGraph(triples: [
        // RDF List structure with only global resources
        Triple(listNode1, Rdf.first, personIri1),
        Triple(listNode1, Rdf.rest, listNode2),
        Triple(listNode2, Rdf.first, personIri2),
        Triple(listNode2, Rdf.rest, Rdf.nil),

        // Person 1 (global resource)
        Triple(
            personIri1,
            IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            IriTerm('http://example.org/Person')),

        // Person 2 (global resource)
        Triple(
            personIri2,
            IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            IriTerm('http://example.org/Person')),
      ]);

      // Register deserializers
      context = DeserializationContextImpl(
          graph: graph,
          registry: registry.clone()
            ..registerDeserializer(TestPersonDeserializer()));

      // Read with specific deserializer
      final result = context.readRdfList<TestPerson>(listNode1,
          deserializer: TestPersonDeserializer());
      final list = result.toList();

      expect(list.length, equals(2));
      expect(list[0], equals(TestPerson('http://example.org/person1')));
      expect(list[1], equals(TestPerson('http://example.org/person2')));
    });

    test('reads list with automatic deserializer resolution from registry', () {
      final listNode1 = BlankNodeTerm();
      final listNode2 = BlankNodeTerm();

      final address1 = BlankNodeTerm();
      final address2 = BlankNodeTerm();

      graph = RdfGraph(triples: [
        // RDF List structure
        Triple(listNode1, Rdf.first, address1),
        Triple(listNode1, Rdf.rest, listNode2),
        Triple(listNode2, Rdf.first, address2),
        Triple(listNode2, Rdf.rest, Rdf.nil),

        // Address 1 properties
        Triple(
            address1,
            IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            IriTerm('http://example.org/Address')),
        Triple(address1, IriTerm('http://example.org/city'),
            LiteralTerm.string('Vienna')),

        // Address 2 properties
        Triple(
            address2,
            IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            IriTerm('http://example.org/Address')),
        Triple(address2, IriTerm('http://example.org/city'),
            LiteralTerm.string('Prague')),
      ]);

      // Register the deserializer in registry - no explicit deserializer parameter needed
      context = DeserializationContextImpl(
          graph: graph,
          registry: registry.clone()
            ..registerDeserializer(TestAddressDeserializer()));

      // Read without specifying deserializer - should use registry to find appropriate one
      final result = context.readRdfList<TestAddress>(listNode1);
      final list = result.toList();

      expect(list.length, equals(2));
      expect(list[0], equals(TestAddress(city: 'Vienna')));
      expect(list[1], equals(TestAddress(city: 'Prague')));
    });

    test('reads list of IRIs as strings using IriTermDeserializer', () {
      final listNode1 = BlankNodeTerm();
      final listNode2 = BlankNodeTerm();
      final listNode3 = BlankNodeTerm();

      final statusActive = IriTerm('http://example.org/status#active');
      final statusPending = IriTerm('http://example.org/status#pending');
      final statusInactive = IriTerm('http://example.org/status#inactive');

      graph = RdfGraph(triples: [
        // RDF List structure with IRI values (not resources)
        Triple(listNode1, Rdf.first, statusActive),
        Triple(listNode1, Rdf.rest, listNode2),
        Triple(listNode2, Rdf.first, statusPending),
        Triple(listNode2, Rdf.rest, listNode3),
        Triple(listNode3, Rdf.first, statusInactive),
        Triple(listNode3, Rdf.rest, Rdf.nil),
      ]);

      // Register the IRI-to-string deserializer
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<String>(listNode1,
          deserializer: IriToStringDeserializer());
      final list = result.toList();

      expect(list.length, equals(3));
      expect(list[0], equals('active'));
      expect(list[1], equals('pending'));
      expect(list[2], equals('inactive'));
    });

    test('reads list of IRIs as custom objects using IriTermDeserializer', () {
      final listNode1 = BlankNodeTerm();
      final listNode2 = BlankNodeTerm();
      final listNode3 = BlankNodeTerm();

      final germanyIri = IriTerm('http://example.org/country/DE');
      final franceIri = IriTerm('http://example.org/country/FR');
      final italyIri = IriTerm('http://example.org/country/IT');

      graph = RdfGraph(triples: [
        // RDF List structure with country IRIs
        Triple(listNode1, Rdf.first, germanyIri),
        Triple(listNode1, Rdf.rest, listNode2),
        Triple(listNode2, Rdf.first, franceIri),
        Triple(listNode2, Rdf.rest, listNode3),
        Triple(listNode3, Rdf.first, italyIri),
        Triple(listNode3, Rdf.rest, Rdf.nil),
      ]);

      // Register the country IRI deserializer
      context = DeserializationContextImpl(
          graph: graph,
          registry: registry.clone()
            ..registerDeserializer(CountryIriDeserializer()));

      final result = context.readRdfList<Country>(listNode1,
          deserializer: CountryIriDeserializer());
      final list = result.toList();

      expect(list.length, equals(3));
      expect(list[0], equals(Country('DE', 'Germany')));
      expect(list[1], equals(Country('FR', 'France')));
      expect(list[2], equals(Country('IT', 'Italy')));
    });

    test('reads list with automatic IRI deserializer resolution from registry',
        () {
      final listNode1 = BlankNodeTerm();
      final listNode2 = BlankNodeTerm();

      final spainIri = IriTerm('http://example.org/country/ES');
      final austriaIri = IriTerm('http://example.org/country/AT');

      graph = RdfGraph(triples: [
        // RDF List structure
        Triple(listNode1, Rdf.first, spainIri),
        Triple(listNode1, Rdf.rest, listNode2),
        Triple(listNode2, Rdf.first, austriaIri),
        Triple(listNode2, Rdf.rest, Rdf.nil),
      ]);

      // Register deserializer in registry for automatic resolution
      context = DeserializationContextImpl(
          graph: graph,
          registry: registry.clone()
            ..registerDeserializer(CountryIriDeserializer()));

      // Read without explicit deserializer - registry should find the IriTermDeserializer
      final result = context.readRdfList<Country>(listNode1);
      final list = result.toList();

      expect(list.length, equals(2));
      expect(list[0], equals(Country('ES', 'Spain')));
      expect(list[1], equals(Country('AT', 'Austria')));
    });

    test('reads mixed list with IRIs as values and literals', () {
      final listNode1 = BlankNodeTerm();
      final listNode2 = BlankNodeTerm();
      final listNode3 = BlankNodeTerm();

      final categoryIri = IriTerm('http://example.org/category#electronics');

      graph = RdfGraph(triples: [
        // Mixed list: string literal, IRI as value, string literal
        Triple(listNode1, Rdf.first, LiteralTerm.string('product')),
        Triple(listNode1, Rdf.rest, listNode2),
        Triple(listNode2, Rdf.first, categoryIri),
        Triple(listNode2, Rdf.rest, listNode3),
        Triple(listNode3, Rdf.first, LiteralTerm.string('description')),
        Triple(listNode3, Rdf.rest, Rdf.nil),
      ]);

      // Register both deserializers
      context = DeserializationContextImpl(
          graph: graph,
          registry: registry.clone()
            ..registerDeserializer(IriToStringDeserializer()));

      // Read as strings - should handle both literals and IRIs
      final result = context.readRdfList<String>(listNode1);
      final list = result.toList();

      expect(list.length, equals(3));
      expect(list[0], equals('product'));
      expect(list[1], equals('electronics')); // IRI fragment extracted
      expect(list[2], equals('description'));
    });
  });

  group('Cycle Detection and Circular References', () {
    test('handles self-referencing list node', () {
      final selfRefNode = BlankNodeTerm();

      final cyclicGraph = RdfGraph(triples: [
        // Self-referencing node: points to itself as rdf:rest
        Triple(selfRefNode, Rdf.first, LiteralTerm.string('value')),
        Triple(selfRefNode, Rdf.rest, selfRefNode), // Cycle!
      ]);

      final cyclicContext = DeserializationContextImpl(
        graph: cyclicGraph,
        registry: registry,
      );

      // This should detect the cycle and not hang
      expect(
          () => cyclicContext.readRdfList<String>(selfRefNode).take(5).toList(),
          throwsA(isA<StateError>()) // Should detect cycle and throw
          );
    });

    test('handles two-node cycle in list', () {
      final node1 = BlankNodeTerm();
      final node2 = BlankNodeTerm();

      final cyclicGraph = RdfGraph(triples: [
        // Node 1
        Triple(node1, Rdf.first, LiteralTerm.string('first')),
        Triple(node1, Rdf.rest, node2),
        // Node 2 points back to node 1, creating a cycle
        Triple(node2, Rdf.first, LiteralTerm.string('second')),
        Triple(node2, Rdf.rest, node1), // Cycle!
      ]);

      final cyclicContext = DeserializationContextImpl(
        graph: cyclicGraph,
        registry: registry,
      );

      // Should detect the cycle
      expect(() => cyclicContext.readRdfList<String>(node1).take(5).toList(),
          throwsA(isA<StateError>()));
    });

    test('handles complex multi-node cycle', () {
      final node1 = BlankNodeTerm();
      final node2 = BlankNodeTerm();
      final node3 = BlankNodeTerm();

      final cyclicGraph = RdfGraph(triples: [
        // Create a 3-node cycle: node1 -> node2 -> node3 -> node1
        Triple(node1, Rdf.first, LiteralTerm.string('first')),
        Triple(node1, Rdf.rest, node2),
        Triple(node2, Rdf.first, LiteralTerm.string('second')),
        Triple(node2, Rdf.rest, node3),
        Triple(node3, Rdf.first, LiteralTerm.string('third')),
        Triple(node3, Rdf.rest, node1), // Cycle back to start!
      ]);

      final cyclicContext = DeserializationContextImpl(
        graph: cyclicGraph,
        registry: registry,
      );

      // Should detect the cycle
      expect(() => cyclicContext.readRdfList<String>(node1).take(10).toList(),
          throwsA(isA<StateError>()));
    });

    test('handles cycle that includes rdf:nil incorrectly', () {
      final node1 = BlankNodeTerm();
      final node2 = BlankNodeTerm();

      final cyclicGraph = RdfGraph(triples: [
        // Malformed list where nil is not at the end
        Triple(node1, Rdf.first, LiteralTerm.string('first')),
        Triple(node1, Rdf.rest, Rdf.nil),
        Triple(Rdf.nil, Rdf.first, LiteralTerm.string('nil_value')),
        Triple(Rdf.nil, Rdf.rest, node2), // This shouldn't happen
        Triple(node2, Rdf.first, LiteralTerm.string('after_nil')),
        Triple(node2, Rdf.rest, node1), // Cycle back
      ]);

      final cyclicContext = DeserializationContextImpl(
        graph: cyclicGraph,
        registry: registry,
      );

      // Should handle the malformed structure gracefully
      final result = cyclicContext.readRdfList<String>(node1).toList();
      expect(result, equals(['first'])); // Should stop at rdf:nil
    });

    test('handles list with circular references in element values', () {
      // Create objects that reference each other circularly
      final personIri1 = IriTerm('http://example.org/person1');
      final personIri2 = IriTerm('http://example.org/person2');
      final listNode1 = BlankNodeTerm();
      final listNode2 = BlankNodeTerm();

      final cyclicGraph = RdfGraph(triples: [
        // List structure
        Triple(listNode1, Rdf.first, personIri1),
        Triple(listNode1, Rdf.rest, listNode2),
        Triple(listNode2, Rdf.first, personIri2),
        Triple(listNode2, Rdf.rest, Rdf.nil),

        // Person 1 refers to Person 2
        Triple(personIri1, IriTerm('http://example.org/knows'), personIri2),
        // Person 2 refers back to Person 1 (circular reference)
        Triple(personIri2, IriTerm('http://example.org/knows'), personIri1),
      ]);

      final cyclicContext = DeserializationContextImpl(
        graph: cyclicGraph,
        registry: registry.clone()
          // Register deserializer for test person
          ..registerDeserializer(TestPersonDeserializer()),
      );

      // Should be able to deserialize the list even with circular refs in values
      final result = cyclicContext.readRdfList<TestPerson>(listNode1).toList();
      expect(result.length, equals(2));
      expect(result[0].iri, equals('http://example.org/person1'));
      expect(result[1].iri, equals('http://example.org/person2'));
    });

    test('detects infinite loop in lazy evaluation', () {
      final node1 = BlankNodeTerm();
      final node2 = BlankNodeTerm();

      final cyclicGraph = RdfGraph(triples: [
        Triple(node1, Rdf.first, LiteralTerm.string('first')),
        Triple(node1, Rdf.rest, node2),
        Triple(node2, Rdf.first, LiteralTerm.string('second')),
        Triple(node2, Rdf.rest, node1), // Cycle
      ]);

      final cyclicContext = DeserializationContextImpl(
        graph: cyclicGraph,
        registry: registry,
      );

      final iterable = cyclicContext.readRdfList<String>(node1);

      // Should be able to get first few elements before cycle is detected
      final iterator = iterable.iterator;
      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, equals('first'));
      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, equals('second'));

      // The cycle should be detected when trying to continue
      expect(() => iterator.moveNext(), throwsA(isA<StateError>()));
    });

    test('handles valid list that resembles but is not a cycle', () {
      final node1 = BlankNodeTerm();
      final node2 = BlankNodeTerm();
      final node3 = BlankNodeTerm();

      final validGraph = RdfGraph(triples: [
        // Valid list: node1 -> node2 -> node3 -> nil
        Triple(node1, Rdf.first, LiteralTerm.string('first')),
        Triple(node1, Rdf.rest, node2),
        Triple(node2, Rdf.first, LiteralTerm.string('second')),
        Triple(node2, Rdf.rest, node3),
        Triple(node3, Rdf.first, LiteralTerm.string('third')),
        Triple(node3, Rdf.rest, Rdf.nil),

        // Additional triples that might confuse cycle detection
        // (but these are not part of the list chain)
        Triple(node3, IriTerm('http://example.org/other'), node1),
      ]);

      final validContext = DeserializationContextImpl(
        graph: validGraph,
        registry: registry,
      );

      // Should work fine - not a cycle in the list structure
      final result = validContext.readRdfList<String>(node1).toList();
      expect(result, equals(['first', 'second', 'third']));
    });
  });

  group('Error Handling for Malformed Lists', () {
    test('handles empty list gracefully', () {
      graph = RdfGraph(triples: []);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<String>(Rdf.nil).toList();

      expect(result, equals([]));
    });

    test('handles list with single nil element', () {
      final listNode = BlankNodeTerm();

      graph = RdfGraph(triples: [
        Triple(listNode, Rdf.first, Rdf.nil),
        Triple(listNode, Rdf.rest, Rdf.nil),
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<Uri>(listNode).toList();

      expect(
          result,
          equals(
              [Uri.parse('http://www.w3.org/1999/02/22-rdf-syntax-ns#nil')]));
    });

    test('handles list with trailing rdf:nil', () {
      final listNode = BlankNodeTerm();
      final validNode = BlankNodeTerm();

      graph = RdfGraph(triples: [
        Triple(listNode, Rdf.first, LiteralTerm.string('value')),
        Triple(listNode, Rdf.rest, Rdf.nil),
        Triple(Rdf.nil, Rdf.first, LiteralTerm.string('nil_value')),
        Triple(Rdf.nil, Rdf.rest, validNode),
        Triple(validNode, Rdf.first, LiteralTerm.string('after_nil')),
        Triple(validNode, Rdf.rest, Rdf.nil),
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<String>(listNode).toList();

      expect(result, equals(['value'])); // Stops at rdf:nil
      final processed = context.getAllProcessedTriples();
      expect(processed.length,
          2); // Only the first two triples should be marked as processed, the rest should be in the unprocessed triples list and not lost
    });

    test('handles list with nested rdf:nil', () {
      final listNode1 = BlankNodeTerm();
      final listNode2 = BlankNodeTerm();

      graph = RdfGraph(triples: [
        Triple(listNode1, Rdf.first, LiteralTerm.string('outer')),
        Triple(listNode1, Rdf.rest, listNode2),
        Triple(listNode2, Rdf.first, Rdf.nil),
        Triple(listNode2, Rdf.rest, Rdf.nil),
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<Object>(listNode1).toList();

      expect(
          result,
          equals([
            'outer',
            Uri.parse('http://www.w3.org/1999/02/22-rdf-syntax-ns#nil')
          ]));
    });

    test('handles list with rdf:nil in the middle', () {
      final listNode1 = BlankNodeTerm();
      final listNode2 = BlankNodeTerm();
      final listNode3 = BlankNodeTerm();

      graph = RdfGraph(triples: [
        Triple(listNode1, Rdf.first, LiteralTerm.string('first')),
        Triple(listNode1, Rdf.rest, listNode2),
        Triple(listNode2, Rdf.first, Rdf.nil),
        Triple(listNode2, Rdf.rest, listNode3),
        Triple(listNode3, Rdf.first, LiteralTerm.string('third')),
        Triple(listNode3, Rdf.rest, Rdf.nil),
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<Object>(listNode1).toList();

      expect(
          result,
          equals([
            'first',
            Uri.parse('http://www.w3.org/1999/02/22-rdf-syntax-ns#nil'),
            'third'
          ]));
    });

    test('handles malformed list with rdf:nil as first element', () {
      final listNode = BlankNodeTerm();

      graph = RdfGraph(triples: [
        Triple(listNode, Rdf.first, Rdf.nil),
        Triple(listNode, Rdf.rest, Rdf.nil),
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<Object>(listNode).toList();

      expect(
          result,
          equals(
              [Uri.parse('http://www.w3.org/1999/02/22-rdf-syntax-ns#nil')]));
    });

    test('handles list with multiple consecutive rdf:nil', () {
      final listNode1 = BlankNodeTerm();
      final listNode2 = BlankNodeTerm();

      graph = RdfGraph(triples: [
        Triple(listNode1, Rdf.first, LiteralTerm.string('value1')),
        Triple(listNode1, Rdf.rest, listNode2),
        Triple(listNode2, Rdf.first, Rdf.nil),
        Triple(listNode2, Rdf.rest, Rdf.nil),
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<Object>(listNode1).toList();

      expect(
          result,
          equals([
            'value1',
            Uri.parse('http://www.w3.org/1999/02/22-rdf-syntax-ns#nil')
          ]));
    });

    test('handles list with rdf:nil followed by valid elements', () {
      final listNode1 = BlankNodeTerm();
      final listNode2 = BlankNodeTerm();
      final validNode = BlankNodeTerm();

      graph = RdfGraph(triples: [
        Triple(listNode1, Rdf.first, Rdf.nil),
        Triple(listNode1, Rdf.rest, listNode2),
        Triple(listNode2, Rdf.first, LiteralTerm.string('value')),
        Triple(listNode2, Rdf.rest, validNode),
        Triple(validNode, Rdf.first, LiteralTerm.string('after_nil')),
        Triple(validNode, Rdf.rest, Rdf.nil),
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<Object>(listNode1).toList();

      expect(
          result,
          equals([
            Uri.parse('http://www.w3.org/1999/02/22-rdf-syntax-ns#nil'),
            'value',
            'after_nil'
          ]));
    });

    test('handles list with interleaved rdf:nil and values', () {
      final listNode1 = BlankNodeTerm();
      final listNode2 = BlankNodeTerm();
      final listNode3 = BlankNodeTerm();

      graph = RdfGraph(triples: [
        Triple(listNode1, Rdf.first, LiteralTerm.string('value1')),
        Triple(listNode1, Rdf.rest, listNode2),
        Triple(listNode2, Rdf.first, Rdf.nil),
        Triple(listNode2, Rdf.rest, listNode3),
        Triple(listNode3, Rdf.first, LiteralTerm.string('value2')),
        Triple(listNode3, Rdf.rest, Rdf.nil),
      ]);
      context = DeserializationContextImpl(graph: graph, registry: registry);

      final result = context.readRdfList<Object>(listNode1).toList();

      expect(
          result,
          equals([
            'value1',
            Uri.parse('http://www.w3.org/1999/02/22-rdf-syntax-ns#nil'),
            'value2'
          ]));
    });

    test('handles list with rdf:nil and cycle', () {
      final node1 = BlankNodeTerm();
      final node2 = BlankNodeTerm();

      final cyclicGraph = RdfGraph(triples: [
        Triple(node1, Rdf.first, LiteralTerm.string('first')),
        Triple(node1, Rdf.rest, node2),
        Triple(node2, Rdf.first, Rdf.nil),
        Triple(node2, Rdf.rest, node1), // Cycle back to node1
      ]);

      final cyclicContext = DeserializationContextImpl(
        graph: cyclicGraph,
        registry: registry,
      );

      // Should detect the cycle and not hang
      expect(() => cyclicContext.readRdfList<Object>(node1).take(5).toList(),
          throwsA(isA<StateError>()) // Should detect cycle and throw
          );
    });
  });
}
