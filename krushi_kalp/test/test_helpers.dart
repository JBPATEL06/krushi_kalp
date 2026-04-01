import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseStorage extends Mock implements SupabaseStorageClient {}
class MockSupabaseBucket extends Mock implements SupabaseBucketApi {}
class MockPostgrestQueryBuilder extends Mock implements PostgrestQueryBuilder {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder<PostgrestList> {}
class MockPostgrestTransformBuilder extends Mock implements PostgrestTransformBuilder<PostgrestList> {}
class MockRef extends Mock implements Ref {}

// Add more mocks as needed
