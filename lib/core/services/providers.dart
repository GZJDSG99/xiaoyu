import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/screen_service.dart';

final screenServiceProvider = Provider<ScreenService>((ref) {
  return ScreenService();
});
