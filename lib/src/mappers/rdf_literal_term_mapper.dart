import 'package:rdf_mapper/src/api/mapper.dart';
import 'package:rdf_mapper/src/deserializers/literal_term_deserializer.dart';
import 'package:rdf_mapper/src/serializers/literal_term_serializer.dart';

/// Bidirectional mapper between Dart objects and RDF literal terms.
///
/// Combines the functionality of both [LiteralTermSerializer] and [LiteralTermDeserializer]
/// for seamless conversion between Dart objects and RDF literal terms in both directions.
abstract interface class RdfLiteralTermMapper<T>
    implements
        Mapper<T>,
        LiteralTermSerializer<T>,
        LiteralTermDeserializer<T> {}
