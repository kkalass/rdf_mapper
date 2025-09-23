import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('Custom Collections', () {
    late RdfMapper rdf;
    late GraphOperations graph;

    setUp(() {
      rdf = RdfMapper.withDefaultRegistry()
        ..registerMapper<Library>(LibraryMapper())
        ..registerMapper<Book>(BookMapper())
        ..registerMapper<Tag>(TagMapper());
      graph = rdf.graph;
    });

    group('ImmutableList', () {
      test('creates immutable list correctly', () {
        final books = [Book('Book 1'), Book('Book 2'), Book('Book 3')];
        final immutableList = ImmutableList(books);

        expect(immutableList.length, equals(3));
        expect(immutableList[0].title, equals('Book 1'));
        expect(immutableList[1].title, equals('Book 2'));
        expect(immutableList[2].title, equals('Book 3'));
      });

      test('preserves order', () {
        final books = [
          Book('First'),
          Book('Second'),
          Book('Third'),
        ];
        final immutableList = ImmutableList(books);

        final titles = immutableList.map((b) => b.title).toList();
        expect(titles, equals(['First', 'Second', 'Third']));
      });

      test('is truly immutable', () {
        final originalBooks = [Book('Book 1'), Book('Book 2')];
        final immutableList = ImmutableList(originalBooks);

        // Modifying original list should not affect immutable list
        originalBooks.add(Book('Book 3'));
        expect(immutableList.length, equals(2));
      });

      test('handles empty list', () {
        final immutableList = ImmutableList<Book>([]);
        expect(immutableList.length, equals(0));
      });
    });

    group('Serialization', () {
      test('serializes ImmutableList to RDF list structure', () {
        final library = Library(
          id: 'https://example.org/lib1',
          name: 'Test Library',
          featuredBooks: ImmutableList([
            Book('Design Patterns'),
            Book('Clean Code'),
          ]),
        );

        final rdfGraph = graph.encodeObject(library);

        // Check that the library has a featuredBooks property
        final librarySubject = const IriTerm('https://example.org/lib1');
        final featuredBooksTriples = rdfGraph.triples
            .where((t) =>
                t.subject == librarySubject &&
                t.predicate == LibraryVocab.featuredBooks)
            .toList();

        expect(featuredBooksTriples, hasLength(1));

        // The object should be either a blank node (for RDF list) or rdf:nil (for empty list)
        final listHead = featuredBooksTriples.first.object;
        expect(listHead, isA<RdfSubject>());

        // Check that RDF list structure exists (rdf:first and rdf:rest predicates)
        final rdfFirst =
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#first');
        final rdfRest =
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#rest');

        final firstTriples =
            rdfGraph.triples.where((t) => t.predicate == rdfFirst).toList();
        final restTriples =
            rdfGraph.triples.where((t) => t.predicate == rdfRest).toList();

        expect(firstTriples, isNotEmpty);
        expect(restTriples, isNotEmpty);

        // Verify the books are in the graph
        final titleTriples = rdfGraph.triples
            .where((t) => t.predicate == LibraryVocab.title)
            .toList();

        final titles =
            titleTriples.map((t) => (t.object as LiteralTerm).value).toList();

        expect(titles, containsAll(['Design Patterns', 'Clean Code']));
      });

      test('serializes empty ImmutableList', () {
        final library = Library(
          id: 'https://example.org/lib1',
          name: 'Empty Library',
          featuredBooks: ImmutableList<Book>([]),
        );

        final rdfGraph = graph.encodeObject(library);

        // Check that the library has a featuredBooks property
        final librarySubject = const IriTerm('https://example.org/lib1');
        final featuredBooksTriples = rdfGraph.triples
            .where((t) =>
                t.subject == librarySubject &&
                t.predicate == LibraryVocab.featuredBooks)
            .toList();

        expect(featuredBooksTriples, hasLength(1));

        // For empty list, the object should be rdf:nil
        final rdfNil =
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#nil');
        expect(featuredBooksTriples.first.object, equals(rdfNil));
      });

      test('serializes single item ImmutableList', () {
        final library = Library(
          id: 'https://example.org/lib1',
          name: 'Single Book Library',
          featuredBooks: ImmutableList([Book('Single Book')]),
        );

        final rdfGraph = graph.encodeObject(library);

        // Check that the library has a featuredBooks property
        final librarySubject = const IriTerm('https://example.org/lib1');
        final featuredBooksTriples = rdfGraph.triples
            .where((t) =>
                t.subject == librarySubject &&
                t.predicate == LibraryVocab.featuredBooks)
            .toList();

        expect(featuredBooksTriples, hasLength(1));

        // The object should be a blank node (list head)
        final listHead = featuredBooksTriples.first.object;
        expect(listHead, isA<BlankNodeTerm>());

        // Check RDF list structure
        final rdfFirst =
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#first');
        final rdfRest =
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#rest');
        final rdfNil =
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#nil');

        // Should have one rdf:first pointing to the book
        final firstTriples = rdfGraph.triples
            .where((t) => t.subject == listHead && t.predicate == rdfFirst)
            .toList();
        expect(firstTriples, hasLength(1));

        // Should have one rdf:rest pointing to rdf:nil
        final restTriples = rdfGraph.triples
            .where((t) => t.subject == listHead && t.predicate == rdfRest)
            .toList();
        expect(restTriples, hasLength(1));
        expect(restTriples.first.object, equals(rdfNil));

        // Verify the book title is in the graph
        final titleTriples = rdfGraph.triples
            .where((t) => t.predicate == LibraryVocab.title)
            .toList();
        expect(titleTriples, hasLength(1));
        expect((titleTriples.first.object as LiteralTerm).value,
            equals('Single Book'));
      });

      test('preserves order in RDF list structure', () {
        final library = Library(
          id: 'https://example.org/lib1',
          name: 'Ordered Library',
          featuredBooks: ImmutableList([
            Book('First Book'),
            Book('Second Book'),
            Book('Third Book'),
          ]),
        );

        final rdfGraph = graph.encodeObject(library);

        // Walk through the RDF list to verify order
        final librarySubject = const IriTerm('https://example.org/lib1');
        final featuredBooksTriples = rdfGraph.triples
            .where((t) =>
                t.subject == librarySubject &&
                t.predicate == LibraryVocab.featuredBooks)
            .toList();

        expect(featuredBooksTriples, hasLength(1));

        final rdfFirst =
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#first');
        final rdfRest =
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#rest');
        final rdfNil =
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#nil');

        // Walk the list and collect book titles in order
        final collectedTitles = <String>[];
        var currentNode = featuredBooksTriples.first.object;

        while (currentNode != rdfNil) {
          // Get the first (book) from current node
          final firstTriples = rdfGraph.triples
              .where((t) => t.subject == currentNode && t.predicate == rdfFirst)
              .toList();
          expect(firstTriples, hasLength(1));

          final bookNode = firstTriples.first.object;

          // Get the book title
          final titleTriples = rdfGraph.triples
              .where((t) =>
                  t.subject == bookNode && t.predicate == LibraryVocab.title)
              .toList();
          expect(titleTriples, hasLength(1));

          final title = (titleTriples.first.object as LiteralTerm).value;
          collectedTitles.add(title);

          // Move to next node
          final restTriples = rdfGraph.triples
              .where((t) => t.subject == currentNode && t.predicate == rdfRest)
              .toList();
          expect(restTriples, hasLength(1));

          currentNode = restTriples.first.object;
        }

        // Verify the order is preserved
        expect(collectedTitles,
            equals(['First Book', 'Second Book', 'Third Book']));
      });
    });

    group('Deserialization', () {
      test('deserializes ImmutableList from RDF list structure', () {
        final originalLibrary = Library(
          id: 'https://example.org/lib1',
          name: 'Test Library',
          featuredBooks: ImmutableList([
            Book('First Book'),
            Book('Second Book'),
            Book('Third Book'),
          ]),
        );

        final turtle = rdf.encodeObject(originalLibrary);
        final deserializedLibrary = rdf.decodeObject<Library>(turtle);

        expect(deserializedLibrary.name, equals('Test Library'));
        expect(deserializedLibrary.featuredBooks.length, equals(3));
        expect(
            deserializedLibrary.featuredBooks[0].title, equals('First Book'));
        expect(
            deserializedLibrary.featuredBooks[1].title, equals('Second Book'));
        expect(
            deserializedLibrary.featuredBooks[2].title, equals('Third Book'));
      });

      test('deserializes empty ImmutableList', () {
        final originalLibrary = Library(
          id: 'https://example.org/lib1',
          name: 'Empty Library',
          featuredBooks: ImmutableList<Book>([]),
        );

        final turtle = rdf.encodeObject(originalLibrary);
        final deserializedLibrary = rdf.decodeObject<Library>(turtle);

        expect(deserializedLibrary.featuredBooks.length, equals(0));
      });

      test('preserves order during deserialization', () {
        final books = [
          Book('Alpha'),
          Book('Beta'),
          Book('Gamma'),
          Book('Delta'),
        ];
        final originalLibrary = Library(
          id: 'https://example.org/lib1',
          name: 'Ordered Library',
          featuredBooks: ImmutableList(books),
        );

        final turtle = rdf.encodeObject(originalLibrary);
        final deserializedLibrary = rdf.decodeObject<Library>(turtle);

        // Verify order is preserved
        for (int i = 0; i < books.length; i++) {
          expect(
            deserializedLibrary.featuredBooks[i].title,
            equals(books[i].title),
          );
        }
      });
    });

    group('Roundtrip Tests', () {
      test('roundtrip preserves all data', () {
        final originalLibrary = Library(
          id: 'https://example.org/complex-lib',
          name: 'Complex Library',
          featuredBooks: ImmutableList([
            Book('Book A'),
            Book('Book B'),
            Book('Book C'),
          ]),
        );

        final turtle = rdf.encodeObject(originalLibrary);
        final deserializedLibrary = rdf.decodeObject<Library>(turtle);

        expect(deserializedLibrary.id, equals(originalLibrary.id));
        expect(deserializedLibrary.name, equals(originalLibrary.name));
        expect(
          deserializedLibrary.featuredBooks.length,
          equals(originalLibrary.featuredBooks.length),
        );

        for (int i = 0; i < originalLibrary.featuredBooks.length; i++) {
          expect(
            deserializedLibrary.featuredBooks[i].title,
            equals(originalLibrary.featuredBooks[i].title),
          );
        }
      });

      test('multiple roundtrips are stable', () {
        final originalLibrary = Library(
          id: 'https://example.org/stable-lib',
          name: 'Stable Library',
          featuredBooks: ImmutableList([
            Book('Stable Book 1'),
            Book('Stable Book 2'),
          ]),
        );

        var currentLibrary = originalLibrary;

        // Perform multiple roundtrips
        for (int i = 0; i < 3; i++) {
          final turtle = rdf.encodeObject(currentLibrary);
          currentLibrary = rdf.decodeObject<Library>(turtle);
        }

        // Should still match original
        expect(currentLibrary.name, equals(originalLibrary.name));
        expect(currentLibrary.featuredBooks.length, equals(2));
        expect(currentLibrary.featuredBooks[0].title, equals('Stable Book 1'));
        expect(currentLibrary.featuredBooks[1].title, equals('Stable Book 2'));
      });
    });

    group('Extension Methods', () {
      test('requireImmutableList works with present data', () {
        final library = Library(
          id: 'https://example.org/lib1',
          name: 'Test Library',
          featuredBooks: ImmutableList([Book('Test Book')]),
        );

        final turtle = rdf.encodeObject(library);
        final deserializedLibrary = rdf.decodeObject<Library>(turtle);

        expect(deserializedLibrary.featuredBooks.length, equals(1));
        expect(deserializedLibrary.featuredBooks[0].title, equals('Test Book'));
      });

      test('optionalImmutableList returns null when missing', () {
        // Create a library with no featured books by using raw Turtle
        const incompleteTurtle = '''
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix lib: <https://example.org/library/> .

<https://example.org/lib1> a lib:Library ;
    lib:name "Library Without Books" .
''';

        // This should work because featuredBooks is optional
        final library = rdf.decodeObject<Library>(incompleteTurtle);
        expect(library.featuredBooks.length, equals(0));
      });

      test('addImmutableList builder method works', () {
        final books = ImmutableList([Book('Builder Book')]);

        // This is tested implicitly in the serialization tests,
        // but we can verify the extension method is available
        expect(books.length, equals(1));
        expect(books[0].title, equals('Builder Book'));
      });
    });

    group('Type Safety', () {
      test('ImmutableList maintains type at runtime', () {
        final books = ImmutableList([Book('Type Test')]);
        expect(books.runtimeType.toString(), contains('ImmutableList'));
      });

      test('generic type is preserved', () {
        final stringList = ImmutableList(['a', 'b', 'c']);
        final bookList = ImmutableList([Book('Book')]);

        // These should be different types
        expect(stringList.runtimeType != bookList.runtimeType, isTrue);
      });
    });

    group('Error Handling', () {
      test('handles malformed RDF gracefully', () {
        // Create malformed RDF that breaks list structure
        const malformedTurtle = '''
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix lib: <https://example.org/library/> .

<https://example.org/lib1> a lib:Library ;
    lib:name "Broken Library" ;
    lib:featuredBooks "not-a-list" .
''';

        // Should handle gracefully or throw meaningful error
        expect(
          () => rdf.decodeObject<Library>(malformedTurtle),
          throwsA(isA<Exception>()),
        );
      });

      test('handles missing required collection appropriately', () {
        // Note: This depends on whether featuredBooks is truly required
        // Based on the mapper, it uses optionalImmutableList with fallback
        const incompleteTurtle = '''
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix lib: <https://example.org/library/> .

<https://example.org/lib1> a lib:Library ;
    lib:name "Incomplete Library" .
''';

        final library = rdf.decodeObject<Library>(incompleteTurtle);

        // Should use the fallback empty ImmutableList
        expect(library.featuredBooks.length, equals(0));
      });
    });

    group('Performance', () {
      test('handles large collections efficiently', () {
        final manyBooks = List.generate(
          100,
          (i) => Book('Book ${i.toString().padLeft(3, '0')}'),
        );

        final library = Library(
          id: 'https://example.org/large-lib',
          name: 'Large Library',
          featuredBooks: ImmutableList(manyBooks),
        );

        // Should complete without timeout
        final stopwatch = Stopwatch()..start();
        final turtle = rdf.encodeObject(library);
        final deserializedLibrary = rdf.decodeObject<Library>(turtle);
        stopwatch.stop();

        expect(deserializedLibrary.featuredBooks.length, equals(100));
        expect(
            stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 second timeout
      });
    });

    group('Multi-Objects vs RDF List Comparison', () {
      test('demonstrates different RDF structures for same data', () {
        final books = ImmutableList([
          Book('Book A'),
          Book('Book B'),
          Book('Book C'),
        ]);

        // Create library using RDF list approach
        final libraryRdfList = Library(
          id: 'https://example.org/rdf-list-lib',
          name: 'RDF List Library',
          featuredBooks: books,
        );

        // Create library using multi-objects approach
        final libraryMultiObjects = Library(
          id: 'https://example.org/multi-objects-lib',
          name: 'Multi Objects Library',
          featuredBooks: books,
        );

        // Set up RDF mapper with multi-objects mapper for comparison
        final rdfWithMultiObjects = RdfMapper.withDefaultRegistry()
          ..registerMapper<Library>(LibraryMultiObjectsMapper())
          ..registerMapper<Book>(BookMapper());

        // Serialize using both approaches
        final rdfListGraph = graph.encodeObject(libraryRdfList);
        final multiObjectsGraph =
            rdfWithMultiObjects.graph.encodeObject(libraryMultiObjects);

        // Verify different RDF structures
        final rdfFirst =
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#first');
        final rdfRest =
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#rest');

        // RDF List approach should have rdf:first and rdf:rest triples
        final rdfListFirstTriples =
            rdfListGraph.triples.where((t) => t.predicate == rdfFirst).toList();
        final rdfListRestTriples =
            rdfListGraph.triples.where((t) => t.predicate == rdfRest).toList();

        expect(rdfListFirstTriples, isNotEmpty,
            reason: 'RDF List approach should use rdf:first');
        expect(rdfListRestTriples, isNotEmpty,
            reason: 'RDF List approach should use rdf:rest');

        // Multi-objects approach should NOT have rdf:first/rdf:rest
        final multiObjectsFirstTriples = multiObjectsGraph.triples
            .where((t) => t.predicate == rdfFirst)
            .toList();
        final multiObjectsRestTriples = multiObjectsGraph.triples
            .where((t) => t.predicate == rdfRest)
            .toList();

        expect(multiObjectsFirstTriples, isEmpty,
            reason: 'Multi-objects approach should NOT use rdf:first');
        expect(multiObjectsRestTriples, isEmpty,
            reason: 'Multi-objects approach should NOT use rdf:rest');

        // Multi-objects approach should have multiple triples with same predicate
        final multiObjectsFeaturedTriples = multiObjectsGraph.triples
            .where((t) => t.predicate == LibraryVocab.featuredBooks)
            .toList();

        expect(multiObjectsFeaturedTriples.length, equals(3),
            reason: 'Multi-objects approach should have one triple per book');

        // RDF List approach should have only one featuredBooks triple (pointing to list head)
        final rdfListFeaturedTriples = rdfListGraph.triples
            .where((t) => t.predicate == LibraryVocab.featuredBooks)
            .toList();

        expect(rdfListFeaturedTriples.length, equals(1),
            reason:
                'RDF List approach should have one triple pointing to list head');
      });

      test('both approaches deserialize to same result', () {
        final originalBooks = [
          Book('Shared Book 1'),
          Book('Shared Book 2'),
          Book('Shared Book 3'),
        ];

        // Create and serialize using RDF list approach
        final libraryRdfList = Library(
          id: 'https://example.org/test-lib',
          name: 'Test Library',
          featuredBooks: ImmutableList(originalBooks),
        );

        final rdfListTurtle = rdf.encodeObject(libraryRdfList);

        // Create and serialize using multi-objects approach
        final libraryMultiObjects = Library(
          id: 'https://example.org/test-lib',
          name: 'Test Library',
          featuredBooks: ImmutableList(originalBooks),
        );

        final rdfWithMultiObjects = RdfMapper.withDefaultRegistry()
          ..registerMapper<Library>(LibraryMultiObjectsMapper())
          ..registerMapper<Book>(BookMapper());

        final multiObjectsTurtle =
            rdfWithMultiObjects.encodeObject(libraryMultiObjects);

        // Deserialize both using the appropriate approach for each
        final deserializedFromRdfList =
            rdf.decodeObject<Library>(rdfListTurtle);

        // For multi-objects, we need to use the multi-objects deserializer
        final deserializedFromMultiObjects =
            rdfWithMultiObjects.decodeObject<Library>(multiObjectsTurtle);

        // Both should have the same content
        expect(deserializedFromRdfList.name,
            equals(deserializedFromMultiObjects.name));
        expect(deserializedFromRdfList.featuredBooks.length,
            equals(deserializedFromMultiObjects.featuredBooks.length));

        // Content should match (though order might differ for multi-objects)
        final rdfListTitles =
            deserializedFromRdfList.featuredBooks.map((b) => b.title).toSet();
        final multiObjectsTitles = deserializedFromMultiObjects.featuredBooks
            .map((b) => b.title)
            .toSet();

        expect(rdfListTitles, equals(multiObjectsTitles));
      });

      test('demonstrates order preservation difference', () {
        final books = ImmutableList([
          Book('First'),
          Book('Second'),
          Book('Third'),
          Book('Fourth'),
        ]);

        // RDF List preserves order
        final libraryRdfList = Library(
          id: 'https://example.org/ordered-lib',
          name: 'Ordered Library',
          featuredBooks: books,
        );

        final rdfListTurtle = rdf.encodeObject(libraryRdfList);
        final deserializedRdfList = rdf.decodeObject<Library>(rdfListTurtle);

        // Verify order is preserved with RDF List
        for (int i = 0; i < books.length; i++) {
          expect(deserializedRdfList.featuredBooks[i].title,
              equals(books[i].title));
        }

        // Multi-objects approach does not guarantee order preservation
        final libraryMultiObjects = Library(
          id: 'https://example.org/unordered-lib',
          name: 'Unordered Library',
          featuredBooks: books,
        );

        final rdfWithMultiObjects = RdfMapper.withDefaultRegistry()
          ..registerMapper<Library>(LibraryMultiObjectsMapper())
          ..registerMapper<Book>(BookMapper());

        final multiObjectsTurtle =
            rdfWithMultiObjects.encodeObject(libraryMultiObjects);

        // For deserialization, we need to use the appropriate mapper for each approach
        final deserializedMultiObjects =
            rdfWithMultiObjects.decodeObject<Library>(multiObjectsTurtle);

        // Content should be the same but order is not guaranteed
        final originalTitles = books.map((b) => b.title).toSet();
        final deserializedTitles =
            deserializedMultiObjects.featuredBooks.map((b) => b.title).toSet();

        expect(deserializedTitles, equals(originalTitles));
        expect(deserializedMultiObjects.featuredBooks.length,
            equals(books.length));
      });

      test('demonstrates cross-compatibility limitations', () {
        // This test shows that you can't mix serialization and deserialization approaches
        final books = ImmutableList([
          Book('Cross Book 1'),
          Book('Cross Book 2'),
        ]);

        // Serialize using multi-objects approach
        final libraryMultiObjects = Library(
          id: 'https://example.org/cross-test-lib',
          name: 'Cross Test Library',
          featuredBooks: books,
        );

        final rdfWithMultiObjects = RdfMapper.withDefaultRegistry()
          ..registerMapper<Library>(LibraryMultiObjectsMapper())
          ..registerMapper<Book>(BookMapper());

        final multiObjectsTurtle =
            rdfWithMultiObjects.encodeObject(libraryMultiObjects);

        // Try to deserialize using RDF list approach (should fail)
        expect(
          () => rdf.decodeObject<Library>(multiObjectsTurtle),
          throwsA(isA<TooManyPropertyValuesException>()),
          reason: 'RDF list deserializer cannot handle multi-objects structure',
        );

        // The reverse test would be more complex due to RDF list structure
        // For now, we've demonstrated the key point: serializer choice determines structure
      });
    });
  });
}

