import 'package:rdf_core/rdf_core.dart';

import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_schema/schema.dart';
import 'package:rdf_vocabularies_core/xsd.dart';

void main() {
  final rdf =
      // Create mapper with default registry
      RdfMapper.withDefaultRegistry()
        // Register our custom mappers
        ..registerMapper<Book>(BookMapper())
        ..registerMapper<Chapter>(ChapterMapper())
        ..registerMapper<ISBN>(ISBNMapper())
        ..registerMapper<Rating>(RatingMapper());

  // Create a book with chapters
  final book = Book(
    id: 'hobbit', // Now just the identifier, not the full IRI
    title: 'The Hobbit',
    author: 'J.R.R. Tolkien',
    published: DateTime(1937, 9, 21),
    isbn: ISBN('9780618260300'),
    rating: Rating(5),
    chapters: [
      Chapter('An Unexpected Party', 1),
      Chapter('Roast Mutton', 2),
      Chapter('A Short Rest', 3),
    ],
    // UNORDERED: Multiple independent values (order doesn't matter)
    genres: ['fantasy', 'adventure', 'children'],
  );

  // --- PRIMARY API: String-based operations ---

  // Convert the book to RDF Turtle format
  final turtle = rdf.encodeObject(book, baseUri: 'http://example.org/book/');

  // Print the resulting Turtle representation

  print('Book as RDF Turtle:');
  print(turtle);

  // Deserialize back to a Book object
  final deserializedBook = rdf.decodeObject<Book>(turtle);

  // Verify it worked correctly
  print('\nDeserialized book:');
  print('Title: ${deserializedBook.title}');
  print('Author: ${deserializedBook.author}');
  print('ISBN: ${deserializedBook.isbn}');
  print('Rating: ${deserializedBook.rating}');
  print('Chapters:');
  for (final chapter in deserializedBook.chapters) {
    print('- ${chapter.title} (${chapter.number})');
  }
  print('Genres: ${deserializedBook.genres.join(', ')}');

  // Example with multiple books using deserializeAllOfType
  final multipleBooks = '''
@prefix schema: <https://schema.org/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<http://example.org/book/hobbit> a schema:Book;
    schema:name "The Hobbit";
    schema:author "J.R.R. Tolkien";
    schema:datePublished "1937-09-20T23:00:00.000Z"^^xsd:dateTime;
    schema:isbn <urn:isbn:9780618260300>;
    schema:genre "fantasy", "adventure", "children";
    schema:aggregateRating "5"^^xsd:integer .
    
<http://example.org/book/lotr> a schema:Book;
    schema:name "The Lord of the Rings";
    schema:author "J.R.R. Tolkien";
    schema:datePublished "1954-07-28T23:00:00.000Z"^^xsd:dateTime;
    schema:isbn <urn:isbn:9780618640157>;
    schema:aggregateRating "5"^^xsd:integer .
''';

  // Use the type-safe deserialization for collections
  final books = rdf.decodeObjects<Book>(multipleBooks);

  print('\nDeserialized multiple books:');
  print('Found ${books.length} books');
  for (final book in books) {
    print('- ${book.title} by ${book.author}');
  }

  // --- GRAPH API: Direct graph operations ---

  print('\n=== GRAPH API EXAMPLES ===');

  // Convert the book to an RDF graph
  final bookGraph = rdf.graph.encodeObject(book);
  print('Graph contains ${bookGraph.size} triples');

  // Deserialize from the graph
  final bookFromGraph = rdf.graph.decodeObject<Book>(bookGraph);
  print('Successfully deserialized book from graph: ${bookFromGraph.title}');

  // Create a combined graph with more data
  final anotherBook = Book(
    id: 'silmarillion', // Now just the identifier, not the full IRI
    title: 'The Silmarillion',
    author: 'J.R.R. Tolkien',
    published: DateTime(1977, 9, 15),
    isbn: ISBN('9780048231536'),
    rating: Rating(4),
    chapters: [Chapter('Ainulindalë', 1)],
    genres: ['mythology', 'high-fantasy'],
  );

  // Serialize multiple books to a single graph
  final booksGraph = rdf.graph.encodeObjects([book, anotherBook]);
  print('Combined graph contains ${booksGraph.size} triples');

  // Retrieve all books from the graph with type safety
  final booksFromGraph = rdf.graph.decodeObjects<Book>(booksGraph);
  print('Found ${booksFromGraph.length} books in the graph:');
  for (final book in booksFromGraph) {
    print('- ${book.title} (${book.published.year})');
  }
}

// --- Domain Model ---

