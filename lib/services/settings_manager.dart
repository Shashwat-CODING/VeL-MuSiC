import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../themes/colors.dart';

import '../ytmusic/ytmusic.dart';

Box _box = Hive.box('SETTINGS');

class SettingsManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final List<ThemeMode> _themeModes = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark
  ];
  late Map<String, String> _location;
  late Map<String, String> _language;
  final List<AudioQuality> _audioQualities = [
    AudioQuality.high,
    AudioQuality.low
  ];
  List<WindowEffect> get windowEffectList => [
        WindowEffect.disabled,
        WindowEffect.solid,
        WindowEffect.transparent,
        WindowEffect.acrylic,
        WindowEffect.mica,
        WindowEffect.tabbed,
        WindowEffect.aero,
      ];
  AudioQuality _streamingQuality = AudioQuality.high;
  AudioQuality _downloadQuality = AudioQuality.high;
  bool _skipSilence = false;
  Color? _accentColor;
  bool _amoledBlack = true;
  bool _dynamicColors = false;
  

  

  WindowEffect _windowEffect = WindowEffect.disabled;
  bool _equalizerEnabled = false;
  List<double> _equalizerBandsGain = [];
  bool _loudnessEnabled = false;
  double _loudnessTargetGain = 0.0;

  ThemeMode get themeMode => _themeMode;
  List<ThemeMode> get themeModes => _themeModes;
  Map<String, String> get location => _location;
  List<Map<String, String>> get locations => _countries;
  Map<String, String> get language => _language;
  List<Map<String, String>> get languages => _languages;
  List<AudioQuality> get audioQualities => _audioQualities;
  AudioQuality get streamingQuality => _streamingQuality;
  AudioQuality get downloadQuality => _downloadQuality;
  bool get skipSilence => _skipSilence;

  Color? get accentColor => _accentColor;
  bool get amoledBlack => _amoledBlack;
  bool get dynamicColors => _dynamicColors;
  WindowEffect get windowEffect => _windowEffect;
  bool get equalizerEnabled => _equalizerEnabled;
  List<double> get equalizerBandsGain => _equalizerBandsGain;
  bool get loudnessEnabled => _loudnessEnabled;
  double get loudnessTargetGain => _loudnessTargetGain;

  Map get settings => _box.toMap();
  SettingsManager() {
    _init();
  }
  _init() {
    _themeMode = _themeModes[_box.get('THEME_MODE', defaultValue: 0)];
    _language = _languages.firstWhere((language) =>
        language['value'] == _box.get('LANGUAGE', defaultValue: 'en-IN'));
    _accentColor = _box.get('ACCENT_COLOR') != null
        ? Color(_box.get('ACCENT_COLOR'))
        : null;
    _amoledBlack = _box.get('AMOLED_BLACK', defaultValue: true);
    _dynamicColors = _box.get('DYNAMIC_COLORS', defaultValue: false);
    _windowEffect = windowEffectList.firstWhere((el) =>
        el.name.toUpperCase() ==
        _box.get('WINDOW_EFFECT',
            defaultValue: WindowEffect.disabled.name.toUpperCase()));

    _location = _countries.firstWhere((country) =>
        country['value'] == _box.get('LOCATION', defaultValue: 'IN'));

    _streamingQuality =
        _audioQualities[_box.get('STREAMING_QUALITY', defaultValue: 0)];
    _downloadQuality =
        _audioQualities[_box.get('DOWNLOAD_QUALITY', defaultValue: 0)];
    _skipSilence = _box.get('SKIP_SILENCE', defaultValue: false);
    _equalizerEnabled = _box.get('EQUALIZER_ENABLED', defaultValue: false);
    _loudnessEnabled = _box.get('LOUDNESS_ENABLED', defaultValue: false);
    _loudnessTargetGain = _box.get('LOUDNESS_TARGET_GAIN', defaultValue: 0.0);
    _equalizerBandsGain =
        _box.get('EQUALIZER_BANDS_GAIN', defaultValue: []).cast<double>();
  }

  setThemeMode(ThemeMode mode) async {
    _box.put('THEME_MODE', _themeModes.indexOf(mode));
    _themeMode = mode;
    if (Platform.isWindows) {
      await Window.setEffect(
        effect: _windowEffect,
        dark: getDarkness(_themeModes.indexOf(mode)),
      );
    }
    notifyListeners();
  }

  setwindowEffect(WindowEffect effect) async {
    _box.put('WINDOW_EFFECT', effect.name.toUpperCase());
    _windowEffect = effect;

    await Window.setEffect(
      effect: _windowEffect,
      dark: getDarkness(_themeModes.indexOf(_themeMode)),
    );

    notifyListeners();
  }

  set location(Map<String, String> value) {
    _box.put('LOCATION', value['value']);
    _location = value;
    GetIt.I<YTMusic>().refreshContext();
    notifyListeners();
  }

  set language(Map<String, String> value) {
    _box.put('LANGUAGE', value['value']);
    _language = value;
    GetIt.I<YTMusic>().refreshContext();
    notifyListeners();
  }

  set streamingQuality(AudioQuality value) {
    _box.put('STREAMING_QUALITY', _audioQualities.indexOf(value));
    _streamingQuality = value;
    notifyListeners();
  }

  set downloadQuality(AudioQuality value) {
    _box.put('DOWNLOAD_QUALITY', _audioQualities.indexOf(value));
    _downloadQuality = value;
    notifyListeners();
  }

  set skipSilence(bool value) {
    _box.put('SKIP_SILENCE', value);
    _skipSilence = value;
    notifyListeners();
  }

  set accentColor(Color? color) {
    print('🎨 Setting accent color to: $color');
    int? c = color?.value;
    _box.put('ACCENT_COLOR', c);
    _accentColor = color;
    
    // Force immediate UI rebuild
    notifyListeners();
    
    // Multiple delayed notifications to ensure all UI elements rebuild
    Future.delayed(const Duration(milliseconds: 50), () {
      print('🎨 Delayed notification 1');
      notifyListeners();
    });
    
    Future.delayed(const Duration(milliseconds: 150), () {
      print('🎨 Delayed notification 2');
      notifyListeners();
    });
    
    Future.delayed(const Duration(milliseconds: 300), () {
      print('🎨 Delayed notification 3');
      notifyListeners();
    });
    
    // Force a complete app rebuild
    Future.delayed(const Duration(milliseconds: 400), () {
      forceAppRebuild();
    });
    
    print('🎨 Notified listeners, new accent color: $_accentColor');
  }

  Future<void> setAccentColorFromArtwork(String? imageUrl) async {
    if (imageUrl == null) return;
    
    print('🎨 Extracting color from artwork: $imageUrl');
    
    try {
      // Use the same method as the player for consistent color extraction
      final colorScheme = await ColorScheme.fromImageProvider(
        provider: CachedNetworkImageProvider(imageUrl),
      );
      
      final extractedColor = colorScheme.primary;
      
      print('🎨 Extracted color from image: $extractedColor');
      print('🎨 Final selected color: $extractedColor');

      accentColor = extractedColor;
      print('🎨 Set accent color to: $accentColor');
      print('🎨 Enhanced notification system activated');
      
    } catch (e) {
      print('❌ Color extraction failed: $e');
      print('🎨 Using fallback color: spotifyGreen');
      accentColor = spotifyGreen;
      print('🎨 Enhanced notification system activated');
      print('🎨 Set accent color to: $accentColor');
    }
  }

  // Force a complete app rebuild by triggering multiple notifications
  void forceAppRebuild() {
    print('🔄 Forcing complete app rebuild');
    notifyListeners();
    
    // Multiple delayed notifications to ensure all UI rebuilds
    Future.delayed(const Duration(milliseconds: 100), () {
      print('🔄 Delayed rebuild notification 1');
      notifyListeners();
    });
    
    Future.delayed(const Duration(milliseconds: 300), () {
      print('🔄 Delayed rebuild notification 2');
      notifyListeners();
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      print('🔄 Delayed rebuild notification 3');
      notifyListeners();
    });
  }

  // Get gradient colors based on accent color
  List<Color> getGradientColors() {
    if (_accentColor == null) return [spotifyGreen, spotifyDarkGreen];
    
    return [
      _accentColor!,
      _accentColor!.withOpacity(0.8),
      _accentColor!.withOpacity(0.6),
    ];
  }

  // Get subtle background color with accent color
  Color getSubtleBackgroundColor() {
    if (_accentColor == null) return spotifyDarkGrey;
    return _accentColor!.withOpacity(0.15);
  }

  // Get card background color with accent color
  Color getCardBackgroundColor() {
    if (_accentColor == null) return spotifyDarkGrey;
    return _accentColor!.withOpacity(0.2);
  }

  set amoledBlack(bool val) {
    _box.put('AMOLED_BLACK', val);
    _amoledBlack = val;
    notifyListeners();
  }

  set dynamicColors(bool isMaterial) {
    _box.put('DYNAMIC_COLORS', isMaterial);
    _dynamicColors = isMaterial;
    notifyListeners();
  }

  set equalizerEnabled(bool enabled) {
    _box.put('EQUALIZER_ENABLED', enabled);
    _equalizerEnabled = enabled;
    notifyListeners();
  }

  set equalizerBandsGain(List<double>? value) {
    if (value != null) {
      _box.put('EQUALIZER_BANDS_GAIN', value);
      _equalizerBandsGain = value;
      notifyListeners();
    }
  }

  Future<void> setEqualizerBandsGain(int index, double value) async {
    _equalizerBandsGain[index] = value;
    await _box.put('EQUALIZER_BANDS_GAIN', equalizerBandsGain);
    notifyListeners();
  }

  set loudnessEnabled(enabled) {
    _box.put('LOUDNESS_ENABLED', enabled);
    _loudnessEnabled = enabled;
    notifyListeners();
  }

  set loudnessTargetGain(double value) {
    _box.put('LOUDNESS_TARGET_GAIN', value);
    _loudnessTargetGain = value;
    notifyListeners();
  }

  Future<void> setSettings(Map value) async {
    await Future.forEach(value.entries, (entry) async {
      await _box.put(entry.key, entry.value);
    });
    notifyListeners();
    _init();
  }
}

