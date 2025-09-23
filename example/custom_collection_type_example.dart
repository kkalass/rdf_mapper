/// Example: Custom collection type with multiple RDF mapping strategies.
///
/// This example demonstrates how to create mappers for custom Dart collection types
/// that can be serialized to different RDF structures depending on your needs.
///
/// The same custom type (`ImmutableList<T>`) can be mapped to:
/// 1. **rdf:List** - Ordered linked list structure (rdf:first/rdf:rest/rdf:nil)
/// 2. **rdf:Seq** - Ordered sequence with numbered properties (_1, _2, _3...)
/// 3. **Unordered items** - Multiple separate triples (default behavior)
///
/// This flexibility allows you to choose the most appropriate RDF representation
/// based on your specific use case and RDF consumption requirements.
library;

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart' show Rdf;

void main() {
  print('=== Custom Collection Type RDF Mapping Example ===\n');

  // Create mapper with default registry and register our custom mappers
  final rdf = RdfMapper.withDefaultRegistry()
    ..registerMapper<Library>(LibraryMapper())
    ..registerMapper<Person>(PersonMapper());

  // Create a library demonstrating different collection mapping strategies
  final library = Library(
    id: 'central-library',
    name: 'Central City Library',
    // Strategy 1: Ordered list of collaborators (uses rdf:List)
    collaborators: ImmutableList(['Alice Johnson', 'Bob Smith', 'Carol White']),
    // Strategy 2: Categorized tags (uses rdf:Seq for clear ordering)
    tags: ImmutableList(['education', 'research', 'community', 'digital']),
    // Strategy 3: Simple member list (uses multiple triples for efficiency)
    members: ImmutableList(['John Doe', 'Jane Smith', 'Mike Wilson']),
    director: Person(
      id: 'director-001',
      name: 'Dr. Sarah Thompson',
      email: 'sarah.thompson@library.org',
    ),
  );

  print('Original Library:');
  print('Name: ${library.name}');
  print('Collaborators: ${library.collaborators.toList()}');
  print('Tags: ${library.tags.toList()}');
  print('Members: ${library.members.toList()}');
  print('Director: ${library.director.name}');
  print('');

  // Serialize to RDF Turtle format
  final turtle =
      rdf.encodeObject(library, baseUri: 'http://example.org/library/');
  print('=== RDF Turtle Representation ===');
  print(turtle);
  print('');

  // Deserialize back to verify round-trip consistency
  final deserializedLibrary = rdf.decodeObject<Library>(turtle);
  print('=== Deserialized Library ===');
  print('Name: ${deserializedLibrary.name}');
  print('Collaborators: ${deserializedLibrary.collaborators.toList()}');
  print('Tags: ${deserializedLibrary.tags.toList()}');
  print('Members: ${deserializedLibrary.members.toList()}');
  print('Director: ${deserializedLibrary.director.name}');
  print('');

  // Demonstrate the different RDF structures created
  _demonstrateRdfStructures(rdf);
}

/// Demonstrates how each collection strategy creates different RDF structures
void _demonstrateRdfStructures(RdfMapper rdf) {
  print('=== RDF Structure Comparison ===\n');

  // Show individual collection mappings
  final collaborators = ImmutableList(['Alice', 'Bob', 'Carol']);
  final tags = ImmutableList(['education', 'research', 'community']);
  final members = ImmutableList(['John', 'Jane', 'Mike']);

  // Which output format to use - turtle adds so much syntactic sugar
  // that the actual RDF structure is not visible, so we use N-Triples for clarity
  final contentType = 'application/n-triples';

  // Strategy 1: RDF List structure
  print('1. RDF List Structure (for collaborators):');
  final collaboratorsNTriples = rdf.encodeObject(RdfListDemo(collaborators),
      contentType: contentType,
      register: (registry) => registry.registerMapper(RdfListDemoMapper()));
  print(collaboratorsNTriples);

  // Strategy 2: RDF Sequence structure
  print('2. RDF Sequence Structure (for tags):');
  final tagsNTriples = rdf.encodeObject(RdfSeqDemo(tags),
      contentType: contentType,
      register: (registry) => registry.registerMapper(RdfSeqDemoMapper()));
  print(tagsNTriples);

  // Strategy 3: Multiple triples structure
  print('3. Multiple Triples Structure (for members):');
  final membersNTriples = rdf.encodeObject(UnorderedItemsDemo(members),
      contentType: contentType,
      register: (registry) =>
          registry.registerMapper(UnorderedItemsDemoMapper()));
  print(membersNTriples);

  print('Notice how each strategy creates a different RDF structure!');
}

// =============================================================================
// DOMAIN MODEL
// =============================================================================

/// Example vocabulary for collection demonstrations
class CollectionVocab {
  static const _base = 'http://example.org/vocab#';

