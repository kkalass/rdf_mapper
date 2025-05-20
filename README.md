# RDF Mapper for Dart

[![pub package](https://img.shields.io/pub/v/rdf_mapper.svg)](https://pub.dev/packages/rdf_mapper)
[![build](https://github.com/kkalass/rdf_mapper/actions/workflows/ci.yml/badge.svg)](https://github.com/kkalass/rdf_mapper/actions)
[![codecov](https://codecov.io/gh/kkalass/rdf_mapper/branch/main/graph/badge.svg)](https://codecov.io/gh/kkalass/rdf_mapper)
[![license](https://img.shields.io/github/license/kkalass/rdf_mapper.svg)](https://github.com/kkalass/rdf_mapper/blob/main/LICENSE)

A powerful library for bidirectional mapping between Dart objects and RDF (Resource Description Framework), built on top of [`rdf_core`](https://pub.dev/packages/rdf_core).

## Overview

[🌐 **Official Homepage**](https://kkalass.github.io/rdf_mapper/)

`rdf_mapper` provides an elegant solution for transforming between Dart object models and RDF graphs, similar to an ORM for databases. This enables developers to work with semantic data in an object-oriented manner without manually managing the complexity of transforming between dart objects and RDF triples.

---

## Part of a whole family of projects

If you are looking for more rdf-related functionality, have a look at our companion projects:

* basic graph classes as well as turtle/jsonld/n-triple encoding and decoding: [rdf_core](https://github.com/kkalass/rdf_core) 
* encode and decode rdf/xml format: [rdf_xml](https://github.com/kkalass/rdf_xml) 
* easy-to-use constants for many well-known vocabularies: [rdf_vocabularies](https://github.com/kkalass/rdf_vocabularies)
* generate your own easy-to-use constants for other vocabularies with a build_runner: [rdf_vocabulary_to_dart](https://github.com/kkalass/rdf_vocabulary_to_dart)

---

## ✨ Key Features

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
  rdf_mapper: ^0.5.0
```

Or use the following command:

```bash
dart pub add rdf_mapper
```

## 🚀 Quick Start

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

final turtle = rdfMapper.encodeObject(person);
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
final person = rdfMapper.decodeObject<Person>(turtleInput);
print('Name: ${person.name}, Age: ${person.age}');
```

### Model and Mapper classes for above examples

```dart
import 'package:rdf_vocabularies/schema.dart';

// Define a model class.
// You can define them as you like, there is no requirement for immutability or such
class Person {
  final String id;
  final String name;
  final int age;
  
  Person({required this.id, required this.name, required this.age});
}

// Create a custom mapper
class PersonMapper implements GlobalResourceMapper<Person> {
  @override
  IriTerm? get typeIri => SchemaPerson.classIri;
  
  @override
  (IriTerm, List<Triple>) toRdfNode(Person value, SerializationContext context, {RdfSubject? parentSubject}) {

    // convert dart objects to triples using the fluent builder API
    return context.resourceBuilder(IriTerm(value.id))
      .literal(SchemaPerson.foafName, value.name)
      .literal(SchemaPerson.foafAge, value.age)
      .build();
  }
  
  @override
  Person fromRdfNode(IriTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    
    return Person(
      id: term.iri,
      name: reader.require<String>(SchemaPerson.foafName),
      age: reader.require<int>(SchemaPerson.foafAge),
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

- **Resource Mappers**: For complex objects with multiple properties
  - `GlobalResourceMapper`: For objects with globally unique identifiers
  - `LocalResourceMapper`: For anonymous objects or auxiliary structures

### Context Classes

- `SerializationContext`: Provides access to the ResourceBuilder
- `DeserializationContext`: Provides access to the ResourceReader

### Fluent APIs

- `ResourceBuilder`: For conveniently creating RDF nodes with a fluent API
- `ResourceReader`: For easily accessing RDF node properties

## Advanced Usage

### Working with Graphs

Working directly with RDF graphs (instead of strings):

```dart
// Graph-based serialization
final graph = rdfMapper.graph.encodeObject(person);

// Graph-based deserialization
final personFromGraph = rdfMapper.graph.decodeObject<Person>(graph);
```

### Deserializing Multiple Objects

```dart
// Deserialize all objects in a graph
final objects = rdfMapper.decodeObjects(turtleInput);

// Only objects of a specific type
final people = rdfMapper.decodeObjects<Person>(turtleInput);
```

### Temporary Mapper Registration

```dart
// Temporary mapper for a single operation
final result = rdfMapper.decodeObject<CustomType>(
  input, 
  register: (registry) {
    registry.registerMapper<CustomType>(CustomTypeMapper());
  },
);
```

### Namespace Helper Class

For clean management of IRIs in RDF, we have [rdf_vocabularies](https://kkalass.github.io/rdf_vocabularies/) which provides constants for the most common vocabularies. 

In addition, if you have your own vocabulary and would like such a helper class generated, you may use [rdf_vocabulary_to_dart](https://kkalass.github.io/rdf_vocabulary_to_dart/) which provides a build_runner for generating dart constants from rdf vocabulary files. It supports all serializations that rdf_core supports (turtle, jsonld, n-triple and also rdf/xml).

But you can also use our Namespace helper class which might be usefull during development

```dart

// Example usage:
final example = Namespace('http://example.com/my-new-vocab/');

// Usage:
builder.literal(example('name'), 'Alice');  // Generates http://example.com/my-new-vocab/name
```

### Complex Example

The following example demonstrates handling complex models with relationships between objects and nested structures:

```dart
import 'package:rdf_core/rdf_core.dart';

import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies/schema.dart';

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

  // Convert the book to RDF Turtle codec
  final turtle = rdf.encodeObject(book);

  // Print the resulting Turtle representation
  final expectedTurtle = '''
@prefix book: <http://example.org/book/> .
@prefix schema: <https://schema.org/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

book:hobbit a schema:Book;
    schema:aggregateRating 5;
    schema:author "J.R.R. Tolkien";
    schema:datePublished "1937-09-20T23:00:00.000Z"^^xsd:dateTime;
    schema:hasPart [ a schema:Chapter ; schema:name "An Unexpected Party" ; schema:position 1 ], [ a schema:Chapter ; schema:name "Roast Mutton" ; schema:position 2 ], [ a schema:Chapter ; schema:name "A Short Rest" ; schema:position 3 ];
    schema:isbn <urn:isbn:9780618260300>;
    schema:name "The Hobbit" .
  ''';

  print('Book as RDF Turtle:');
  print(turtle);
  assert(turtle.trim() == expectedTurtle.trim());
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
  final Iterable<Chapter> chapters;

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
class BookMapper implements GlobalResourceMapper<Book> {
  static final titlePredicate = SchemaBook.name;
  static final authorPredicate = SchemaBook.author;
  static final publishedPredicate = SchemaBook.datePublished;
  static final isbnPredicate = SchemaBook.isbn;
  static final ratingPredicate = SchemaBook.aggregateRating;
  static final chapterPredicate = SchemaBook.hasPart;

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
      chapters: reader.getValues<Chapter>(chapterPredicate),
    );
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    Book book,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(IriTerm(_createIriFromId(book.id)))
        .literal(titlePredicate, book.title)
        .literal(authorPredicate, book.author)
        .literal<DateTime>(publishedPredicate, book.published)
        .iri<ISBN>(isbnPredicate, book.isbn)
        .literal<Rating>(ratingPredicate, book.rating)
        .childNodes(chapterPredicate, book.chapters)
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
        .resourceBuilder(BlankNodeTerm())
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

## ⚠️ Error Handling

RDF Mapper provides specific exceptions to help diagnose mapping issues:

- `RdfMappingException`: Base exception for all mapping errors
- `SerializationException`: Errors during serialization
- `DeserializationException`: Errors during deserialization
- `SerializerNotFoundException`: When no serializer is registered for a type
- `DeserializerNotFoundException`: When no deserializer is registered for a type
- `PropertyValueNotFoundException`: When a required property is missing
- `TooManyPropertyValuesException`: When multiple values exist for a single-valued property

## 🚦 Performance Considerations

- RDF Mapper uses efficient traversal algorithms for both serialization and deserialization
- For large graphs, consider using the graph-based API instead of string serialization
- Consider implementing custom mappers for performance-critical types in your application

## 🛣️ Roadmap / Next Steps

- Detect cycles, optimally support them.
- Properly Support Collection (`rdf:first` / `rdf:rest` / `rdf:nil` pattern) for serialization and derserialization as dart List.
- Implement default behaviour for nodes without mapper ((Json-LD?) Maps)
- Support generating mappers based on annotations
- Support "any" feature and annotation which puts the remaining properties of a node into a (Json-LD?) Map that is a property of the dart class
- Support mapping to / from multiple RDF classes (e.g. schema:Person and foaf:Person)
- Improve test coverage

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!

- Fork the repo and submit a PR
- See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines
- Join the discussion in [GitHub Issues](https://github.com/kkalass/rdf_mapper/issues)

## 🤖 AI Policy

This project is proudly human-led and human-controlled, with all key decisions, design, and code reviews made by people. At the same time, it stands on the shoulders of LLM giants: generative AI tools are used throughout the development process to accelerate iteration, inspire new ideas, and improve documentation quality. We believe that combining human expertise with the best of AI leads to higher-quality, more innovative open source software.

---

© 2025 Klas Kalaß. Licensed under the MIT License.
