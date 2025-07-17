# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.0] - 2025-07-17

### Added

- Added unified resource mapping interfaces that work with both IRI and BlankNode subjects:
  - Added `UnifiedResourceMapper<T>` for mappers that handle both global (IRI) and local (BlankNode) resources
  - Added `UnifiedResourceSerializer<T>` and `UnifiedResourceDeserializer<T>` for flexible resource handling
  - Enables creation of mappers that work seamlessly with any RDF subject type (used by collection mappers and RdfGraph mapping)
- Added comprehensive RDF list support:
  - Added `requireRdfList<T>()` and `optionalRdfList<T>()` convenience methods to ResourceReader
  - Added `addRdfList<T>()` method to ResourceBuilder for serializing lists as RDF list structures
  - Added `requireCollection<C, T>()` and `optionalCollection<C, T>()` methods to DeserializationService
- Added comprehensive RDF container support:
  - Added `requireRdfSeq<T>()`, `requireRdfBag<T>()`, and `requireRdfAlt<T>()` methods to ResourceReader
  - Added `optionalRdfSeq<T>()`, `optionalRdfBag<T>()`, and `optionalRdfAlt<T>()` methods to ResourceReader
  - Added `addRdfSeq<T>()`, `addRdfBag<T>()`, and `addRdfAlt<T>()` methods to ResourceBuilder
- Added multi-objects collection support as alternative to RDF lists:
  - Added `MultiObjectsSerializer<T>`, `MultiObjectsDeserializer<T>`, and `MultiObjectsMapper<T>` interfaces
  - Added `UnorderedItemsMapper<T>` and related classes for unordered collections using multiple RDF triples with same predicate
  - Enables choice between RDF list structures (ordered, structured) and multi-objects approach (unordered, flat)
- Added adapter classes for type transformation in mapping operations:
  - Added `AdaptingUnifiedResourceMapper<T, V>` for transforming between related types in unified resource mapping
  - Added `AdaptingMultiObjectsMapper<T, V>` for transforming between related types in multi-objects mapping
  - Enables reuse of existing mappers for similar types without duplicating mapping logic
- Added `InvalidRdfListStructureException` with detailed error analysis and suggestions for alternative approaches
- Added `CircularRdfListException` for detecting circular references in RDF list structures
- Added `UriIriMapper` for mapping Dart `Uri` objects to IRI terms
- Added cycle detection in RDF list processing to prevent infinite loops
- Added enhanced deserialization fallback to find deserializers by RDF datatype when type-based lookup fails
- Added support for 'application/n-triples' content type in serialization documentation

### Changed

- **Breaking Change**: Modified serialization API return types from `List<Triple>` to `Iterable<Triple>` for improved performance and memory efficiency:
  - `ResourceSerializer.toRdfResource()` methods now return `(RdfSubject, Iterable<Triple>)`
  - `SerializationService` methods (`value()`, `values()`, `resource()`, etc.) now return `Iterable<Triple>`
  - `SerializationContext.resource()` now returns `Iterable<Triple>`
  - `ResourceBuilder.build()` now returns `(S, Iterable<Triple>)`
  - Internal ResourceBuilder implementation optimized to avoid creating intermediate lists
- **Breaking Change**: Modified deserialization API return types from `List<Triple>` to `Iterable<Triple>`:
  - `DeserializationContext.getTriplesForSubject()` now returns `Iterable<Triple>`
  - Internal helper methods updated to work with iterables instead of lists
- **Breaking Change**: Updated RDF core dependency to `^0.9.5` (from `^0.9.4`) with corresponding API changes:
  - `RdfGraph.fromTriples()` constructor now used instead of `RdfGraph(triples: ...)`
- **Breaking Change**: Modified `SerializationContext.serialize()` return type from `(RdfTerm, Iterable<Triple>)` to `(Iterable<RdfTerm>, Iterable<Triple>)` to support multi-objects serialization
- **Breaking Change**: Simplified API by consolidating deserializer parameters - replaced multiple specific deserializer parameters with single `deserializer` parameter across:
  - `DeserializationService.require()`, `optional()`, `collect()`, `getValues()`, `getMap()` methods
  - `ResourceReader.require()`, `optional()`, `getValues()`, `getMap()` methods  
  - `ResourceBuilder.addValue()`, `addValueIfNotNull()` methods (consolidated serializer parameters similarly)