  static const Library = const IriTerm(_base + 'Library');
  static const tags = const IriTerm(_base + 'tags');
  static const collaborators = const IriTerm(_base + 'collaborators');
  static const members = const IriTerm(_base + 'members');
  static const director = const IriTerm(_base + 'director');
}

/// Library demonstrating different RDF mapping strategies for the same custom collection type.
class Library {
  final String id;
  final String name;

  /// Strategy 1: Map to rdf:List (ordered linked list structure)
  /// RDF: `<list> rdf:first "item1" ; rdf:rest <next>` .
  final ImmutableList<String> collaborators;

  /// Strategy 2: Map to rdf:Seq (ordered sequence with numbered properties)
  /// RDF: `<seq> rdf:type rdf:Seq ; rdf:_1 "item1" ; rdf:_2 "item2"` .
  final ImmutableList<String> tags;

  /// Strategy 3: Map to unordered items (multiple separate triples)
  /// RDF: `<subject> <predicate> "item1" . <subject> <predicate> "item2"` .
  final ImmutableList<String> members;

  final Person director;

  Library({
    required this.id,
    required this.name,
    required this.collaborators,
    required this.tags,
    required this.members,
    required this.director,
  });
}

class RdfListDemo {
  final ImmutableList<String> items;

  RdfListDemo(this.items);
}

class RdfSeqDemo {
  final ImmutableList<String> items;

  RdfSeqDemo(this.items);
}

class UnorderedItemsDemo {
  final ImmutableList<String> items;

  UnorderedItemsDemo(this.items);
}

/// Person entity for demonstration
class Person {
  final String id;
  final String name;
  final String email;

  Person({
    required this.id,
    required this.name,
    required this.email,
  });
}

// =============================================================================
// MAPPERS
// =============================================================================
final IriTerm demoPredicate = const IriTerm('http://example.org/items');

class RdfListDemoMapper implements LocalResourceMapper<RdfListDemo> {
  @override
  RdfListDemo fromRdfResource(
      BlankNodeTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return RdfListDemo(
      reader.requireCollection(demoPredicate, ImmutableListMapperRdfList.new),
    );
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
      RdfListDemo demo, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final subject = BlankNodeTerm();
    return context
        .resourceBuilder(subject)
        .addCollection(
            demoPredicate, demo.items, ImmutableListMapperRdfList.new)
        .build();
  }

  @override
  IriTerm? get typeIri => null;
}

class RdfSeqDemoMapper implements LocalResourceMapper<RdfSeqDemo> {
  @override
  RdfSeqDemo fromRdfResource(
      BlankNodeTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return RdfSeqDemo(
      reader.requireCollection(demoPredicate, ImmutableListMapperRdfSeq.new),
    );
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
      RdfSeqDemo demo, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final subject = BlankNodeTerm();
    return context
        .resourceBuilder(subject)
        .addCollection(demoPredicate, demo.items, ImmutableListMapperRdfSeq.new)
        .build();
  }

  @override
  IriTerm? get typeIri => null;
}

class UnorderedItemsDemoMapper
    implements LocalResourceMapper<UnorderedItemsDemo> {
  @override
  UnorderedItemsDemo fromRdfResource(
      BlankNodeTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return UnorderedItemsDemo(
      reader.requireCollection(
          demoPredicate, ImmutableListMapperUnorderedItems.new),
    );
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
      UnorderedItemsDemo demo, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final subject = BlankNodeTerm();
    return context
        .resourceBuilder(subject)
        .addCollection(
            demoPredicate, demo.items, ImmutableListMapperUnorderedItems.new)
        .build();
  }

  @override
  IriTerm? get typeIri => null;
}

/// Mapper for Library that uses different collection strategies
class LibraryMapper implements GlobalResourceMapper<Library> {
  @override
  final IriTerm typeIri = CollectionVocab.Library;

  @override
  Library fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Library(
      id: _extractIdFromIri(subject.value),
      name: reader.require<String>(const IriTerm('http://schema.org/name')),
      // Strategy 1: Use RDF List for collaborators (preserves order)
      collaborators: reader
          .requireImmutableListRdfList<String>(CollectionVocab.collaborators),
      // Strategy 2: Use RDF Sequence for tags (numbered ordering)
      tags: reader.requireImmutableListRdfSeq<String>(CollectionVocab.tags),
      // Strategy 3: Use multiple triples for members (efficient, unordered)
      members:
          reader.requireImmutableListUnordered<String>(CollectionVocab.members),
      director: reader.require<Person>(CollectionVocab.director),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      Library library, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final subject =
        context.createIriTerm('http://example.org/library/${library.id}');
    return context
        .resourceBuilder(subject)
        .addValue(const IriTerm('http://schema.org/name'), library.name)
        // Strategy 1: Add as RDF List
        .addImmutableListRdfList<String>(
            CollectionVocab.collaborators, library.collaborators)
        // Strategy 2: Add as RDF Sequence
        .addImmutableListRdfSeq<String>(CollectionVocab.tags, library.tags)
        // Strategy 3: Add as multiple triples
        .addImmutableListUnordered<String>(
            CollectionVocab.members, library.members)
        .addValue<Person>(CollectionVocab.director, library.director)
        .build();
  }

