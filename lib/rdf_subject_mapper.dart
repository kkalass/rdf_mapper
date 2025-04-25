import 'package:rdf_mapper/rdf_subject_deserializer.dart';
import 'package:rdf_mapper/rdf_subject_serializer.dart';

abstract interface class RdfSubjectMapper<T>
    implements RdfSubjectDeserializer<T>, RdfSubjectSerializer<T> {}
