import 'package:rdf_mapper/rdf_mapper.dart';

/// Example demonstrating how to combine IriIdSerializer with ExtractingIriTermDeserializer
/// for bidirectional local ID to full IRI mapping.
void main() {
  // Create a registry with custom ID mappers
  final registry = RdfMapperRegistry()
    // Serializer: Convert local ID to full IRI
    ..registerSerializer<String>(IriIdSerializer(
      expand: (id, context) =>
          context.createIriTerm('http://example.org/items/$id'),
    ))
    // Deserializer: Extract ID from full IRI
    ..registerDeserializer<String>(ExtractingIriTermDeserializer<String>(
      extract: (term, context) {
        final iri = term.value;
        const prefix = 'http://example.org/items/';
        if (iri.startsWith(prefix)) {
          return iri.substring(prefix.length);
        }
        throw ArgumentError('Cannot extract ID from IRI: $iri');
      },
    ));

  final mapper = RdfMapper(registry: registry);

  // Example usage
  final localId = "42";

  // Serialize local ID to RDF
  final rdfString = mapper.encodeObject(localId);
  print('RDF representation:');
  print(rdfString);

  // Deserialize back to local ID
  final extractedId = mapper.decodeObject<String>(rdfString);
  print('\nExtracted ID: $extractedId');

  // Roundtrip verification
  assert(localId == extractedId);
  print('✅ Roundtrip successful!');
}