  /// Extracts the identifier from a full IRI
  String _extractIdFromIri(String iri) {
    const prefix = 'http://example.org/library/';
    if (!iri.startsWith(prefix)) {
      throw ArgumentError('Invalid Library IRI format: $iri');
    }
    return iri.substring(prefix.length);
  }
}

/// Simple mapper for Person
class PersonMapper implements GlobalResourceMapper<Person> {
  @override
  final IriTerm typeIri = const IriTerm('http://schema.org/Person');

  @override
  Person fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Person(
      id: _extractIdFromIri(subject.value),
      name: reader.require<String>(const IriTerm('http://schema.org/name')),
      email: reader.require<String>(const IriTerm('http://schema.org/email')),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      Person person, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final subject =
        context.createIriTerm('http://example.org/person/${person.id}');
    return context
        .resourceBuilder(subject)
        .addValue(const IriTerm('http://schema.org/name'), person.name)
        .addValue(const IriTerm('http://schema.org/email'), person.email)
        .build();
  }

  /// Extracts the identifier from a full IRI
  String _extractIdFromIri(String iri) {
    const prefix = 'http://example.org/person/';
    if (!iri.startsWith(prefix)) {
      throw ArgumentError('Invalid Person IRI format: $iri');
    }
    return iri.substring(prefix.length);
  }
}

// =============================================================================
// EXTENSION METHODS FOR CONVENIENCE
// =============================================================================

/// Extension methods for ResourceReader to add ImmutableList support
extension ImmutableListReaderExtensions on ResourceReader {
  /// Read a required ImmutableList using RDF List strategy
  ImmutableList<T> requireImmutableListRdfList<T>(RdfPredicate predicate) =>
      requireCollection<ImmutableList<T>, T>(
        predicate,
        ImmutableListMapperRdfList<T>.new,
      );

  /// Read an optional ImmutableList using RDF List strategy
  ImmutableList<T>? optionalImmutableListRdfList<T>(RdfPredicate predicate) =>
      optionalCollection<ImmutableList<T>, T>(
        predicate,
        ImmutableListMapperRdfList<T>.new,
      );

  /// Read a required ImmutableList using RDF Sequence strategy
  ImmutableList<T> requireImmutableListRdfSeq<T>(RdfPredicate predicate) =>
      requireCollection<ImmutableList<T>, T>(
        predicate,
        ImmutableListMapperRdfSeq<T>.new,
      );

  /// Read an optional ImmutableList using RDF Sequence strategy
  ImmutableList<T>? optionalImmutableListRdfSeq<T>(RdfPredicate predicate) =>
      optionalCollection<ImmutableList<T>, T>(
        predicate,
        ImmutableListMapperRdfSeq<T>.new,
      );

  /// Read a required ImmutableList using unordered items strategy
  ImmutableList<T> requireImmutableListUnordered<T>(RdfPredicate predicate) =>
      requireCollection<ImmutableList<T>, T>(
          predicate, ImmutableListMapperUnorderedItems<T>.new);

  /// Read an optional ImmutableList using unordered items strategy
  ImmutableList<T>? optionalImmutableListUnordered<T>(RdfPredicate predicate) =>
      optionalCollection<ImmutableList<T>, T>(
        predicate,
        ImmutableListMapperUnorderedItems<T>.new,
      );
}

/// Extension methods for ResourceBuilder to add ImmutableList support
extension ImmutableListBuilderExtensions<S extends RdfSubject>
    on ResourceBuilder<S> {
  /// Add an ImmutableList using RDF List strategy
  ResourceBuilder<S> addImmutableListRdfList<T>(
          RdfPredicate predicate, ImmutableList<T> collection) =>
      addCollection<ImmutableList<T>, T>(
        predicate,
        collection,
        ImmutableListMapperRdfList<T>.new,
      );

  /// Add an ImmutableList using RDF Sequence strategy
  ResourceBuilder<S> addImmutableListRdfSeq<T>(
          RdfPredicate predicate, ImmutableList<T> collection) =>
      addCollection<ImmutableList<T>, T>(
        predicate,
        collection,
        ImmutableListMapperRdfSeq<T>.new,
      );

  /// Add an ImmutableList using unordered items strategy
  ResourceBuilder<S> addImmutableListUnordered<T>(
          RdfPredicate predicate, ImmutableList<T> collection) =>
      addCollection<ImmutableList<T>, T>(
        predicate,
        collection,
        ImmutableListMapperUnorderedItems<T>.new,
      );
}

