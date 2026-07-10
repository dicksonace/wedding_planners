import 'package:flutter_test/flutter_test.dart';
import 'package:wedplan_ghana/main.dart';
import 'package:wedplan_ghana/store/app_store.dart';
import 'package:wedplan_ghana/router/app_router.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App launches login flow', (tester) async {
    final store = AppStore();
    final router = AppRouter.create(store);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: WedPlanApp(router: router),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
