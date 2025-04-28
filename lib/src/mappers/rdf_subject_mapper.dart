import 'package:rdf_mapper/src/deserializers/rdf_subject_deserializer.dart';
import 'package:rdf_mapper/src/serializers/rdf_subject_serializer.dart';

abstract interface class RdfSubjectMapper<T>
    implements RdfSubjectDeserializer<T>, RdfSubjectSerializer<T> {}
