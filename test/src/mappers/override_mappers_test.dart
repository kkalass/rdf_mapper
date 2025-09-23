import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:rdf_vocabularies_core/xsd.dart';
import 'package:test/test.dart';
import '../deserializers/mock_deserialization_context.dart' as mdc;
import '../serializers/mock_serialization_context.dart' as msc;

/// Mock DeserializationContext for testing override mappers
class MockDeserializationContext extends mdc.MockDeserializationContext {
  final Map<Type, dynamic> _mockResults = {};

  /// Set the expected result for a given type when fromLiteralTerm is called
  void setMockResult<T>(T result) {
    _mockResults[T] = result;
  }

  @override
  T fromLiteralTerm<T>(
    LiteralTerm term, {
    LiteralTermDeserializer<T>? deserializer,
    bool bypassDatatypeCheck = false,
  }) {
    // Simulate the behavior of looking up a registered mapper
    if (_mockResults.containsKey(T)) {
      return _mockResults[T] as T;
    }

    // For basic types, provide default behavior only for specific test values
    if (T == String &&
        (term.value == 'Hello World' ||
            term.value == 'Hallo Welt' ||
            term.value == '' ||
            term.value == '你好世界')) {
      return term.value as T;
    } else if (T == int && term.value != 'invalid') {
      return int.parse(term.value) as T;
    } else if (T == double && term.value != 'invalid') {
      return double.parse(term.value) as T;
    } else if (T == bool) {
      return (term.value == 'true') as T;
    }

    throw DeserializationException('No mock result configured for type $T');
  }
}

/// Mock SerializationContext for testing override mappers
class MockSerializationContext extends msc.MockSerializationContext {
  final Map<dynamic, LiteralTerm> _mockResults = {};

  /// Set the expected literal term result for a given value when toLiteralTerm is called
  void setMockResult<T>(T value, LiteralTerm result) {
    _mockResults[value] = result;
  }

  @override
  LiteralTerm toLiteralTerm<T>(T value,
      {LiteralTermSerializer<T>? serializer}) {
    // Check for explicit mock results first
    if (_mockResults.containsKey(value)) {
      return _mockResults[value]!;
    }

    // For basic types, provide default behavior
    if (value is String) {
      return LiteralTerm(value, datatype: Xsd.string);
    } else if (value is int) {
      return LiteralTerm(value.toString(), datatype: Xsd.int);
    } else if (value is double) {
      return LiteralTerm(value.toString(), datatype: Xsd.double);
    } else if (value is bool) {
      return LiteralTerm(value.toString(), datatype: Xsd.boolean);
    }

    throw SerializationException('No mock result configured for value $value');
  }
}

