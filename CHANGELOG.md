# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.4] - 2025-06-25

### Added

- Added `BaseRdfIriTermMapper<T>` abstract class for flexible IRI-based mapping using URI templates
- Added support for URI template placeholders (`{variable}` and `{+variable}` for full URI components)
- Added provider system for static placeholders in URI templates (e.g., configurable base URIs)
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
