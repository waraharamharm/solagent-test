import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/core/l10n/l10n.dart';
import 'package:solagent/features/support/application/donate_providers.dart';
import 'package:solagent/features/support/domain/donate_option.dart';
import 'package:solagent/features/support/presentation/support_screen.dart';

Future<void> _pump(
  WidgetTester tester,
  List<DonateOption> options, {
  UrlOpener? opener,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        donateOptionsProvider.overrideWithValue(options),
        if (opener != null) urlOpenerProvider.overrideWithValue(opener),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: SupportScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('wording says donation, never payment', (tester) async {
    await _pump(tester, const [DonateLink('CloudTips', 'https://x.test/p')]);
    expect(find.textContaining('voluntary gift'), findsOneWidget);
    expect(find.text('CloudTips'), findsOneWidget);
    expect(
      find.textContaining(RegExp('premium|buy|unlock', caseSensitive: false)),
      findsNothing,
    );
  });

  testWidgets('a link opens in the external browser', (tester) async {
    Uri? opened;
    await _pump(
      tester,
      const [DonateLink('Boosty', 'https://boosty.test/me')],
      opener: (url) async {
        opened = url;
        return true;
      },
    );
    await tester.tap(find.text('Boosty'));
    await tester.pumpAndSettle();
    expect(opened, Uri.parse('https://boosty.test/me'));
    expect(find.text('Could not open the link'), findsNothing);
  });

  testWidgets('non-https links are refused', (tester) async {
    var called = false;
    await _pump(
      tester,
      const [DonateLink('Bad', 'http://insecure.test')],
      opener: (_) async {
        called = true;
        return true;
      },
    );
    await tester.tap(find.text('Bad'));
    await tester.pumpAndSettle();
    expect(called, isFalse);
    expect(find.text('Could not open the link'), findsOneWidget);
  });

  testWidgets('failed launch tells the user', (tester) async {
    await _pump(tester, const [
      DonateLink('CloudTips', 'https://x.test/p'),
    ], opener: (_) async => false);
    await tester.tap(find.text('CloudTips'));
    await tester.pumpAndSettle();
    expect(find.text('Could not open the link'), findsOneWidget);
  });

  testWidgets('a transfer is copied to the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester, const [DonateTransfer('SBP', '+7 900 000-00-00')]);
    await tester.tap(find.text('SBP'));
    await tester.pumpAndSettle();
    expect(copied, '+7 900 000-00-00');
    expect(find.text('Copied'), findsOneWidget);
  });
}
