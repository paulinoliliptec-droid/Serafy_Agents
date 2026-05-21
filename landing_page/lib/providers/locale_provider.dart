import 'package:flutter_riverpod/flutter_riverpod.dart';

// 'pt' | 'en'
final localeProvider = StateProvider<String>((ref) => 'pt');
