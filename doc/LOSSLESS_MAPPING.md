# Lossless RDF Mapping in rdf_mapper

This document explains how to use rdf_mapper to perform lossless RDF mapping, ensuring that all information from an original RDF document is preserved when converting to Dart objects and back again. This is crucial for scenarios where you need to maintain the integrity of the full RDF graph, even for triples that aren't explicitly mapped to properties in your Dart model.

## Core Concepts for Lossless Mapping
rdf_mapper offers two complementary strategies to achieve lossless mapping:

Preserving Unmapped Triples within an Object (unmappedGraph field): This strategy focuses on retaining all triples directly associated with a specific subject (your Dart object's ID) that are not explicitly mapped to other properties of that object. This ensures that the object itself is a complete representation of its part of the RDF graph.

Preserving the Entire Document (decodeObjectLossless method): This strategy ensures that all triples from the original input document are preserved, even those completely unrelated to the primary object being decoded. It provides a way to retrieve the primary object and any other entities or "remainder" triples from the document.

These two strategies can be used independently or combined for comprehensive lossless mapping.

## CompletenessMode: Controlling Incomplete Deserialization Handling

The `CompletenessMode` enum is a crucial feature that controls how rdf_mapper handles situations where not all triples in an RDF graph can be mapped to Dart objects during **deserialization with the normal (non-lossless) API**. This mode only applies to deserialization operations and can be used to enforce exceptions when a deserialization would lose data.

**Important**: CompletenessMode only affects deserialization methods like `decodeObject()` and `decodeObjects()`. It does not apply to serialization operations (`encodeObject()`, `encodeObjects()`) or to the lossless methods (`decodeObjectLossless()`, `encodeObjectLossless()`) which inherently preserve all data.

### Available Modes

- **`CompletenessMode.strict`** (default): Throws an `IncompleteDeserializationException` if any triples remain unmapped after deserialization. This ensures complete data processing and prevents data loss by failing when unmapped data is detected.

- **`CompletenessMode.lenient`**: Silently ignores unmapped triples and continues processing. This allows for graceful handling of partially mappable data without errors, but **data will be lost**.

- **`CompletenessMode.warnOnly`**: Logs warnings for unmapped triples but continues processing. Useful for development and debugging to identify potentially missing mappings while still **losing unmapped data**.

- **`CompletenessMode.infoOnly`**: Logs informational messages about unmapped triples. The least intrusive mode for monitoring data completeness while **losing unmapped data**.

### Usage Examples (Deserialization Only)

```dart
// Strict mode (default) - will throw exception if unmapped triples exist
// This prevents data loss by failing when unmapped data is detected
final person = rdfMapper.decodeObject<Person>(turtle);

// Lenient mode - will silently ignore unmapped triples (DATA WILL BE LOST)
final person = rdfMapper.decodeObject<Person>(turtle, 
    completeness: CompletenessMode.lenient);

// Warn mode - will log warnings for unmapped triples (DATA WILL BE LOST)
final people = rdfMapper.decodeObjects<Person>(turtle,
    completenessMode: CompletenessMode.warnOnly);

// Also works with codec approach for deserialization
final codec = rdfMapper.graph.objectCodec<Person>(
    completeness: CompletenessMode.lenient);
final person = codec.decode(graph); // Only decoding, not encoding

// Note: CompletenessMode has NO EFFECT on encoding operations
final graph = codec.encode(person); // CompletenessMode doesn't apply here
```

### Why CompletenessMode is Important for Data Integrity

CompletenessMode serves as a safeguard against **accidental data loss** during deserialization:

- **Strict mode** (default) ensures you're aware when your mappers don't cover all the data in your RDF
- **Other modes** allow controlled data loss when you explicitly decide it's acceptable
- This is particularly important when transitioning from simple mapping to lossless mapping approaches

### CompletenessMode vs Lossless Mapping

The key difference between CompletenessMode and lossless mapping:

**Normal API with CompletenessMode**:
- `CompletenessMode.strict`: Fails if data would be lost (throws exception)
- `CompletenessMode.lenient/warnOnly/infoOnly`: Allows data loss but makes it visible

**Lossless API** (no CompletenessMode needed):
- `decodeObjectLossless()`: Never loses data - unmapped data goes to remainder graph
- `encodeObjectLossless()`: Preserves all data from both object and remainder graph

### Transition Strategy: Using CompletenessMode to Identify What Needs Lossless Handling

CompletenessMode is particularly useful during the transition to lossless mapping to identify what data would be lost:

```dart
// Step 1: Use strict mode to identify what needs to be captured losslessly
try {
  final person = rdfMapper.decodeObject<Person>(turtle, 
      completeness: CompletenessMode.strict);
  // If this succeeds, your current mappers handle all the data
} catch (IncompleteDeserializationException e) {
  print('Data that would be lost:');
  print('Unmapped subjects: ${e.unmappedSubjects}');
  print('Unmapped types: ${e.unmappedTypes}');
  print('Remaining triples: ${e.remainingTripleCount}');
  
  // Step 2: Implement lossless mapping to capture this data
  final (person, remainder) = rdfMapper.decodeObjectLossless<Person>(turtle);
  // Now no data is lost - unmapped data is in remainder graph
}
```

### IncompleteDeserializationException Details

When using `CompletenessMode.strict`, you may encounter `IncompleteDeserializationException` which provides detailed information about what couldn't be mapped:

- `remainingGraph`: The complete graph of unmapped triples
- `unmappedSubjects`: Set of subjects that couldn't be deserialized
- `unmappedTypes`: Set of RDF types that lack registered mappers
- `hasRemainingTriples`: Boolean indicating if any triples were left unmapped
- `remainingTripleCount`: Number of unmapped triples
- `unmappedSubjectCount` and `unmappedTypeCount`: Counts for analysis

This information is invaluable for implementing comprehensive lossless mapping strategies.

## Strategy 1: Preserving Unmapped Triples within an Object
The core idea is to designate a field in your Dart model to store any triples that are part of the original RDF graph and are about the same subject as your Dart object, but are not explicitly mapped to other properties of your object. These are often referred to as "unmapped triples" or "catch-all triples."

For this purpose, we recommend using an RdfGraph instance (from package:rdf_core/rdf_core.dart) as the type for this field, as it provides a robust way to manage a collection of RDF triples, including handling blank nodes.

### 1. Update Your Dart Model
Add an RdfGraph field to your model class. This field will hold all triples directly related to the object's subject that aren't mapped to other properties.

```dart
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_schema/schema.dart';
import 'package:rdf_core/rdf_core.dart'; // Correct import for RdfGraph

class Person {
  final String id;
  final String name;
  final int age;
  final RdfGraph unmappedGraph; // Field to store unmapped triples

  Person({
    required this.id,
    required this.name,
    required this.age,
    RdfGraph? unmappedGraph,
  }) : unmappedGraph = unmappedGraph ?? RdfGraph({}); // Initialize with an empty graph

  @override
  String toString() {
    return 'Person(id: $id, name: $name, age: $age, unmappedGraph: ${unmappedGraph.triples.length} triples)';
  }
}
```

### 2. Decoding - Using reader.getUnmapped in your GlobalResourceMapper

Within your GlobalResourceMapper's fromRdfResource method, you'll use the reader.getUnmapped<U>() method. This is the core mechanism for the 'Preserving Unmapped Triples within an Object' strategy, ensuring your Dart object fully captures its relevant subgraph. This method automatically collects all triples for the current subject (and its connected blank nodes) that were not consumed by other reader.require or reader.optional calls. These triples are then converted into the type U (e.g., RdfGraph) using an UnmappedTriplesMapper.

Important: The reader.getUnmapped<U>() call should typically be the last operation performed on the reader for a given subject. This ensures that all explicit property mappings have had the opportunity to consume their respective triples, leaving only the truly unmapped triples to be collected.

```dart
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_schema/schema.dart';
import 'package:rdf_core/rdf_core.dart'; 

class PersonMapper implements GlobalResourceMapper<Person> {
  @override
  IriTerm? get typeIri => SchemaPerson.classIri;

  @override
  Person fromRdfResource(IriTerm term, DeserializationContext context) {
    final reader = context.reader(term);

    final name = reader.require<String>(SchemaPerson.foafName);
    final age = reader.require<int>(SchemaPerson.foafAge);

    // Use getUnmapped to retrieve the remaining triples for this subject
    // This should generally be the last call on the reader.
    // The default RdfGraphUnmappedTriplesMapper is used here implicitly.
    final unmappedGraph = reader.getUnmapped<RdfGraph>();

    return Person(
      id: term.iri,
      name: name,
      age: age,
      unmappedGraph: unmappedGraph,
    );
  }

  // ... toRdfResource implementation will be covered next ...
}
```

### 3. Encoding - Using builder.addUnmapped in your GlobalResourceMapper

In your GlobalResourceMapper's toRdfResource method, use the builder.addUnmapped(value.unmappedGraph) method. This method is essential for the 'Preserving Unmapped Triples within an Object' strategy during serialization, ensuring all local triples are included in the output. This will take the RdfGraph from your model's unmappedGraph field and add its triples to the output.

```dart
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_schema/schema.dart';
import 'package:rdf_core/rdf_core.dart'; 

class PersonMapper implements GlobalResourceMapper<Person> {
  @override
  IriTerm? get typeIri => SchemaPerson.classIri;

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(Person value, SerializationContext context, {RdfSubject? parentSubject}) {
    final builder = context.resourceBuilder(const IriTerm(value.id))
      .addValue(SchemaPerson.foafName, value.name)
      .addValue(SchemaPerson.foafAge, value.age)

      // Add the unmapped graph's triples to the builder
      // The default RdfGraphUnmappedTriplesMapper is used here implicitly.
      .addUnmapped(value.unmappedGraph);

    // The build() method will now return all triples, including the unmapped ones.
    return builder.build();
  }

  // ... fromRdfResource implementation as covered above ...
}
```

## Strategy 2: Preserving the Entire Document
This strategy focuses on ensuring that the entire original RDF document can be round-tripped, even if it contains entities or triples not directly related to the primary object being mapped.

### 1. Decoding: Using rdfMapper.decodeObjectLossless
The decodeObjectLossless method allows you to process an entire RDF document and retrieve your primary mapped object along with all other triples that were not part of that object's subgraph. This method takes the full Turtle string and returns a Dart record (T object, RdfGraph remainderGraph).

The object (T) will contain all its explicitly mapped properties, and if its GlobalResourceMapper is implemented to use reader.getUnmapped, its unmappedGraph field will be populated with relevant triples.

The remainderGraph will contain all other triples from the original document that were not consumed by the mapping process for the object (i.e., not directly about the object or its connected blank nodes, and not explicitly mapped or captured in the unmappedGraph field).

```dart
// Example usage of decodeObjectLossless
final turtleInput = '''
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix ex: <http://example.org/> .

<http://example.org/person/1> a foaf:Person ;
  foaf:name "John Smith" ;
  foaf:age 30 ;
  ex:hasSecret _:secret .

_:secret ex:code "XYZ" ;
         ex:notes "Top secret info" .

<http://example.org/event/party> a ex:Event ;
  ex:location "Central Park" ;
  ex:date "2024-07-09" .
''';

final (person, remainderGraph) = rdfMapper.decodeObjectLossless<Person>(
  turtleInput,
  subject: const IriTerm('http://example.org/person/1'),
);

print('Decoded Person: $person');
print('Unmapped Triples within Person: ${person.unmappedGraph.triples.length}');
print('Remainder Graph Triples: ${remainderGraph.triples.length}');
```

### 2. Encoding: Using rdfMapper.encodeObjectLossless
To complete the lossless round-trip for the entire document, you need a way to combine the re-serialized primary object's graph with the remainderGraph obtained during decoding. The encodeObjectLossless method facilitates this by taking your mapped object and the remainderGraph, producing a single RdfGraph that represents the entire document.

```dart
// Conceptual method signature for encodeObjectLossless
// In lib/src/rdf_mapper.dart
class RdfMapper {
  // ... other methods ...

  /// Combines a mapped Dart object's graph with a remainder graph
  /// to form a complete RdfGraph representing the original document.
  ///
  /// The [object] is serialized using its registered GlobalResourceMapper,
  /// which should include its `unmappedGraph` field if implemented for lossless object mapping.
  /// The [remainderGraph] contains any other triples from the original document
  /// that were not part of the object's subgraph.
  RdfGraph encodeObjectLossless<T>((T object, RdfGraph remainderGraph));
```

## Advanced Use Cases: Custom UnmappedTriplesMapper
While rdf_mapper provides a default UnmappedTriplesMapper for RdfGraph, you might have a custom graph-like data structure (U) you prefer to use for storing unmapped triples. This might be due to a preference for a different graph library, specific performance requirements, or integration with existing data models.

### Define Your Custom UnmappedTriplesMapper
Implement the UnmappedTriplesMapper<U> interface, where U is your custom type.

```dart
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_core/rdf_core.dart'; // For Triple, IriTerm, etc.

// Assume you have a custom class like this:
class MyCustomGraphType {
  final Set<Triple> internalTriples;
  MyCustomGraphType(this.internalTriples);
  // Add methods as needed for your custom graph type
}

/// A custom implementation of UnmappedTriplesMapper for MyCustomGraphType.
class MyCustomUnmappedTriplesMapper implements UnmappedTriplesMapper<MyCustomGraphType> {
  @override
  MyCustomGraphType fromUnmappedTriples(Iterable<Triple> triples) {
    // Convert the raw triples into your custom graph type
    return MyCustomGraphType(triples.toSet());
  }

  @override
  Iterable<Triple> toUnmappedTriples(MyCustomGraphType value) {
    // Convert your custom graph type back into a set of triples
    // Ensure only triples relevant to the subject are returned if your custom type holds more.
    return value.internalTriples;
  }
}
```

### 6. Registering or Passing Your Custom Mapper
You have two options for using your custom UnmappedTriplesMapper:

a) Register Globally (Recommended for common types)
You can register your custom mapper with the RdfMapper's registry, similar to how GlobalResourceMappers are registered. This allows getUnmapped() and addUnmapped() to automatically discover and use your mapper when U is MyCustomGraphType. 

