import 'package:rdf_mapper/src/deserializers/rdf_literal_term_deserializer.dart';
import 'package:rdf_mapper/src/serializers/rdf_literal_term_serializer.dart';

abstract interface class RdfLiteralTermMapper<T>
    implements RdfLiteralTermDeserializer<T>, RdfLiteralTermSerializer<T> {}
