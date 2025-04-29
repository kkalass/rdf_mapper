import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/api/mapper.dart';

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
  );

  // --- PRIMARY API: String-based operations ---

  // Convert the book to RDF Turtle format
  final turtle = rdf.serialize(book);

  // Print the resulting Turtle representation
  final expectedTurtle = '''
@prefix schema: <https://schema.org/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<http://example.org/book/hobbit> a schema:Book;
    schema:name "The Hobbit";
    schema:author "J.R.R. Tolkien";
    schema:datePublished "1937-09-20T23:00:00.000Z"^^xsd:dateTime;
    schema:isbn <urn:isbn:9780618260300>;
    schema:aggregateRating "5"^^xsd:integer;
    schema:hasPart _:b0, _:b1, _:b2 .
_:b0 a schema:Chapter;
    schema:name "An Unexpected Party";
    schema:position "1"^^xsd:integer .
_:b1 a schema:Chapter;
    schema:name "Roast Mutton";
    schema:position "2"^^xsd:integer .
_:b2 a schema:Chapter;
    schema:name "A Short Rest";
    schema:position "3"^^xsd:integer .
''';

  print('Book as RDF Turtle:');
  print(turtle);
  assert(turtle == expectedTurtle);

  // Deserialize back to a Book object
  final deserializedBook = rdf.deserialize<Book>(turtle);

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

  // Example with multiple books using deserializeAllOfType
  final multipleBooks = '''
@prefix schema: <https://schema.org/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<http://example.org/book/hobbit> a schema:Book;
    schema:name "The Hobbit";
    schema:author "J.R.R. Tolkien";
    schema:datePublished "1937-09-20T23:00:00.000Z"^^xsd:dateTime;
    schema:isbn <urn:isbn:9780618260300>;
    schema:aggregateRating "5"^^xsd:integer .
    
<http://example.org/book/lotr> a schema:Book;
    schema:name "The Lord of the Rings";
    schema:author "J.R.R. Tolkien";
    schema:datePublished "1954-07-28T23:00:00.000Z"^^xsd:dateTime;
    schema:isbn <urn:isbn:9780618640157>;
    schema:aggregateRating "5"^^xsd:integer .
''';

  // Use the type-safe deserialization for collections
  final books = rdf.deserializeAllOfType<Book>(multipleBooks);

  print('\nDeserialized multiple books:');
  print('Found ${books.length} books');
  for (final book in books) {
    print('- ${book.title} by ${book.author}');
  }

  // --- GRAPH API: Direct graph operations ---

  print('\n=== GRAPH API EXAMPLES ===');

  // Convert the book to an RDF graph
  final bookGraph = rdf.graph.serialize(book);
  print('Graph contains ${bookGraph.size} triples');

  // Deserialize from the graph
  final bookFromGraph = rdf.graph.deserialize<Book>(bookGraph);
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
  );

  // Serialize multiple books to a single graph
  final booksGraph = rdf.graph.serialize([book, anotherBook]);
  print('Combined graph contains ${booksGraph.size} triples');

  // Retrieve all books from the graph with type safety
  final booksFromGraph = rdf.graph.deserializeAllOfType<Book>(booksGraph);
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
  final List<Chapter> chapters;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.published,
    required this.isbn,
    required this.rating,
    required this.chapters,
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
class BookMapper implements IriNodeMapper<Book> {
  static final titlePredicate = SchemaProperties.name;
  static final authorPredicate = SchemaProperties.author;
  static final publishedPredicate = SchemaProperties.datePublished;
  static final isbnPredicate = IriTerm('https://schema.org/isbn');
  static final ratingPredicate = IriTerm('https://schema.org/aggregateRating');
  static final chapterPredicate = IriTerm('https://schema.org/hasPart');

  // Base IRI prefix for book resources
  static const String bookIriPrefix = 'http://example.org/book/';

  @override
  final IriTerm typeIri = IriTerm('https://schema.org/Book');

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
  Book fromRdfNode(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Book(
      // Extract just the identifier part from the IRI
      id: _extractIdFromIri(subject.iri),
      title: reader.require<String>(titlePredicate),
      author: reader.require<String>(authorPredicate),
      published: reader.require<DateTime>(publishedPredicate),
      isbn: reader.require<ISBN>(isbnPredicate),
      rating: reader.require<Rating>(ratingPredicate),
      chapters: reader.getList<Chapter>(chapterPredicate),
    );
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    Book book,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) =>
      // Create full IRI from the identifier
      context
          .nodeBuilder(IriTerm(_createIriFromId(book.id)))
          .literal(titlePredicate, book.title)
          .literal(authorPredicate, book.author)
          .literal<DateTime>(publishedPredicate, book.published)
          .iri<ISBN>(isbnPredicate, book.isbn)
          .literal<Rating>(ratingPredicate, book.rating)
          .childNodeList(chapterPredicate, book.chapters)
          .build();
}

// Blank node-based entity mapper
class ChapterMapper implements BlankNodeMapper<Chapter> {
  static final titlePredicate = IriTerm('https://schema.org/name');
  static final numberPredicate = IriTerm('https://schema.org/position');

  @override
  final IriTerm typeIri = IriTerm('https://schema.org/Chapter');

  @override
  Chapter fromRdfNode(BlankNodeTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    return Chapter(
      reader.require<String>(titlePredicate),
      reader.require<int>(numberPredicate),
    );
  }

  @override
  (BlankNodeTerm, List<Triple>) toRdfNode(
    Chapter chapter,
    SerializationContext ctxt, {
    RdfSubject? parentSubject,
  }) {
    return ctxt
        .nodeBuilder(BlankNodeTerm())
        .literal(titlePredicate, chapter.title)
        .literal<int>(numberPredicate, chapter.number)
        .build();
  }
}

// Custom IRI mapper
class ISBNMapper implements IriTermMapper<ISBN> {
  static const String ISBN_URI_PREFIX = 'urn:isbn:';

  @override
  IriTerm toRdfTerm(ISBN isbn, SerializationContext context) {
    return IriTerm('$ISBN_URI_PREFIX${isbn.value}');
  }

  @override
  ISBN fromRdfTerm(IriTerm term, DeserializationContext context) {
    final uri = term.iri;
    if (!uri.startsWith(ISBN_URI_PREFIX)) {
      throw ArgumentError('Invalid ISBN URI format: $uri');
    }
    return ISBN(uri.substring(ISBN_URI_PREFIX.length));
  }
}

// Custom literal mapper
class RatingMapper implements LiteralTermMapper<Rating> {
  @override
  LiteralTerm toRdfTerm(Rating rating, SerializationContext context) {
    return LiteralTerm.typed(rating.stars.toString(), 'integer');
  }

  @override
  Rating fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    return Rating(int.parse(term.value));
  }
}