**Important**: UnmappedTriplesMapper registration only enables the type for unmapped triples handling through getUnmapped() and addUnmapped(). It does NOT automatically create resource mappers.

**Using the type as a resource**: If you need to use your custom unmapped type as a resource (e.g., as a property value that gets its own subject), you must register separate GlobalResourceMapper and LocalResourceMapper implementations. 

For RdfGraph, the library provides `RdfGraphGlobalResourceMapper` and `RdfGraphLocalResourceMapper`, but these have important limitations:
- The RdfGraph must have a clear single root subject for serialization to work correctly
- Multiple root subjects or disconnected graphs will cause serialization errors

This design ensures better control over how unmapped data types are used throughout your application.

```dart
// In your RdfMapper initialization
final rdfMapper = RdfMapper.withDefaultRegistry();
rdfMapper.registerMapper<MyCustomGraphType>(MyCustomUnmappedTriplesMapper());

// Now, in your GlobalResourceMapper, you can simply call:
// final unmappedData = reader.getUnmapped<MyCustomGraphType>();
// builder.addUnmapped(value.unmappedData);
```

b) Pass Directly (For specific, non-globally registered uses)
If you don't want to register it globally, or if you need to use a specific instance, you can pass it directly to the getUnmapped and addUnmapped methods:

```dart
// In your GlobalResourceMapper
final myCustomMapper = MyCustomUnmappedTriplesMapper(); // Create an instance

// Deserialization
final unmappedData = reader.getUnmapped<MyCustomGraphType>( unmappedTriplesDeserializer: myCustomMapper);

// Serialization
builder.addUnmapped(value.unmappedData, unmappedTriplesSerializer: myCustomMapper);
```

