import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://qqevudshpcpahuerhthv.supabase.co',
    'sb_publishable_V3mRFNLRC1DNt8n61_Z0CQ_UkQxNo6r',
  );

  try {
    final response = await supabase.storage.from('mock_test').download('mock_test_json_file/39/1780420722449_demo_mcq.json');
    final String jsonString = utf8.decode(response);
    print('RAW CONTENT:');
    print(jsonString);

    final List<dynamic> data = json.decode(jsonString);
    print('QUESTIONS COUNT: ${data.length}');
  } catch (e, stack) {
    print('ERROR: $e');
    print(stack);
  }
}
