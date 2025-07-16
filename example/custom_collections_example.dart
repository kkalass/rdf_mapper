import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Example demonstrating custom collection types with different RDF approaches.
///
/// This example shows how to:
/// - Create custom collection types (ImmutableList)
/// - Use RDF Lists for ordered collections (rdf:first/rdf:rest structure)
/// - Use Multi-Objects for unordered collections (multiple triples with same predicate)
/// - Add convenient extension methods to ResourceBuilder and ResourceReader
/// - Choose the right approach based on your needs
void main() {
  final rdf = RdfMapper.withDefaultRegistry()
    ..registerMapper<Library>(LibraryMapper())
    ..registerMapper<Book>(BookMapper())
    ..registerMapper<Tag>(TagMapper());

  // Create a library with custom collection types
  final library = Library(
    id: 'https://example.org/libraries/main',
    name: 'Main Library',

    // ImmutableList: Ordered, immutable collection using RDF Lists
    featuredBooks: ImmutableList([
      Book('The Art of Computer Programming'),
      Book('Design Patterns'),
      Book('Clean Code'),
    ]),
  );

  print('=== Original Library ===');
  print('Name: ${library.name}');
  print(
      'Featured Books (ImmutableList): ${library.featuredBooks.map((b) => b.title).join(', ')}');
  print('');

  // Serialize to RDF using RDF Lists (ordered, structured)
  final turtle = rdf.encodeObject(library);
  print('=== Serialized Library (RDF Lists Approach) ===');
  print(turtle);
  print('');

  // Deserialize back
  final deserializedLibrary = rdf.decodeObject<Library>(turtle);

  print('=== Deserialized Library ===');
  print('Name: ${deserializedLibrary.name}');
  print(
      'Featured Books (ImmutableList): ${deserializedLibrary.featuredBooks.map((b) => b.title).join(', ')}');
  print('');

  // Verify roundtrip consistency
  assert(deserializedLibrary.name == library.name);
  assert(
      deserializedLibrary.featuredBooks.length == library.featuredBooks.length);

  // Verify ImmutableList order is preserved with RDF Lists
  for (int i = 0; i < library.featuredBooks.length; i++) {
    assert(deserializedLibrary.featuredBooks[i].title ==
        library.featuredBooks[i].title);
  }

  print('✅ RDF Lists approach: Order preserved, assertions passed!');

  // Now demonstrate Multi-Objects approach
  print('');
  print('=== Multi-Objects Approach Comparison ===');

  // Create mapper with multi-objects approach for comparison
  final rdfMultiObjects = RdfMapper.withDefaultRegistry()
    ..registerMapper<Library>(LibraryMultiObjectsMapper())
    ..registerMapper<Book>(BookMapper())
    ..registerMapper<Tag>(TagMapper());

  final libraryMultiObjects = Library(
    id: 'https://example.org/libraries/multi',
    name: 'Multi-Objects Library',
    featuredBooks: library.featuredBooks, // Same data
  );

  final turtleMultiObjects = rdfMultiObjects.encodeObject(libraryMultiObjects);
  print('=== Serialized Library (Multi-Objects Approach) ===');
  print(turtleMultiObjects);
  print('');

  final deserializedMultiObjects =
      rdfMultiObjects.decodeObject<Library>(turtleMultiObjects);
  print('=== Deserialized Multi-Objects Library ===');
  print('Name: ${deserializedMultiObjects.name}');
  print(
      'Featured Books: ${deserializedMultiObjects.featuredBooks.map((b) => b.title).join(', ')}');
  print('');

  print('✅ Multi-Objects approach: Flat structure, efficient queries!');
  print('');

  // Demonstrate type safety
  print('=== Type Safety & Flexibility ===');
  print(
      'Both approaches use the same ImmutableList type: ${library.featuredBooks.runtimeType}');
  print(
      'You can choose RDF representation independently of Dart collection type!');
}

// Custom Collection Types

/// Immutable list wrapper that preserves order and prevents modification
class ImmutableList<T> {
  final List<T> _items;

  ImmutableList(Iterable<T> items) : _items = List.unmodifiable(items);

  int get length => _items.length;

  T operator [](int index) => _items[index];

  Iterable<R> map<R>(R Function(T) transform) => _items.map(transform);

  @override
  String toString() => 'ImmutableList($_items)';
}

// Collection Serializers/Deserializers

/// Serializer for ImmutableList using RDF list structure (preserves order)
class ImmutableListSerializer<T>
    extends BaseRdfListSerializer<ImmutableList<T>, T> {
  const ImmutableListSerializer(super.itemSerializer);

  @override
  (RdfSubject, List<Triple>) toRdfResource(
      ImmutableList<T> collection, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final (subject, triples) =
        buildRdfList(collection._items, context, parentSubject: parentSubject);
    return (subject, triples.toList());
  }
}

/// Deserializer for ImmutableList from RDF list structure (preserves order)
class ImmutableListDeserializer<T>
    extends BaseRdfListDeserializer<ImmutableList<T>, T> {
  const ImmutableListDeserializer(super.itemDeserializer);

  @override
  ImmutableList<T> fromRdfResource(
      RdfSubject subject, DeserializationContext context) {
    final items = readRdfList(subject, context);
    return ImmutableList(items);
  }
}

