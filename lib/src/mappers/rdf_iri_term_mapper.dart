import 'package:rdf_mapper/src/api/mapper.dart';
import 'package:rdf_mapper/src/deserializers/iri_term_deserializer.dart';
import 'package:rdf_mapper/src/serializers/iri_term_serializer.dart';

/// Bidirectional mapper between Dart objects and RDF IRI terms.
///
/// Combines the functionality of both [IriTermSerializer] and [IriTermDeserializer]
/// for seamless conversion between Dart objects and RDF IRI terms in both directions.
abstract interface class RdfIriTermMapper<T>
    implements Mapper<T>, IriTermSerializer<T>, IriTermDeserializer<T> {}
