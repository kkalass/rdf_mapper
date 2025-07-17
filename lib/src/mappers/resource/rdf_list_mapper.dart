import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_list_deserializer.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_list_serializer.dart';

class RdfListMapper<T> extends UnifiedResourceMapperBase<List<T>, T> {
  RdfListMapper(
      {Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})
      : super(
          RdfListSerializer(itemSerializer: itemSerializer),
          RdfListDeserializer(itemDeserializer: itemDeserializer),
        );
}

class AdaptingRdfListMapper<C, T>
    extends AdaptingUnifiedResourceMapper<C, List<T>> {
  AdaptingRdfListMapper(
      List<T> Function(C) toWrappedType, C Function(List<T>) fromWrappedType,
      {Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})
      : super(
          RdfListMapper<T>(
              itemDeserializer: itemDeserializer,
              itemSerializer: itemSerializer),
          toWrappedType,
          fromWrappedType,
        );
}

class RdfFooMapper<T> extends AdaptingRdfListMapper<Set<T>, T> {
  RdfFooMapper(
      {Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})
      : super(
          (set) => set.toList(),
          (list) => list.toSet(),
          itemDeserializer: itemDeserializer,
          itemSerializer: itemSerializer,
        );
}