## Complete Example
Here's a full example demonstrating the lossless mapping process:
```dart
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_schema/schema.dart';
import 'package:rdf_core/rdf_core.dart'; 

// 1. Define the Model with unmappedGraph field
class Person {
  final String id;
  final String name;
  final int age;
  final RdfGraph unmappedGraph;

  Person({
    required this.id,
    required this.name,
    required this.age,
    RdfGraph? unmappedGraph,
  }) : unmappedGraph = unmappedGraph ?? RdfGraph();

  @override
  String toString() {
    return 'Person(id: $id, name: $name, age: $age, unmappedGraph: ${unmappedGraph.triples.length} triples)';
  }
}

// 2. Implement the GlobalResourceMapper with getUnmapped and addUnmapped
class PersonMapper implements GlobalResourceMapper<Person> {
  @override
  IriTerm? get typeIri => SchemaPerson.classIri;

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(Person value, SerializationContext context, {RdfSubject? parentSubject}) {
    final builder = context.resourceBuilder(const IriTerm(value.id))
      .addValue(SchemaPerson.foafName, value.name)
      .addValue(SchemaPerson.foafAge, value.age)

      // Add the unmapped graph's triples
      .addUnmapped(value.unmappedGraph); // Uses default RdfGraphUnmappedTriplesMapper

    return builder.build();
  }

  @override
  Person fromRdfResource(IriTerm term, DeserializationContext context) {
    final reader = context.reader(term);

    final name = reader.require<String>(SchemaPerson.foafName);
    final age = reader.require<int>(SchemaPerson.foafAge);

    // Get the unmapped triples as an RdfGraph
    final unmappedGraph = reader.getUnmapped<RdfGraph>(); // Uses default RdfGraphUnmappedTriplesMapper

    return Person(
      id: term.iri,
      name: name,
      age: age,
      unmappedGraph: unmappedGraph,
    );
  }
}

void main() {
  // Setup the RDF Mapper
  final rdfMapper = RdfMapper.withDefaultRegistry();
  rdfMapper.registerMapper<Person>(PersonMapper());

  final turtleInput = '''
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix ex: <http://example.org/> .
@prefix geo: <http://www.opengis.net/ont/geosparql#> .

<http://example.org/person/1> a foaf:Person ;
  foaf:name "John Smith" ;
  foaf:age 30 ;
  ex:hasSecret _:secret ;
  ex:favoriteColor "blue" . # This will be unmapped

_:secret ex:code "XYZ" ;
         ex:notes "Top secret info" ;
         geo:hasGeometry _:geom . # Nested blank node in unmapped part

_:geom geo:asWKT "POINT(10 20)" . # Further nested blank node

<http://example.org/event/party> a ex:Event ;
  ex:location "Central Park" ;
  ex:date "2024-07-09" . # This will be in the remainder graph

<http://example.org/organization/acme> ex:name "Acme Corp" . # Also in remainder
''';

  print('--- Original Turtle Input ---');
  print(turtleInput);

  // Decode the Person object in a lossless way
  final (person, remainderGraph) = rdfMapper.decodeObjectLossless<Person>(
    turtleInput,
    subject: const IriTerm('http://example.org/person/1'),
  );

  print('\n--- Decoded Person Object ---');
  print(person);

  print('\n--- Unmapped Triples within Person.unmappedGraph ---');
  for (final triple in person.unmappedGraph.triples) {
    print(triple);
  }

  print('\n--- Remainder Graph (Triples not about Person 1) ---');
  // Assuming rdfMapper.turtleEncoder.encode is available and synchronous
  final remainderTurtle = rdfMapper.turtleEncoder.encode(remainderGraph);
  print(remainderTurtle);

  // Re-serialize the Person object and combine with the remainder graph for full round-trip
  final fullRoundTripGraph = rdfMapper.encodeObjectLossless(person, remainderGraph);

  print('\n--- Full Document Re-serialized (Person + Remainder) ---');
  final fullRoundTripTurtle = rdfMapper.turtleEncoder.encode(fullRoundTripGraph);
  print(fullRoundTripTurtle);

  // Verify that the full round-trip is semantically equivalent to the original
  // (Note: Blank node identifiers might change, but the graph structure should be equivalent)
}
```

