import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleStorageKey = '__locale_key__';

class FFLocalizations {
  FFLocalizations(this.locale);

  final Locale locale;

  static FFLocalizations of(BuildContext context) =>
      Localizations.of<FFLocalizations>(context, FFLocalizations)!;

  static List<String> languages() => ['en', 'hi'];

  static late SharedPreferences _prefs;
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();
  static Future storeLocale(String locale) =>
      _prefs.setString(_kLocaleStorageKey, locale);
  static Locale? getStoredLocale() {
    final locale = _prefs.getString(_kLocaleStorageKey);
    return locale != null && locale.isNotEmpty ? createLocale(locale) : null;
  }

  String get languageCode => locale.toString();
  String? get languageShortCode =>
      _languagesWithShortCode.contains(locale.toString())
          ? '${locale.toString()}_short'
          : null;
  int get languageIndex => languages().contains(languageCode)
      ? languages().indexOf(languageCode)
      : 0;

  String getText(String key) =>
      (kTranslationsMap[key] ?? {})[locale.toString()] ?? '';

  String getVariableText({
    String? enText = '',
    String? hiText = '',
  }) =>
      [enText, hiText][languageIndex] ?? '';

  static const Set<String> _languagesWithShortCode = {
    'ar',
    'az',
    'ca',
    'cs',
    'da',
    'de',
    'dv',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'gr',
    'he',
    'hi',
    'hu',
    'it',
    'km',
    'ku',
    'mn',
    'ms',
    'no',
    'pt',
    'ro',
    'ru',
    'rw',
    'sv',
    'th',
    'uk',
    'vi',
  };
}

/// Used if the locale is not supported by GlobalMaterialLocalizations.
class FallbackMaterialLocalizationDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(FallbackMaterialLocalizationDelegate old) => false;
}

/// Used if the locale is not supported by GlobalCupertinoLocalizations.
class FallbackCupertinoLocalizationDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(FallbackCupertinoLocalizationDelegate old) => false;
}

class FFLocalizationsDelegate extends LocalizationsDelegate<FFLocalizations> {
  const FFLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<FFLocalizations> load(Locale locale) =>
      SynchronousFuture<FFLocalizations>(FFLocalizations(locale));

  @override
  bool shouldReload(FFLocalizationsDelegate old) => false;
}

Locale createLocale(String language) => language.contains('_')
    ? Locale.fromSubtags(
        languageCode: language.split('_').first,
        scriptCode: language.split('_').last,
      )
    : Locale(language);

bool _isSupportedLocale(Locale locale) {
  final language = locale.toString();
  return FFLocalizations.languages().contains(
    language.endsWith('_')
        ? language.substring(0, language.length - 1)
        : language,
  );
}

