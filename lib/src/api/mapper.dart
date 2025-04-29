import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

/// Base marker interface for bidirectional RDF mappers.
///
/// A mapper combines the functionality of both a serializer and a deserializer,
/// providing bidirectional conversion between Dart objects and RDF representations.
///
/// This is a marker interface that specific mapper interfaces extend.
sealed class Mapper<T> {}

/// Bidirectional mapper between Dart objects and RDF blank node subjects.
///
/// Combines the functionality of blank node deserialization and subject serialization
/// for handling anonymous nodes in RDF graphs.
abstract interface class BlankSubjectMapper<T>
    implements
        Mapper<T>,
        BlankNodeSubjectGraphDeserializer<T>,
        SubjectGraphSerializer<T> {}

/// Bidirectional mapper between Dart objects and RDF IRI terms.
///
/// Combines the functionality of both [IriTermSerializer] and [IriTermDeserializer]
/// for seamless conversion between Dart objects and RDF IRI terms in both directions.
abstract interface class IriTermMapper<T>
    implements Mapper<T>, IriTermSerializer<T>, IriTermDeserializer<T> {}

/// Bidirectional mapper between Dart objects and RDF literal terms.
///
/// Combines the functionality of both [LiteralTermSerializer] and [LiteralTermDeserializer]
/// for seamless conversion between Dart objects and RDF literal terms in both directions.
abstract interface class LiteralTermMapper<T>
    implements
        Mapper<T>,
        LiteralTermSerializer<T>,
        LiteralTermDeserializer<T> {}

/// Bidirectional mapper between Dart objects and RDF subjects with associated triples.
///
/// Combines the functionality of both [SubjectGraphSerializer] and [IriSubjectGraphDeserializer]
/// for seamless conversion between Dart objects and RDF subjects in both directions.
abstract interface class SubjectMapper<T>
    implements
        Mapper<T>,
        SubjectGraphSerializer<T>,
        IriSubjectGraphDeserializer<T> {}