bool getDarkness(int themeMode) {
  if (themeMode == 0) {
    return MediaQueryData.fromView(
                    WidgetsBinding.instance.platformDispatcher.views.first)
                .platformBrightness ==
            Brightness.dark
        ? true
        : false;
  } else if (themeMode == 2) {
    return true;
  }
  return false;
}

enum AudioQuality { high, low }

List<Map<String, String>> _countries = [
  {"name": "Algeria", "value": "DZ"},
  {"name": "Argentina", "value": "AR"},
  {"name": "Australia", "value": "AU"},
  {"name": "Austria", "value": "AT"},
  {"name": "Azerbaijan", "value": "AZ"},
  {"name": "Bahrain", "value": "BH"},
  {"name": "Bangladesh", "value": "BD"},
  {"name": "Belarus", "value": "BY"},
  {"name": "Belgium", "value": "BE"},
  {"name": "Bolivia", "value": "BO"},
  {"name": "Bosnia and Herzegovina", "value": "BA"},
  {"name": "Brazil", "value": "BR"},
  {"name": "Bulgaria", "value": "BG"},
  {"name": "Cambodia", "value": "KH"},
  {"name": "Canada", "value": "CA"},
  {"name": "Chile", "value": "CL"},
  {"name": "Colombia", "value": "CO"},
  {"name": "Costa Rica", "value": "CR"},
  {"name": "Croatia", "value": "HR"},
  {"name": "Cyprus", "value": "CY"},
  {"name": "Czechia", "value": "CZ"},
  {"name": "Denmark", "value": "DK"},
  {"name": "Dominican Republic", "value": "DO"},
  {"name": "Ecuador", "value": "EC"},
  {"name": "Egypt", "value": "EG"},
  {"name": "El Salvador", "value": "SV"},
  {"name": "Estonia", "value": "EE"},
  {"name": "Finland", "value": "FI"},
  {"name": "France", "value": "FR"},
  {"name": "Georgia", "value": "GE"},
  {"name": "Germany", "value": "DE"},
  {"name": "Ghana", "value": "GH"},
  {"name": "Greece", "value": "GR"},
  {"name": "Guatemala", "value": "GT"},
  {"name": "Honduras", "value": "HN"},
  {"name": "Hong Kong", "value": "HK"},
  {"name": "Hungary", "value": "HU"},
  {"name": "Iceland", "value": "IS"},
  {"name": "India", "value": "IN"},
  {"name": "Indonesia", "value": "ID"},
  {"name": "Iraq", "value": "IQ"},
  {"name": "Ireland", "value": "IE"},
  {"name": "Israel", "value": "IL"},
  {"name": "Italy", "value": "IT"},
  {"name": "Jamaica", "value": "JM"},
  {"name": "Japan", "value": "JP"},
  {"name": "Jordan", "value": "JO"},
  {"name": "Kazakhstan", "value": "KZ"},
  {"name": "Kenya", "value": "KE"},
  {"name": "Kuwait", "value": "KW"},
  {"name": "Laos", "value": "LA"},
  {"name": "Latvia", "value": "LV"},
  {"name": "Lebanon", "value": "LB"},
  {"name": "Libya", "value": "LY"},
  {"name": "Liechtenstein", "value": "LI"},
  {"name": "Lithuania", "value": "LT"},
  {"name": "Luxembourg", "value": "LU"},
  {"name": "Malaysia", "value": "MY"},
  {"name": "Malta", "value": "MT"},
  {"name": "Mexico", "value": "MX"},
  {"name": "Moldova", "value": "MD"},
  {"name": "Montenegro", "value": "ME"},
  {"name": "Morocco", "value": "MA"},
  {"name": "Nepal", "value": "NP"},
  {"name": "Netherlands", "value": "NL"},
  {"name": "New Zealand", "value": "NZ"},
  {"name": "Nicaragua", "value": "NI"},
  {"name": "Nigeria", "value": "NG"},
  {"name": "North Macedonia", "value": "MK"},
  {"name": "Norway", "value": "NO"},
  {"name": "Oman", "value": "OM"},
  {"name": "Pakistan", "value": "PK"},
  {"name": "Panama", "value": "PA"},
  {"name": "Papua New Guinea", "value": "PG"},
  {"name": "Paraguay", "value": "PY"},
  {"name": "Peru", "value": "PE"},
  {"name": "Philippines", "value": "PH"},
  {"name": "Poland", "value": "PL"},
  {"name": "Portugal", "value": "PT"},
  {"name": "Puerto Rico", "value": "PR"},
  {"name": "Qatar", "value": "QA"},
  {"name": "Romania", "value": "RO"},
  {"name": "Russia", "value": "RU"},
  {"name": "Saudi Arabia", "value": "SA"},
  {"name": "Senegal", "value": "SN"},
  {"name": "Serbia", "value": "RS"},
  {"name": "Singapore", "value": "SG"},
  {"name": "Slovakia", "value": "SK"},
  {"name": "Slovenia", "value": "SI"},
  {"name": "South Africa", "value": "ZA"},
  {"name": "South Korea", "value": "KR"},
  {"name": "Spain", "value": "ES"},
  {"name": "Sri Lanka", "value": "LK"},
  {"name": "Sweden", "value": "SE"},
  {"name": "Switzerland", "value": "CH"},
  {"name": "Taiwan", "value": "TW"},
  {"name": "Tanzania", "value": "TZ"},
  {"name": "Thailand", "value": "TH"},
  {"name": "Tunisia", "value": "TN"},
  {"name": "Turkey", "value": "TR"},
  {"name": "Uganda", "value": "UG"},
  {"name": "Ukraine", "value": "UA"},
  {"name": "United Arab Emirates", "value": "AE"},
  {"name": "United Kingdom", "value": "GB"},
  {"name": "United States", "value": "US"},
  {"name": "Uruguay", "value": "UY"},
  {"name": "Venezuela", "value": "VE"},
  {"name": "Vietnam", "value": "VN"},
  {"name": "Yemen", "value": "YE"},
  {"name": "Zimbabwe", "value": "ZW"}
];