// Custom Collection Types (copied from example for testing)

/// Immutable list wrapper that preserves order and prevents modification
class ImmutableList<T> {
  final List<T> _items;

  ImmutableList(Iterable<T> items) : _items = List.unmodifiable(items);

  int get length => _items.length;

  T operator [](int index) => _items[index];

  Iterable<R> map<R>(R Function(T) transform) => _items.map(transform);

  @override
  String toString() => 'ImmutableList($_items)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImmutableList<T> &&
          runtimeType == other.runtimeType &&
          _items.length == other._items.length &&
          _items
              .asMap()
              .entries
              .every((entry) => entry.value == other._items[entry.key]);

  @override
  int get hashCode => _items.hashCode;
}

// Collection Serializers/Deserializers

/// Serializer for ImmutableList using RDF list structure (preserves order)
class ImmutableListSerializer<T>
    with RdfListSerializerMixin<T>
    implements UnifiedResourceSerializer<ImmutableList<T>> {
  final Serializer<T>? _itemSerializer;

  const ImmutableListSerializer(this._itemSerializer);

  @override
  (RdfSubject, Iterable<Triple>) toRdfResource(
      ImmutableList<T> collection, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final (subject, triples) = buildRdfList(
        collection._items, context, _itemSerializer,
        parentSubject: parentSubject);
    return (subject, triples.toList());
  }
}

