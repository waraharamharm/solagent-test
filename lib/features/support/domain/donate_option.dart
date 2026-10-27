/// One way to donate. Donations are voluntary gifts only: no option may
/// unlock features or be worded as a payment for access.
sealed class DonateOption {
  const DonateOption(this.label);

  final String label;
}

/// An external page (CloudTips, YooMoney, Boosty...) opened in the browser.
final class DonateLink extends DonateOption {
  const DonateLink(super.label, this.url);

  final String url;
}

/// Details for a direct transfer (SBP phone number, card) copied to the clipboard.
final class DonateTransfer extends DonateOption {
  const DonateTransfer(super.label, this.value);

  final String value;
}
