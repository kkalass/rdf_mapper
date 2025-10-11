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
- **RDF Collections**: Full support for RDF Lists and Containers (Seq, Bag, Alt) with order preservation
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
  rdf_mapper: ^0.10.4
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
import 'package:rdf_vocabularies_schema/schema.dart';

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
  (IriTerm, Iterable<Triple>) toRdfResource(Person value, SerializationContext context, {RdfSubject? parentSubject}) {

    // convert dart objects to triples using the fluent builder API
    return context.resourceBuilder(const IriTerm(value.id))
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
import 'package:rdf_vocabularies_schema/schema.dart';

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
- `addValues<T>(predicate, values)` - Add multiple values for the same predicate (no guaranteed order)
- `addRdfList<T>(predicate, list)` - Add an ordered list using RDF list structure
- `addCollection<C, T>(predicate, collection, factory)` - **Base method** Add a collection using the specified collection mapping factory - used by e.g. addValues and addRdfList
- `addValueIfNotNull<T>(predicate, value)` - Conditionally add a value if not null
- `when(condition, builderFunction)` - Conditionally apply builder operations

**ResourceReader** provides methods for reading RDF resource properties:
- `require<T>(predicate)` - Get a required single value (throws if missing)
- `optional<T>(predicate)` - Get an optional single value (returns null if missing)
- `getValues<T>(predicate)` - Get multiple values for the same predicate (no guaranteed order)
- `requireRdfList<T>(predicate)` - Get a required ordered list from RDF list structure
- `optionalRdfList<T>(predicate)` - Get an optional ordered list from RDF list structure  
- `requireCollection<C, T>(predicate, factory)` - **Base method** Get a required collection with a mapper created by the given factory - used by e.g. requireRdfList and getValues. 
- `optionalCollection<C, T>(predicate, factory)` - **Base method** Get an optional collection with a mapper created by the given factory - used by e.g. optionalRdfList.

> **When to use different collection approaches:**
> - Use `addRdfList()` / `optionalRdfList()` / `requireRdfList()` when **order matters** (e.g., book chapters, steps in a process)
> - Use `addValues()` / `getValues()` when you have **multiple independent values** (e.g., tags, categories, unordered lists)
> - Use `addCollection()` / `optionalCollection()` / `requireCollection()` when you need **maximum control** over both the Dart collection type and the representation in RDF.

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

Here's a complete example showing different mapper types and collection strategies:

```dart
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_schema/schema.dart';

void main() {
  final rdf = RdfMapper.withDefaultRegistry()
    ..registerMapper<Book>(BookMapper())
    ..registerMapper<Chapter>(ChapterMapper())
    ..registerMapper<ISBN>(ISBNMapper());

  final book = Book(
    id: 'hobbit',
    title: 'The Hobbit',
    author: 'J.R.R. Tolkien',
    isbn: ISBN('9780618260300'),
    chapters: [Chapter('An Unexpected Party', 1), Chapter('Roast Mutton', 2)], // Ordered
    genres: ['fantasy', 'adventure', 'children'],                              // Unordered
  );

  final turtle = rdf.encodeObject(book);
  print(turtle);
  
  final deserializedBook = rdf.decodeObject<Book>(turtle);
  print('Title: ${deserializedBook.title}');
}

// Domain model
class Book {
  final String id;
  final String title;
  final String author;
  final ISBN isbn;
  final List<Chapter> chapters;  // Will use RDF List (ordered)
  final List<String> genres;     // Will use multiple triples (unordered)
  
  Book({required this.id, required this.title, required this.author, 
        required this.isbn, required this.chapters, required this.genres});
}

class Chapter {
  final String title;
  final int number;
  Chapter(this.title, this.number);
}

class ISBN {
  final String value;
  ISBN(this.value);
}

// Mappers
class BookMapper implements GlobalResourceMapper<Book> {
  @override
  final IriTerm typeIri = SchemaBook.classIri;

  @override
  Book fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Book(
      id: subject.iri.split('/').last,
      title: reader.require<String>(SchemaBook.name),
      author: reader.require<String>(SchemaBook.author),
      isbn: reader.require<ISBN>(SchemaBook.isbn),
      chapters: reader.optionalRdfList<Chapter>(SchemaBook.hasPart) ?? const [], // RDF List
      genres: reader.getValues<String>(SchemaBook.genre).toList(),               // Multiple values
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(Book book, SerializationContext context, {RdfSubject? parentSubject}) {
    return context.resourceBuilder(const IriTerm('http://example.org/book/${book.id}'))
        .addValue(SchemaBook.name, book.title)
        .addValue(SchemaBook.author, book.author)
        .addValue<ISBN>(SchemaBook.isbn, book.isbn)
        .addRdfList<Chapter>(SchemaBook.hasPart, book.chapters)  // Preserves order
        .addValues<String>(SchemaBook.genre, book.genres)        // Multiple triples
        .build();
  }
}

class ChapterMapper implements LocalResourceMapper<Chapter> {
  @override
  final IriTerm typeIri = SchemaChapter.classIri;

  @override
  Chapter fromRdfResource(BlankNodeTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Chapter(
      reader.require<String>(SchemaChapter.name),
      reader.require<int>(SchemaChapter.position),
    );
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(Chapter chapter, SerializationContext context, {RdfSubject? parentSubject}) {
    return context.resourceBuilder(BlankNodeTerm())
        .addValue(SchemaChapter.name, chapter.title)
        .addValue<int>(SchemaChapter.position, chapter.number)
        .build();
  }
}

class ISBNMapper implements IriTermMapper<ISBN> {
  @override
  IriTerm toRdfTerm(ISBN isbn, SerializationContext context) => const IriTerm('urn:isbn:${isbn.value}');

  @override
  ISBN fromRdfTerm(IriTerm term, DeserializationContext context) => ISBN(term.iri.split(':').last);
}
```

### RDF Collections

The library provides multiple strategies for handling collections in RDF:

1. **RDF Lists**: Ordered collections using `rdf:first`/`rdf:rest`/`rdf:nil` (preserves sequence)
2. **Multi-Objects**: Flat collections using multiple triples (unordered, efficient)
3. **RDF Containers**: Structured collections using numbered properties `rdf:_1`, `rdf:_2` (Seq/Bag/Alt)

#### Quick Guide: When to Use Each

| **Use RDF Lists** (`addRdfList`/`optionalRdfList`/...) | **Use Multi-Objects** (`addValues`/`getValues`) | **Use RDF Containers** (`addRdfSeq`/`addRdfBag`/`addRdfAlt`/...) |
|---|---|---|
| Order matters (chapters, steps, rankings) | Order doesn't matter (tags, keywords, authors) | Need explicit container semantics |
| Need to preserve exact sequence | Want flatter RDF structure | Seq: ordered with numbered properties |
| Working with existing RDF list data | Better query performance needed | Bag: unordered, allows duplicates |
| Linked list structure preferred | Simple multiple triples | Alt: alternatives with preference order |

#### RDF Lists (Ordered Collections)

```dart
class BookMapper implements GlobalResourceMapper<Book> {
  @override
  Book fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Book(
      // Preserves chapter order
      chapters: reader.optionalRdfList<Chapter>(Schema.hasPart) ?? const [],
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(Book book, SerializationContext context, {RdfSubject? parentSubject}) {
    return context.resourceBuilder(subject)
        .addRdfList<Chapter>(Schema.hasPart, book.chapters) // Preserves order
        .build();
  }
}
```

#### Multi-Objects (Flat Collections)

```dart
class LibraryMapper implements GlobalResourceMapper<Library> {
  @override
  Library fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Library(
      // Multiple independent values (no order guarantee)
      featuredBooks: reader.getValues<Book>(Schema.featuredBooks).toList(),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(Library library, SerializationContext context, {RdfSubject? parentSubject}) {
    return context.resourceBuilder(subject)
        .addValues<Book>(Schema.featuredBooks, library.featuredBooks) // One triple per book
        .build();
  }
}
```

#### Custom Collection Types

Use the base collection methods for custom collection types:

```dart
// Extension methods for your custom collection type
extension ImmutableListExtensions on ResourceReader {
  ImmutableList<T> requireImmutableList<T>(RdfPredicate predicate) =>
      requireCollection<ImmutableList<T>, T>(
        predicate,
        ImmutableListDeserializer<T>.new, // Your custom deserializer factory
      );
}

extension ImmutableListBuilderExtensions<S extends RdfSubject> on ResourceBuilder<S> {
  ResourceBuilder<S> addImmutableList<T>(RdfPredicate predicate, ImmutableList<T> collection) =>
      addCollection<ImmutableList<T>, T>(
        predicate,
        collection,
        ImmutableListSerializer<T>.new, // Your custom serializer factory
      );
}

// Usage in mappers
class MyMapper implements GlobalResourceMapper<MyClass> {
  @override
  MyClass fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return MyClass(
      items: reader.requireImmutableList<String>(Schema.keywords),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(MyClass obj, SerializationContext context, {RdfSubject? parentSubject}) {
    return context.resourceBuilder(subject)
        .addImmutableList<String>(Schema.keywords, obj.items)
        .build();
  }
}
```

#### RDF Containers (Seq, Bag, Alt)

For specialized container semantics:

```dart
// Use specific container types when semantics matter
chapters: reader.optionalRdfSeq<String>(Schema.hasPart) ?? const [],      // Ordered sequence
keywords: reader.optionalRdfBag<String>(Schema.keywords) ?? const [],      // Unordered collection  
formats: reader.optionalRdfAlt<String>(Schema.encodingFormat) ?? const [], // Alternatives with preference

// In builder
.addRdfSeq<String>(Schema.hasPart, resource.chapters)       // rdf:Seq
.addRdfBag<String>(Schema.keywords, resource.keywords)      // rdf:Bag
.addRdfAlt<String>(Schema.encodingFormat, resource.formats) // rdf:Alt
```

> 💡 **See complete examples**: [`example/collections_example.dart`](example/collections_example.dart) and [`example/custom_collection_type_example.dart`](example/custom_collection_type_example.dart)

### Document Pattern with SerializationProvider

For RDF documents that follow the FOAF Document pattern (like Solid WebID profiles), rdf_mapper provides the `SerializationProvider` interface for contextual serialization. This is especially useful when nested objects need access to their container's properties:

```dart
// Generic document wrapper
class Document<T> {
  final String documentIri;
  final T primaryTopic;        // foaf:primaryTopic
  final RdfGraph unmapped;     // For lossless round-trip
  
  Document({required this.documentIri, required this.primaryTopic, required this.unmapped});
}

// Person that can receive document context
class Person {
  final String id;
  final String name;
  final String? documentContext;  // Optional: knows about its document
  
  Person({required this.id, required this.name, this.documentContext});
}

// Document mapper using SerializationProvider for contextual nested mapping
class DocumentMapper<T> implements GlobalResourceMapper<Document<T>> {
  final SerializationProvider<Document<T>, T> _primaryTopicProvider;
  
  const DocumentMapper({required SerializationProvider<Document<T>, T> primaryTopic})
    : _primaryTopicProvider = primaryTopic;

  @override
  IriTerm? get typeIri => FoafDocument.classIri;

  @override
  Document<T> fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Document<T>(
      documentIri: subject.iri,
      primaryTopic: reader.require(
        Foaf.primaryTopic,
        deserializer: _primaryTopicProvider.deserializer(subject, context),
      ),
      // Capture ALL unmapped triples from the entire graph for lossless document handling
      unmapped: reader.getUnmapped<RdfGraph>(globalUnmapped: true),
    );
  }
  
  @override
  (IriTerm, Iterable<Triple>) toRdfResource(Document<T> document, SerializationContext context, {RdfSubject? parentSubject}) {
    final subject = const IriTerm(document.documentIri);
    return context.resourceBuilder(subject)
      .addValue(
        Foaf.primaryTopic,
        document.primaryTopic,
        serializer: _primaryTopicProvider.serializer(document, subject, context),
      )
      .addUnmapped(document.unmapped)
      .build();
  }
}

// Registration with IRI-contextual provider
final rdfMapper = RdfMapper.withMappers((r) => r
  .registerMapper<Document<Person>>(DocumentMapper(
    primaryTopic: SerializationProvider.iriContextual(
      (IriTerm documentIri) => PersonMapper(
        documentIriProvider: () => documentIri.iri  // Pass document context to Person
      )
    )
  )));
```

This pattern works perfectly for:
- **Solid WebID Profiles**: FOAF PersonalProfileDocument with foaf:primaryTopic pointing to the person
- **FOAF Documents**: Any document that has a primary topic requiring contextual information
- **Nested Context**: When child objects need to know about their parent containers

**Key Features:**
- **Global Unmapped Triples**: Use `reader.getUnmapped<RdfGraph>(globalUnmapped: true)` to capture ALL unmapped triples from the entire graph, not just the current subject. Perfect for document patterns where you want to preserve unprocessed metadata, annotations, or "dangling" triples.
- **Contextual Serialization**: SerializationProvider enables nested objects to receive context from their containers

**SerializationProvider factory methods:**
- `SerializationProvider.nonContextual(mapper)` - Same mapper for all contexts
- `SerializationProvider.iriContextual(factory)` - Create mapper based on subject IRI
- `SerializationProvider.custom(...)` - Full control over serializer/deserializer creation

**Example RDF (Solid WebID style):**
```turtle
@prefix : <#> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix schema: <http://schema.org/> .

<https://alice.datapod.example/profile/card> 
    a foaf:PersonalProfileDocument ;
    foaf:primaryTopic <https://alice.datapod.example/profile/card#me> .

<https://alice.datapod.example/profile/card#me>
    a foaf:Person ;
    foaf:name "Alice Smith" ;
    schema:email "alice@example.com" .
```

> 💡 **See complete example**: [`example/document_pattern_example.dart`](example/document_pattern_example.dart)

### Lossless Mapping - Preserve All Your Data

Want to ensure no RDF data is lost during conversion? rdf_mapper provides powerful lossless mapping features:

#### Global Lossless Mapping (Recommended)

For document-level lossless mapping, use the `globalUnmapped` flag to capture ALL unmapped triples in a single object:

```dart
class Document {
  final String documentIri;
  final Person primaryTopic;
  final RdfGraph unmapped; // Contains ALL unmapped triples from the entire document
  
  Document({required this.documentIri, required this.primaryTopic, required this.unmapped});
}

class DocumentMapper implements GlobalResourceMapper<Document> {
  @override
  Document fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Document(
      documentIri: subject.iri,
      primaryTopic: reader.require<Person>(foafPrimaryTopic),
      // Capture ALL unmapped triples from the entire graph - no need for decodeObjectLossless!
      unmapped: reader.getUnmapped<RdfGraph>(globalUnmapped: true),
    );
  }
  // ... serialization restores with addUnmapped(document.unmapped)
}

// Simple usage - no lossless API needed!
final document = rdfMapper.decodeObject<Document>(turtle);
final restoredTurtle = rdfMapper.encodeObject(document);
// Complete round-trip preservation with regular decode/encode methods!
```

#### Traditional Lossless API

For scenarios where you want to keep your domain objects pure and free from RDF dependencies:

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

#### Object-Level Lossless Mapping

**Preserve unmapped properties within individual objects:**

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
  (IriTerm, Iterable<Triple>) toRdfResource(Person person, SerializationContext context, {RdfSubject? parentSubject}) {
    return context.resourceBuilder(const IriTerm(person.id))
      .addValue(foafName, person.name)
      .addUnmapped(person.unmappedGraph) // Restores unmapped data
      .build();
  }
}
```

Perfect for applications that need to preserve unknown properties, support evolving schemas, or maintain complete data fidelity.

**When to use each approach:**
- **Global Lossless (`globalUnmapped: true`)**: Best for document patterns, single-object graphs, or when you want one place to capture all unmapped data. Requires your domain objects to include RDF-specific fields.
- **Traditional Lossless API (`decodeObjectLossless`/`encodeObjectLossless`)**: When you want to keep your domain objects pure and free from RDF dependencies. The unmapped data is handled separately from your business objects, maintaining clean separation of concerns.
- **Object-Level Lossless**: When individual objects need to preserve their own unmapped properties independently, but you're okay with RDF-aware domain objects.

**Architecture considerations:**
```dart
// Pure domain objects - no RDF dependencies
class Person {
  final String id;
  final String name;
  // No RdfGraph field - keep business logic clean
}

