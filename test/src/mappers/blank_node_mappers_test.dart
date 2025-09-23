import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

// Test models
class Chapter {
  final String title;
  final int number;

  Chapter(this.title, this.number);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chapter &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          number == other.number;

  @override
  int get hashCode => title.hashCode ^ number.hashCode;
}

class ChapterMapper implements LocalResourceMapper<Chapter> {
  static final titlePredicate = const IriTerm('http://example.org/title');
  static final numberPredicate = const IriTerm('http://example.org/number');

  @override
  final IriTerm typeIri = const IriTerm('http://example.org/Chapter');

  @override
  Chapter fromRdfResource(BlankNodeTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    return Chapter(
      reader.require<String>(titlePredicate),
      reader.require<int>(numberPredicate),
    );
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
    Chapter chapter,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(BlankNodeTerm())
        .addValue(titlePredicate, chapter.title)
        .addValue<int>(numberPredicate, chapter.number)
        .build();
  }
}

void main() {
  late RdfMapperRegistry registry;
  late RdfMapper rdfMapper;

  setUp(() {
    registry = RdfMapperRegistry();
    rdfMapper = RdfMapper(registry: registry);
    rdfMapper.registerMapper<Chapter>(ChapterMapper());
  });

  group('BlankNode Mappers', () {
    test('serializes Dart objects to blank nodes with associated triples', () {
      final chapter = Chapter('Introduction', 1);
      final graph = rdfMapper.graph.encodeObject(chapter);

      // Verify exactly one blank node was created
      final blankNodes = graph.triples
          .map((t) => t.subject)
          .whereType<BlankNodeTerm>()
          .toSet();
      expect(blankNodes.length, equals(1));

      final blankNode = blankNodes.first;

      // Check for type triple
      final typeTriples = graph.findTriples(
        subject: blankNode,
        predicate:
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
      );
      expect(typeTriples.length, equals(1));
      expect(
        typeTriples[0].object,
        equals(const IriTerm('http://example.org/Chapter')),
      );

      // Check for title
      final titleTriples = graph.findTriples(
        subject: blankNode,
        predicate: ChapterMapper.titlePredicate,
      );
      expect(titleTriples.length, equals(1));
      expect(
        (titleTriples[0].object as LiteralTerm).value,
        equals('Introduction'),
      );

      // Check for number
      final numberTriples = graph.findTriples(
        subject: blankNode,
        predicate: ChapterMapper.numberPredicate,
      );
      expect(numberTriples.length, equals(1));
      expect((numberTriples[0].object as LiteralTerm).value, equals('1'));
    });

    test('deserializes blank nodes back to Dart objects', () {
      // Create a small graph with a blank node
      final blankNode = BlankNodeTerm();
      final triples = [
        Triple(
          blankNode,
          const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
          const IriTerm('http://example.org/Chapter'),
        ),
        Triple(
          blankNode,
          ChapterMapper.titlePredicate,
          LiteralTerm.string('Advanced Topics'),
        ),
        Triple(
          blankNode,
          ChapterMapper.numberPredicate,
          LiteralTerm.typed('42', 'integer'),
        ),
      ];

      final graph = RdfGraph(triples: triples);

      // Deserialize
      final chapter = rdfMapper.graph.decodeObject<Chapter>(
        graph,
        subject: blankNode,
      );

      // Verify properties
      expect(chapter.title, equals('Advanced Topics'));
      expect(chapter.number, equals(42));
    });

    test('handles blank nodes without type IRI', () {
      // Create a blank node mapper without type IRI
      final mapper = AnonymousMapper();
      rdfMapper.registerMapper<AnonymousData>(mapper);

      // Serialize
      final data = AnonymousData('test data');
      final graph = rdfMapper.graph.encodeObject(data);

      // Verify no type triple
      final blankNode = graph.triples.first.subject as BlankNodeTerm;
      final typeTriples = graph.findTriples(
        subject: blankNode,
        predicate:
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
      );
      expect(typeTriples.length, equals(0));

      // Verify content still present
      final contentTriples = graph.findTriples(
        subject: blankNode,
        predicate: AnonymousMapper.contentPredicate,
      );
      expect(contentTriples.length, equals(1));
      expect(
        (contentTriples[0].object as LiteralTerm).value,
        equals('test data'),
      );

      // Deserialize
      final deserialized = rdfMapper.graph.decodeObject<AnonymousData>(
        graph,
        subject: blankNode,
      );
      expect(deserialized.content, equals('test data'));
    });

    test('blank node mapper works in nested object structures', () {
      // Define parent class and mapper
      final documentMapper = DocumentMapper();
      rdfMapper.registerMapper<Document>(documentMapper);

      // Create test objects
      final chapters = [
        Chapter('Chapter 1', 1),
        Chapter('Chapter 2', 2),
        Chapter('Chapter 3', 3),
      ];
      final document = Document('Test Document', chapters);

      // Serialize
      final graph = rdfMapper.graph.encodeObject(document);

      // Find document subject
      final documentSubjects = graph
          .findTriples(
            predicate: DocumentMapper.titlePredicate,
            object: LiteralTerm.string('Test Document'),
          )
          .map((t) => t.subject)
          .toList();
      expect(documentSubjects.length, equals(1));

      // Find chapters
      final chapterTriples = graph.findTriples(
        subject: documentSubjects.first,
        predicate: DocumentMapper.chaptersPredicate,
      );
      expect(chapterTriples.length, equals(3));

      // Verify all chapters are blank nodes
      for (final triple in chapterTriples) {
        expect(triple.object, isA<BlankNodeTerm>());
      }

      // Deserialize
      final deserializedDocument = rdfMapper.graph.decodeObject<Document>(
        graph,
        subject: documentSubjects.first,
      );

      // Verify document
      expect(deserializedDocument.title, equals('Test Document'));
      var deserChapters = deserializedDocument.chapters.toList();
      expect(deserializedDocument.chapters.length, equals(3));
      expect(deserChapters[0].title, equals('Chapter 1'));
      expect(deserChapters[1].title, equals('Chapter 2'));
      expect(deserChapters[2].title, equals('Chapter 3'));
    });
  });
}

