import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_list_deserializer.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_list_serializer.dart';

class RdfListMapper<T> extends UnifiedResourceMapperBase<List<T>, T> {
  RdfListMapper([Mapper<T>? itemMapper])
      : super(
          RdfListSerializer(itemMapper),
          RdfListDeserializer(itemMapper),
        );
}