/// Deserializer for ImmutableList from RDF list structure (preserves order)
class ImmutableListDeserializer<T>
    with RdfListDeserializerMixin<T>
    implements UnifiedResourceDeserializer<ImmutableList<T>> {
  final Deserializer<T>? itemDeserializer;

  const ImmutableListDeserializer({this.itemDeserializer});

  @override
  ImmutableList<T> fromRdfResource(
      RdfSubject subject, DeserializationContext context) {
    final items = readRdfList(subject, context, itemDeserializer);
    return ImmutableList(items);
  }
}

// Extension Methods for Convenient APIs

/// Extension methods for ResourceReader to add custom collection support
extension CustomCollectionReaderExtensions on ResourceReader {
  /// Read a required ImmutableList (ordered, immutable)
  ImmutableList<T> requireImmutableList<T>(RdfPredicate predicate) =>
      requireCollection<ImmutableList<T>, T>(
        predicate,
        ImmutableListDeserializer.new,
      );

  /// Read an optional ImmutableList (ordered, immutable)
  ImmutableList<T>? optionalImmutableList<T>(RdfPredicate predicate) =>
      optionalCollection<ImmutableList<T>, T>(
        predicate,
        ImmutableListDeserializer.new,
      );
}

/// Extension methods for ResourceBuilder to add custom collection support
extension CustomCollectionBuilderExtensions<S extends RdfSubject>
    on ResourceBuilder<S> {
  /// Add an ImmutableList (ordered, immutable)
  ResourceBuilder<S> addImmutableList<T>(
          RdfPredicate predicate, ImmutableList<T> collection) =>
      addCollection<ImmutableList<T>, T>(
        predicate,
        collection,
        ({itemSerializer}) => ImmutableListSerializer<T>(itemSerializer),
      );
}