- **Breaking Change**: Enhanced `DeserializationContext.getTriplesForSubject()` with `trackRead` parameter (defaults to true)
- **Breaking Change**: Removed `readRdfList()` method from `DeserializationContext` (moved to collection infrastructure)
- **Breaking Change**: `LiteralTermDeserializer.datatype` property is now nullable (`IriTerm?` instead of `IriTerm`) - deserializers can specify a datatype to be used as fallback when exact Dart type mapping fails or target type is too broad (e.g., `Object`), or return `null` to only handle exact type matches
- Enhanced serialization context with unified `serialize()` method supporting all value types
- Enhanced collection deserialization to automatically detect and use multi-objects deserializers when available
- Updated main example to demonstrate RDF list usage with proper order preservation for book chapters
- Added `custom_collection_type_example.dart` demonstrating multiple RDF mapping strategies for the same custom collection type:
  - Strategy 1: RDF List (rdf:first/rdf:rest structure) for preserving order
  - Strategy 2: RDF Sequence (rdf:_1, rdf:_2, etc.) for numbered ordering
  - Strategy 3: Multiple triples for efficient unordered collections

## [0.8.8] - 2025-07-10

### Changed

- **Breaking Change**: Modified `UnmappedTriplesSerializer.toUnmappedTriples()` method signature to include `RdfSubject subject` parameter
- **Breaking Change**: Renamed `RdfGraphMapper` to `RdfGraphUnmappedTriplesMapper` for clarity
- **Breaking Change**: Removed automatic resource mapper registration when registering `UnmappedTriplesMapper` implementations
- **Breaking Change**: Removed `includeBlankNodes` parameter from `ResourceReader.getUnmapped()` and `DeserializationService.getUnmapped()` methods
- **Breaking Change**: Modified `RdfGraphUnmappedTriplesMapper` constructor to accept optional `deep` parameter (defaults to `true`)
- Separated UnmappedTriplesMapper registration from resource mapping - UnmappedTriplesMapper now only handles unmapped triples, not resource serialization

*Note* even though there are breaking changes we stick to increasing the patch version only, because
the interfaces that were changed were added in yesterdays release and are very specific, so it is very
unlikely to really affect any users.

### Added

- Added `RdfGraphGlobalResourceMapper` and `RdfGraphLocalResourceMapper` for explicit RdfGraph resource mapping
- Added improved root subject detection algorithm for RdfGraph with enhanced cycle handling and heuristics
- Added `deep` property to `UnmappedTriplesDeserializer` interface to control blank node collection behavior
- Added comprehensive test suite for `_getSingleRootSubject` implementation covering edge cases and complex scenarios
- Added extensive documentation about the distinction between unmapped triples mapping and resource mapping

### Fixed

- Fixed RdfGraph root subject detection to properly handle cyclic graphs with a single identifiable root
- Fixed error messages to be more specific about the type of root subject detection failure

### Enhanced

- Enhanced lossless mapping documentation to clarify the relationship between UnmappedTriplesMapper and resource mappers
- Enhanced RdfGraph resource mappers to require single root subjects, ensuring clear graph structure
- Enhanced error handling in root subject detection with detailed diagnostic messages

### Technical Details

- The `toUnmappedTriples` method now receives the subject parameter to enable proper context-aware serialization
- RdfGraph resource mappers now validate that the graph has a single unambiguous root subject before serialization
- The `deep` property on deserializers controls whether blank nodes are recursively followed when collecting unmapped triples
- The root subject detection algorithm uses heuristics to handle common cyclic patterns while maintaining strict validation

## [0.8.7] - 2025-07-09

### Added

- **Lossless RDF Mapping**: Complete framework for preserving all RDF data during serialization/deserialization cycles
  - Added `CompletenessMode` enum with `strict`, `lenient`, `warnOnly`, and `infoOnly` modes for handling incomplete deserialization
  - Added `IncompleteDeserializationException` with detailed error reporting including unmapped subjects, types, and remaining triple counts
  - Added support for preserving unmapped triples within objects using `reader.getUnmapped()` and `builder.addUnmapped()` methods
  - Added lossless codecs for both single objects and collections: `RdfObjectLosslessCodec<T>` and `RdfObjectsLosslessCodec<T>`
  - Added string-based lossless codecs: `RdfObjectLosslessStringCodec<T>` and `RdfObjectsLosslessStringCodec<T>`

