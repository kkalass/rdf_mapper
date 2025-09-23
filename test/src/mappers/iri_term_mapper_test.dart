import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

import '../deserializers/mock_deserialization_context.dart';
import '../serializers/mock_serialization_context.dart';

void main() {
  group('IriTermMapper', () {
    late RdfMapperRegistry registry;
    late RdfMapper rdfMapper;

    setUp(() {
      registry = RdfMapperRegistry();
      rdfMapper = RdfMapper(registry: registry);
      rdfMapper.registerMapper<ResourceReference>(ResourceReferenceMapper());
    });

    test('should serialize and deserialize objects to IRI terms', () {
      // Create test object
      final reference = ResourceReference(
        uri: 'http://example.org/resource/123',
      );

      // Serialize to term
      final context = MockSerializationContext();
      final mapper = ResourceReferenceMapper();
      final term = mapper.toRdfTerm(reference, context);

      // Verify serialized term
      expect(term, isA<IriTerm>());
      expect((term).value, equals('http://example.org/resource/123'));

      // Deserialize from term
      final deserializedReference = mapper.fromRdfTerm(
        term,
        MockDeserializationContext(),
      );

      // Verify deserialized object
      expect(deserializedReference, isA<ResourceReference>());
      expect(
        deserializedReference.uri,
        equals('http://example.org/resource/123'),
      );
    });

    test('should handle IRI term references in complex objects', () {
      // Register parent object mapper
      rdfMapper.registerMapper<ResourceContainer>(ResourceContainerMapper());

      // Create test objects
      final reference = ResourceReference(
        uri: 'http://example.org/resource/123',
      );
      final container = ResourceContainer(
        id: 'http://example.org/container/1',
        name: 'Test Container',
        resource: reference,
      );

      // Serialize to graph
      final graph = rdfMapper.graph.encodeObject(container);

      // Verify the main subject properties
      final subjectTriples = graph.findTriples(
        subject: const IriTerm('http://example.org/container/1'),
      );
      expect(subjectTriples.length, greaterThan(1));

      // Find the resource reference triple
      final resourceTriples = graph.findTriples(
        subject: const IriTerm('http://example.org/container/1'),
        predicate: const IriTerm('http://example.org/resource'),
      );
      expect(resourceTriples.length, equals(1));
      expect(resourceTriples[0].object, isA<IriTerm>());
      expect(
        (resourceTriples[0].object as IriTerm).value,
        equals('http://example.org/resource/123'),
      );

      // Deserialize from graph
      final deserializedContainer =
          rdfMapper.graph.decodeObject<ResourceContainer>(graph);

      // Verify deserialized properties
      expect(deserializedContainer.id, equals(container.id));
      expect(deserializedContainer.name, equals(container.name));
      expect(deserializedContainer.resource, isNotNull);
      expect(deserializedContainer.resource.uri, equals(reference.uri));
    });

    test('should handle multiple IRI term references in collections', () {
      // Register container with multiple references mapper
      rdfMapper.registerMapper<MultiReferenceContainer>(
        MultiReferenceContainerMapper(),
      );

      // Create test objects
      final reference1 = ResourceReference(
        uri: 'http://example.org/resource/1',
      );
      final reference2 = ResourceReference(
        uri: 'http://example.org/resource/2',
      );
      final reference3 = ResourceReference(
        uri: 'http://example.org/resource/3',
      );

      final container = MultiReferenceContainer(
        id: 'http://example.org/container/multi',
        name: 'Multi Reference',
        resources: [reference1, reference2, reference3],
      );

      // Serialize to graph
      final graph = rdfMapper.graph.encodeObject(container);

      // Deserialize from graph
      final deserializedContainer =
          rdfMapper.graph.decodeObject<MultiReferenceContainer>(graph);

      // Verify deserialized object properties
      expect(deserializedContainer.id, equals(container.id));
      expect(deserializedContainer.name, equals(container.name));
      expect(deserializedContainer.resources, isNotNull);
      expect(deserializedContainer.resources.length, equals(3));

      // Sort references for consistent testing
      final sortedResources = [...deserializedContainer.resources]
        ..sort((a, b) => a.uri.compareTo(b.uri));

      expect(sortedResources[0].uri, equals('http://example.org/resource/1'));
      expect(sortedResources[1].uri, equals('http://example.org/resource/2'));
      expect(sortedResources[2].uri, equals('http://example.org/resource/3'));
    });

    test('should handle custom URI transformation during mapping', () {
      // Register a mapper that modifies the URI structure
      rdfMapper.registerMapper<TransformedResource>(
        TransformedResourceMapper(),
      );

      // Create test object with a simple identifier that needs transformation
      final resource = TransformedResource(id: 'resource-123');

      // Serialize to graph
      final graph = rdfMapper.graph.encodeObject(resource);

      // Find the triple with the IRI term
      final identityTriples = graph.findTriples(
        subject: graph.triples.first.subject,
        predicate: const IriTerm('http://example.org/identity'),
      );
      expect(identityTriples.length, equals(1));
      expect(identityTriples[0].object, isA<IriTerm>());
      expect(
        (identityTriples[0].object as IriTerm).value,
        equals('http://example.org/resources/resource-123'),
      );

      // Deserialize from graph
      final deserializedResource =
          rdfMapper.graph.decodeObject<TransformedResource>(graph);

      // Verify the transformed URI was correctly extracted back to the simple ID
      expect(deserializedResource.id, equals('resource-123'));
    });

    test('should correctly handle circular references', () {
      // Register mappers that can have circular references
      rdfMapper.registerMapper<Person>(PersonMapper());

      // Create circular reference structure
      final alice = Person(
        id: 'http://example.org/person/alice',
        name: 'Alice',
      );
      final bob = Person(id: 'http://example.org/person/bob', name: 'Bob');

      // Create circular reference
      alice.knows = [PersonReference(uri: bob.id)];

      bob.knows = [PersonReference(uri: alice.id)];

      // Serialize the structure to a graph
      final graph = rdfMapper.graph.encodeObjects([alice, bob]);

      // Verify both subjects are in the graph
      final aliceSubject = graph.findTriples(
        subject: const IriTerm('http://example.org/person/alice'),
      );
      final bobSubject = graph.findTriples(
        subject: const IriTerm('http://example.org/person/bob'),
      );
      expect(aliceSubject, isNotEmpty);
      expect(bobSubject, isNotEmpty);

      // Verify the knows relationships are properly serialized
      final aliceKnows = graph.findTriples(
        subject: const IriTerm('http://example.org/person/alice'),
        predicate: const IriTerm('http://example.org/knows'),
      );
      expect(aliceKnows.length, equals(1));
      expect(aliceKnows[0].object, isA<IriTerm>());
      expect(
        (aliceKnows[0].object as IriTerm).value,
        equals('http://example.org/person/bob'),
      );

      // Verify Bob knows Alice
      final bobKnows = graph.findTriples(
        subject: const IriTerm('http://example.org/person/bob'),
        predicate: const IriTerm('http://example.org/knows'),
      );
      expect(bobKnows.length, equals(1));
      expect(bobKnows[0].object, isA<IriTerm>());
      expect(
        (bobKnows[0].object as IriTerm).value,
        equals('http://example.org/person/alice'),
      );

      // Deserialize all objects from the graph
      final deserializedPeople = rdfMapper.graph.decodeObjects<Person>(graph);
      expect(deserializedPeople.length, equals(2));

      // Find Alice and Bob in the deserialized list
      final deserializedAlice = deserializedPeople.firstWhere(
        (p) => p.id == 'http://example.org/person/alice',
      );
      final deserializedBob = deserializedPeople.firstWhere(
        (p) => p.id == 'http://example.org/person/bob',
      );

      // Verify the circular references were preserved
      expect(deserializedAlice.knows.length, equals(1));
      expect(
        deserializedAlice.knows[0].uri,
        equals('http://example.org/person/bob'),
      );

      expect(deserializedBob.knows.length, equals(1));
      expect(
        deserializedBob.knows[0].uri,
        equals('http://example.org/person/alice'),
      );
    });
  });
}

