import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/api/mapper.dart';
import 'package:test/test.dart';

void main() {
  group('RdfMapper more tests', () {
    late RdfCore rdfCore;
    late RdfMapper rdf;
    setUp(() {
      rdfCore = RdfCore.withStandardFormats();
      rdf = RdfMapper.withDefaultRegistry();
      rdf.registerMapper<TestItem>(
        TestItemRdfMapper(storageRoot: "https://some.static.url.example.com/"),
      );
    });
    test('Converting item to RDF graph and back works', () {
      // Create test item
      final originalItem = TestItem(name: 'Graph conversion test', age: 42);

      // Convert to graph
      final graph = rdf.graph.serialize<TestItem>(originalItem);
      expect(graph.triples, isNotEmpty);

      // Convert back to item
      final reconstructedItem = rdf.graph.deserialize<TestItem>(graph);

      // Verify properties match
      expect(reconstructedItem.name, equals(originalItem.name));
      expect(reconstructedItem.age, equals(originalItem.age));
    });

    test('Converting item to turtle', () {
      final serializer = rdfCore.getSerializer(contentType: 'text/turtle');
      // Create test item
      final originalItem = TestItem(name: 'Graph Conversion Test', age: 42);

      // Convert to graph, using a custom deserializer to provide a custom
      // storage root.
      final graph = rdf.graph.serialize<TestItem>(
        originalItem,
        register:
            (registry) => registry.registerMapper(
              TestItemRdfMapper(storageRoot: storageRootForTest),
            ),
      );
      expect(graph.triples, isNotEmpty);
      final turtle = serializer.write(graph);

      // Verify generated turtle
      expect(
        turtle,
        equals(
          """
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<https://example.com/pod/Graph%20Conversion%20Test> a <http://kalass.de/dart/rdf/test-ontology#TestItem>;
    <http://kalass.de/dart/rdf/test-ontology#name> "Graph Conversion Test";
    <http://kalass.de/dart/rdf/test-ontology#age> "42"^^xsd:integer .
""".trim(),
        ),
      );
    });

    test('Converting item to turtle with prefixes', () {
      final serializer = rdfCore.getSerializer(contentType: 'text/turtle');
      // Create test item
      final originalItem = TestItem(name: 'Graph Conversion Test', age: 42);

      // Convert to graph
      final graph = rdf.graph.serialize<TestItem>(
        originalItem,
        register:
            (registry) => registry.registerMapper(
              TestItemRdfMapper(storageRoot: storageRootForTest),
            ),
      );
      expect(graph.triples, isNotEmpty);
      final turtle = serializer.write(
        graph,
        customPrefixes: {"test": "http://kalass.de/dart/rdf/test-ontology#"},
      );

      // Verify generated turtle
      expect(
        turtle,
        equals(
          """
@prefix test: <http://kalass.de/dart/rdf/test-ontology#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<https://example.com/pod/Graph%20Conversion%20Test> a test:TestItem;
    test:name "Graph Conversion Test";
    test:age "42"^^xsd:integer .
""".trim(),
        ),
      );
    });

    test('Converting item from turtle ', () {
      final parser = rdfCore.getParser(contentType: 'text/turtle');
      // Create test item
      final turtle = """
@prefix test: <http://kalass.de/dart/rdf/test-ontology#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<https://example.com/pod/Graph%20Conversion%20Test> a test:TestItem;
    test:name "Graph Conversion Test";
    test:age "42"^^xsd:integer .
""";

      // Convert to graph
      final graph = parser.parse(turtle);
      final allSubjects = rdf.graph.deserializeAll(
        graph,
        register:
            (registry) => registry.registerMapper(
              TestItemRdfMapper(storageRoot: storageRootForTest),
            ),
      );

      // Verify generated turtle
      expect(allSubjects.length, equals(1));
      expect(allSubjects[0], isA<TestItem>());
      var item = allSubjects[0] as TestItem;
      expect(item.name, "Graph Conversion Test");
      expect(item.age, 42);
    });
  });
}

const storageRootForTest = "https://example.com/pod/";

class TestItem {
  final String name;
  final int age;

  TestItem({required this.name, required this.age});
}

final class TestItemRdfMapper implements IriNodeMapper<TestItem> {
  final String storageRoot;

  TestItemRdfMapper({required this.storageRoot});

  @override
  final IriTerm typeIri = IriTerm(
    "http://kalass.de/dart/rdf/test-ontology#TestItem",
  );

  @override
  TestItem fromRdfNode(IriTerm iri, DeserializationContext context) {
    return TestItem(
      name: context.require(
        iri,
        IriTerm("http://kalass.de/dart/rdf/test-ontology#name"),
      ),
      age: context.require(
        iri,
        IriTerm("http://kalass.de/dart/rdf/test-ontology#age"),
      ),
    );
  }

  @override
  (RdfSubject, List<Triple>) toRdfNode(
    TestItem instance,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final itemIri = IriTerm(
      "$storageRoot${Uri.encodeComponent(instance.name)}",
    );

    return (
      itemIri,
      [
        // Add basic properties
        context.literal(
          itemIri,
          IriTerm("http://kalass.de/dart/rdf/test-ontology#name"),
          instance.name,
        ),

        context.literal(
          itemIri,
          IriTerm("http://kalass.de/dart/rdf/test-ontology#age"),
          instance.age,
        ),
      ],
    );
  }
}
