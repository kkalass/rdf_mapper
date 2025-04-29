import 'package:rdf_mapper/src/api/mapper.dart';
import 'package:rdf_mapper/src/deserializers/subject_deserializer.dart';
import 'package:rdf_mapper/src/serializers/subject_serializer.dart';

/// Bidirectional mapper between Dart objects and RDF subjects with associated triples.
///
/// Combines the functionality of both [SubjectSerializer] and [SubjectDeserializer]
/// for seamless conversion between Dart objects and RDF subjects in both directions.
abstract interface class RdfSubjectMapper<T>
    implements Mapper<T>, SubjectSerializer<T>, SubjectDeserializer<T> {}