// Test models and mappers

class ResourceReference {
  final String uri;

  ResourceReference({required this.uri});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResourceReference && other.uri == uri;
  }

  @override
  int get hashCode => uri.hashCode;
}

class ResourceContainer {
  final String id;
  final String name;
  final ResourceReference resource;

  ResourceContainer({
    required this.id,
    required this.name,
    required this.resource,
  });
}

class MultiReferenceContainer {
  final String id;
  final String name;
  final Iterable<ResourceReference> resources;

  MultiReferenceContainer({
    required this.id,
    required this.name,
    required this.resources,
  });
}

class TransformedResource {
  final String id;

  TransformedResource({required this.id});
}

class Person {
  final String id;
  final String name;
  List<PersonReference> knows = [];

  Person({required this.id, required this.name});
}

class PersonReference {
  final String uri;

  PersonReference({required this.uri});
}

// Mappers

class ResourceReferenceMapper implements IriTermMapper<ResourceReference> {
  @override
  ResourceReference fromRdfTerm(IriTerm term, DeserializationContext context) {
    return ResourceReference(uri: term.value);
  }

  @override
  IriTerm toRdfTerm(ResourceReference value, SerializationContext context) {
    return context.createIriTerm(value.uri);
  }
}

class ResourceContainerMapper
    implements GlobalResourceMapper<ResourceContainer> {
  @override
  final IriTerm typeIri = const IriTerm('http://example.org/ResourceContainer');

  @override
  ResourceContainer fromRdfResource(
    IriTerm subject,
    DeserializationContext context,
  ) {
    final reader = context.reader(subject);
    final name =
        reader.require<String>(const IriTerm('http://example.org/name'));
    final resource = reader.require<ResourceReference>(
      const IriTerm('http://example.org/resource'),
    );

    return ResourceContainer(id: subject.value, name: name, resource: resource);
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    ResourceContainer value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(value.id))
        .addValue(const IriTerm('http://example.org/name'), value.name)
        // We have a IriTermMapper for ResourceReference, no need to specify
        // that this shall be serialized as IriTerm
        .addValue(const IriTerm('http://example.org/resource'), value.resource)
        .build();
  }
}