void main() {
  group('DatatypeOverrideMapper', () {
    late DatatypeOverrideMapper<String> stringMapper;
    late DatatypeOverrideMapper<int> intMapper;
    late DatatypeOverrideMapper<double> doubleMapper;
    late MockDeserializationContext deserializationContext;
    late MockSerializationContext serializationContext;

    // Define custom datatypes for testing
    final customStringType =
        const IriTerm('http://example.org/types/CustomString');
    final temperatureType = const IriTerm('http://qudt.org/vocab/unit/CEL');
    final customIntType = const IriTerm('http://example.org/types/CustomInt');

    setUp(() {
      stringMapper = DatatypeOverrideMapper<String>(customStringType);
      intMapper = DatatypeOverrideMapper<int>(customIntType);
      doubleMapper = DatatypeOverrideMapper<double>(temperatureType);
      deserializationContext = MockDeserializationContext();
      serializationContext = MockSerializationContext();
    });

    group('constructor', () {
      test('creates mapper with custom datatype', () {
        final mapper = DatatypeOverrideMapper<String>(customStringType);
        expect(mapper.datatype, equals(customStringType));
      });

      test('is const constructible', () {
        const customType = const IriTerm('http://example.org/test');
        const mapper = DatatypeOverrideMapper<String>(customType);
        expect(mapper.datatype, equals(customType));
      });
    });

    group('toRdfTerm', () {
      test('overrides datatype for string values', () {
        const testValue = 'Hello World';

        // Set up mock to return standard string literal
        serializationContext.setMockResult(
          testValue,
          LiteralTerm(testValue, datatype: Xsd.string),
        );

        final result = stringMapper.toRdfTerm(testValue, serializationContext);

        expect(result.value, equals('Hello World'));
        expect(result.datatype, equals(customStringType));
        expect(result.language, isNull);
      });

      test('overrides datatype for numeric values', () {
        const testValue = 23.5;

        // Set up mock to return standard double literal
        serializationContext.setMockResult(
          testValue,
          LiteralTerm('23.5', datatype: Xsd.double),
        );

        final result = doubleMapper.toRdfTerm(testValue, serializationContext);

        expect(result.value, equals('23.5'));
        expect(result.datatype, equals(temperatureType));
        expect(result.language, isNull);
      });

      test('preserves string representation from underlying mapper', () {
        const testValue = 42;

        // Set up mock to return formatted integer
        serializationContext.setMockResult(
          testValue,
          LiteralTerm('42', datatype: Xsd.int),
        );

        final result = intMapper.toRdfTerm(testValue, serializationContext);

        expect(result.value, equals('42'));
        expect(result.datatype, equals(customIntType));
      });
    });

    group('fromRdfTerm', () {
      test('successfully deserializes with correct datatype', () {
        final term = LiteralTerm('Hello World', datatype: customStringType);
        deserializationContext.setMockResult<String>('Hello World');

        final result = stringMapper.fromRdfTerm(term, deserializationContext);

        expect(result, equals('Hello World'));
      });

      test('successfully deserializes numeric values with custom datatype', () {
        final term = LiteralTerm('23.5', datatype: temperatureType);
        deserializationContext.setMockResult<double>(23.5);

        final result = doubleMapper.fromRdfTerm(term, deserializationContext);

        expect(result, equals(23.5));
      });

      test('throws DeserializerDatatypeMismatchException for wrong datatype',
          () {
        final term = LiteralTerm('Hello World', datatype: Xsd.string);

        expect(
          () => stringMapper.fromRdfTerm(term, deserializationContext),
          throwsA(
            allOf(
              isA<DeserializerDatatypeMismatchException>(),
              predicate<DeserializerDatatypeMismatchException>((e) =>
                  e.actual == Xsd.string &&
                  e.expected == customStringType &&
                  e.targetType == String &&
                  e.message.contains('Failed to parse String')),
            ),
          ),
        );
      });

      test('bypasses datatype check when requested', () {
        final term = LiteralTerm('Hello World', datatype: Xsd.string);
        deserializationContext.setMockResult<String>('Hello World');

        final result = stringMapper.fromRdfTerm(
          term,
          deserializationContext,
          bypassDatatypeCheck: true,
        );

        expect(result, equals('Hello World'));
      });

      test('throws DeserializationException when underlying parsing fails', () {
        final term = LiteralTerm('invalid', datatype: customIntType);
        // Don't set mock result to trigger failure - the mock's default behavior
        // will actually parse 'invalid' as int which will fail

        expect(
          () => intMapper.fromRdfTerm(term, deserializationContext),
          throwsA(
            allOf(
              isA<DeserializationException>(),
              predicate<DeserializationException>((e) =>
                  e.toString().contains('Failed to parse int') &&
                  e.toString().contains('Error:')),
            ),
          ),
        );
      });

      test('handles null datatype gracefully', () {
        final term = LiteralTerm('test');

        expect(
          () => stringMapper.fromRdfTerm(term, deserializationContext),
          throwsA(isA<DeserializerDatatypeMismatchException>()),
        );
      });
    });

    group('roundtrip serialization', () {
      test('maintains value integrity through serialize/deserialize cycle', () {
        const originalValue = 'Test String';

        // Set up mocks for the roundtrip
        serializationContext.setMockResult(
          originalValue,
          LiteralTerm(originalValue, datatype: Xsd.string),
        );
        deserializationContext.setMockResult<String>(originalValue);

        // Serialize
        final term =
            stringMapper.toRdfTerm(originalValue, serializationContext);
        expect(term.datatype, equals(customStringType));

        // Deserialize
        final deserializedValue =
            stringMapper.fromRdfTerm(term, deserializationContext);
        expect(deserializedValue, equals(originalValue));
      });
    });
  });

  group('LanguageOverrideMapper', () {
    late LanguageOverrideMapper<String> englishMapper;
    late LanguageOverrideMapper<String> germanMapper;
    late MockDeserializationContext deserializationContext;
    late MockSerializationContext serializationContext;

    setUp(() {
      englishMapper = const LanguageOverrideMapper<String>('en');
      germanMapper = const LanguageOverrideMapper<String>('de');
      deserializationContext = MockDeserializationContext();
      serializationContext = MockSerializationContext();
    });

    group('constructor', () {
      test('creates mapper with language tag', () {
        const mapper = LanguageOverrideMapper<String>('fr');
        expect(mapper.language, equals('fr'));
      });

      test('is const constructible', () {
        const mapper = LanguageOverrideMapper<String>('es');
        expect(mapper.language, equals('es'));
      });

      test('supports complex language tags', () {
        const mapper = LanguageOverrideMapper<String>('en-US');
        expect(mapper.language, equals('en-US'));
      });
    });

    group('toRdfTerm', () {
      test('creates language-tagged literal for English', () {
        const testValue = 'Hello World';

        // Set up mock to return standard string literal
        serializationContext.setMockResult(
          testValue,
          LiteralTerm(testValue, datatype: Xsd.string),
        );

        final result = englishMapper.toRdfTerm(testValue, serializationContext);

        expect(result.value, equals('Hello World'));
        expect(result.language, equals('en'));
        expect(result.datatype, equals(Rdf.langString));
      });

      test('creates language-tagged literal for German', () {
        const testValue = 'Hallo Welt';

        serializationContext.setMockResult(
          testValue,
          LiteralTerm(testValue, datatype: Xsd.string),
        );

        final result = germanMapper.toRdfTerm(testValue, serializationContext);

        expect(result.value, equals('Hallo Welt'));
        expect(result.language, equals('de'));
        expect(result.datatype, equals(Rdf.langString));
      });

      test('handles empty strings', () {
        const testValue = '';

        serializationContext.setMockResult(
          testValue,
          LiteralTerm(testValue, datatype: Xsd.string),
        );

        final result = englishMapper.toRdfTerm(testValue, serializationContext);

        expect(result.value, equals(''));
        expect(result.language, equals('en'));
        expect(result.datatype, equals(Rdf.langString));
      });

      test('works with complex language tags', () {
        const mapper = LanguageOverrideMapper<String>('zh-Hans');
        const testValue = '你好世界';

        serializationContext.setMockResult(
          testValue,
          LiteralTerm(testValue, datatype: Xsd.string),
        );

        final result = mapper.toRdfTerm(testValue, serializationContext);

        expect(result.value, equals('你好世界'));
        expect(result.language, equals('zh-Hans'));
        expect(result.datatype, equals(Rdf.langString));
      });
    });

    group('fromRdfTerm', () {
      test('successfully deserializes rdf:langString', () {
        final term = LiteralTerm.withLanguage('Hello World', 'en');
        deserializationContext.setMockResult<String>('Hello World');

        final result = englishMapper.fromRdfTerm(term, deserializationContext);

        expect(result, equals('Hello World'));
      });

      test('throws DeserializerDatatypeMismatchException for wrong datatype',
          () {
        final term = LiteralTerm('Hello World', datatype: Xsd.string);

        expect(
          () => englishMapper.fromRdfTerm(term, deserializationContext),
          throwsA(
            allOf(
              isA<DeserializerDatatypeMismatchException>(),
              predicate<DeserializerDatatypeMismatchException>((e) =>
                  e.actual == Xsd.string &&
                  e.expected == Rdf.langString &&
                  e.targetType == String &&
                  e.message.contains('Failed to parse String')),
            ),
          ),
        );
      });

      test('bypasses datatype check when requested', () {
        final term = LiteralTerm('Hello World', datatype: Xsd.string);
        deserializationContext.setMockResult<String>('Hello World');

        final result = englishMapper.fromRdfTerm(
          term,
          deserializationContext,
          bypassDatatypeCheck: true,
        );

        expect(result, equals('Hello World'));
      });

      test('throws DeserializationException when underlying parsing fails', () {
        final term = LiteralTerm.withLanguage('test', 'en');
        // Don't set mock result - this should trigger our mock failure

        expect(
          () => englishMapper.fromRdfTerm(term, deserializationContext),
          throwsA(
            allOf(
              isA<DeserializationException>(),
              predicate<DeserializationException>((e) => e
                  .toString()
                  .contains('No mock result configured for type String')),
            ),
          ),
        );
      });

      test('handles different language tags in input gracefully', () {
        // Input has German language tag, but mapper expects English validation
        final term = LiteralTerm.withLanguage('Hallo', 'de');
        deserializationContext.setMockResult<String>('Hallo');

        // Should work because we only validate datatype (rdf:langString), not language
        final result = englishMapper.fromRdfTerm(term, deserializationContext);
        expect(result, equals('Hallo'));
      });
    });

    group('roundtrip serialization', () {
      test('maintains value integrity through serialize/deserialize cycle', () {
        const originalValue = 'Hello World';

        // Set up mocks for the roundtrip
        serializationContext.setMockResult(
          originalValue,
          LiteralTerm(originalValue, datatype: Xsd.string),
        );
        deserializationContext.setMockResult<String>(originalValue);

        // Serialize
        final term =
            englishMapper.toRdfTerm(originalValue, serializationContext);
        expect(term.language, equals('en'));
        expect(term.datatype, equals(Rdf.langString));

        // Deserialize
        final deserializedValue =
            englishMapper.fromRdfTerm(term, deserializationContext);
        expect(deserializedValue, equals(originalValue));
      });

      test('works with multilingual content', () {
        const englishText = 'Hello World';
        const germanText = 'Hallo Welt';

        // Create separate contexts to avoid mock confusion
        final englishSerializationContext = MockSerializationContext();
        final germanSerializationContext = MockSerializationContext();
        final englishDeserializationContext = MockDeserializationContext();
        final germanDeserializationContext = MockDeserializationContext();

        // Set up English mocks
        englishSerializationContext.setMockResult(
          englishText,
          LiteralTerm(englishText, datatype: Xsd.string),
        );
        englishDeserializationContext.setMockResult<String>(englishText);

        // Set up German mocks
        germanSerializationContext.setMockResult(
          germanText,
          LiteralTerm(germanText, datatype: Xsd.string),
        );
        germanDeserializationContext.setMockResult<String>(germanText);

        // English roundtrip
        final englishTerm =
            englishMapper.toRdfTerm(englishText, englishSerializationContext);
        expect(englishTerm.language, equals('en'));
        final englishResult = englishMapper.fromRdfTerm(
            englishTerm, englishDeserializationContext);
        expect(englishResult, equals(englishText));

        // German roundtrip
        final germanTerm =
            germanMapper.toRdfTerm(germanText, germanSerializationContext);
        expect(germanTerm.language, equals('de'));
        final germanResult =
            germanMapper.fromRdfTerm(germanTerm, germanDeserializationContext);
        expect(germanResult, equals(germanText));
      });
    });
  });

  group('Integration scenarios', () {
    test(
        'DatatypeOverrideMapper and LanguageOverrideMapper have different use cases',
        () {
      final customType = const IriTerm('http://example.org/CustomType');
      final datatypeMapper = DatatypeOverrideMapper<String>(customType);
      const languageMapper = LanguageOverrideMapper<String>('en');

      expect(datatypeMapper.datatype, equals(customType));
      expect(languageMapper.language, equals('en'));

      // They serve different purposes and shouldn't be confused
      expect(datatypeMapper.runtimeType,
          isNot(equals(languageMapper.runtimeType)));
    });

    test('Both mappers can work with same base type', () {
      // Both can work with String, but produce different RDF representations
      final customType = const IriTerm('http://example.org/SpecialString');
      final datatypeMapper = DatatypeOverrideMapper<String>(customType);
      const languageMapper = LanguageOverrideMapper<String>('fr');

      final context = MockSerializationContext();
      const testValue = 'test value';

      context.setMockResult(
        testValue,
        LiteralTerm(testValue, datatype: Xsd.string),
      );

      final datatypeTerm = datatypeMapper.toRdfTerm(testValue, context);
      final languageTerm = languageMapper.toRdfTerm(testValue, context);

      expect(datatypeTerm.datatype, equals(customType));
      expect(datatypeTerm.language, isNull);

      expect(languageTerm.datatype, equals(Rdf.langString));
      expect(languageTerm.language, equals('fr'));
    });
  });

  group('Critical Usage Warnings', () {
    test('documents infinite recursion risk with ANY registry registration',
        () {
      // This test documents the critical warning but doesn't actually test the recursion
      // to avoid breaking the test suite with a stack overflow

      final customType = const IriTerm('http://example.org/CustomType');
      final datatypeMapper = DatatypeOverrideMapper<String>(customType);
      const languageMapper = LanguageOverrideMapper<String>('en');

      // These mappers delegate to context.fromLiteralTerm<T> and context.toLiteralTerm<T>
      // which always use the registry system. ANY registry registration causes recursion:
      //
      // 1. User calls serialize/deserialize operation
      // 2. Context uses registry to find mapper for type T
      // 3. Registry returns our override mapper
      // 4. Override mapper calls context.toLiteralTerm<T>/fromLiteralTerm<T>
      // 5. Context uses registry again to find mapper for type T
      // 6. Registry returns the same override mapper -> INFINITE RECURSION!
      //
      // This happens with ANY registry: global, local, cloned, etc.

      expect(datatypeMapper, isA<LiteralTermMapper<String>>());
      expect(languageMapper, isA<LiteralTermMapper<String>>());

      // CORRECT usage: Explicit serializer/deserializer parameters only
      // - builder.addValue(predicate, value, serializer: mapper)
      // - reader.require<T>(predicate, deserializer: mapper)
      //
      // NEVER register in any RdfMapperRegistry instance!
    });

    test('confirms delegation behavior that causes recursion risk', () {
      final customType = const IriTerm('http://example.org/Test');
      final mapper = DatatypeOverrideMapper<String>(customType);
      final context = MockSerializationContext();

      const testValue = 'test';
      context.setMockResult(
          testValue, LiteralTerm(testValue, datatype: Xsd.string));

      // This shows the delegation - mapper calls context.toLiteralTerm
      // In real usage, context.toLiteralTerm<String> would consult the registry
      // If this mapper were registered for String type, it would find itself again
      final result = mapper.toRdfTerm(testValue, context);

      expect(result.value, equals('test'));
      expect(result.datatype, equals(customType));
    });
  });
}
