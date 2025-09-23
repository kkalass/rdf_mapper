// ignore_for_file: avoid_print

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/foaf.dart';

/// Example demonstrating the Document Pattern using SerializationProvider.
///
/// This pattern is commonly used for:
/// - FOAF Profile Documents (WebID profiles)
/// - Solid Pod documents
/// - Any RDF document that has a primary topic with contextual properties
///
/// The Document Pattern allows preserving the document structure while
/// providing contextual information to nested mappers.

/// Generic document wrapper that represents a FOAF Document.
class Document<T> {
  /// The IRI of the document itself
  final String documentIri;

  /// The primary topic of the document (foaf:primaryTopic)
  final T primaryTopic;

  /// Any unmapped triples for lossless round-trip mapping
  final RdfGraph unmapped;

  const Document({
    required this.documentIri,
    required this.primaryTopic,
    required this.unmapped,
  });

  @override
  String toString() =>
      'Document{documentIri: $documentIri, primaryTopic: $primaryTopic}';
}

/// Person class that can use document context for relative values.
class Person {
  final String id;
  final String name;
  final String? email;
  final DateTime? birthDate;

  /// Photo path relative to the document
  final String? photoPath;

  const Person({
    required this.id,
    required this.name,
    this.email,
    this.birthDate,
    this.photoPath,
  });

  @override
  String toString() =>
      'Person{id: $id, name: $name, email: $email, photoPath: $photoPath}';
}

/// Mapper for Document that uses SerializationProvider for the primary topic.
class DocumentMapper<T> implements GlobalResourceMapper<Document<T>> {
  final SerializationProvider<Document<T>, T> _primaryTopicProvider;

  const DocumentMapper({
    required SerializationProvider<Document<T>, T> primaryTopic,
  }) : _primaryTopicProvider = primaryTopic;

  @override
  IriTerm? get typeIri => FoafPersonalProfileDocument.classIri;

  @override
  Document<T> fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    final documentIri = subject.value;
    final T primaryTopic = reader.require(
      FoafPersonalProfileDocument.primaryTopic,
      deserializer: _primaryTopicProvider.deserializer(subject, context),
    );

    // Get unmapped triples as the last reader operation for lossless mapping
    final RdfGraph unmapped =
        reader.getUnmapped<RdfGraph>(globalUnmapped: true);

    return Document<T>(
      documentIri: documentIri,
      primaryTopic: primaryTopic,
      unmapped: unmapped,
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Document<T> document,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = context.createIriTerm(document.documentIri);

    return context
        .resourceBuilder(subject)
        .addValue(
          FoafPersonalProfileDocument.primaryTopic,
          document.primaryTopic,
          serializer: _primaryTopicProvider.serializer(
            document,
            subject,
            context,
          ),
        )
        .addUnmapped(document.unmapped)
        .build();
  }
}

/// Person mapper that can optionally receive document context.
class PersonMapper implements GlobalResourceMapper<Person> {
  /// Optional provider for the document IRI context
  final String Function() documentIriProvider;

  const PersonMapper({required this.documentIriProvider});

  @override
  IriTerm? get typeIri => FoafPerson.classIri;

  @override
  Person fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    // Get photo IRI and make it relative to document if possible
    final docIri = documentIriProvider();
    final photoPath = reader.optional<String>(FoafPerson.schemahttpImage,
        deserializer: IriRelativeDeserializer(docIri));

    return Person(
      id: subject.value,
      name: reader.require<String>(FoafPerson.name),
      email: reader.optional<String>(FoafPerson.schemahttpEmail),
      birthDate: reader.optional<DateTime>(FoafPerson.schemahttpBirthDate,
          deserializer: const DateMapper()),
      photoPath: photoPath,
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Person person,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = context.createIriTerm(person.id);

    // Convert relative photo path back to absolute IRI
    final docIri = documentIriProvider();

    return context
        .resourceBuilder(subject)
        .addValue(FoafPerson.name, person.name)
        .addValueIfNotNull(FoafPerson.schemahttpEmail, person.email)
        .addValueIfNotNull(FoafPerson.schemahttpBirthDate, person.birthDate,
            serializer: const DateMapper())
        .addValueIfNotNull(FoafPerson.schemahttpImage, person.photoPath,
            serializer: IriRelativeSerializer(docIri))
        .build();
  }
}

