import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// معرّفات الإعلانات. القيم الافتراضية هي معرّفات الاختبار الرسمية من Google.
// عند النشر الحقيقي مرّر معرّفاتك عبر --dart-define (انظر README) أو متغيرات GitHub.
const String kBannerId = String.fromEnvironment('ADMOB_BANNER',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111');
const String kInterstitialId = String.fromEnvironment('ADMOB_INTERSTITIAL',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712');
const String kRewardedId = String.fromEnvironment('ADMOB_REWARDED',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917');

class Ads {
  static InterstitialAd? _interstitial;
  static RewardedAd? _rewarded;
  static int _stageCounter = 0;

  static Future<void> init() async {
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadRewarded();
  }

  static void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: kInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  static void _loadRewarded() {
    RewardedAd.load(
      adUnitId: kRewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  /// إعلان بيني كل [every] مرحلة منتهية (لا نزعج اللاعب كثيراً)
  static void stageFinished({int every = 2}) {
    _stageCounter++;
    if (_stageCounter % every != 0) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }

  /// إعلان مكافأة: اللاعب يختار المشاهدة مقابل لمعات
  static void showRewarded({
    required VoidCallback onReward,
    required VoidCallback onUnavailable,
  }) {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      onUnavailable();
      return;
    }
    _rewarded = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _loadRewarded();
      },
    );
    ad.show(onUserEarnedReward: (view, reward) => onReward());
  }
}

/// بانر صغير أسفل الشاشة
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: kBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
