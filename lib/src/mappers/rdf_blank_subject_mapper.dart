import 'package:rdf_mapper/src/deserializers/blank_node_term_deserializer.dart';
import 'package:rdf_mapper/src/serializers/subject_serializer.dart';

/// Bidirectional mapper between Dart objects and RDF blank node subjects.
///
/// Combines the functionality of blank node deserialization and subject serialization
/// for handling anonymous nodes in RDF graphs.
abstract interface class RdfBlankSubjectMapper<T>
    implements BlankNodeTermDeserializer<T>, SubjectSerializer<T> {}
