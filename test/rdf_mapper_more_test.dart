import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('RdfMapper more tests', () {
    late RdfCore rdfCore;
    late RdfMapper rdf;
    setUp(() {
      rdfCore = RdfCore.withStandardCodecs();
      rdf = RdfMapper.withDefaultRegistry();
      rdf.registerMapper<TestItem>(
        TestItemRdfMapper(storageRoot: "https://some.static.url.example.com/"),
      );
    });
    test('Converting item to RDF graph and back works', () {
      // Create test item
      final originalItem = TestItem(name: 'Graph conversion test', age: 42);

      // Convert to graph
      final graph = rdf.graph.encodeObject<TestItem>(originalItem);
      expect(graph.triples, isNotEmpty);

      // Convert back to item
      final reconstructedItem = rdf.graph.decodeObject<TestItem>(graph);

      // Verify properties match
      expect(reconstructedItem.name, equals(originalItem.name));
      expect(reconstructedItem.age, equals(originalItem.age));
    });

    test('Converting item to turtle', () {
      final codec = rdfCore.codec(contentType: 'text/turtle');
      // Create test item
      final originalItem = TestItem(name: 'Graph Conversion Test', age: 42);

      // Convert to graph, using a custom deserializer to provide a custom
      // storage root.
      final graph = rdf.graph.encodeObject<TestItem>(
        originalItem,
        register: (registry) => registry.registerMapper(
          TestItemRdfMapper(storageRoot: storageRootForTest),
        ),
      );
      expect(graph.triples, isNotEmpty);
      final turtle = codec.encode(graph);

      //print(turtle);
      // Verify generated turtle
      expect(
        turtle,
        equals(
          """
@prefix to: <http://kalass.de/dart/rdf/test-ontology#> .

<https://example.com/pod/Graph%20Conversion%20Test> a to:TestItem;
    to:age 42;
    to:name "Graph Conversion Test" .
"""
              .trim(),
        ),
      );

      // Convert back to graph
      final graph2 = codec.decode(turtle);
      expect(graph2, equals(graph));
    });

    test('Converting item to turtle with prefixes', () {
      final codec = rdfCore.codec(
        contentType: 'text/turtle',
        encoderOptions: TurtleEncoderOptions(
          customPrefixes: {"test": "http://kalass.de/dart/rdf/test-ontology#"},
        ),
      );
      // Create test item
      final originalItem = TestItem(name: 'Graph Conversion Test', age: 42);

      // Convert to graph
      final graph = rdf.graph.encodeObject<TestItem>(
        originalItem,
        register: (registry) => registry.registerMapper(
          TestItemRdfMapper(storageRoot: storageRootForTest),
        ),
      );
      expect(graph.triples, isNotEmpty);
      final turtle = codec.encode(graph);
      //print(turtle);
      // Verify generated turtle
      expect(
        turtle,
        equals(
          """
@prefix test: <http://kalass.de/dart/rdf/test-ontology#> .

<https://example.com/pod/Graph%20Conversion%20Test> a test:TestItem;
    test:age 42;
    test:name "Graph Conversion Test" .
"""
              .trim(),
        ),
      );
    });

    test('Converting item from turtle ', () {
      final codec = rdfCore.codec(contentType: 'text/turtle');
      // Create test item
      final turtle = """
@prefix test: <http://kalass.de/dart/rdf/test-ontology#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<https://example.com/pod/Graph%20Conversion%20Test> a test:TestItem;
    test:name "Graph Conversion Test";
    test:age "42"^^xsd:integer .
""";

      // Convert to graph
      final graph = codec.decode(turtle);
      final allSubjects = rdf.graph.decodeObjects(
        graph,
        register: (registry) => registry.registerMapper(
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

final class TestItemRdfMapper implements GlobalResourceMapper<TestItem> {
  final String storageRoot;

  TestItemRdfMapper({required this.storageRoot});

  @override
  final IriTerm typeIri = const IriTerm(
    "http://kalass.de/dart/rdf/test-ontology#TestItem",
  );

  @override
  TestItem fromRdfResource(IriTerm iri, DeserializationContext context) {
    final reader = context.reader(iri);
    return TestItem(
      name: reader.require(
        const IriTerm("http://kalass.de/dart/rdf/test-ontology#name"),
      ),
      age: reader.require(
        const IriTerm("http://kalass.de/dart/rdf/test-ontology#age"),
      ),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    TestItem instance,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final itemIri = context.createIriTerm(
      "$storageRoot${Uri.encodeComponent(instance.name)}",
    );
    return context
        .resourceBuilder(itemIri)
        .addValue(
          const IriTerm("http://kalass.de/dart/rdf/test-ontology#name"),
          instance.name,
        )
        .addValue(
          const IriTerm("http://kalass.de/dart/rdf/test-ontology#age"),
          instance.age,
        )
        .build();
  }
}
