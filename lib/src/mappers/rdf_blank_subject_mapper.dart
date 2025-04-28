import 'package:rdf_mapper/src/deserializers/rdf_blank_node_term_deserializer.dart';
import 'package:rdf_mapper/src/serializers/rdf_subject_serializer.dart';

abstract interface class RdfBlankSubjectMapper<T>
    implements RdfBlankNodeTermDeserializer<T>, RdfSubjectSerializer<T> {}