### Alternative Unmapped Types for Shallow Mapping

While `RdfGraph` is the recommended type for unmapped triples due to its deep mapping capabilities (automatically including connected blank nodes), rdf_mapper also provides two alternative types for unmapped triples that use shallow mapping:

#### `Map<RdfPredicate, List<RdfObject>>`
This type groups unmapped triples by their predicates, where predicates can be any `RdfPredicate` (actually can only be `IriTerm` according to RDF spec, so it is sort of an alias).

#### `Map<IriTerm, List<RdfObject>>`
This type is similar but clearly names the predicates as being `IriTerm`.

**Important: Shallow vs Deep Mapping**
- **RdfGraph (Deep)**: Automatically includes all triples connected to the subject through blank nodes, preserving the complete subgraph structure
- **Map Types (Shallow)**: Only include direct triples about the subject, **not** connected blank node triples

**Example of the difference:**
```dart
// Input RDF with nested blank nodes
final turtle = '''
<http://example.org/person> 
  foaf:name "John" ;
  ex:hasAddress _:addr .

_:addr 
  ex:street "123 Main St" ;
  ex:city "Anytown" .
''';

// With RdfGraph (deep=true) - includes blank node triples
final unmappedGraph = reader.getUnmapped<RdfGraph>();
// Contains: person -> hasAddress -> _:addr AND _:addr -> street/city -> values

// With Map<IriTerm, List<RdfObject>> (deep=false) - only direct triples
final unmappedMap = reader.getUnmapped<Map<IriTerm, List<RdfObject>>>();
// Contains: person -> hasAddress -> _:addr ONLY (no blank node content)
```