// Additional test classes

class AnonymousData {
  final String content;
  AnonymousData(this.content);
}

class AnonymousMapper implements LocalResourceMapper<AnonymousData> {
  static final contentPredicate = const IriTerm('http://example.org/content');

  @override
  final IriTerm? typeIri = null; // Explicitly null

  @override
  AnonymousData fromRdfResource(
    BlankNodeTerm term,
    DeserializationContext context,
  ) {
    final reader = context.reader(term);
    return AnonymousData(reader.require<String>(contentPredicate));
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
    AnonymousData data,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(BlankNodeTerm())
        .addValue(contentPredicate, data.content)
        .build();
  }
}

class Document {
  final String title;
  final Iterable<Chapter> chapters;

  Document(this.title, this.chapters);
}

class DocumentMapper implements GlobalResourceMapper<Document> {
  static final titlePredicate = const IriTerm('http://example.org/title');
  static final chaptersPredicate = const IriTerm('http://example.org/chapters');

  @override
  final IriTerm typeIri = const IriTerm('http://example.org/Document');

  @override
  Document fromRdfResource(IriTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    return Document(
      reader.require<String>(titlePredicate),
      reader.getValues<Chapter>(chaptersPredicate),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Document document,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    // Create a document IRI based on title
    final docId =
        'http://example.org/documents/${document.title.replaceAll(' ', '_')}';

    // Use the childResources method to properly handle the chapters
    return context
        .resourceBuilder(context.createIriTerm(docId))
        .addValue(titlePredicate, document.title)
        .addValues(chaptersPredicate, document.chapters)
        .build();
  }
}