- **New RdfMapper Convenience Methods**: High-level API methods for lossless operations
  - Added `decodeObjectLossless<T>()` method for decoding single objects with remainder graph preservation
  - Added `encodeObjectLossless<T>()` method for encoding single objects with remainder graph combination
  - Added `decodeObjectsLossless<T>()` method for decoding multiple objects with remainder graph preservation  
  - Added `encodeObjectsLossless<T>()` method for encoding multiple objects with remainder graph combination

- **Enhanced Graph Operations**: Extended graph-based codec support
  - Added `objectLosslessCodec<T>()` method to `GraphOperations` for graph-based lossless single object codecs
  - Added `objectsLosslessCodec<T>()` method to `GraphOperations` for graph-based lossless multiple objects codecs

- **Comprehensive Documentation**: Complete lossless mapping documentation
  - Added detailed `LOSSLESS_MAPPING.md` documentation covering both unmapped triples preservation and complete document preservation strategies
  - Added practical examples demonstrating round-trip consistency and data integrity preservation
  - Added guidance on combining both lossless mapping strategies for comprehensive data preservation

### Enhanced

- Enhanced `RdfMapper` API with comprehensive lossless mapping support across all content types (Turtle, JSON-LD, N-Triples, etc.)
- Enhanced error handling with detailed information about incomplete deserialization scenarios
- Enhanced existing `decodeObject()` and `decodeObjects()` methods with `CompletenessMode` support for backward-compatible lossless behavior
- Enhanced test coverage with comprehensive lossless mapping test suites covering edge cases, error scenarios, and round-trip fidelity

### Technical Details

- All lossless codecs return tuples `(T, RdfGraph)` or `(Iterable<T>, RdfGraph)` where the second element contains unmapped/remainder triples
- Lossless methods preserve complete RDF document integrity, enabling perfect round-trip serialization
- CompletenessMode integration allows gradual migration from strict to lenient deserialization behavior
- Full backward compatibility maintained - existing code continues to work without changes

## [0.8.6] - 2025-07-03

### Fixed

- Fixed incorrect generic type parameters in `ResourceBuilder.addValues()` method serializer parameters (changed from `<S>` to `<V>` to match the value type)

## [0.8.5] - 2025-06-26

### Added

- Support all three serializer types (`literalTermSerializer`, `iriTermSerializer`, and `resourceSerializer`) in `ResourceBuilder.addMap()`

### Enhanced

- Enhanced documentation for `ResourceBuilder.addMap()` method to clarify that it supports all three serializer types (`literalTermSerializer`, `iriTermSerializer`, and `resourceSerializer`) with comprehensive examples for each approach

## [0.8.4] - 2025-06-25

### Added

- Added `BaseRdfIriTermMapper<T>` abstract class for flexible IRI-based mapping using URI templates
- Added support for URI template placeholders (`{variable}` and `{+variable}` for full URI components)
- Added `resolvePlaceholder()` method for providing placeholder values, enabling const constructors for simple cases
- Added comprehensive enum mapping example (`enum_mapping_example.dart`) demonstrating both literal and IRI-based approaches
- Added full test coverage for `BaseRdfIriTermMapper` including template validation, provider requirements, and roundtrip scenarios

### Enhanced

- Enhanced enum mapping capabilities with two distinct approaches:
  - Literal-based mapping using `BaseRdfLiteralTermMapper<T>` for simple string representations
  - IRI-based mapping using `BaseRdfIriTermMapper<T>` for semantic URI representations
- Improved documentation with practical examples for enum property mapping in RDF models

## [0.8.3] - 2025-06-24

### Added

- Added `DatatypeOverrideMapper<T>` class for custom RDF datatype assignment to literal values
- Added `LanguageOverrideMapper<T>` class for language tag assignment to literal values  
- Added comprehensive unit tests for both override mappers covering construction, serialization, deserialization, error handling, and roundtrip scenarios
- Added critical documentation and warnings about registry usage to prevent infinite recursion
- Added examples for both annotation-based usage (primary) and manual usage (advanced) scenarios


## [0.8.2] - 2025-06-24

### Removed
- Unused imports