**Usage example:**
```dart
class PersonWithMapUnmapped {
  final String id;
  final String name;
  final Map<IriTerm, List<RdfObject>> unmappedData;

  PersonWithMapUnmapped({
    required this.id,
    required this.name,
    required this.age,
    Map<IriTerm, List<RdfObject>>? unmappedData,
  }) : unmappedData = unmappedData ?? {};
}

class PersonWithMapMapper implements GlobalResourceMapper<PersonWithMapUnmapped> {
  @override
  PersonWithMapUnmapped fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return PersonWithMapUnmapped(
      id: subject.iri,
      name: reader.require<String>(foafName),
      unmappedData: reader.getUnmapped<Map<IriTerm, List<RdfObject>>>(),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(PersonWithMapUnmapped value, SerializationContext context, {RdfSubject? parentSubject}) {
    return context.resourceBuilder(const IriTerm(value.id))
      .addValue(foafName, value.name)
      .addUnmapped(value.unmappedData)
      .build();
  }
}
```

These map types are automatically registered by default and can be useful when:
- You need a simpler data structure than `RdfGraph`
- You want to process unmapped data programmatically by predicate
- You're certain your unmapped data doesn't contain complex blank node structures
- You're working with flat RDF data where deep mapping isn't necessary

**Choose RdfGraph when you need complete subgraph preservation, and choose Map types when you need simple, shallow unmapped data handling.**

