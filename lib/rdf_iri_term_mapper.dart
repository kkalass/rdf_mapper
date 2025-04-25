import 'package:rdf_mapper/rdf_iri_term_deserializer.dart';
import 'package:rdf_mapper/rdf_iri_term_serializer.dart';

abstract interface class RdfIriTermMapper<T>
    implements RdfIriTermDeserializer<T>, RdfIriTermSerializer<T> {}