## [0.8.1] - 2025-06-24

### Added

- Added `IriFullMapper` class for complete IRI mapping with full URI preservation
- Added `DelegatingRdfLiteralTermMapper` abstract class for creating custom wrapper types with different datatypes
- Added comprehensive test coverage for `DelegatingRdfLiteralTermMapper` including edge cases and roundtrip consistency
- Added extensive documentation on datatype handling and best practices in README and class documentation
- Added detailed examples for custom wrapper types, global registration, and local scope solutions
- Added comprehensive integration tests for global mapper registration scenarios, including verification of the documented patterns

### Changed

- Enhanced `DeserializerDatatypeMismatchException` error messages with improved formatting and more comprehensive solution guidance
- Updated documentation to mention simpler `LiteralMapping.withType()` option alongside existing `LiteralMapping.mapperInstance()` for annotations library
- Reorganized exception message solutions to group local-scope options (annotations vs manual) for better clarity
- Made standard mapper classes (`BoolMapper`, etc.) final for better performance and to prevent inheritance
- Significantly improved documentation for `BaseRdfLiteralTermMapper`, `DelegatingRdfLiteralTermMapper`, and standard mappers
- Enhanced main library documentation with datatype handling concepts and examples

### Fixed

- Improved exception message formatting to be more educational and provide clearer migration paths
- Enhanced error messages to include both annotation-based and manual custom wrapper type solutions

## [0.8.0] - 2025-06-20

### Added

- Added comprehensive datatype validation for literal term deserializers with helpful error messages
- Added `DeserializerDatatypeMismatchException` that provides detailed guidance on resolving datatype mismatches
- Added extensive test coverage for datatype mismatch scenarios and bypass functionality

### Changed

- **Breaking Change**: Added `bypassDatatypeCheck` parameter to `LiteralTermDeserializer.fromRdfTerm()` method signature
- **Breaking Change**: Removed individual serializer and deserializer exports for standard types (BoolSerializer, BoolDeserializer, DoubleSerializer, DoubleDeserializer, IntSerializer, IntDeserializer, StringSerializer, StringDeserializer, DateTimeSerializer, DateTimeDeserializer) - use unified mapper classes instead (BoolMapper, DoubleMapper, IntMapper, StringMapper, DateTimeMapper)
- Enhanced exception messages to provide educational context about roundtrip consistency and multiple solution approaches
- Made common deserializers and mappers instantiable with `const` keyword for better performance
- Updated `DeserializationContext.fromLiteralTerm()` method signature to include `bypassDatatypeCheck` parameter

### Fixed

- Datatype strictness now properly enforces roundtrip consistency to prevent data corruption in RDF stores
- Literal term mappers now correctly validate expected vs actual datatypes during deserialization

## [0.7.1] - 2025-06-07

### Changed

- Deserialize single instance now tries hard to find the correct deserializer based on the generic type parameter instead of only relying on the type from the graph.

## [0.7.0] - 2025-05-23

### Changed

- **Breaking Change** Simplified `ResourceBuilder` and related classes to have only `addValue`, `addValues`, `addValuesFromSource`, `addValueIfNotNull` instead of duplicating those for iri/literal/resource

## [0.6.2] - 2025-05-20

### Changed

- **Breaking Change** `childNode` -> `childResource` and related.
- **Breaking Change** `fromRdfNode` -> `fromRdfResource` and `toRdfNode` -> `toRdfResource`. Hopefully this was the last wrong usage of the term "node"

## [0.6.1] - 2025-05-20

### Changed

- **Breaking Change** `NodeSerializer` -> `ResourceSerializer`

## [0.6.0] - 2025-05-20

### Changed

- Relaxed Dart SDK requirement from 3.7 to 3.6
- **Breaking Change** Renamed `BlankNodeDeserializer` to `LocalResourceDeserializer` and `IriNodeDeserializer` to `GlobalResourceDeserializer` as well as `BlankNodeSerializer` to ` LocalResourceSerializer` and `IriNodeSerializer` to `GlobalResourceSerializer`
- **Breaking Change** Renamed `getList` and `literalList` etc. to make it clearer that those are actually not mapped to dart Lists, but merely to multi-value predicates (e.g. mutliple triples with the same subject and predicate). Also changed the type of those from List to Iterable.

