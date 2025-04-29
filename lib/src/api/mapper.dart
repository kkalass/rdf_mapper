import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

/// Base marker interface for bidirectional RDF mappers.
///
/// A mapper combines the functionality of both a serializer and a deserializer,
/// providing bidirectional conversion between Dart objects and RDF representations.
///
/// This is a marker interface that specific mapper interfaces extend.
abstract interface class Mapper<T> implements Serializer<T>, Deserializer<T> {}
