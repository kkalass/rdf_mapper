import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies/rdf.dart';

class RdfListMapper<T> extends CommonResourceMapper<List<T>> {
  final Deserializer<T>? _deserializer;
  final Serializer<T>? _serializer;

  const RdfListMapper([Mapper<T>? itemMapper])
      : _deserializer = itemMapper is Deserializer<T>
            ? itemMapper as Deserializer<T>
            : null,
        _serializer =
            itemMapper is Serializer<T> ? itemMapper as Serializer<T> : null;

  @override
  List<T> fromRdfResource<S extends RdfSubject>(
      S subject, DeserializationContext context) {
    if (subject is! BlankNodeTerm && subject != Rdf.nil) {
      throw ArgumentError(
          "Expected subject to be a BlankNodeTerm or rdf:nil, but found: $subject");
    }
    return context
        .readRdfList<T>(subject, deserializer: _deserializer)
        .toList();
  }

  @override
  (RdfSubject, List<Triple>) toRdfResource(
      List<T> values, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final (subject, triples) =
        context.buildRdfList(values, serializer: _serializer);
    return (subject, triples.toList());
  }

  @override
  IriTerm? get typeIri => Rdf.List;
}
