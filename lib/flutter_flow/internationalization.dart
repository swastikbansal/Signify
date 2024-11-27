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
    'wz6eakba': {
      'en': '',
      'hi': '',
    },
    'v4uk70of': {
      'en': 'Type to translate',
      'hi': 'अनुवाद करने के लिए टाइप करें',
    },
    'iriw5ix1': {
      'en': 'Voice to Sign',
      'hi': 'आवाज़ से हस्ताक्षर',
    },
    'ktfggi18': {
      'en': 'Voice to sign',
      'hi': 'आवाज़ से हस्ताक्षर',
    },
  },
  // signtovoice2
  {
    'bvy4o6by': {
      'en': 'English',
      'hi': '',
    },
    'd24i707f': {
      'en': 'English',
      'hi': '',
    },
    '7m2y2l69': {
      'en': 'Hindi',
      'hi': '',
    },
    'ibczj7lb': {
      'en': 'Marathi',
      'hi': '',
    },
    '6lmmq93s': {
      'en': 'Telgu',
      'hi': '',
    },
    '0lqgt6mm': {
      'en': 'Punjabi',
      'hi': '',
    },
    '80zs9si9': {
      'en': 'Gujrati',
      'hi': '',
    },
    'drx645ue': {
      'en': 'Select Language',
      'hi': '',
    },
    'b71xuugh': {
      'en': 'Search...',
      'hi': '',
    },
    'nt3iz8g2': {
      'en': 'Translated Text',
      'hi': 'अनूदित पाठ',
    },
    'helpdw8b': {
      'en': 'Sign to Voice',
      'hi': 'आवाज़ के लिए संकेत',
    },
    'vgleqcd8': {
      'en': 'Sign to Voice',
      'hi': 'आवाज़ के लिए संकेत',
    },
  },
  // account
  {
    'opa1gsfg': {
      'en': 'Account',
      'hi': 'खाता',
    },
    'pyaebrd0': {
      'en': 'Elaine Edwards',
      'hi': 'एलेन एडवर्ड्स',
    },
    'cxr8x8my': {
      'en': 'elaine.edwards@google.com',
      'hi': 'elaine.edwards@google.com',
    },
    'ftlfnl17': {
      'en': 'Switch to Dark Mode',
      'hi': 'डार्क मोड पर स्विच करें',
    },
    'qadjglei': {
      'en': 'Switch to Light Mode',
      'hi': 'लाइट मोड पर स्विच करें',
    },
    'uqk0102r': {
      'en': 'Account Settings',
      'hi': 'अकाउंट सेटिंग',
    },
    '0atseb36': {
      'en': 'Change Password',
      'hi': 'पासवर्ड बदलें',
    },
    'p8q20g0b': {
      'en': 'Edit Profile',
      'hi': 'प्रोफ़ाइल संपादित करें',
    },
    'fk8qzqux': {
      'en': 'Support',
      'hi': 'सहायता',
    },
    'ykhohr2e': {
      'en': 'Settings',
      'hi': 'सेटिंग्स',
    },
    'qvrt3ym6': {
      'en': 'Tutorial',
      'hi': 'ट्यूटोरियल',
    },
    '3yem8mmx': {
      'en': 'Submit a Bug',
      'hi': 'बग सबमिट करें',
    },
    'wvcbff35': {
      'en': 'Submit a Feature Request',
      'hi': 'फ़ीचर अनुरोध सबमिट करें',
    },
    'l2zmexq5': {
      'en': 'Logout',
      'hi': 'लॉग आउट',
    },
    'i7imiuyr': {
      'en': 'Account',
      'hi': 'खाता',
    },
  },
  // education
  {
    'p01mcqgl': {
      'en': 'Hey Manuel',
      'hi': 'हे मैनुअल!',
    },
    'ddp2sajy': {
      'en': 'Stay up to date with the latest news below.',
      'hi': 'नीचे दी गई ताजा खबरों से अपडेट रहें।',
    },
    '6xkomr20': {
      'en': 'Search all articles...',
      'hi': 'सभी लेख खोजें...',
    },
    'fzy0yjab': {
      'en': 'HSBC is getting back into consumer lending...',
      'hi': 'एचएसबीसी उपभोक्ता ऋण देने के क्षेत्र में वापस आ रहा है...',
    },
    '6nkng215': {
      'en': 'Jackson Hewiit',
      'hi': 'जैक्सन हेविट',
    },
    'p9122ujx': {
      'en': '24',
      'hi': '24',
    },
    '7zfaar95': {
      'en': '12h',
      'hi': '12 घंटे',
    },
    '0x77h9h6': {
      'en': 'HSBC is getting back into consumer lending...',
      'hi': 'एचएसबीसी उपभोक्ता ऋण देने के क्षेत्र में वापस आ रहा है...',
    },
    '8ookai0n': {
      'en': 'Jackson Hewiit',
      'hi': 'जैक्सन हेविट',
    },
    'u6lijkb0': {
      'en': '24',
      'hi': '24',
    },
    'v26i76vt': {
      'en': '12h',
      'hi': '12 घंटे',
    },
    'jduozejm': {
      'en': 'For You',
      'hi': 'आपके लिए',
    },
    'a68hn241': {
      'en': 'Sci-Fi',
      'hi': 'विज्ञान-कथा',
    },
    'rk7baojg': {
      'en': 'Fiction',
      'hi': 'कल्पना',
    },
    'ds2qf966': {
      'en': 'Technology',
      'hi': 'तकनीकी',
    },
    'okg8jrdj': {
      'en': 'Ai News',
      'hi': 'एआई न्यूज़',
    },
    'jcrcyrzm': {
      'en': 'Startups',
      'hi': 'स्टार्टअप',
    },
    '7y1ozxqa': {
      'en': 'For You',
      'hi': 'आपके लिए',
    },
    'gebkvr2g': {
      'en': 'Popular Today',
      'hi': 'आज लोकप्रिय',
    },
    'lythb4ih': {
      'en':
          'HSBC is getting back into consumer lending in the us according to...',
      'hi': 'एचएसबीसी अमेरिका में उपभोक्ता ऋण देने में वापस आ रहा है...',
    },
    '79wf5ril': {
      'en': 'Jackson Hewiit',
      'hi': 'जैक्सन हेविट',
    },
    'x1gfjzsy': {
      'en': '24',
      'hi': '24',
    },
    'd77x6xsp': {
      'en': '12h',
      'hi': '12 घंटे',
    },
    '2tvxijww': {
      'en': 'Read Now',
      'hi': 'अभी पढ़ें',
    },
    '3qjzcg9k': {
      'en':
          'HSBC is getting back into consumer lending in the us according to...',
      'hi': 'एचएसबीसी अमेरिका में उपभोक्ता ऋण देने में वापस आ रहा है...',
    },
    'u9ttvvk4': {
      'en': 'Jackson Hewiit',
      'hi': 'जैक्सन हेविट',
    },
    'zegojctj': {
      'en': '24',
      'hi': '24',
    },
    'tke25qsr': {
      'en': '12h',
      'hi': '12 घंटे',
    },
    'lw7fn82o': {
      'en': 'Read Now',
      'hi': 'अभी पढ़ें',
    },
    'p985k5iy': {
      'en':
          'HSBC is getting back into consumer lending in the us according to...',
      'hi': 'एचएसबीसी अमेरिका में उपभोक्ता ऋण देने में वापस आ रहा है...',
    },
    '75khnl5b': {
      'en': 'Jackson Hewiit',
      'hi': 'जैक्सन हेविट',
    },
    '4ryf2646': {
      'en': '24',
      'hi': '24',
    },
    'm3m5b57i': {
      'en': '12h',
      'hi': '12 घंटे',
    },
    'mgptg10b': {
      'en': 'Read Now',
      'hi': 'अभी पढ़ें',
    },
    'rdorkg51': {
      'en': 'Education',
      'hi': 'आवाज़ के लिए संकेत',
    },
  },
  // Miscellaneous
  {
    '3r4v0idp': {
      'en': 'Allow camera to capture ISL Signs. ',
      'hi': 'कैमरे को आईएसएल चिह्नों को कैप्चर करने की अनुमति दें।',
    },
    's3h4i5gz': {
      'en': 'Allow microphone access to use Speech Recognition.',
      'hi':
          'वाक् पहचान का उपयोग करने के लिए माइक्रोफ़ोन तक पहुंच की अनुमति दें.',
    },
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
