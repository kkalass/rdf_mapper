import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Example demonstrating custom collection types with extension methods.
///
/// This example shows how to:
/// - Create custom collection types (ImmutableList)
/// - Implement collection serializers/deserializers for them
/// - Add convenient extension methods to ResourceBuilder and ResourceReader
/// - Use the custom collections as easily as built-in RDF lists
void main() {
  final rdf = RdfMapper.withDefaultRegistry()
    ..registerMapper<Library>(LibraryMapper())
    ..registerMapper<Book>(BookMapper())
    ..registerMapper<Tag>(TagMapper());

  // Create a library with custom collection types
  final library = Library(
    id: 'https://example.org/libraries/main',
    name: 'Main Library',

    // ImmutableList: Ordered, immutable collection of featured books
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

  // Serialize to RDF
  final turtle = rdf.encodeObject(library);
  print('=== Serialized Library ===');
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

  // Verify ImmutableList order is preserved
  for (int i = 0; i < library.featuredBooks.length; i++) {
    assert(deserializedLibrary.featuredBooks[i].title ==
        library.featuredBooks[i].title);
  }

  print('✅ All assertions passed - custom collection types work perfectly!');

  // Demonstrate type safety
  print('');
  print('=== Type Safety Demonstration ===');
  print('ImmutableList is immutable: ${library.featuredBooks.runtimeType}');
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
        (itemSerializer) => ImmutableListSerializer<T>(itemSerializer),
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