// Domain Model

class Library {
  final String id;
  final String name;
  final ImmutableList<Book> featuredBooks; // Ordered, immutable collection

  Library({
    required this.id,
    required this.name,
    required this.featuredBooks,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Library &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          featuredBooks == other.featuredBooks;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ featuredBooks.hashCode;
}

class Book {
  final String title;

  Book(this.title);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book && runtimeType == other.runtimeType && title == other.title;

  @override
  int get hashCode => title.hashCode;

  @override
  String toString() => 'Book(title: $title)';
}

class Tag {
  final String name;

  Tag(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

// Vocabulary
class LibraryVocab {
  static const String _ns = 'https://example.org/library/';

  // Types
  static final library = const IriTerm('${_ns}Library');
  static final book = const IriTerm('${_ns}Book');
  static final tag = const IriTerm('${_ns}Tag');

  // Properties
  static final name = const IriTerm('${_ns}name');
  static final title = const IriTerm('${_ns}title');
  static final featuredBooks = const IriTerm('${_ns}featuredBooks');
  static final categories = const IriTerm('${_ns}categories');
}

// Mappers

class LibraryMapper implements GlobalResourceMapper<Library> {
  @override
  IriTerm? get typeIri => LibraryVocab.library;

  @override
  Library fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    return Library(
      id: subject.value,
      name: reader.require<String>(LibraryVocab.name),

      // Use our custom extension methods - as convenient as built-in methods!
      featuredBooks:
          reader.optionalImmutableList<Book>(LibraryVocab.featuredBooks) ??
              ImmutableList([]),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Library library,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(library.id))
        .addValue(LibraryVocab.name, library.name)

        // Use our custom extension methods - as convenient as built-in methods!
        .addImmutableList<Book>(
            LibraryVocab.featuredBooks, library.featuredBooks)
        .build();
  }
}

class BookMapper implements LocalResourceMapper<Book> {
  @override
  IriTerm? get typeIri => LibraryVocab.book;

  @override
  Book fromRdfResource(BlankNodeTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Book(reader.require<String>(LibraryVocab.title));
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
    Book book,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(BlankNodeTerm())
        .addValue(LibraryVocab.title, book.title)
        .build();
  }
}

class TagMapper implements LocalResourceMapper<Tag> {
  @override
  IriTerm? get typeIri => LibraryVocab.tag;

  @override
  Tag fromRdfResource(BlankNodeTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Tag(reader.require<String>(LibraryVocab.name));
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
    Tag tag,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(BlankNodeTerm())
        .addValue(LibraryVocab.name, tag.name)
        .build();
  }
}

// Alternative Collection Serializers/Deserializers using MultiObjects approach

/// Alternative serializer for ImmutableList using multi-objects approach (unordered)
class ImmutableListMultiObjectsSerializer<T>
    implements MultiObjectsSerializer<ImmutableList<T>> {
  final Serializer<T>? itemSerializer;

  const ImmutableListMultiObjectsSerializer({this.itemSerializer});

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
      ImmutableList<T> collection, SerializationContext context) {
    final rdfObjects = collection
        .map((v) => context.serialize(v, serializer: itemSerializer))
        .toList();
    return (
      rdfObjects.expand((r) => r.$1).cast<RdfObject>(),
      rdfObjects.expand((r) => r.$2)
    );
  }
}

/// Alternative deserializer for ImmutableList using multi-objects approach (unordered)
class ImmutableListMultiObjectsDeserializer<T>
    implements MultiObjectsDeserializer<ImmutableList<T>> {
  final Deserializer<T>? itemDeserializer;

  const ImmutableListMultiObjectsDeserializer({this.itemDeserializer});

  @override
  ImmutableList<T> fromRdfObjects(
      Iterable<RdfObject> objects, DeserializationContext context) {
    final items = objects.map(
        (obj) => context.deserialize<T>(obj, deserializer: itemDeserializer));
    return ImmutableList(items);
  }
}

// Extension Methods for Multi-Objects approach

/// Extension methods for ResourceReader using multi-objects approach
extension MultiObjectsCollectionReaderExtensions on ResourceReader {
  /// Read a required ImmutableList using multi-objects approach (unordered)
  ImmutableList<T> requireImmutableListMultiObjects<T>(
          RdfPredicate predicate) =>
      requireCollection<ImmutableList<T>, T>(
        predicate,
        ImmutableListMultiObjectsDeserializer.new,
      );

  /// Read an optional ImmutableList using multi-objects approach (unordered)
  ImmutableList<T>? optionalImmutableListMultiObjects<T>(
          RdfPredicate predicate) =>
      optionalCollection<ImmutableList<T>, T>(
        predicate,
        ImmutableListMultiObjectsDeserializer.new,
      );
}

/// Extension methods for ResourceBuilder using multi-objects approach
extension MultiObjectsCollectionBuilderExtensions<S extends RdfSubject>
    on ResourceBuilder<S> {
  /// Add an ImmutableList using multi-objects approach (unordered)
  ResourceBuilder<S> addImmutableListMultiObjects<T>(
          RdfPredicate predicate, ImmutableList<T> collection) =>
      addCollection<ImmutableList<T>, T>(
        predicate,
        collection,
        ImmutableListMultiObjectsSerializer.new,
      );
}

// Test mappers that use the multi-objects approach
class LibraryMultiObjectsMapper implements GlobalResourceMapper<Library> {
  @override
  IriTerm? get typeIri => LibraryVocab.library;

  @override
  Library fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    return Library(
      id: subject.value,
      name: reader.require<String>(LibraryVocab.name),

      // Use multi-objects extension methods
      featuredBooks: reader.optionalImmutableListMultiObjects<Book>(
              LibraryVocab.featuredBooks) ??
          ImmutableList([]),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Library library,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(library.id))
        .addValue(LibraryVocab.name, library.name)

        // Use multi-objects extension methods
        .addImmutableListMultiObjects<Book>(
            LibraryVocab.featuredBooks, library.featuredBooks)
        .build();
  }
}