class MultiReferenceContainerMapper
    implements GlobalResourceMapper<MultiReferenceContainer> {
  @override
  final IriTerm typeIri =
      const IriTerm('http://example.org/MultiReferenceContainer');

  @override
  MultiReferenceContainer fromRdfResource(
    IriTerm subject,
    DeserializationContext context,
  ) {
    final reader = context.reader(subject);
    final name =
        reader.require<String>(const IriTerm('http://example.org/name'));
    final resources = reader.getValues<ResourceReference>(
      const IriTerm('http://example.org/resources'),
    );

    return MultiReferenceContainer(
      id: subject.value,
      name: name,
      resources: resources,
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    MultiReferenceContainer value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final builder = context
        .resourceBuilder(context.createIriTerm(value.id))
        .addValue(const IriTerm('http://example.org/name'), value.name);

    for (final resource in value.resources) {
      builder.addValue(const IriTerm('http://example.org/resources'), resource);
    }

    return builder.build();
  }
}

class TransformedResourceMapper
    implements GlobalResourceMapper<TransformedResource> {
  static const String baseUri = 'http://example.org/resources/';

  @override
  final IriTerm typeIri =
      const IriTerm('http://example.org/TransformedResource');

  @override
  TransformedResource fromRdfResource(
    IriTerm subject,
    DeserializationContext context,
  ) {
    final reader = context.reader(subject);
    final identityIri = reader.require<ResourceReference>(
      const IriTerm('http://example.org/identity'),
    );

    // Extract the ID from the full URI
    final id = identityIri.uri.substring(baseUri.length);

    return TransformedResource(id: id);
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    TransformedResource value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    // Transform the simple ID to a full URI
    final identityUri = '$baseUri${value.id}';
    final identity = ResourceReference(uri: identityUri);

    return context
        .resourceBuilder(context.createIriTerm(identityUri))
        .addValue(const IriTerm('http://example.org/identity'), identity)
        .build();
  }
}

class PersonMapper implements GlobalResourceMapper<Person> {
  @override
  final IriTerm typeIri = const IriTerm('http://example.org/Person');

  @override
  Person fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final name =
        reader.require<String>(const IriTerm('http://example.org/name'));
    final knows = reader
        .getValues<ResourceReference>(const IriTerm('http://example.org/knows'))
        .map((ref) => PersonReference(uri: ref.uri))
        .toList();

    final person = Person(id: subject.value, name: name);
    person.knows = knows;
    return person;
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Person value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final builder = context
        .resourceBuilder(context.createIriTerm(value.id))
        .addValue(const IriTerm('http://example.org/name'), value.name);

    for (final personRef in value.knows) {
      builder.addValue(const IriTerm('http://example.org/knows'),
          ResourceReference(uri: personRef.uri));
    }

    return builder.build();
  }
}
