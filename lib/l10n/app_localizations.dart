import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// App name shown in the task switcher
  ///
  /// In en, this message translates to:
  /// **'SolAgent'**
  String get appTitle;

  /// Name of the user's VDS: bottom tab label, page title and home tile title
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get commonServer;

  /// Short name of the AI provider section: tab label, page title, home tile title
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get commonAi;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// Shown when the AI has proposed a command and waits for the user to approve or decline it
  ///
  /// In en, this message translates to:
  /// **'Your decision needed'**
  String get commonDecisionNeeded;

  /// Status of a running job; also the screen-reader label of the wavy progress line
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get commonWorking;

  /// Name of the feature where the AI fixes a failing script on the server
  ///
  /// In en, this message translates to:
  /// **'Self-healing'**
  String get commonSelfHealing;

  /// No description provided for @shellTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get shellTabOverview;

  /// No description provided for @shellTabDeploy.
  ///
  /// In en, this message translates to:
  /// **'Deployment'**
  String get shellTabDeploy;

  /// Tooltip of the round dock button when no job is running
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get shellJobRun;

  /// No description provided for @homeServerNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get homeServerNotConnected;

  /// Small status word next to the server tile once the server is stored
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get homeServerSaved;

  /// No description provided for @homeAiNoKey.
  ///
  /// In en, this message translates to:
  /// **'No key'**
  String get homeAiNoKey;

  /// Small status word next to the AI tile once the provider is fully set up
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get homeAiReady;

  /// No description provided for @homeRunWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your decision'**
  String get homeRunWaiting;

  /// No description provided for @homeRunLastSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Last run passed'**
  String get homeRunLastSucceeded;

  /// No description provided for @homeRunDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo on your server'**
  String get homeRunDemo;

  /// No description provided for @homeRunLastFailed.
  ///
  /// In en, this message translates to:
  /// **'Last run failed'**
  String get homeRunLastFailed;

  /// No description provided for @homeHeroReviewCommand.
  ///
  /// In en, this message translates to:
  /// **'Review the command'**
  String get homeHeroReviewCommand;

  /// No description provided for @homeHeroServerBusy.
  ///
  /// In en, this message translates to:
  /// **'The server is running a task'**
  String get homeHeroServerBusy;

  /// No description provided for @homeHeroOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get homeHeroOpen;

  /// No description provided for @homeHeroConnectServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect a server'**
  String get homeHeroConnectServerTitle;

  /// No description provided for @homeHeroConnectServerBody.
  ///
  /// In en, this message translates to:
  /// **'Your VDS address and a password or key. We’ll check the system and remember the server’s fingerprint.'**
  String get homeHeroConnectServerBody;

  /// No description provided for @homeHeroAddServer.
  ///
  /// In en, this message translates to:
  /// **'Add server'**
  String get homeHeroAddServer;

  /// No description provided for @homeHeroConnectAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect AI'**
  String get homeHeroConnectAiTitle;

  /// No description provided for @homeHeroConnectAiBody.
  ///
  /// In en, this message translates to:
  /// **'You’ll need your own API key: DeepSeek, Grok, OpenRouter, OpenAI, or a custom address.'**
  String get homeHeroConnectAiBody;

  /// No description provided for @homeHeroAddKey.
  ///
  /// In en, this message translates to:
  /// **'Add key'**
  String get homeHeroAddKey;

  /// No description provided for @homeHeroAllSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything is connected'**
  String get homeHeroAllSetTitle;

  /// No description provided for @homeHeroAllSetBody.
  ///
  /// In en, this message translates to:
  /// **'Server and AI are ready. Try self-healing on the demo script.'**
  String get homeHeroAllSetBody;

  /// No description provided for @homeHeroOpenDemo.
  ///
  /// In en, this message translates to:
  /// **'Open demo'**
  String get homeHeroOpenDemo;

  /// No description provided for @homeThemeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get homeThemeTooltip;

  /// No description provided for @homeThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Match system'**
  String get homeThemeSystem;

  /// No description provided for @homeThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get homeThemeLight;

  /// No description provided for @homeThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get homeThemeDark;

  /// No description provided for @homeLanguageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get homeLanguageTooltip;

  /// No description provided for @homeLanguageAuto.
  ///
  /// In en, this message translates to:
  /// **'Match device'**
  String get homeLanguageAuto;

  /// No description provided for @homeSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support the project'**
  String get homeSupportTitle;

  /// No description provided for @homeSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Donation for development'**
  String get homeSupportSubtitle;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support the project'**
  String get supportTitle;

  /// No description provided for @supportIntro.
  ///
  /// In en, this message translates to:
  /// **'SolAgent is free. A donation is a voluntary gift for the development of the project, not payment for access or features.'**
  String get supportIntro;

  /// No description provided for @supportGroupOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get supportGroupOnline;

  /// No description provided for @supportGroupTransfer.
  ///
  /// In en, this message translates to:
  /// **'Direct transfer'**
  String get supportGroupTransfer;

  /// No description provided for @supportOpensInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Opens in your browser'**
  String get supportOpensInBrowser;

  /// No description provided for @supportTapToCopy.
  ///
  /// In en, this message translates to:
  /// **'Tap to copy'**
  String get supportTapToCopy;

  /// No description provided for @supportCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get supportCopied;

  /// No description provided for @supportOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get supportOpenFailed;

  /// No description provided for @serverNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New server'**
  String get serverNewTitle;

  /// Body of the dialog asking the user to verify the SSH host key fingerprint; {command} is a shell command shown as is
  ///
  /// In en, this message translates to:
  /// **'Compare this fingerprint with the one on your server. Run this on the server:\n{command}'**
  String serverFingerprintPrompt(String command);

  /// No description provided for @serverFingerprintMatches.
  ///
  /// In en, this message translates to:
  /// **'It matches'**
  String get serverFingerprintMatches;

  /// No description provided for @serverForgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove the server?'**
  String get serverForgetTitle;

  /// No description provided for @serverForgetBody.
  ///
  /// In en, this message translates to:
  /// **'The address and the password or key will be deleted from this device.'**
  String get serverForgetBody;

  /// No description provided for @serverForgetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove server'**
  String get serverForgetTooltip;

  /// No description provided for @serverLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the server'**
  String get serverLoadFailed;

  /// No description provided for @serverSecretKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Private key (PEM / OpenSSH)'**
  String get serverSecretKeyLabel;

  /// No description provided for @serverSectionAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get serverSectionAddress;

  /// No description provided for @serverHostLabel.
  ///
  /// In en, this message translates to:
  /// **'IP or domain'**
  String get serverHostLabel;

  /// No description provided for @serverUserLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get serverUserLabel;

  /// No description provided for @serverPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get serverPortLabel;

  /// No description provided for @serverPortNotNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get serverPortNotNumber;

  /// No description provided for @serverSectionLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get serverSectionLogin;

  /// No description provided for @serverAuthKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get serverAuthKey;

  /// No description provided for @serverFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Fill in this field'**
  String get serverFieldRequired;

  /// Second line of the saved server tile
  ///
  /// In en, this message translates to:
  /// **'{username} · port {port} · {auth}'**
  String serverProfileSubtitle(String username, int port, String auth);

  /// Sign-in method inside serverProfileSubtitle ("port 22 · key")
  ///
  /// In en, this message translates to:
  /// **'key'**
  String get serverAuthByKey;

  /// Sign-in method inside serverProfileSubtitle ("port 22 · password")
  ///
  /// In en, this message translates to:
  /// **'password'**
  String get serverAuthByPassword;

  /// No description provided for @serverCheck.
  ///
  /// In en, this message translates to:
  /// **'Check server'**
  String get serverCheck;

  /// No description provided for @serverOsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{os}: only Ubuntu and Debian are supported'**
  String serverOsUnsupported(String os);

  /// No description provided for @serverLoginRoot.
  ///
  /// In en, this message translates to:
  /// **'Signed in as root'**
  String get serverLoginRoot;

  /// No description provided for @serverLoginNotRoot.
  ///
  /// In en, this message translates to:
  /// **'Not signed in as root: installation needs sudo'**
  String get serverLoginNotRoot;

  /// No description provided for @serverFingerprintPinned.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint saved'**
  String get serverFingerprintPinned;

  /// No description provided for @serverErrHostKeyMismatch.
  ///
  /// In en, this message translates to:
  /// **'The server’s fingerprint has changed. Either the server was reinstalled or the connection is being intercepted. The connection was refused.'**
  String get serverErrHostKeyMismatch;

  /// No description provided for @serverErrRejected.
  ///
  /// In en, this message translates to:
  /// **'Connection cancelled'**
  String get serverErrRejected;

  /// No description provided for @serverErrAuth.
  ///
  /// In en, this message translates to:
  /// **'The server rejected the password or key'**
  String get serverErrAuth;

  /// No description provided for @serverErrInvalidKey.
  ///
  /// In en, this message translates to:
  /// **'The key can’t be read or needs a passphrase'**
  String get serverErrInvalidKey;

  /// No description provided for @serverErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Server unreachable: check the address and port'**
  String get serverErrNetwork;

  /// No description provided for @serverErrTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server didn’t respond in time'**
  String get serverErrTimeout;

  /// No description provided for @serverErrSsh.
  ///
  /// In en, this message translates to:
  /// **'SSH error'**
  String get serverErrSsh;

  /// No description provided for @serverErrCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t check the server'**
  String get serverErrCheckFailed;

  /// No description provided for @fixDemoStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get fixDemoStop;

  /// No description provided for @fixDemoStart.
  ///
  /// In en, this message translates to:
  /// **'Run demo'**
  String get fixDemoStart;

  /// No description provided for @fixDemoProposalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The AI suggests one command'**
  String get fixDemoProposalSubtitle;

  /// No description provided for @fixDemoWorkingTitle.
  ///
  /// In en, this message translates to:
  /// **'Working on it'**
  String get fixDemoWorkingTitle;

  /// No description provided for @fixDemoConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get fixDemoConnecting;

  /// No description provided for @fixDemoDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get fixDemoDoneTitle;

  /// No description provided for @fixDemoDoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The script passed after the fix'**
  String get fixDemoDoneSubtitle;

  /// No description provided for @fixDemoStoppedTitle.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get fixDemoStoppedTitle;

  /// No description provided for @fixDemoDeclinedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You declined the command'**
  String get fixDemoDeclinedSubtitle;

  /// No description provided for @fixDemoCancelledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The run was interrupted'**
  String get fixDemoCancelledSubtitle;

  /// No description provided for @fixDemoNotFixedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not fixed'**
  String get fixDemoNotFixedTitle;

  /// No description provided for @fixDemoNoFixSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The AI found no safe command: {message}'**
  String fixDemoNoFixSubtitle(String message);

  /// No description provided for @fixDemoGaveUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t fix it after several attempts'**
  String get fixDemoGaveUpSubtitle;

  /// No description provided for @fixDemoLostTitle.
  ///
  /// In en, this message translates to:
  /// **'Task interrupted'**
  String get fixDemoLostTitle;

  /// No description provided for @fixDemoLostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The server rebooted or ran out of memory'**
  String get fixDemoLostSubtitle;

  /// No description provided for @fixDemoErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get fixDemoErrorTitle;

  /// No description provided for @fixDemoErrorFallback.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get fixDemoErrorFallback;

  /// No description provided for @fixDemoIdleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The demo script fails without the file {path}. The AI will find the cause and suggest a command.'**
  String fixDemoIdleSubtitle(String path);

  /// No description provided for @fixDemoErrHostNotChecked.
  ///
  /// In en, this message translates to:
  /// **'The server hasn’t been checked yet. Open the Server tab and tap “Check server”.'**
  String get fixDemoErrHostNotChecked;

  /// No description provided for @fixDemoErrStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t start the run\n{error}'**
  String fixDemoErrStartFailed(String error);

  /// No description provided for @fixDemoDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get fixDemoDecline;

  /// Button that approves the AI's proposed command; nothing runs on the server before it is pressed
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get fixDemoApprove;

  /// No description provided for @fixDemoLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Server log'**
  String get fixDemoLogTitle;

  /// No description provided for @fixDemoLogCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get fixDemoLogCollapse;

  /// No description provided for @fixDemoLogShowAll.
  ///
  /// In en, this message translates to:
  /// **'Full log'**
  String get fixDemoLogShowAll;

  /// No description provided for @llmLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the settings'**
  String get llmLoadFailed;

  /// No description provided for @llmSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get llmSettingsSaved;

  /// No description provided for @llmClearKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the key?'**
  String get llmClearKeyTitle;

  /// No description provided for @llmClearKeyBody.
  ///
  /// In en, this message translates to:
  /// **'The key will be removed from this device.'**
  String get llmClearKeyBody;

  /// No description provided for @llmSectionProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get llmSectionProvider;

  /// No description provided for @llmSectionEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Address and model'**
  String get llmSectionEndpoint;

  /// No description provided for @llmModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get llmModelLabel;

  /// No description provided for @llmApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get llmApiKey;

  /// No description provided for @llmKeySaved.
  ///
  /// In en, this message translates to:
  /// **'Key saved'**
  String get llmKeySaved;

  /// No description provided for @llmKeyDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete key'**
  String get llmKeyDeleteTooltip;

  /// No description provided for @llmSaveKey.
  ///
  /// In en, this message translates to:
  /// **'Save key'**
  String get llmSaveKey;

  /// No description provided for @llmSectionCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get llmSectionCheck;

  /// No description provided for @llmCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get llmCheckConnection;

  /// No description provided for @llmCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t run the check'**
  String get llmCheckFailed;

  /// No description provided for @llmModelReply.
  ///
  /// In en, this message translates to:
  /// **'Model reply: {reply}'**
  String llmModelReply(String reply);

  /// No description provided for @problemServerNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'The server isn’t set up yet'**
  String get problemServerNotConfigured;

  /// No description provided for @problemServerOsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t detect the server’s operating system'**
  String get problemServerOsUnknown;

  /// No description provided for @problemAiNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Set up the AI and its key first'**
  String get problemAiNotConfigured;

  /// No description provided for @problemEmptyKey.
  ///
  /// In en, this message translates to:
  /// **'The key is empty'**
  String get problemEmptyKey;

  /// No description provided for @problemEmptyPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is empty'**
  String get problemEmptyPassword;

  /// No description provided for @problemBaseUrlNotAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Enter a full address, for example https://api.example.com/v1'**
  String get problemBaseUrlNotAbsolute;

  /// No description provided for @problemBaseUrlInsecureHttp.
  ///
  /// In en, this message translates to:
  /// **'Without https your key would travel as plain text. Use http only on a local network'**
  String get problemBaseUrlInsecureHttp;

  /// No description provided for @problemBaseUrlUnsupportedScheme.
  ///
  /// In en, this message translates to:
  /// **'Only http and https are supported'**
  String get problemBaseUrlUnsupportedScheme;

  /// No description provided for @problemServerBadHost.
  ///
  /// In en, this message translates to:
  /// **'Invalid server address'**
  String get problemServerBadHost;

  /// No description provided for @problemServerBadPort.
  ///
  /// In en, this message translates to:
  /// **'Port must be from 1 to 65535'**
  String get problemServerBadPort;

  /// No description provided for @problemServerBadLogin.
  ///
  /// In en, this message translates to:
  /// **'Invalid login'**
  String get problemServerBadLogin;

  /// No description provided for @llmPresetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom endpoint'**
  String get llmPresetCustom;

  /// No description provided for @llmCheckNeedSettings.
  ///
  /// In en, this message translates to:
  /// **'Fill in the settings and the key first'**
  String get llmCheckNeedSettings;

  /// No description provided for @llmCheckFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t run the check\n{error}'**
  String llmCheckFailedWithError(String error);

  /// No description provided for @llmErrForbidden.
  ///
  /// In en, this message translates to:
  /// **'Access denied. A common cause is your region: turn on a VPN'**
  String get llmErrForbidden;

  /// No description provided for @llmErrUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'The key was not accepted: make sure you pasted all of it'**
  String get llmErrUnauthorized;

  /// No description provided for @llmErrRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Rate limit reached or the balance has run out'**
  String get llmErrRateLimited;

  /// No description provided for @llmErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can’t reach the provider'**
  String get llmErrNetwork;

  /// No description provided for @llmErrServer.
  ///
  /// In en, this message translates to:
  /// **'Provider error'**
  String get llmErrServer;

  /// No description provided for @llmErrBadResponse.
  ///
  /// In en, this message translates to:
  /// **'The provider sent a response we can’t read'**
  String get llmErrBadResponse;

  /// No description provided for @fixStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to the server…'**
  String get fixStatusConnecting;

  /// No description provided for @fixStatusWaitingDecision.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your decision'**
  String get fixStatusWaitingDecision;

  /// No description provided for @fixStepYourDecision.
  ///
  /// In en, this message translates to:
  /// **'Your decision'**
  String get fixStepYourDecision;

  /// No description provided for @fixStepRunScript.
  ///
  /// In en, this message translates to:
  /// **'Starting the script'**
  String get fixStepRunScript;

  /// No description provided for @fixStepRerun.
  ///
  /// In en, this message translates to:
  /// **'Re-run {round}'**
  String fixStepRerun(int round);

  /// No description provided for @fixStepFix.
  ///
  /// In en, this message translates to:
  /// **'Fix {round}'**
  String fixStepFix(int round);

  /// No description provided for @fixLogExitCode.
  ///
  /// In en, this message translates to:
  /// **'── exit code {code} ──'**
  String fixLogExitCode(int code);

  /// No description provided for @fixDetailJobInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The job was interrupted'**
  String get fixDetailJobInterrupted;

  /// No description provided for @fixDetailJobFailedCode.
  ///
  /// In en, this message translates to:
  /// **'Failed, code {code}'**
  String fixDetailJobFailedCode(int code);

  /// No description provided for @fixStatusDiagnosing.
  ///
  /// In en, this message translates to:
  /// **'The AI is analyzing the error (attempt {round})…'**
  String fixStatusDiagnosing(int round);

  /// No description provided for @fixStepDiagnosing.
  ///
  /// In en, this message translates to:
  /// **'The AI is looking for the cause'**
  String get fixStepDiagnosing;

  /// No description provided for @fixLogBlockedCommand.
  ///
  /// In en, this message translates to:
  /// **'── The AI proposed a forbidden command, rejected: {reason} ──'**
  String fixLogBlockedCommand(String reason);

  /// No description provided for @fixDetailCommandForbidden.
  ///
  /// In en, this message translates to:
  /// **'The command is forbidden by the rules; the AI was asked for another one'**
  String get fixDetailCommandForbidden;

  /// No description provided for @fixDetailAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get fixDetailAllowed;

  /// No description provided for @fixDetailDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get fixDetailDeclined;

  /// No description provided for @fixErrAi.
  ///
  /// In en, this message translates to:
  /// **'AI: {detail}'**
  String fixErrAi(String detail);

  /// No description provided for @fixErrAiFormat.
  ///
  /// In en, this message translates to:
  /// **'The AI answered in an unexpected format\n{detail}'**
  String fixErrAiFormat(String detail);

  /// No description provided for @fixErrConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection to the server was lost\n{detail}'**
  String fixErrConnection(String detail);

  /// No description provided for @fixErrServer.
  ///
  /// In en, this message translates to:
  /// **'Server: {detail}'**
  String fixErrServer(String detail);

  /// No description provided for @blockCurlPipeShell.
  ///
  /// In en, this message translates to:
  /// **'Downloading a script from the internet and running it (curl | bash)'**
  String get blockCurlPipeShell;

  /// No description provided for @blockPipeToShell.
  ///
  /// In en, this message translates to:
  /// **'Piping text into a shell to run it'**
  String get blockPipeToShell;

  /// No description provided for @blockPipeToInterpreter.
  ///
  /// In en, this message translates to:
  /// **'Piping text into an interpreter to run it'**
  String get blockPipeToInterpreter;

  /// No description provided for @blockRunDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Running something that was downloaded from the internet'**
  String get blockRunDownloaded;

  /// No description provided for @blockProcessSubstitution.
  ///
  /// In en, this message translates to:
  /// **'Running a script through process substitution'**
  String get blockProcessSubstitution;

  /// No description provided for @blockEval.
  ///
  /// In en, this message translates to:
  /// **'eval hides what will be run'**
  String get blockEval;

  /// No description provided for @blockDecodeHidden.
  ///
  /// In en, this message translates to:
  /// **'Decoding hidden content'**
  String get blockDecodeHidden;

  /// No description provided for @blockEscapedBytes.
  ///
  /// In en, this message translates to:
  /// **'Escaped bytes inside the command'**
  String get blockEscapedBytes;

  /// No description provided for @blockNoPreserveRoot.
  ///
  /// In en, this message translates to:
  /// **'Deleting the filesystem root'**
  String get blockNoPreserveRoot;

  /// No description provided for @blockFindDelete.
  ///
  /// In en, this message translates to:
  /// **'Mass deletion with find'**
  String get blockFindDelete;

  /// No description provided for @blockDiskPartitioning.
  ///
  /// In en, this message translates to:
  /// **'Working with disk partitions'**
  String get blockDiskPartitioning;

  /// No description provided for @blockWriteToDevice.
  ///
  /// In en, this message translates to:
  /// **'Writing straight to a device'**
  String get blockWriteToDevice;

  /// No description provided for @blockForkBomb.
  ///
  /// In en, this message translates to:
  /// **'Fork bomb'**
  String get blockForkBomb;

  /// No description provided for @blockRebootShutdown.
  ///
  /// In en, this message translates to:
  /// **'Rebooting or shutting down the server'**
  String get blockRebootShutdown;

  /// No description provided for @blockAccountChanges.
  ///
  /// In en, this message translates to:
  /// **'Changing user accounts'**
  String get blockAccountChanges;

  /// No description provided for @blockCredentialsAccess.
  ///
  /// In en, this message translates to:
  /// **'Access to keys, passwords or login settings'**
  String get blockCredentialsAccess;

  /// No description provided for @blockStopSsh.
  ///
  /// In en, this message translates to:
  /// **'Stopping SSH: you would lose access to the server'**
  String get blockStopSsh;

  /// No description provided for @blockFirewallReset.
  ///
  /// In en, this message translates to:
  /// **'Resetting the firewall'**
  String get blockFirewallReset;

  /// No description provided for @blockRawNetwork.
  ///
  /// In en, this message translates to:
  /// **'Raw network connection (data could leak)'**
  String get blockRawNetwork;

  /// No description provided for @blockKillAll.
  ///
  /// In en, this message translates to:
  /// **'Terminating all processes'**
  String get blockKillAll;

  /// No description provided for @blockCronRemoval.
  ///
  /// In en, this message translates to:
  /// **'Deleting all cron jobs'**
  String get blockCronRemoval;

  /// No description provided for @blockHistoryHiding.
  ///
  /// In en, this message translates to:
  /// **'Hiding the command history'**
  String get blockHistoryHiding;

  /// No description provided for @blockInteractiveSu.
  ///
  /// In en, this message translates to:
  /// **'Interactive login as another user'**
  String get blockInteractiveSu;

  /// No description provided for @blockSolagentDir.
  ///
  /// In en, this message translates to:
  /// **'SolAgent’s own working directory'**
  String get blockSolagentDir;

  /// No description provided for @blockDownloadAndRun.
  ///
  /// In en, this message translates to:
  /// **'Downloading a file from the internet and running it'**
  String get blockDownloadAndRun;

  /// No description provided for @blockXargsExec.
  ///
  /// In en, this message translates to:
  /// **'Running text through xargs'**
  String get blockXargsExec;

  /// No description provided for @blockEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty command'**
  String get blockEmpty;

  /// No description provided for @blockTooLong.
  ///
  /// In en, this message translates to:
  /// **'The command is too long'**
  String get blockTooLong;

  /// No description provided for @blockControlChars.
  ///
  /// In en, this message translates to:
  /// **'Invisible control characters'**
  String get blockControlChars;

  /// No description provided for @blockRecursiveDelete.
  ///
  /// In en, this message translates to:
  /// **'Recursive deletion of the root, home or a system directory'**
  String get blockRecursiveDelete;

  /// No description provided for @blockRecursiveChmod.
  ///
  /// In en, this message translates to:
  /// **'Recursive permission change on a system directory'**
  String get blockRecursiveChmod;

  /// No description provided for @warnRoot.
  ///
  /// In en, this message translates to:
  /// **'Runs with root rights'**
  String get warnRoot;

  /// No description provided for @warnRm.
  ///
  /// In en, this message translates to:
  /// **'Deletes files without asking'**
  String get warnRm;

  /// No description provided for @warnPackages.
  ///
  /// In en, this message translates to:
  /// **'Removes packages'**
  String get warnPackages;

  /// No description provided for @warnService.
  ///
  /// In en, this message translates to:
  /// **'Stops or restarts a service'**
  String get warnService;

  /// No description provided for @warnDocker.
  ///
  /// In en, this message translates to:
  /// **'Deletes Docker containers or data'**
  String get warnDocker;

  /// No description provided for @warnChmod777.
  ///
  /// In en, this message translates to:
  /// **'Makes a file writable by everyone'**
  String get warnChmod777;

  /// No description provided for @warnEtcOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrites a system file'**
  String get warnEtcOverwrite;

  /// No description provided for @warnKill.
  ///
  /// In en, this message translates to:
  /// **'Terminates processes'**
  String get warnKill;

  /// No description provided for @warnDownload.
  ///
  /// In en, this message translates to:
  /// **'Downloads from the internet'**
  String get warnDownload;

  /// No description provided for @warnFirewall.
  ///
  /// In en, this message translates to:
  /// **'Changes the firewall'**
  String get warnFirewall;

  /// No description provided for @guardReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm it’s you to access the server'**
  String get guardReason;

  /// No description provided for @guardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No screen lock or fingerprint is set up on this device. Turn one on in the phone settings: without it, access to the server stays closed.'**
  String get guardUnavailable;

  /// No description provided for @guardDenied.
  ///
  /// In en, this message translates to:
  /// **'Access closed'**
  String get guardDenied;

  /// No description provided for @guardChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get guardChecking;

  /// No description provided for @guardUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get guardUnlock;

  /// No description provided for @ragSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Knowledge base'**
  String get ragSectionTitle;

  /// No description provided for @ragHint.
  ///
  /// In en, this message translates to:
  /// **'Documentation and approved solutions help the AI with typical errors. Only a scrubbed excerpt of the error is sent.'**
  String get ragHint;

  /// No description provided for @ragAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get ragAddressLabel;

  /// No description provided for @ragKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Access key'**
  String get ragKeyLabel;

  /// No description provided for @ragSaveKey.
  ///
  /// In en, this message translates to:
  /// **'Save access key'**
  String get ragSaveKey;

  /// No description provided for @ragKeySaved.
  ///
  /// In en, this message translates to:
  /// **'Access key saved'**
  String get ragKeySaved;

  /// No description provided for @ragKeyDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete access key'**
  String get ragKeyDeleteTooltip;

  /// No description provided for @ragClearKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the access key?'**
  String get ragClearKeyTitle;

  /// No description provided for @ragClearKeyBody.
  ///
  /// In en, this message translates to:
  /// **'The AI will repair without the knowledge base.'**
  String get ragClearKeyBody;

  /// No description provided for @ragCheck.
  ///
  /// In en, this message translates to:
  /// **'Check knowledge base'**
  String get ragCheck;

  /// No description provided for @ragCheckOk.
  ///
  /// In en, this message translates to:
  /// **'Connected. Passages found: {count}'**
  String ragCheckOk(int count);

  /// No description provided for @ragErrUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'The server rejected the key.'**
  String get ragErrUnauthorized;

  /// No description provided for @ragErrRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Try again in {seconds} s.'**
  String ragErrRateLimited(int seconds);

  /// No description provided for @ragErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the knowledge base.'**
  String get ragErrNetwork;

  /// No description provided for @ragErrServer.
  ///
  /// In en, this message translates to:
  /// **'The knowledge base failed (HTTP {status}).'**
  String ragErrServer(int status);

  /// No description provided for @ragErrBadResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected reply from the knowledge base.'**
  String get ragErrBadResponse;

  /// No description provided for @ragNoKey.
  ///
  /// In en, this message translates to:
  /// **'Save an access key first.'**
  String get ragNoKey;

  /// No description provided for @monitorChannelName.
  ///
  /// In en, this message translates to:
  /// **'Install progress'**
  String get monitorChannelName;

  /// No description provided for @monitorTitle.
  ///
  /// In en, this message translates to:
  /// **'SolAgent: install in progress'**
  String get monitorTitle;

  /// No description provided for @monitorStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get monitorStarting;

  /// No description provided for @monitorStep.
  ///
  /// In en, this message translates to:
  /// **'Step: {step}'**
  String monitorStep(String step);

  /// No description provided for @monitorWaiting.
  ///
  /// In en, this message translates to:
  /// **'No connection to the server, retrying. The install keeps running.'**
  String get monitorWaiting;

  /// No description provided for @monitorFinishedOk.
  ///
  /// In en, this message translates to:
  /// **'Install finished'**
  String get monitorFinishedOk;

  /// No description provided for @monitorFinishedFailed.
  ///
  /// In en, this message translates to:
  /// **'Install finished with an error'**
  String get monitorFinishedFailed;

  /// No description provided for @monitorLost.
  ///
  /// In en, this message translates to:
  /// **'The install process was stopped on the server'**
  String get monitorLost;

  /// No description provided for @fixStatusStopping.
  ///
  /// In en, this message translates to:
  /// **'Stopping the install…'**
  String get fixStatusStopping;

  /// No description provided for @fixDemoStopping.
  ///
  /// In en, this message translates to:
  /// **'Stopping…'**
  String get fixDemoStopping;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