## [0.5.0] - 2025-05-20

### Changed

- **Breaking Change**: Renamed `IriNodeMapper` to `GlobalResourceMapper` and `BlankNodeMapper` to `LocalResourceMapper` for more clarity, since those do not map the identifier (aka Node) but the entire resource (aka the collection of triples with the same subject). Likewise, renamed `NodeBuilder` to `ResourceBuilder` and `NodeReader` to `ResourceReader`.

- **Breaking Change**: Renamed `ResourceReader.get` to  `ResourceReader.optional` and `ResourceReader.getMany` to `ResourceReader.collect`.

### Added

- Improved documentation for resource mapping concepts
- Enhanced type safety for resource mappers
- Added `fromLiteralTerm` for deserialization context, `toLiteralTerm` for serialization context

### Fixed

- Fixed inconsistencies in API documentation
- Improved error handling for invalid resource mappings

## [0.4.0] - 2025-05-15

### Added

- Comprehensive Codec API for standardized conversion between Dart objects and RDF graphs
  - Added `RdfMapperCodec`, `RdfMapperEncoder`, and `RdfMapperDecoder` base classes
  - Added specific implementations for single objects and collections
  - Added string-based codec variants for direct serialization to RDF formats

### Changed

- Updated rdf_core dependency to 0.9.2
- Updated rdf_vocabularies to 0.3.0
- Refactored API for better consistency with Dart's standard library patterns
  - Renamed `serialize`/`deserialize` methods to `encodeObject`/`decodeObject` in `RdfMapper` and `GraphOperations`
  - Added collection variants with `encodeObjects`/`decodeObjects`

## [0.3.0] - 2025-05-08

### Changed

- Updated rdf_core to 0.8.1, which is a breaking change again.

## [0.2.0] - 2025-05-08

### Changed

- Updated rdf_core to 0.7.6, made use of new rdf_vocabularies project

## [0.1.6] - 2025-04-30

### Fixed

- Improved release tool process reliability
  - Fixed issue with git commits for documentation files
  - Enhanced output capture for better detection of changed files
  - Improved version string consistency in documentation files
- Fixed documentation version references to ensure consistency across all files

## [0.1.5] - 2025-04-30

### Fixed

- Enhanced release tool to properly handle development versions
  - Automatically removes `-dev` suffix during release process
  - Uses base version number for changelog validation
  - Ensures proper version handling throughout the entire release process
- Improved git integration in release tool
  - Added more robust handling of documentation files
  - Fixed issue with new API documentation files not being properly tracked

## [0.1.4] - 2025-04-30

### Fixed

- Fixed `deserializeAll` to properly handle child nodes with dynamically provided mappers
  - Root nodes still require globally registered mappers
  - Child nodes can now use context-dependent mappers provided by parent objects
  - Improves support for complex object hierarchies with context-dependent relationships

## [0.1.3] - 2025-04-30

### Added

- Completed NodeBuilder API with missing methods from SerializationService:
  - `constant()` - For direct use of pre-created RDF terms
  - `literals()` - For extracting multiple literal values from a source object
  - `iris()` - For extracting multiple IRI values from a source object
  - `childResources()` - For extracting multiple child nodes from a source object
- Enhanced documentation for all NodeBuilder methods

## [0.1.2] - 2025-04-30

### Added

- Added optional `documentUrl` parameter to RDF parsing methods for resolving relative references in RDF documents
- Enhanced API documentation for public methods

## [0.1.1] - 2025-04-30

### Added

- Support for constant namespace construction, enabling compile-time safety and improved performance

### Changed

- Updated roadmap with new planned features and milestones
- Improved code formatting for better readability and consistency

## [0.1.0] - 2025-04-29

### Added

- Initial release with core functionality for bidirectional mapping between Dart objects and RDF
- Support for IriNodeMapper, BlankNodeMapper, IriTermMapper, and LiteralTermMapper
- SerializationContext and DeserializationContext for handling RDF conversions
- Fluent NodeBuilder and NodeReader APIs
- Default registry with built-in mappers for common Dart types (String, int, double, bool, DateTime, Uri)
- String-based API for RDF format serialization and deserialization
- Graph-based API for direct RDF graph manipulation
- Comprehensive error handling with specific exception types
- Extension methods for collection handling
- Comprehensive documentation and examples
