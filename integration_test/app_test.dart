// Tüm integration testleri tek komutla çalıştırmak için bu dosyayı kullan:
// flutter test integration_test/app_test.dart
//   --dart-define=TEST_PROVIDER_EMAIL=...
//   --dart-define=TEST_PROVIDER_PASSWORD=...

import 'auth_test.dart' as auth;
import 'dashboard_test.dart' as dashboard;
import 'bids_test.dart' as bids;

void main() {
  auth.main();
  dashboard.main();
  bids.main();
}