final kTranslationsMap = <Map<String, Map<String, String>>>[
  // voicetosign1
  {
    'mofmk3y7': {
      'en': 'Voice to Sign',
      'hi': '',
    },
    'ktfggi18': {
      'en': 'Voice to sign',
      'hi': '',
    },
  },
  // signtovoice2
  {
    'helpdw8b': {
      'en': 'Sign to Voice',
      'hi': '',
    },
    'vgleqcd8': {
      'en': 'Sign to Voice',
      'hi': '',
    },
  },
  // account
  {
    '0plr8zao': {
      'en': 'check.io',
      'hi': '',
    },
    'nxfkvmms': {
      'en': 'Platform Navigation',
      'hi': '',
    },
    'fo03dr10': {
      'en': 'Dashboard',
      'hi': '',
    },
    'htmniitf': {
      'en': 'Chats',
      'hi': '',
    },
    '2nfb9gjz': {
      'en': 'Projects',
      'hi': '',
    },
    'pb8qio10': {
      'en': 'Recent Orders',
      'hi': '',
    },
    'up0x8yda': {
      'en': '12',
      'hi': '',
    },
    '4eq04jq7': {
      'en': 'Settings',
      'hi': '',
    },
    'ytvm4q4s': {
      'en': 'Billing',
      'hi': '',
    },
    'bcuus5s2': {
      'en': 'Explore',
      'hi': '',
    },
    '0hvmjktm': {
      'en': 'Light Mode',
      'hi': '',
    },
    '5eqbgzv5': {
      'en': 'Dark Mode',
      'hi': '',
    },
    'phke9xac': {
      'en': 'Casper Ghost',
      'hi': '',
    },
    'n7bwxsbb': {
      'en': 'admin@gmail.com',
      'hi': '',
    },
    'dd8iradh': {
      'en': 'Casper Ghost',
      'hi': '',
    },
    'lyfkw2r6': {
      'en': 'casper@ghustbusters.com',
      'hi': '',
    },
    'p1ih8xhx': {
      'en': '2,200',
      'hi': '',
    },
    'tgq82f3t': {
      'en': 'Orders Placed',
      'hi': '',
    },
    'yy7ic0or': {
      'en': '\$212.4k',
      'hi': '',
    },
    '08tfmiv7': {
      'en': 'Money Earned',
      'hi': '',
    },
    'l2fk4itw': {
      'en': 'My Account Information',
      'hi': '',
    },
    'xahzriuo': {
      'en': 'Change Password',
      'hi': '',
    },
    '0xglczvg': {
      'en': 'Edit Profile',
      'hi': '',
    },
    'yfeo6cip': {
      'en': 'Support',
      'hi': '',
    },
    'a4jmr8eo': {
      'en': 'Tutorial',
      'hi': '',
    },
    'sm892sb4': {
      'en': 'Submit a Bug',
      'hi': '',
    },
    'gjfmltln': {
      'en': 'Submit a Feature Request',
      'hi': '',
    },
    '0s13co6n': {
      'en': 'Light ',
      'hi': '',
    },
    'gn9s7d1u': {
      'en': 'Dark',
      'hi': '',
    },
    '5plol8na': {
      'en': 'Log Out',
      'hi': '',
    },
    '62x3ju65': {
      'en': 'Account',
      'hi': '',
    },
    'q1v1v0pu': {
      'en': 'Account',
      'hi': '',
    },
  },
  // Miscellaneous
  {
    'qosu3dvi': {
      'en': '',
      'hi': '',
    },
    'uh91lc5h': {
      'en': '',
      'hi': '',
    },
    'xpnzpcrj': {
      'en': '',
      'hi': '',
    },
    'vc4v7o6h': {
      'en': '',
      'hi': '',
    },
    'ydqrk7j3': {
      'en': '',
      'hi': '',
    },
    'gmmte5of': {
      'en': '',
      'hi': '',
    },
    '4e0mkiy4': {
      'en': '',
      'hi': '',
    },
    'j08usgvg': {
      'en': '',
      'hi': '',
    },
    'wk1q6bbg': {
      'en': '',
      'hi': '',
    },
    'y13ld9ca': {
      'en': '',
      'hi': '',
    },
    'l0o2pq94': {
      'en': '',
      'hi': '',
    },
    'ldfhcdtn': {
      'en': '',
      'hi': '',
    },
    'p69so707': {
      'en': '',
      'hi': '',
    },
    'gufoxw3u': {
      'en': '',
      'hi': '',
    },
    '3m5oblqc': {
      'en': '',
      'hi': '',
    },
    'v88kbv30': {
      'en': '',
      'hi': '',
    },
    'zityxbnu': {
      'en': '',
      'hi': '',
    },
    'ai9sfw9v': {
      'en': '',
      'hi': '',
    },
    'uvz02mo7': {
      'en': '',
      'hi': '',
    },
    '76c56ru0': {
      'en': '',
      'hi': '',
    },
    'dg89xl87': {
      'en': '',
      'hi': '',
    },
    '4mw7pyga': {
      'en': '',
      'hi': '',
    },
    'duo04puv': {
      'en': '',
      'hi': '',
    },
    '5lbpozk8': {
      'en': '',
      'hi': '',
    },
    'nu6to8dm': {
      'en': '',
      'hi': '',
    },
  },
].reduce((a, b) => a..addAll(b));
