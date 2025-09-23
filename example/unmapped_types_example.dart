import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Example demonstrating the difference between deep (RdfGraph) and shallow (Map) unmapped types
void main() {
  final rdfMapper = RdfMapper.withDefaultRegistry()
    ..registerMapper<PersonWithGraph>(PersonWithGraphMapper())
    ..registerMapper<PersonWithMap>(PersonWithMapMapper());

  // RDF input with nested blank nodes
  final turtle = '''
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix ex: <http://example.org/> .

<http://example.org/person> 
  foaf:name "John Smith" ;
  ex:hasAddress _:addr ;
  ex:customField "some value" .

_:addr 
  ex:street "123 Main St" ;
  ex:city "Anytown" ;
  ex:country "USA" .
''';

  print('=== Deep Mapping with RdfGraph ===');
  final personWithGraph = rdfMapper.decodeObject<PersonWithGraph>(
    turtle,
    subject: const IriTerm('http://example.org/person'),
  );
  print('Name: ${personWithGraph.name}');
  print(
      'Unmapped graph has ${personWithGraph.unmappedGraph.triples.length} triples:');
  for (final triple in personWithGraph.unmappedGraph.triples) {
    print('  $triple');
  }

  print('\n=== Shallow Mapping with Map<IriTerm, List<RdfObject>> ===');
  final personWithMap = rdfMapper.decodeObject<PersonWithMap>(
    turtle,
    subject: const IriTerm('http://example.org/person'),
    completeness: CompletenessMode
        .lenient, // Needed because blank node triples are not captured
  );
  print('Name: ${personWithMap.name}');
  print('Unmapped map has ${personWithMap.unmappedData.length} predicates:');
  for (final entry in personWithMap.unmappedData.entries) {
    print('  ${entry.key}: ${entry.value}');
  }

  print('\n=== Round-trip comparison ===');
  final graphRoundtrip = rdfMapper.graph.encodeObject(personWithGraph);
  final mapRoundtrip = rdfMapper.graph.encodeObject(personWithMap);

  print('Graph round-trip preserves ${graphRoundtrip.size} triples');
  print('Map round-trip preserves ${mapRoundtrip.size} triples');
}

// Deep mapping with RdfGraph
class PersonWithGraph {
  final String id;
  final String name;
  final RdfGraph unmappedGraph;

  PersonWithGraph({
    required this.id,
    required this.name,
    RdfGraph? unmappedGraph,
  }) : unmappedGraph = unmappedGraph ?? RdfGraph();
}

class PersonWithGraphMapper implements GlobalResourceMapper<PersonWithGraph> {
  @override
  IriTerm? get typeIri => null;

  @override
  PersonWithGraph fromRdfResource(
      IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final foafName = const IriTerm('http://xmlns.com/foaf/0.1/name');
    return PersonWithGraph(
      id: subject.value,
      name: reader.require<String>(foafName),
      unmappedGraph: reader.getUnmapped<RdfGraph>(), // Deep mapping
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      PersonWithGraph value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final foafName = const IriTerm('http://xmlns.com/foaf/0.1/name');
    return context
        .resourceBuilder(context.createIriTerm(value.id))
        .addValue(foafName, value.name)
        .addUnmapped(value.unmappedGraph)
        .build();
  }
}

// Shallow mapping with Map
class PersonWithMap {
  final String id;
  final String name;
  final Map<IriTerm, List<RdfObject>> unmappedData;

  PersonWithMap({
    required this.id,
    required this.name,
    Map<IriTerm, List<RdfObject>>? unmappedData,
  }) : unmappedData = unmappedData ?? {};
}

class PersonWithMapMapper implements GlobalResourceMapper<PersonWithMap> {
  @override
  IriTerm? get typeIri => null;

  @override
  PersonWithMap fromRdfResource(
      IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final foafName = const IriTerm('http://xmlns.com/foaf/0.1/name');
    return PersonWithMap(
      id: subject.value,
      name: reader.require<String>(foafName),
      unmappedData: reader
          .getUnmapped<Map<IriTerm, List<RdfObject>>>(), // Shallow mapping
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      PersonWithMap value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final foafName = const IriTerm('http://xmlns.com/foaf/0.1/name');
    return context
        .resourceBuilder(context.createIriTerm(value.id))
        .addValue(foafName, value.name)
        .addUnmapped(value.unmappedData)
        .build();
  }
}
