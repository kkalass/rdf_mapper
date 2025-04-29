# RDF Mapper for Dart

[![Dart](https://img.shields.io/badge/Dart-2.17%2B-blue.svg)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![pub package](https://img.shields.io/pub/v/rdf_mapper.svg)](https://pub.dev/packages/rdf_mapper)
[![codecov](https://codecov.io/gh/yourorg/rdf_mapper/branch/main/graph/badge.svg)](https://codecov.io/gh/yourorg/rdf_mapper)

A powerful library for bidirectional mapping between Dart objects and RDF (Resource Description Framework), built on top of [`rdf_core`](https://pub.dev/packages/rdf_core).

## Overview

`rdf_mapper` provides an elegant solution for transforming between Dart object models and RDF graphs, similar to an ORM for databases. This enables developers to work with semantic data in an object-oriented manner without manually managing the complexity of RDF serialization and deserialization.

### Key Features

- **Bidirectional Mapping**: Seamless conversion between Dart objects and RDF representations
- **Type-Safe**: Fully typed API for safe RDF mapping operations
- **Extensible**: Easy creation of custom mappers for domain-specific types
- **Flexible**: Support for all core RDF concepts: IRI nodes, blank nodes, and literals
- **Dual API**: Work with RDF strings or directly with graph structures

## What is RDF?

Resource Description Framework (RDF) is a standard model for data interchange on the Web. It extends the linking structure of the Web by using URIs to name relationships between things as well as the two ends of the link.

RDF is built around statements known as "triples" in the form of subject-predicate-object:

- **Subject**: The resource being described (identified by an IRI or blank node)
- **Predicate**: The property or relationship (always an IRI)
- **Object**: The value or related resource (an IRI, blank node, or literal value)

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  rdf_mapper: ^0.1.0
```

Or use the following command:

```bash
dart pub add rdf_mapper
```

## Quick Start

### Basic Setup

```dart
import 'package:rdf_mapper/rdf_mapper.dart';

// Create a mapper instance with default registry
final rdfMapper = RdfMapper.withDefaultRegistry();
```

### Serialization

```dart
// Register the mapper
rdfMapper.registerMapper<Person>(PersonMapper());

// Serialize an object
final person = Person(
  id: 'http://example.org/person/1',
  name: 'John Smith',
  age: 30,
);

final turtle = rdfMapper.serialize(person);
print(turtle);
```

### Deserialization

```dart
// RDF Turtle input
final turtleInput = '''
@prefix foaf: <http://xmlns.com/foaf/0.1/> .

<http://example.org/person/1> a foaf:Person ;
  foaf:name "John Smith" ;
  foaf:age 30 .
''';

// Deserialize an object
final person = rdfMapper.deserialize<Person>(turtleInput);
print('Name: ${person.name}, Age: ${person.age}');
```

### Model and Mapper classes for above examples

```dart
// Define a model class.
// You can define them as you like, there is no requirement for immutability or such
class Person {
  final String id;
  final String name;
  final int age;
  
  Person({required this.id, required this.name, required this.age});
}

// Create a custom mapper
class PersonMapper implements IriNodeMapper<Person> {
  @override
  IriTerm? get typeIri => IriTerm('http://xmlns.com/foaf/0.1/Person');
  
  @override
  (IriTerm, List<Triple>) toRdfNode(Person value, SerializationContext context, {RdfSubject? parentSubject}) {

    // convert dart objects to triples using the fluent builder API
    return context.nodeBuilder(IriTerm(value.id))
      .literal(IriTerm('http://xmlns.com/foaf/0.1/name'), value.name)
      .literal(IriTerm('http://xmlns.com/foaf/0.1/age'), value.age)
      .build();
  }
  
  @override
  Person fromRdfNode(IriTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    
    return Person(
      id: term.iri,
      name: reader.require<String>(IriTerm('http://xmlns.com/foaf/0.1/name')),
      age: reader.require<int>(IriTerm('http://xmlns.com/foaf/0.1/age')),
    );
  }
}
```

## Architecture

The library is built around several core concepts:

### Mapper Hierarchy

- **Term Mappers**: For simple values (IRI terms or literals)
  - `IriTermMapper`: For IRIs (e.g., URIs, URLs)
  - `LiteralTermMapper`: For literal values (strings, numbers, dates)

- **Node Mappers**: For complex objects with multiple properties
  - `IriNodeMapper`: For objects with globally unique identifiers
  - `BlankNodeMapper`: For anonymous objects or auxiliary structures

### Context Classes

- `SerializationContext`: Provides access to the NodeBuilder
- `DeserializationContext`: Provides access to the NodeReader

### Fluent APIs

- `NodeBuilder`: For conveniently creating RDF nodes with a fluent API
- `NodeReader`: For easily accessing RDF node properties

## Advanced Usage

### Working with Graphs

Working directly with RDF graphs (instead of strings):

```dart
// Graph-based serialization
final graph = rdfMapper.graph.serialize(person);

// Graph-based deserialization
final personFromGraph = rdfMapper.graph.deserialize<Person>(graph);
```

### Deserializing Multiple Objects

```dart
// Deserialize all objects in a graph
final objects = rdfMapper.deserializeAll(turtleInput);

// Only objects of a specific type
final people = rdfMapper.deserializeAllOfType<Person>(turtleInput);
```

### Temporary Mapper Registration

```dart
// Temporary mapper for a single operation
final result = rdfMapper.deserialize<CustomType>(
  input, 
  register: (registry) {
    registry.registerMapper<CustomType>(CustomTypeMapper());
  },
);
```

### Namespace Helper Class

For clean management of IRIs in RDF, you can use [vocab.dart from rdf_core](https://kkalass.github.io/rdf_core/api/vocab/) which
provides constants for the most common predicates of the most common vocabularies.

But you can also use our Namespace helper class which is more flexible but less discoverable:

```dart

// Example usage:
final foaf = Namespace('http://xmlns.com/foaf/0.1/');
final schema = Namespace('http://schema.org/');

// Usage:
builder.literal(foaf('name'), 'Alice');  // Generates http://xmlns.com/foaf/0.1/name
```

## Complex Example

The following example demonstrates handling complex models with relationships between objects and nested structures:

```dart
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
  }) {
    return context
        .nodeBuilder(IriTerm(_createIriFromId(book.id)))
        .literal(titlePredicate, book.title)
        .literal(authorPredicate, book.author)
        .literal<DateTime>(publishedPredicate, book.published)
        .iri<ISBN>(isbnPredicate, book.isbn)
        .literal<Rating>(ratingPredicate, book.rating)
        .childNodeList(chapterPredicate, book.chapters)
        .build();
  }
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
  static const String isbnUriPrefix = 'urn:isbn:';

  @override
  IriTerm toRdfTerm(ISBN isbn, SerializationContext context) {
    return IriTerm('$isbnUriPrefix${isbn.value}');
  }

  @override
  ISBN fromRdfTerm(IriTerm term, DeserializationContext context) {
    final uri = term.iri;
    if (!uri.startsWith(isbnUriPrefix)) {
      throw ArgumentError('Invalid ISBN URI format: $uri');
    }
    return ISBN(uri.substring(isbnUriPrefix.length));
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
```



## Supported RDF Types

The library includes built-in mappers for common Dart types:

| Dart Type | RDF Datatype |
|-----------|--------------|
| `String` | xsd:string |
| `int` | xsd:integer |
| `double` | xsd:decimal |
| `bool` | xsd:boolean |
| `DateTime` | xsd:dateTime |
| `Uri` | IRI |

## Error Handling

RDF Mapper provides specific exceptions to help diagnose mapping issues:

- `RdfMappingException`: Base exception for all mapping errors
- `SerializationException`: Errors during serialization
- `DeserializationException`: Errors during deserialization
- `SerializerNotFoundException`: When no serializer is registered for a type
- `DeserializerNotFoundException`: When no deserializer is registered for a type
- `PropertyValueNotFoundException`: When a required property is missing
- `TooManyPropertyValuesException`: When multiple values exist for a single-valued property

## Performance Considerations

- RDF Mapper uses efficient traversal algorithms for both serialization and deserialization
- For large graphs, consider using the graph-based API instead of string serialization
- Consider implementing custom mappers for performance-critical types in your application

## Contributing

Contributions are welcome! Please read the [contributing guidelines](CONTRIBUTING.md) for more information.

## License

This project is licensed under the [MIT License](LICENSE).