## Quick Start: Using Annotations (Recommended)

For the easiest implementation of lossless mapping, we highly recommend using the `rdf_mapper_annotations` and `rdf_mapper_generator` packages. This approach requires minimal code and automatically generates the necessary mapper implementation.

### 1. Add Dependencies

```sh
dart pub add rdf_mapper rdf_mapper_annotations
dart pub add rdf_mapper_generator build_runner --dev
```

### 2. Annotate Your Class

```dart
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

@RdfLocalResource()
class Data {
  
  @RdfUnmappedTriples()
  late final RdfGraph unmappedGraph; // Automatically captures all unmapped triples
}

// works for global resource as well
@RdfGlobalResource(SchemaPerson.classIri, IriStrategy())
class Person {
  @RdfIriPart
  late final String iri;

  @RdfUnmappedTriples()
  late final RdfGraph unmappedGraph; // Automatically captures all unmapped triples
}
```

### 3. Generate the Mapper

```bash
dart run build_runner build
```

That's it! The generator creates a complete mapper implementation that automatically handles unmapped triples. The generated mapper will:
- Map all your annotated properties to RDF
- Capture any unmapped triples in the `@RdfUnmappedTriples()` field
- Handle both serialization and deserialization automatically

### 4. Use with RdfMapper

```dart
final rdfMapper = RdfMapper.withDefaultRegistry();
// The generated mapper is automatically registered

// Lossless decoding - unmapped triples are captured in unmappedGraph
final person = rdfMapper.decodeObject<Data>(turtle);

// Lossless encoding - unmapped triples are included in output
final encodedTurtle = rdfMapper.encodeObject(person);
```

This annotation-based approach is much simpler than manual mapper implementation and handles all the complexity of lossless mapping automatically. For more control or custom logic, you can always fall back to the manual implementation described in the previous sections.