/// Custom immutable collection type.
///
/// This example collection type demonstrates how any custom Dart collection
/// can be mapped to RDF using different strategies. The key is implementing
/// the appropriate mixins and mapper interfaces.
class ImmutableList<T> with Iterable<T> {
  final List<T> _items;

  ImmutableList(this._items);

  @override
  Iterator<T> get iterator => _items.iterator;

  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;
  T operator [](int index) => _items[index];
}

// =============================================================================
// MAPPING STRATEGY 1: RDF LIST (rdf:first/rdf:rest/rdf:nil)
// =============================================================================

/// Maps `ImmutableList<T>` to rdf:List structure.
///
/// Creates a linked list structure using rdf:first/rdf:rest/rdf:nil.
/// Best for: Preserving order when RDF consumers understand rdf:List.
class ImmutableListMapperRdfList<T>
    with RdfListSerializerMixin<T>, RdfListDeserializerMixin<T>
    implements UnifiedResourceMapper<ImmutableList<T>> {
  final Serializer<T>? _itemSerializer;
  final Deserializer<T>? _itemDeserializer;

  ImmutableListMapperRdfList(
      {Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})
      : _itemSerializer = itemSerializer,
        _itemDeserializer = itemDeserializer;

  @override
  (RdfSubject, Iterable<Triple>) toRdfResource(
      ImmutableList<T> list, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final (subject, triples) = buildRdfList(list, context, _itemSerializer,
        parentSubject: parentSubject);
    return (subject, triples.toList());
  }

  @override
  ImmutableList<T> fromRdfResource(
      RdfSubject subject, DeserializationContext context) {
    if (subject != Rdf.nil && subject is! BlankNodeTerm) {
      throw ArgumentError('Expected BlankNodeTerm, got ${subject.runtimeType}');
    }
    final list = readRdfList(subject, context, _itemDeserializer).toList();
    return ImmutableList<T>(list);
  }
}

// =============================================================================
// MAPPING STRATEGY 2: RDF SEQUENCE (rdf:_1, rdf:_2, rdf:_3...)
// =============================================================================

/// Maps `ImmutableList<T>` to rdf:Seq structure.
///
/// Creates numbered properties (_1, _2, _3...) for ordered items.
/// Best for: When you need clear ordering with simple property access.
class ImmutableListMapperRdfSeq<T>
    with RdfContainerSerializerMixin<T>, RdfContainerDeserializerMixin<T>
    implements UnifiedResourceMapper<ImmutableList<T>> {
  final Serializer<T>? _itemSerializer;
  final Deserializer<T>? _itemDeserializer;

  @override
  final IriTerm typeIri = Rdf.Seq;

  ImmutableListMapperRdfSeq(
      {Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})
      : _itemSerializer = itemSerializer,
        _itemDeserializer = itemDeserializer;

  @override
  (RdfSubject, Iterable<Triple>) toRdfResource(
      ImmutableList<T> list, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final (subject, triples) = buildRdfContainer(
        BlankNodeTerm(), list, context, typeIri, _itemSerializer,
        parentSubject: parentSubject);
    return (subject, triples.toList());
  }

  @override
  ImmutableList<T> fromRdfResource(
      RdfSubject subject, DeserializationContext context) {
    if (subject is! BlankNodeTerm) {
      throw ArgumentError('Expected BlankNodeTerm, got ${subject.runtimeType}');
    }
    final list =
        readRdfContainer(subject, context, typeIri, _itemDeserializer).toList();
    return ImmutableList<T>(list);
  }
}

// =============================================================================
// MAPPING STRATEGY 3: UNORDERED ITEMS (multiple separate triples)
// =============================================================================

/// Maps `ImmutableList<T>` to multiple separate triples.
///
/// Each item becomes a separate triple with the same predicate.
/// Best for: Maximum compatibility, when order doesn't matter.
class ImmutableListMapperUnorderedItems<T>
    with UnorderedItemsSerializerMixin<T>, UnorderedItemsDeserializerMixin<T>
    implements MultiObjectsMapper<ImmutableList<T>> {
  final Deserializer<T>? _itemDeserializer;
  final Serializer<T>? _itemSerializer;

  ImmutableListMapperUnorderedItems(
      {Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})
      : _itemDeserializer = itemDeserializer,
        _itemSerializer = itemSerializer;

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          ImmutableList<T> value, SerializationContext context) =>
      buildRdfObjects(value, context, _itemSerializer);

  @override
  ImmutableList<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      ImmutableList<T>(
          readRdfObjects(objects, context, _itemDeserializer).toList());
}