// Use lossless API for external unmapped data handling
final (person, unmappedTriples) = rdfMapper.decodeObjectLossless<Person>(turtle);
// person is a pure business object, unmappedTriples handled separately

// vs.

// RDF-aware domain objects
class Document {
  final String documentIri;
  final Person primaryTopic;
  final RdfGraph unmapped; // RDF-specific field in domain model
}
```

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

### IRI Mappers

For working with IRIs as subjects, objects, or properties, the library provides several specialized mappers:

#### Complete Bidirectional Mappers

These mappers implement both serialization and deserialization in a single class:

| Mapper | Purpose | Use Case |
|--------|---------|----------|
| `IriFullMapper` | Complete IRIs | Direct IRI-to-string mapping |
| `BaseRdfIriTermMapper` | URI templates | Template-based IRI generation with placeholders |
| `IriRelativeMapper` | Relative IRIs | Document-relative references |
| `FragmentIriTermMapper` | IRI fragments | Extract/append fragment parts (after #) |
| `LastPathElementIriTermMapper` | Path elements | Extract/append last path segment |

#### Individual Serializers and Deserializers

For custom combinations or one-way operations, use these individual components:

| Component | Direction | Purpose |
|-----------|-----------|---------|
| `IriIdSerializer` | Object → IRI | Expand local identifiers to full IRIs |
| `ExtractingIriTermDeserializer` | IRI → Object | Custom extraction with flexible functions |
| `IriRelativeSerializer` | Relative → Absolute | Convert relative to absolute IRIs |
| `IriRelativeDeserializer` | Absolute → Relative | Convert absolute to relative IRIs |

> **💡 Tip**: Individual serializers and deserializers are equivalent to the complete mappers above. For example, `IriRelativeMapper` uses the same implementation as `IriRelativeSerializer` and `IriRelativeDeserializer` internally.

#### URI Template Mapping Example

Use `BaseRdfIriTermMapper` for complex URI template scenarios:

```dart
class ProductMapper extends BaseRdfIriTermMapper<Product> {
  const ProductMapper() : super('http://shop.example.org/{category}/{id}', 'id');

