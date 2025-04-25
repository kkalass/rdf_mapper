import 'package:rdf_mapper/rdf_literal_term_deserializer.dart';
import 'package:rdf_mapper/rdf_literal_term_serializer.dart';

abstract interface class RdfLiteralTermMapper<T>
    implements RdfLiteralTermDeserializer<T>, RdfLiteralTermSerializer<T> {}