List<Map<String, String>> _languages = [
  {"name": "Afrikaans", "value": "af"},
  {"name": "Azərbaycan", "value": "az"},
  {"name": "Bahasa Indonesia", "value": "id"},
  {"name": "Bahasa Malaysia", "value": "ms"},
  {"name": "Bosanski", "value": "bs"},
  {"name": "Català", "value": "ca"},
  {"name": "Čeština", "value": "cs"},
  {"name": "Dansk", "value": "da"},
  {"name": "Deutsch", "value": "de"},
  {"name": "Eesti", "value": "et"},
  {"name": "English (India)", "value": "en-IN"},
  {"name": "English (UK)", "value": "en-GB"},
  {"name": "English (US)", "value": "en"},
  {"name": "Español (España)", "value": "es"},
  {"name": "Español (Latinoamérica)", "value": "es-419"},
  {"name": "Español (US)", "value": "es-US"},
  {"name": "Euskara", "value": "eu"},
  {"name": "Filipino", "value": "fil"},
  {"name": "Français", "value": "fr"},
  {"name": "Français (Canada)", "value": "fr-CA"},
  {"name": "Galego", "value": "gl"},
  {"name": "Hrvatski", "value": "hr"},
  {"name": "IsiZulu", "value": "zu"},
  {"name": "Íslenska", "value": "is"},
  {"name": "Italiano", "value": "it"},
  {"name": "Kiswahili", "value": "sw"},
  {"name": "Latviešu valoda", "value": "lv"},
  {"name": "Lietuvių", "value": "lt"},
  {"name": "Magyar", "value": "hu"},
  {"name": "Nederlands", "value": "nl"},
  {"name": "Norsk", "value": "no"},
  {"name": "O‘zbek", "value": "uz"},
  {"name": "Polski", "value": "pl"},
  {"name": "Português", "value": "pt-PT"},
  {"name": "Português (Brasil)", "value": "pt"},
  {"name": "Română", "value": "ro"},
  {"name": "Shqip", "value": "sq"},
  {"name": "Slovenčina", "value": "sk"},
  {"name": "Slovenščina", "value": "sl"},
  {"name": "Srpski", "value": "sr-Latn"},
  {"name": "Suomi", "value": "fi"},
  {"name": "Svenska", "value": "sv"},
  {"name": "Tiếng Việt", "value": "vi"},
  {"name": "Türkçe", "value": "tr"},
  {"name": "Беларуская", "value": "be"},
  {"name": "Български", "value": "bg"},
  {"name": "Кыргызча", "value": "ky"},
  {"name": "Қазақ Тілі", "value": "kk"},
  {"name": "Македонски", "value": "mk"},
  {"name": "Монгол", "value": "mn"},
  {"name": "Русский", "value": "ru"},
  {"name": "Српски", "value": "sr"},
  {"name": "Українська", "value": "uk"},
  {"name": "Ελληνικά", "value": "el"},
  {"name": "Հայերեն", "value": "hy"},
  {"name": "עברית", "value": "iw"},
  {"name": "اردو", "value": "ur"},
  {"name": "العربية", "value": "ar"},
  {"name": "فارسی", "value": "fa"},
  {"name": "नेपाली", "value": "ne"},
  {"name": "मराठी", "value": "mr"},
  {"name": "हिन्दी", "value": "hi"},
  {"name": "অসমীয়া", "value": "as"},
  {"name": "বাংলা", "value": "bn"},
  {"name": "ਪੰਜਾਬੀ", "value": "pa"},
  {"name": "ગુજરાતી", "value": "gu"},
  {"name": "ଓଡ଼ିଆ", "value": "or"},
  {"name": "தமிழ்", "value": "ta"},
  {"name": "తెలుగు", "value": "te"},
  {"name": "ಕನ್ನಡ", "value": "kn"},
  {"name": "മലയാളം", "value": "ml"},
  {"name": "සිංහල", "value": "si"},
  {"name": "ภาษาไทย", "value": "th"},
  {"name": "ລາວ", "value": "lo"},
  {"name": "ဗမာ", "value": "my"},
  {"name": "ქართული", "value": "ka"},
  {"name": "አማርኛ", "value": "am"},
  {"name": "ខ្មែរ", "value": "km"},
  {"name": "中文 (简体)", "value": "zh-CN"},
  {"name": "中文 (繁體)", "value": "zh-TW"},
  {"name": "中文 (香港)", "value": "zh-HK"},
  {"name": "日本語", "value": "ja"},
  {"name": "한국어", "value": "ko"}
];