void main() {
  // Create an RDF mapper with Document and Person mappers
  final rdfMapper = RdfMapper.withMappers((registry) => registry
    // Register Document<Person> with an IRI-contextual serialization provider
    // The provider creates PersonMapper instances that know about their document context
    ..registerMapper<Document<Person>>(DocumentMapper<Person>(
        primaryTopic:
            SerializationProvider.iriContextual<Document<Person>, Person>(
      (IriTerm documentIri) => PersonMapper(
        documentIriProvider: () => documentIri.value,
      ),
    ))));

  print('=== Document Pattern Example ===\n');

  // Example 1: FOAF Profile Document (like a Solid WebID)
  runFoafProfileExample(rdfMapper);

  print('\n${'=' * 50}\n');

  // Example 2: Multiple documents with different contexts
  runMultipleDocumentsExample(rdfMapper);
}

void runFoafProfileExample(RdfMapper rdfMapper) {
  print('1. FOAF Profile Document Example (Solid WebID style)');
  print('---------------------------------------------------');

  // Sample RDF data representing a FOAF profile document
  const turtle = '''
@prefix : <#> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix schema: <http://schema.org/> .
@prefix solid: <http://www.w3.org/ns/solid/terms#> .

<https://alice.datapod.example/profile/card> 
    a foaf:PersonalProfileDocument ;
    foaf:maker <https://alice.datapod.example/profile/card#me> ;
    foaf:primaryTopic <https://alice.datapod.example/profile/card#me> .

<https://alice.datapod.example/profile/card#me>
    a schema:Person, foaf:Person ;
    foaf:name "Alice Smith" ;
    schema:email "alice@example.com" ;
    schema:birthDate "1990-05-15"^^<http://www.w3.org/2001/XMLSchema#date> ;
    schema:image <https://alice.datapod.example/profile/photos/avatar.jpg> .
''';

  print('RDF Input:');
  print(turtle);
  print('');

  // Deserialize the document
  final document = rdfMapper.decodeObject<Document<Person>>(turtle);
  print('Deserialized Document:');
  print('  Document IRI: ${document.documentIri}');
  print('  Primary Topic: ${document.primaryTopic}');
  print('  Photo path: ${document.primaryTopic.photoPath}');
  print('');

  // Serialize it back
  final serializedTurtle = rdfMapper.encodeObject(document);
  print('Serialized back to RDF:');
  print(serializedTurtle);
}

void runMultipleDocumentsExample(RdfMapper rdfMapper) {
  print('2. Multiple Documents with Different Contexts');
  print('--------------------------------------------');

  // Create documents programmatically
  final aliceDocument = Document<Person>(
    documentIri: 'https://alice.example/profile',
    primaryTopic: const Person(
      id: 'https://alice.example/profile#me',
      name: 'Alice Johnson',
      email: 'alice.j@example.com',
      photoPath: 'photos/alice.jpg', // Relative to document
    ),
    unmapped: RdfGraph(),
  );

  final bobDocument = Document<Person>(
    documentIri: 'https://bob.example/about',
    primaryTopic: Person(
      id: 'https://bob.example/about#self',
      name: 'Bob Wilson',
      email: 'bob.w@example.com',
      birthDate: DateTime(1985, 12, 10),
      photoPath:
          'https://external.example/avatars/bob.png', // Absolute external URL
    ),
    unmapped: RdfGraph(),
  );

  print('Created documents:');
  print('  Alice: ${aliceDocument.primaryTopic}');
  print('  Bob: ${bobDocument.primaryTopic}');
  print('');

  // Serialize both documents
  final aliceRdf = rdfMapper.encodeObject(aliceDocument);
  final bobRdf = rdfMapper.encodeObject(bobDocument);

  print('Alice\'s document as RDF:');
  print(aliceRdf);
  print('');

  print('Bob\'s document as RDF:');
  print(bobRdf);
  print('');

  // Deserialize them back
  final aliceBack = rdfMapper.decodeObject<Document<Person>>(aliceRdf);
  final bobBack = rdfMapper.decodeObject<Document<Person>>(bobRdf);

  print('Round-trip results:');
  print('  Alice person: ${aliceBack.primaryTopic}');
  print('  Bob person: ${bobBack.primaryTopic}');
}
