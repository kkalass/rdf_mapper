# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
