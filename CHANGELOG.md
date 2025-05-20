# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.1] - 2025-05-22

### Changed

- **Breaking Change** `NodeSerializer` -> `ResourceSerializer`

## [0.6.0] - 2025-05-22

### Changed

- Relaxed Dart SDK requirement from 3.7 to 3.6
- **Breaking Change** Renamed `BlankNodeDeserializer` to `LocalResourceDeserializer` and `IriNodeDeserializer` to `GlobalResourceDeserializer` as well as `BlankNodeSerializer` to ` LocalResourceSerializer` and `GlobalNodeSerializer` to `GlobalResourceSerializer`
- **Breaking Change** Renamed `getList` and `literalList` etc. to make it clearer that those are actually not mapped to dart Lists, but merely to multi-value predicates (e.g. mutliple triples with the same subject and predicate). Also changed the type of those from List to Iterable.

## [0.5.0] - 2025-05-22

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
  - `childNodes()` - For extracting multiple child nodes from a source object
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
