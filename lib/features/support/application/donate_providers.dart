import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/donate_option.dart';

/// Fill this list in to show the donate button. While it is empty the app
/// shows no donate entry at all. Only https links are opened.
const donateOptionsConfig = <DonateOption>[
  DonateLink(
    'SBP QR',
    'https://c2c.cbrpay.ru/AS1I000TTGM8MMPL8J9BRFUKVFAN51K0',
  ),
  DonateLink('YooMoney', 'https://yoomoney.ru/to/4100119669065528'),
];

final donateOptionsProvider = Provider<List<DonateOption>>(
  (ref) => donateOptionsConfig,
);

typedef UrlOpener = Future<bool> Function(Uri url);

final urlOpenerProvider = Provider<UrlOpener>(
  (ref) =>
      (url) => launchUrl(url, mode: LaunchMode.externalApplication),
);
