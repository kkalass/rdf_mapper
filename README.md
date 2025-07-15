# RDF Mapper for Dart

[![pub package](https://img.shields.io/pub/v/rdf_mapper.svg)](https://pub.dev/packages/rdf_mapper)
[![build](https://github.com/kkalass/rdf_mapper/actions/workflows/ci.yml/badge.svg)](https://github.com/kkalass/rdf_mapper/actions)
[![codecov](https://codecov.io/gh/kkalass/rdf_mapper/branch/main/graph/badge.svg)](https://codecov.io/gh/kkalass/rdf_mapper)
[![license](https://img.shields.io/github/license/kkalass/rdf_mapper.svg)](https://github.com/kkalass/rdf_mapper/blob/main/LICENSE)

A powerful library for bidirectional mapping between Dart objects and RDF (Resource Description Framework), built on top of [`rdf_core`](https://pub.dev/packages/rdf_core).

## Overview

[🌐 **Official Homepage**](https://kkalass.github.io/rdf_mapper/)

`rdf_mapper` provides an elegant solution for transforming between Dart object models and RDF graphs, similar to an ORM for databases. This enables developers to work with semantic data in an object-oriented manner without manually managing the complexity of transforming between dart objects and RDF triples.

> **🎯 New: Code Generation Available!**  
> For the ultimate developer experience, use our **annotation-driven code generation** with [`rdf_mapper_annotations`](https://pub.dev/packages/rdf_mapper_annotations) and [`rdf_mapper_generator`](https://pub.dev/packages/rdf_mapper_generator). Simply annotate your classes, run `dart run build_runner build`, and get type-safe, zero-boilerplate RDF mappers automatically generated!

---

## Part of a whole family of projects

If you are looking for more rdf-related functionality, have a look at our companion projects:

* **Easy code generation**: [rdf_mapper_annotations](https://github.com/kkalass/rdf_mapper_annotations) + [rdf_mapper_generator](https://github.com/kkalass/rdf_mapper_generator) - Generate type-safe mappers with zero boilerplate using annotations
* basic graph classes as well as turtle/jsonld/n-triple encoding and decoding: [rdf_core](https://github.com/kkalass/rdf_core) 
* encode and decode rdf/xml format: [rdf_xml](https://github.com/kkalass/rdf_xml) 
* easy-to-use constants for many well-known vocabularies: [rdf_vocabularies](https://github.com/kkalass/rdf_vocabularies)
* generate your own easy-to-use constants for other vocabularies with a build_runner: [rdf_vocabulary_to_dart](https://github.com/kkalass/rdf_vocabulary_to_dart)

---

## ✨ Key Features

- **Bidirectional Mapping**: Seamless conversion between Dart objects and RDF representations
- **Type-Safe**: Fully typed API for safe RDF mapping operations
- **Code Generation**: Zero-boilerplate mapping with [`rdf_mapper_generator`](https://pub.dev/packages/rdf_mapper_generator) - annotate your classes and get optimized mappers automatically
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
  rdf_mapper: ^0.8.8
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
  (IriTerm, List<Triple>) toRdfResource(Person value, SerializationContext context, {RdfSubject? parentSubject}) {

    // convert dart objects to triples using the fluent builder API
    return context.resourceBuilder(IriTerm(value.id))
      .addValue(SchemaPerson.foafName, value.name)
      .addValue(SchemaPerson.foafAge, value.age)
      .build();
  }
  
  @override
  Person fromRdfResource(IriTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    
    return Person(
      id: term.iri,
      name: reader.require<String>(SchemaPerson.foafName),
      age: reader.require<int>(SchemaPerson.foafAge),
    );
  }
}
```

## 🔥 Zero-Boilerplate Code Generation

**Want to eliminate all that mapper boilerplate?** Use our code generation approach for the ultimate developer experience:

### 1. Add dependencies:

```sh
dart pub add rdf_mapper rdf_mapper_annotations
dart pub add rdf_mapper_generator build_runner --dev
```

### 2. Annotate your classes:

```dart
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies/schema.dart';

@RdfGlobalResource(
  SchemaPerson.classIri,
  IriStrategy('http://example.org/person/{id}'),
)
class Person {
  @RdfIriPart('id')
  final String id;

  @RdfProperty(SchemaPerson.foafName)
  final String name;

  @RdfProperty(SchemaPerson.foafAge)
  final int age;

  Person({required this.id, required this.name, required this.age});
}
```

### 3. Generate mappers:

```bash
dart run build_runner build
```

### 4. Use your generated mappers:

```dart
// Initialize the mapper system (auto-generated)
final mapper = initRdfMapper();

// Use exactly like the manual approach - same API!
final person = Person(id: '1', name: 'John Smith', age: 30);
final turtle = mapper.encodeObject(person);
final deserializedPerson = mapper.decodeObject<Person>(turtle);
```

**That's it!** No manual mapping code, no runtime reflection, just pure generated performance.

**Key Benefits:**
- 🔥 **Zero boilerplate** - Write business logic, not serialization code
- 🛡️ **Type safety** - Compile-time guarantees for your RDF mappings
- ⚡ **Performance** - Generated code with no runtime overhead
- 🎯 **Schema.org support** - Works seamlessly with rdf_vocabularies
- 🔧 **Flexible mapping** - Custom mappers, IRI templates, complex relationships

Learn more: [rdf_mapper_generator documentation](https://kkalass.github.io/rdf_mapper_generator/)

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

**ResourceBuilder** provides methods for creating RDF resources:
- `addValue<T>(predicate, value)` - Add a single property value
- `addRdfList<T>(predicate, list)` - Add an ordered list using RDF list structure
- `addValues<T>(predicate, values)` - Add multiple values for the same predicate (no guaranteed order)
- `addValueIfNotNull<T>(predicate, value)` - Conditionally add a value if not null
- `when(condition, builderFunction)` - Conditionally apply builder operations

**ResourceReader** provides methods for reading RDF resource properties:
- `require<T>(predicate)` - Get a required single value (throws if missing)
- `optional<T>(predicate)` - Get an optional single value (returns null if missing)
- `requireRdfList<T>(predicate)` - Get a required ordered list from RDF list structure
- `optionalRdfList<T>(predicate)` - Get an optional ordered list from RDF list structure  
- `getValues<T>(predicate)` - Get multiple values for the same predicate (no guaranteed order)

> **When to use RDF lists vs multiple values:**
> - Use `addRdfList()` / `optionalRdfList()` when **order matters** (e.g., book chapters, steps in a process)
> - Use `addValues()` / `getValues()` when you have **multiple independent values** (e.g., tags, categories)

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
builder.addValue(example('name'), 'Alice');  // Generates http://example.com/my-new-vocab/name
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
    // ORDERED: Chapters must be in sequence (preserves element order)
    chapters: [
      Chapter('An Unexpected Party', 1),
      Chapter('Roast Mutton', 2),
      Chapter('A Short Rest', 3),
    ],
    // UNORDERED: Multiple independent values (no guaranteed order)
    genres: ['fantasy', 'adventure', 'children'],
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
    schema:genre "adventure", "children", "fantasy";
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
  // ORDERED: Chapters sequence matters (mapped to RDF list)
  final List<Chapter> chapters;
  // UNORDERED: Multiple independent values (mapped to multiple triples)
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
      id: _extractIdFromIri(subject.iri),
      title: reader.require<String>(titlePredicate),
      author: reader.require<String>(authorPredicate),
      published: reader.require<DateTime>(publishedPredicate),
      isbn: reader.require<ISBN>(isbnPredicate),
      rating: reader.require<Rating>(ratingPredicate),
      // ORDERED: Use optionalRdfList for chapters (preserves sequence)
      chapters: reader.optionalRdfList<Chapter>(chapterPredicate) ?? const [],
      // UNORDERED: Use getValues for genres (multiple independent values)
      genres: reader.getValues<String>(genrePredicate).toList(),
    );
  }

  @override
  (IriTerm, List<Triple>) toRdfResource(
    Book book,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(IriTerm(_createIriFromId(book.id)))
        .addValue(titlePredicate, book.title)
        .addValue(authorPredicate, book.author)
        .addValue<DateTime>(publishedPredicate, book.published)
        .addValue<ISBN>(isbnPredicate, book.isbn)
        .addValue<Rating>(ratingPredicate, book.rating)
        // ORDERED: Use addRdfList for chapters (preserves sequence)
        .addRdfList<Chapter>(chapterPredicate, book.chapters)
        // UNORDERED: Use addValues for genres (multiple independent values)
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
  (BlankNodeTerm, List<Triple>) toRdfResource(
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

### RDF Collections (Lists)

The library provides full support for RDF Collections using the standard `rdf:first`/`rdf:rest`/`rdf:nil` pattern, allowing you to map Dart `List<T>` objects to RDF list structures while preserving element order.

#### Basic RDF List Usage

```dart
class Book {
  final List<Chapter> chapters;
  // ... other properties
}

class BookMapper implements GlobalResourceMapper<Book> {
  @override
  Book fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Book(
      // Deserialize RDF list to Dart List
      chapters: reader.optionalRdfList<Chapter>(Schema.hasPart) ?? const [],
      // Use requireRdfList<T>() if the list is mandatory
      // chapters: reader.requireRdfList<Chapter>(Schema.hasPart),
    );
  }

  @override
  (IriTerm, List<Triple>) toRdfResource(Book book, SerializationContext context, {RdfSubject? parentSubject}) {
    return context
        .resourceBuilder(subject)
        // Serialize Dart List to RDF list structure
        .addRdfList<Chapter>(Schema.hasPart, book.chapters)
        .build();
  }
}
```

> 💡 **Performance tip**: For optional lists, you can use `.when(list.isNotEmpty, (builder) => builder.addRdfList(...))` to avoid creating empty RDF list structures when the list is empty. However, this is optional - `addRdfList([])` works fine and is simpler.

#### Advanced Collection Support

For custom collection types or more control, use the general collection infrastructure:

```dart
// Custom collection type (e.g., immutable list, set, etc.)
final customCollection = reader.requireCollection<ImmutableList<String>, String>(
  Schema.keywords,
  (itemDeserializer) => CustomListDeserializer<String>(itemDeserializer),
);

// Custom collection serialization
builder.addCollection<MyCustomList<String>, String>(
  Schema.keywords,
  myCustomList,
  (itemSerializer) => CustomListSerializer<String>(itemSerializer),
);
```

#### Creating Custom Collection Extension Methods

You can extend the ResourceBuilder and ResourceReader APIs with your own convenience methods for custom collection types:

```dart
// Extension methods for ResourceReader
extension ImmutableListReaderExtensions on ResourceReader {
  ImmutableList<T> requireImmutableList<T>(RdfPredicate predicate) =>
      requireCollection<ImmutableList<T>, T>(
        predicate,
        (itemDeserializer) => ImmutableListDeserializer<T>(itemDeserializer),
      );

  ImmutableList<T>? optionalImmutableList<T>(RdfPredicate predicate) =>
      optionalCollection<ImmutableList<T>, T>(
        predicate,
        (itemDeserializer) => ImmutableListDeserializer<T>(itemDeserializer),
      );
}

// Extension methods for ResourceBuilder  
extension ImmutableListBuilderExtensions<S extends RdfSubject> on ResourceBuilder<S> {
  ResourceBuilder<S> addImmutableList<T>(RdfPredicate predicate, ImmutableList<T> collection) =>
      addCollection<ImmutableList<T>, T>(
        predicate,
        collection,
        (itemSerializer) => ImmutableListSerializer<T>(itemSerializer),
      );
}

// Usage in your mappers - now as convenient as the built-in methods!
class MyMapper implements GlobalResourceMapper<MyClass> {
  @override
  MyClass fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return MyClass(
      items: reader.requireImmutableList<String>(Schema.keywords),
      optionalItems: reader.optionalImmutableList<Tag>(Schema.tags),
    );
  }

  @override
  (IriTerm, List<Triple>) toRdfResource(MyClass obj, SerializationContext context, {RdfSubject? parentSubject}) {
    return context.resourceBuilder(subject)
        .addImmutableList<String>(Schema.keywords, obj.items)
        .addImmutableList<Tag>(Schema.tags, obj.optionalItems)
        .build();
  }
}
```

This pattern allows you to create type-safe, convenient APIs for any collection type while leveraging the library's existing collection infrastructure.

#### RDF List Output

RDF lists are serialized using the standard pattern:
```turtle
<book1> schema:hasPart (
  [ a schema:Chapter ; schema:name "Chapter 1" ; schema:position 1 ]
  [ a schema:Chapter ; schema:name "Chapter 2" ; schema:position 2 ]
  [ a schema:Chapter ; schema:name "Chapter 3" ; schema:position 3 ]
) .
```

This preserves the exact order of elements, unlike simple multiple property values which have no guaranteed order.

#### Choosing Between RDF Lists and Multiple Values

**Use RDF Lists (`addRdfList` / `optionalRdfList`)** when:
- **Order matters**: Book chapters, process steps, ranked items
- **Sequence is meaningful**: Navigation breadcrumbs, recipe instructions  
- **You need deterministic iteration**: Algorithm steps, workflow stages

**Use Multiple Values (`addValues` / `getValues`)** when:
- **Order doesn't matter**: Tags, categories, keywords
- **Independent relationships**: Multiple authors, related links, contact emails
- **Set-like data**: Permissions, capabilities, supported formats

```dart
// ORDERED: Use RDF Lists for sequential data
sections: reader.optionalRdfList<Section>(vocab.sections) ?? const [],

// UNORDERED: Use getValues for independent multiple values  
tags: reader.getValues<String>(vocab.tags).toList(),
authors: reader.getValues<Author>(vocab.authors).toList(),
```

**RDF Output Comparison:**
```turtle
# RDF List (ordered) - uses rdf:first/rdf:rest structure
<article> vocab:sections ( 
  [ vocab:title "Introduction" ; vocab:number 1 ]
  [ vocab:title "Main Content" ; vocab:number 2 ]  
  [ vocab:title "Conclusion" ; vocab:number 3 ]
) .

# Multiple Values (unordered) - separate triples
<article> vocab:tags "rdf", "semantic-web", "tutorial" ;
          vocab:authors [ vocab:name "Alice" ], [ vocab:name "Bob" ] .
```

> 💡 **See the complete example**: [`example/collections_example.dart`](example/collections_example.dart) demonstrates both approaches with a practical article/blog post scenario.

### Lossless Mapping - Preserve All Your Data

Want to ensure no RDF data is lost during conversion? rdf_mapper provides powerful lossless mapping features:

```dart
// Decode with remainder - get your object plus any unmapped data
final (person, remainderGraph) = rdfMapper.decodeObjectLossless<Person>(turtle);

// Your object contains all mapped properties
print(person.name); // "John Smith"

// remainderGraph contains any triples that weren't part of your object
print('Preserved ${remainderGraph.triples.length} unmapped triples');

// Encode back to preserve everything
final restoredTurtle = rdfMapper.encodeObjectLossless((person, remainderGraph));
// Now you have the complete original data back!
```

**Preserve unmapped properties within objects:**

Using annotations with code generation (recommended):
```dart
@RdfGlobalResource(SchemaPerson.classIri, IriStrategy('http://example.org/person/{id}'))
class Person {
  @RdfIriPart('id')
  final String id;
  
  @RdfProperty(SchemaPerson.foafName)
  final String name;
  
  @RdfUnmappedTriples()
  final RdfGraph unmappedGraph; // Automatically captures unmapped properties
  
  Person({required this.id, required this.name, RdfGraph? unmappedGraph})
    : unmappedGraph = unmappedGraph ?? RdfGraph();
}
// Run: dart run build_runner build
// That's it! The generator creates the mapper automatically.
```

Manual implementation:
```dart
class Person {
  final String id;
  final String name;
  final RdfGraph unmappedGraph; // Catches unmapped properties
  
  Person({required this.id, required this.name, RdfGraph? unmappedGraph})
    : unmappedGraph = unmappedGraph ?? RdfGraph();
}

class PersonMapper implements GlobalResourceMapper<Person> {
  @override
  Person fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Person(
      id: subject.iri,
      name: reader.require<String>(foafName),
      unmappedGraph: reader.getUnmapped<RdfGraph>(), // Captures unmapped data, should be the last reader call
    );
  }

  @override
  (IriTerm, List<Triple>) toRdfResource(Person person, SerializationContext context, {RdfSubject? parentSubject}) {
    return context.resourceBuilder(IriTerm(person.id))
      .addValue(foafName, person.name)
      .addUnmapped(person.unmappedGraph) // Restores unmapped data
      .build();
  }
}
```

Perfect for applications that need to preserve unknown properties, support evolving schemas, or maintain complete data fidelity. 

**Alternative unmapped types:** You can also use `Map<IriTerm, List<RdfObject>>` or `Map<RdfPredicate, List<RdfObject>>` for simpler, shallow unmapped data handling (without nested blank node triples).

See the [Lossless Mapping Guide](doc/LOSSLESS_MAPPING.md) for complete details.

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

## 🎯 Datatype Handling and Best Practices

### Understanding Datatype Strictness

RDF Mapper enforces **datatype strictness** by default to ensure:
- **Roundtrip Consistency**: Values serialize back to the same RDF datatype
- **Semantic Preservation**: Original meaning is maintained across transformations
- **Data Integrity**: Prevention of data corruption in RDF stores

### Common Datatype Scenarios

#### Working with Standard Types
```dart
// These work out of the box
final person = Person(
  name: "Alice",        // -> xsd:string
  age: 30,              // -> xsd:integer  
  height: 1.75,         // -> xsd:decimal
  isActive: true,       // -> xsd:boolean
  birthDate: DateTime.now(), // -> xsd:dateTime
);
```

#### Handling Non-Standard Datatypes

When your RDF data uses different datatypes than the defaults:

```turtle
# RDF data with non-standard datatypes
ex:temperature "23.5"^^units:celsius .
ex:weight "70.5"^^units:kilogram .
ex:score "95.0"^^xsd:double .  # double instead of decimal
```

**Solution 1: Custom Wrapper Types (Recommended)**
```dart
@RdfLiteral(IriTerm('http://qudt.org/vocab/unit/CEL'))
class Temperature {
  @RdfValue()
  final double celsius;
  const Temperature(this.celsius);
}

// Or manual implementation
class Weight {
  final double kilograms;
  const Weight(this.kilograms);
}

class WeightMapper extends DelegatingRdfLiteralTermMapper<Weight, double> {
  static final kgDatatype = IriTerm('http://qudt.org/vocab/unit/KiloGM');
  
  const WeightMapper() : super(const DoubleMapper(), kgDatatype);
  
  @override
  Weight convertFrom(double value) => Weight(value);
  
  @override  
  double convertTo(Weight value) => value.kilograms;
}
```

**Solution 2: Global Registration**
```dart
// For existing types with different datatypes
final rdfMapper = RdfMapper.withMappers((registry) => registry
  ..registerMapper<double>(DoubleMapper(Xsd.double))  // Use xsd:double
  ..registerMapper<Temperature>(TemperatureMapper())
  ..registerMapper<Weight>(WeightMapper()));
```

**Solution 3: Local Scope Override**
```dart
// For specific predicates only - simpler option
@RdfProperty('http://example.org/score',
             literal: const LiteralMapping.withType(Xsd.double))
double? testScore;

// Alternative: mapper instance approach
@RdfProperty('http://example.org/score',
             literal: LiteralMapping.mapperInstance(DoubleMapper(Xsd.double)))
double? testScore;
```

### Troubleshooting Datatype Issues

When you see `DeserializerDatatypeMismatchException`:

1. **Identify the mismatch**: The exception shows actual vs expected datatypes
2. **Choose your strategy**: Global, wrapper type, or local scope solution
3. **Implement the fix**: Use the code examples provided in the exception message
4. **Test roundtrip**: Ensure serialize → deserialize produces identical results

### Performance Tips

- Use `const` constructors for mappers when possible
- Prefer wrapper types over global overrides for better type safety
- Consider caching for expensive custom conversions
- Use `bypassDatatypeCheck` sparingly and only when necessary

## ⚠️ Error Handling

RDF Mapper provides specific exceptions to help diagnose mapping issues:

- `RdfMappingException`: Base exception for all mapping errors
- `SerializationException`: Errors during serialization
- `DeserializationException`: Errors during deserialization
- `SerializerNotFoundException`: When no serializer is registered for a type
- `DeserializerNotFoundException`: When no deserializer is registered for a type
- `PropertyValueNotFoundException`: When a required property is missing
- `TooManyPropertyValuesException`: When multiple values exist for a single-valued property
- `DeserializerDatatypeMismatchException`: When RDF datatype doesn't match expected type

### Handling Datatype Mismatches

The library enforces **datatype strictness** to ensure roundtrip consistency and semantic preservation. When you encounter a `DeserializerDatatypeMismatchException`, you have several resolution options:

#### Global Solution (affects all instances)
```dart
// Register a mapper for the encountered datatype
final rdfMapper = RdfMapper.withMappers((registry) => 
  registry.registerMapper<double>(DoubleMapper(Xsd.double)));
```

#### Custom Wrapper Types (recommended)
```dart
// Using annotations
@RdfLiteral(Xsd.double)
class MyCustomDouble {
  @RdfValue()
  final double value;
  const MyCustomDouble(this.value);
}

// Manual implementation
class MyCustomDouble {
  final double value;
  const MyCustomDouble(this.value);
}

class MyCustomDoubleMapper extends DelegatingRdfLiteralTermMapper<MyCustomDouble, double> {
  const MyCustomDoubleMapper() : super(const DoubleMapper(), Xsd.double);
  
  @override
  MyCustomDouble convertFrom(double value) => MyCustomDouble(value);
  
  @override
  double convertTo(MyCustomDouble value) => value.value;
}
```

#### Local Scope (for specific predicates)
```dart
// In custom resource mappers
reader.require(myPredicate, deserializer: DoubleMapper(Xsd.double));

// With annotations - simpler option
@RdfProperty(myPredicate, 
             literal: const LiteralMapping.withType(Xsd.double))

// With annotations - mapper instance approach
@RdfProperty(myPredicate, 
             literal: LiteralMapping.mapperInstance(DoubleMapper(Xsd.double)))
```

#### Bypass Option (use carefully)
```dart
// Only when flexible datatype handling is required
context.fromLiteralTerm(term, bypassDatatypeCheck: true);
```

## 🚦 Performance Considerations

- RDF Mapper uses efficient traversal algorithms for both serialization and deserialization
- For large graphs, consider using the graph-based API instead of string serialization
- Consider implementing custom mappers for performance-critical types in your application

## 🛣️ Roadmap / Next Steps

- Detect cycles, optimally support them.
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
