import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/mappers/resource/rdf_list_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('RdfListMapper', () {
    group('Constructor compatibility', () {
      test('RdfListMapper.new is a valid CollectionMapperFactory', () {
        // The default constructor should be assignable to CollectionMapperFactory
        CollectionMapperFactory<List<String>, String> factory =
            RdfListMapper.new;

        // Should be able to call it as a factory function
        final mapper = factory();
        expect(mapper, isA<RdfListMapper<String>>());
        expect(mapper, isA<UnifiedResourceMapper<List<String>>>());
      });

      test('RdfListMapper.new creates mapper with no custom serializers', () {
        final mapper = RdfListMapper<String>();

        expect(mapper, isA<RdfListMapper<String>>());
        expect(mapper, isA<UnifiedResourceMapper<List<String>>>());
      });

      test('RdfListMapper.new creates mapper with custom serializers', () {
        final mapper = RdfListMapper<String>();

        expect(mapper, isA<RdfListMapper<String>>());
        expect(mapper, isA<UnifiedResourceMapper<List<String>>>());
      });

      test(
          'factory function signature matches CollectionMapperFactory requirements',
          () {
        // Test that the constructor signature exactly matches what's expected
        // by CollectionMapperFactory typedef

        // This should compile without any type errors
        CollectionMapperFactory<List<int>, int> intListFactory =
            RdfListMapper.new;
        CollectionMapperFactory<List<String>, String> stringListFactory =
            RdfListMapper.new;
        CollectionMapperFactory<List<double>, double> doubleListFactory =
            RdfListMapper.new;

        // Test instantiation with the factory functions
        final intMapper = intListFactory();
        final stringMapper = stringListFactory();
        final doubleMapper = doubleListFactory();

        expect(intMapper, isA<RdfListMapper<int>>());
        expect(stringMapper, isA<RdfListMapper<String>>());
        expect(doubleMapper, isA<RdfListMapper<double>>());
      });

      test('RdfListMapper type inference works correctly', () {
        // Test type inference when used as factory
        CollectionMapperFactory<List<String>, String> factory =
            RdfListMapper.new;

        final mapper = factory();

        // Verify that the mapper has the correct generic types
        expect(mapper, isA<UnifiedResourceMapper<List<String>>>());
        expect(mapper, isA<RdfListMapper<String>>());
      });
    });

    group('Integration with CollectionMapperFactory pattern', () {
      test('can be used in contexts expecting CollectionMapperFactory', () {
        // Simulate how the factory might be used in registration or configuration
        final factories =
            <String, CollectionMapperFactory<List<dynamic>, dynamic>>{
          'list': RdfListMapper.new,
        };

        final listFactory = factories['list']!;
        final mapper = listFactory();

        expect(mapper, isA<RdfListMapper>());
      });

      test('factory pattern enables flexible mapper creation', () {
        // Test that the factory pattern enables creation with different configurations
        CollectionMapperFactory<List<String>, String> factory =
            RdfListMapper.new;

        // Create mappers with different configurations
        final mapperDefault = factory();
        final mapperWithNulls =
            factory(itemDeserializer: null, itemSerializer: null);

        expect(mapperDefault, isA<RdfListMapper<String>>());
        expect(mapperWithNulls, isA<RdfListMapper<String>>());
      });
    });
  });
}
