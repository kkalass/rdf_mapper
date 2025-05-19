import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies/schema.dart';
import 'rdf_annotations.dart';

/// This file demonstrates how the annotations can be used to mark up model classes
/// for automatic mapper generation.

// --- Annotated Model Classes ---

@RdfGlobalResource(SchemaBook.classIri, RdfIri('http://example.org/book/{id}'))
class Book {
  @RdfIriPart('id')
  final String id;

  @RdfProperty(SchemaBook.name)
  final String title;

  @RdfProperty(SchemaBook.author)
  final String author;

  @RdfProperty(SchemaBook.datePublished)
  final DateTime published;

  // The mode is automatically detected from the @RdfIri annotation on the ISBN class, we do not need to
  // know here that it is actually mapped to a IriTerm and not a LiteralTerm.
  @RdfProperty(SchemaBook.isbn)
  final ISBN isbn;

  // Note how we use an (annotated) custom class for the rating which essentially is an int.
  @RdfProperty(SchemaBook.aggregateRating)
  final Rating rating;

  // List type is automatically detected
  @RdfProperty(SchemaBook.hasPart)
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

@RdfLocalResource(SchemaChapter.classIri)
class Chapter {
  @RdfProperty(SchemaChapter.name)
  final String title;

  @RdfProperty(SchemaChapter.position)
  final int number;

  Chapter(this.title, this.number);
}

@RdfIri('urn:isbn:{value}')
class ISBN {
  @RdfIriPart() // marks this property as the value source
  final String value;

  ISBN(this.value);
}

@RdfLiteral()
class Rating {
  @RdfValue()
  final int stars;

  Rating(this.stars) {
    if (stars < 0 || stars > 5) {
      throw ArgumentError('Rating must be between 0 and 5 stars');
    }
  }
}

// --- The mappers below demonstrate what would be generated ---
// --- See below the main() function for an example of how to use them ---

/// This class would be auto-generated based on the Book class annotations.
class GeneratedBookMapper implements GlobalResourceMapper<Book> {
  @override
  final IriTerm typeIri = SchemaBook.classIri;

  // Generated based on RdfId.baseIriPrefix
  static const String _baseIriPrefix = 'http://example.org/book/';

  String _createIriFromId(String id) => '$_baseIriPrefix$id';

  String _extractIdFromIri(String iri) {
    if (!iri.startsWith(_baseIriPrefix)) {
      throw ArgumentError('Invalid Book IRI format: $iri');
    }
    return iri.substring(_baseIriPrefix.length);
  }

  @override
  Book fromRdfNode(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Book(
      // From @RdfId
      id: _extractIdFromIri(subject.iri),
      // From @RdfProperty, required by default
      title: reader.require<String>(SchemaBook.name),
      author: reader.require<String>(SchemaBook.author),
      published: reader.require<DateTime>(SchemaBook.datePublished),
      isbn: reader.require<ISBN>(SchemaBook.isbn),
      rating: reader.require<Rating>(SchemaBook.aggregateRating),
      // From @RdfProperty with mode = list
      chapters: reader.getList<Chapter>(SchemaBook.hasPart),
    );
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    Book book,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .nodeBuilder(IriTerm(_createIriFromId(book.id)))
        .literal(SchemaBook.name, book.title)
        .literal(SchemaBook.author, book.author)
        .literal<DateTime>(SchemaBook.datePublished, book.published)
        // Mode detected from @RdfIri annotation on ISBN class
        .iri<ISBN>(SchemaBook.isbn, book.isbn)
        // Mode detected from @RdfLiteral annotation on Rating class
        .literal<Rating>(SchemaBook.aggregateRating, book.rating)
        // Mode detected from property's List type
        .childNodeList(SchemaBook.hasPart, book.chapters)
        .build();
  }
}

/// This class would be auto-generated based on the Chapter class annotations.
class GeneratedChapterMapper implements LocalResourceMapper<Chapter> {
  @override
  final IriTerm typeIri = SchemaChapter.classIri;

  @override
  Chapter fromRdfNode(BlankNodeTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    return Chapter(
      reader.require<String>(SchemaChapter.name),
      reader.require<int>(SchemaChapter.position),
    );
  }

  @override
  (BlankNodeTerm, List<Triple>) toRdfNode(
    Chapter chapter,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .nodeBuilder(BlankNodeTerm())
        .literal(SchemaChapter.name, chapter.title)
        .literal<int>(SchemaChapter.position, chapter.number)
        .build();
  }
}

/// This class would be auto-generated based on the ISBN class annotations.
class GeneratedISBNMapper implements IriTermMapper<ISBN> {
  // From @RdfIri(iriPrefix: 'urn:isbn:')
  static const String _iriPrefix = 'urn:isbn:';

  @override
  IriTerm toRdfTerm(ISBN isbn, SerializationContext context) {
    // Using the value from @RdfValue annotated property
    // Note that we do this toLiteralTerm in reality only if isbn.value is not a
    // string.
    var term = context.toLiteralTerm(isbn.value);
    return IriTerm('$_iriPrefix${term.value}');
  }

  @override
  ISBN fromRdfTerm(IriTerm term, DeserializationContext context) {
    final uri = term.iri;
    if (!uri.startsWith(_iriPrefix)) {
      throw ArgumentError('Invalid ISBN URI format: $uri');
    }
    return ISBN(
      // this indirection is actually only done if the type is *not* a string
      context.fromLiteralTerm<String>(
        LiteralTerm(uri.substring(_iriPrefix.length)),
      ),
    );
  }
}

/// This class would be auto-generated based on the Rating class annotations.
class GeneratedRatingMapper implements LiteralTermMapper<Rating> {
  @override
  LiteralTerm toRdfTerm(Rating rating, SerializationContext context) {
    // Using the value from @RdfValue annotated property
    return context.toLiteralTerm(rating.stars);
  }

  @override
  Rating fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    return Rating(context.fromLiteralTerm<int>(term));
  }
}

// This would normally happen at build time via code generation
// Register all the generated mappers
RdfMapper initRdfMapper() {
  return RdfMapper.withDefaultRegistry()
    ..registerMapper<Book>(GeneratedBookMapper())
    ..registerMapper<Chapter>(GeneratedChapterMapper())
    ..registerMapper<ISBN>(GeneratedISBNMapper())
    ..registerMapper<Rating>(GeneratedRatingMapper());
}

// If the generated initRdfMapper() method has no required parameters,
// the mapper will automatically generate this global variable for convenience
final rdfMapper = initRdfMapper();

// --- The code below demonstrates how you work with the generated code ---

void main() {
  // Create a sample book
  final book = Book(
    id: 'hobbit',
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

  // Convert to RDF and print
  final turtle = rdfMapper.encodeObject(
    book,
    baseUri: 'http://example.org/book/',
  );
  print('Book as RDF Turtle:');
  print(turtle);

  // Deserialize back to a Book object
  final deserializedBook = rdfMapper.decodeObject<Book>(turtle);

  // Verify it worked correctly
  print('\nDeserialized book:');
  print('Title: ${deserializedBook.title}');
  print('Author: ${deserializedBook.author}');
  print('Chapters:');
  for (final chapter in deserializedBook.chapters) {
    print('- ${chapter.title} (${chapter.number})');
  }
}