  @override
  String resolvePlaceholder(String placeholderName) {
    return switch (placeholderName) {
      'category' => 'electronics', // Could be dynamic
      _ => super.resolvePlaceholder(placeholderName),
    };
  }

  @override
  String convertToString(Product product) => product.id;

  @override
  Product convertFromString(String id) => Product(id: id);
}

// Usage: Product(id: "laptop-123") ↔ "http://shop.example.org/electronics/laptop-123"
```

#### Convenience Mappers Example

For specific IRI parts, use the convenience mappers:

```dart
// Fragment mapper for anchor-style references
const fragmentMapper = FragmentIriTermMapper('http://docs.example.org/guide');
// "introduction" ↔ "http://docs.example.org/guide#introduction"

// Path element mapper for REST-style resources  
const pathMapper = LastPathElementIriTermMapper('http://api.example.org/users/');
// "alice" ↔ "http://api.example.org/users/alice"
```

#### Relative IRI Example

Useful for document systems, APIs, or any scenario requiring compact IRI representation **in Dart objects**:

```dart
// For a documentation system
const baseUri = 'http://docs.example.org/v2/';
const mapper = IriRelativeMapper(baseUri);

// Relative IRIs become absolute when serialized TO RDF
final iriTerm = mapper.toRdfTerm('getting-started.html', context);
print(iriTerm.iri); // "http://docs.example.org/v2/getting-started.html"

// Absolute IRIs become relative when deserialized FROM RDF  
final relative = mapper.fromRdfTerm(iriTerm, context);
print(relative); // "getting-started.html"
```

**Important**: This affects the **Dart object representation** only. The RDF serialization always contains absolute IRIs. This is useful when the same Dart classes are used for both RDF mapping and other serialization formats (JSON, databases, etc.) where compact relative IRIs are preferred.


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
@RdfLiteral(const IriTerm('http://qudt.org/vocab/unit/CEL'))
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
  static final kgDatatype = const IriTerm('http://qudt.org/vocab/unit/KiloGM');
  
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