// Primary entity with an identifier that will be part of the IRI
class Book {
  final String id;
  final String title;
  final String author;
  final DateTime published;
  final ISBN isbn;
  final Rating rating;
  // Note: since order of chapters matters, we map to rdf:List in the mapper below
  final List<Chapter> chapters;
  // Note: genres are multiple independent values, so we use addValues/getValues
  final List<String> genres;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.published,
    required this.isbn,
    required this.rating,
    required this.chapters,
    required this.genres,
  });
}

// Value object using blank nodes (no identifier)
class Chapter {
  final String title;
  final int number;

  Chapter(this.title, this.number);
}

// Custom identifier type using IRI mapping
class ISBN {
  final String value;

  ISBN(this.value);

  @override
  String toString() => value;
}

// Custom value type using literal mapping
class Rating {
  final int stars;

  Rating(this.stars) {
    if (stars < 0 || stars > 5) {
      throw ArgumentError('Rating must be between 0 and 5 stars');
    }
  }

  @override
  String toString() => '$stars stars';
}

// --- Mappers ---

// IRI-based entity mapper
class BookMapper implements GlobalResourceMapper<Book> {
  static final titlePredicate = SchemaBook.name;
  static final authorPredicate = SchemaBook.author;
  static final publishedPredicate = SchemaBook.datePublished;
  static final isbnPredicate = SchemaBook.isbn;
  static final ratingPredicate = SchemaBook.aggregateRating;
  static final chapterPredicate = SchemaBook.hasPart;
  static final genrePredicate = SchemaBook.genre;

  // Base IRI prefix for book resources
  static const String bookIriPrefix = 'http://example.org/book/';

  @override
  final IriTerm typeIri = SchemaBook.classIri;

  /// Converts an ID to a full IRI
  String _createIriFromId(String id) => '$bookIriPrefix$id';

  /// Extracts the identifier from a full IRI
  String _extractIdFromIri(String iri) {
    if (!iri.startsWith(bookIriPrefix)) {
      throw ArgumentError('Invalid Book IRI format: $iri');
    }
    return iri.substring(bookIriPrefix.length);
  }

  @override
  Book fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Book(
      // Extract just the identifier part from the IRI
      id: _extractIdFromIri(subject.value),
      title: reader.require<String>(titlePredicate),
      author: reader.require<String>(authorPredicate),
      published: reader.require<DateTime>(publishedPredicate),
      isbn: reader.require<ISBN>(isbnPredicate),
      rating: reader.require<Rating>(ratingPredicate),
      chapters: reader.optionalRdfList<Chapter>(chapterPredicate) ?? const [],
      genres: reader.getValues<String>(genrePredicate).toList(),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Book book,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(_createIriFromId(book.id)))
        .addValue(titlePredicate, book.title)
        .addValue(authorPredicate, book.author)
        .addValue<DateTime>(publishedPredicate, book.published)
        .addValue<ISBN>(isbnPredicate, book.isbn)
        .addValue<Rating>(ratingPredicate, book.rating)
        .when(
            book.chapters.isNotEmpty,
            (builder) => builder.addRdfList<Chapter>(
                  chapterPredicate,
                  book.chapters,
                ))
        // UNORDERED: Multiple independent values (no guaranteed order)
        .addValues<String>(genrePredicate, book.genres)
        .build();
  }
}

// Blank node-based entity mapper
class ChapterMapper implements LocalResourceMapper<Chapter> {
  static final titlePredicate = SchemaChapter.name;
  static final numberPredicate = SchemaChapter.position;

  @override
  final IriTerm typeIri = SchemaChapter.classIri;

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
    SerializationContext ctxt, {
    RdfSubject? parentSubject,
  }) {
    return ctxt
        .resourceBuilder(BlankNodeTerm())
        .addValue(titlePredicate, chapter.title)
        .addValue<int>(numberPredicate, chapter.number)
        .build();
  }
}

// Custom IRI mapper
class ISBNMapper implements IriTermMapper<ISBN> {
  static const String ISBN_URI_PREFIX = 'urn:isbn:';

  @override
  IriTerm toRdfTerm(ISBN isbn, SerializationContext context) {
    return context.createIriTerm('$ISBN_URI_PREFIX${isbn.value}');
  }

  @override
  ISBN fromRdfTerm(IriTerm term, DeserializationContext context) {
    final uri = term.value;
    if (!uri.startsWith(ISBN_URI_PREFIX)) {
      throw ArgumentError('Invalid ISBN URI format: $uri');
    }
    return ISBN(uri.substring(ISBN_URI_PREFIX.length));
  }
}

// Custom literal mapper
class RatingMapper implements LiteralTermMapper<Rating> {
  final IriTerm datatype = Xsd.integer;
  const RatingMapper();

  @override
  LiteralTerm toRdfTerm(Rating rating, SerializationContext context) {
    return LiteralTerm.typed(rating.stars.toString(), 'integer');
  }

  @override
  Rating fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    return Rating(int.parse(term.value));
  }
}