/// Serializer for ImmutableList using multi-objects approach (flat structure)
class ImmutableListMultiObjectsSerializer<T>
    implements MultiObjectsSerializer<ImmutableList<T>> {
  final Serializer<T>? itemSerializer;
  const ImmutableListMultiObjectsSerializer(this.itemSerializer);

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
      ImmutableList<T> values, SerializationContext context) {
    final triples = <Triple>[];
    final objects = <RdfObject>[];
    for (var i = 0; i < values.length; i++) {
      final item = values[i];
      final (terms, itemTriples) =
          context.serialize<T>(item, serializer: itemSerializer);
      triples.addAll(itemTriples);
      objects.addAll(terms.cast<RdfObject>());
    }
    return (objects, triples);
  }
}

/// Deserializer for ImmutableList from RDF list structure (preserves order)
class ImmutableListMultiObjectsDeserializer<T>
    implements MultiObjectsDeserializer<ImmutableList<T>> {
  final Deserializer<T>? itemDeserializer;

  const ImmutableListMultiObjectsDeserializer(this.itemDeserializer);

  @override
  ImmutableList<T> fromRdfObjects(
      Iterable<RdfObject> objects, DeserializationContext context) {
    final items = objects
        .map((o) => context.deserialize<T>(o, deserializer: itemDeserializer))
        .toList();
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

  /// Read a required ImmutableList (flat, immutable)
  ImmutableList<T> requireImmutableListMultiObjects<T>(
          RdfPredicate predicate) =>
      requireCollection<ImmutableList<T>, T>(
        predicate,
        ImmutableListMultiObjectsDeserializer.new,
      );

  /// Read an optional ImmutableList (flat, immutable)
  ImmutableList<T>? optionalImmutableListMultiObjects<T>(
          RdfPredicate predicate) =>
      optionalCollection<ImmutableList<T>, T>(
        predicate,
        ImmutableListMultiObjectsDeserializer.new,
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
        (itemSerializer) => ImmutableListSerializer<T>(itemSerializer),
      );

  /// Add an ImmutableList (flat, unordered)
  ResourceBuilder<S> addImmutableListMultiObjects<T>(
          RdfPredicate predicate, ImmutableList<T> collection) =>
      addCollection<ImmutableList<T>, T>(
        predicate,
        collection,
        (itemSerializer) =>
            ImmutableListMultiObjectsSerializer<T>(itemSerializer),
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
}

class Book {
  final String title;

  Book(this.title);
}

class Tag {
  final String name;

  Tag(this.name);
}

// Vocabulary
class LibraryVocab {
  static const String _ns = 'https://example.org/library/';

  // Types
  static final library = IriTerm('${_ns}Library');
  static final book = IriTerm('${_ns}Book');
  static final tag = IriTerm('${_ns}Tag');

  // Properties
  static final name = IriTerm('${_ns}name');
  static final title = IriTerm('${_ns}title');
  static final featuredBooks = IriTerm('${_ns}featuredBooks');
  static final categories = IriTerm('${_ns}categories');
}

// Mappers

class LibraryMapper implements GlobalResourceMapper<Library> {
  @override
  IriTerm? get typeIri => LibraryVocab.library;

  @override
  Library fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    return Library(
      id: subject.iri,
      name: reader.require<String>(LibraryVocab.name),

      // Use our custom extension methods - as convenient as built-in methods!
      // ImmutableList: uses rdf:first/rdf:rest structure
      featuredBooks:
          reader.optionalImmutableList<Book>(LibraryVocab.featuredBooks) ??
              ImmutableList([]),
    );
  }

  @override
  (IriTerm, List<Triple>) toRdfResource(
    Library library,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(IriTerm(library.id))
        .addValue(LibraryVocab.name, library.name)

        // Use our custom extension methods - as convenient as built-in methods!
        // ImmutableList: uses rdf:first/rdf:rest structure
        .addImmutableList<Book>(
            LibraryVocab.featuredBooks, library.featuredBooks)
        .build();
  }
}

// Alternative mapper using Multi-Objects approach (flat structure)
class LibraryMultiObjectsMapper implements GlobalResourceMapper<Library> {
  @override
  IriTerm? get typeIri => LibraryVocab.library;

  @override
  Library fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    return Library(
      id: subject.iri,
      name: reader.require<String>(LibraryVocab.name),

      // Use our custom extension methods - as convenient as built-in methods!
      // Multi-objects approach: one triple per book
      // This reads a flat structure with multiple triples for the same predicate
      featuredBooks: reader.optionalImmutableListMultiObjects<Book>(
              LibraryVocab.featuredBooks) ??
          ImmutableList([]),
    );
  }

  @override
  (IriTerm, List<Triple>) toRdfResource(
    Library library,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(IriTerm(library.id))
        .addValue(LibraryVocab.name, library.name)

        // Use our custom extension methods - as convenient as built-in methods!
        // Multi-objects approach: creates one triple per book (plus of course the triples that define the book resources)
        .addImmutableListMultiObjects<Book>(
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
  (BlankNodeTerm, List<Triple>) toRdfResource(
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
  (BlankNodeTerm, List<Triple>) toRdfResource(
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
