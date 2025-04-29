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
  rdf_mapper: ^1.0.0
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
// Define a simple model class
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
    final subject = IriTerm(value.id);
    final builder = context.nodeBuilder(subject);
    
    // Add properties using the fluent API
    builder
      .literal(IriTerm('http://xmlns.com/foaf/0.1/name'), value.name)
      .literal(IriTerm('http://xmlns.com/foaf/0.1/age'), value.age);
    
    return builder.build();
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

- `SerializationContext`: Provides access to the NodeBuilder and other utilities
- `DeserializationContext`: Provides access to the NodeReader and RDF graph

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

## Complex Example

The following example demonstrates handling complex models with relationships between objects and nested structures:

```dart
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

// Namespace constants for better readability
final foaf = Namespace('http://xmlns.com/foaf/0.1/');
final schema = Namespace('http://schema.org/');

// Model classes
class Address {
  final String street;
  final String city;
  final String postalCode;
  final String country;
  
  Address({
    required this.street, 
    required this.city, 
    required this.postalCode, 
    required this.country
  });
}

class Person {
  final String id;
  final String name;
  final int age;
  final Address address;
  final List<Person> friends;
  
  Person({
    required this.id, 
    required this.name, 
    required this.age, 
    required this.address,
    this.friends = const []
  });
}

// Mapper for Address class - implements BlankNodeMapper for anonymous resources
class AddressMapper implements BlankNodeMapper<Address> {
  @override
  IriTerm? get typeIri => schema('Address');
  
  @override
  (BlankNodeTerm, List<Triple>) toRdfNode(
    Address value, 
    SerializationContext context, 
    {RdfSubject? parentSubject}
  ) {
    final subject = BlankNodeTerm();
    final builder = context.nodeBuilder(subject);
    
    builder
      .literal(schema('streetAddress'), value.street)
      .literal(schema('addressLocality'), value.city)
      .literal(schema('postalCode'), value.postalCode)
      .literal(schema('addressCountry'), value.country);
      
    return builder.build();
  }
  
  @override
  Address fromRdfNode(BlankNodeTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    
    return Address(
      street: reader.require<String>(schema('streetAddress')),
      city: reader.require<String>(schema('addressLocality')),
      postalCode: reader.require<String>(schema('postalCode')),
      country: reader.require<String>(schema('addressCountry')),
    );
  }
}

// Mapper for Person class
class PersonMapper implements IriNodeMapper<Person> {
  @override
  IriTerm? get typeIri => foaf('Person');
  
  @override
  (IriTerm, List<Triple>) toRdfNode(
    Person value, 
    SerializationContext context, 
    {RdfSubject? parentSubject}
  ) {
    final subject = IriTerm(value.id);
    final builder = context.nodeBuilder(subject);
    
    // Simple properties
    builder
      .literal(foaf('name'), value.name)
      .literal(foaf('age'), value.age);
    
    // Nested Address as BlankNode
    builder.childNode(schema('address'), value.address);
    
    // List of friends as IRI references
    if (value.friends.isNotEmpty) {
      builder.childNodeList(foaf('knows'), value.friends);
    }
    
    return builder.build();
  }
  
  @override
  Person fromRdfNode(IriTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    
    return Person(
      id: term.iri,
      name: reader.require<String>(foaf('name')),
      age: reader.require<int>(foaf('age')),
      address: reader.require<Address>(schema('address')),
      friends: reader.getList<Person>(foaf('knows')),
    );
  }
}
```

### Namespace Helper Class

For clean management of IRIs in RDF, we recommend using a Namespace helper class:

```dart
/// Helper class for managing RDF namespaces
class Namespace {
  final String _base;
  
  Namespace(this._base);
  
  /// Creates an IRI term by appending the local name to the namespace base
  IriTerm call(String localName) => IriTerm('$_base$localName');
  
  /// Returns the base URL of the namespace
  String get uri => _base;
}

// Example usage:
final foaf = Namespace('http://xmlns.com/foaf/0.1/');
final schema = Namespace('http://schema.org/');

// Usage:
builder.literal(foaf('name'), 'Alice');  // Generates http://xmlns.com/foaf/0.1/name
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
