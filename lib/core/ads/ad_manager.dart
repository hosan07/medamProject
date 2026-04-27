import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  AdManager._();

  static final AdManager instance = AdManager._();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  static Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }
    await MobileAds.instance.initialize();
  }

  BannerAd initBannerAd({
    AdSize size = AdSize.banner,
    VoidCallback? onLoaded,
    void Function(LoadAdError error)? onFailed,
  }) {
    final banner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded?.call(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed?.call(error);
        },
      ),
    );
    banner.load();
    return banner;
  }

  void initInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) {
      return;
    }

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isInterstitialLoading = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (_) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<bool> showInterstitialAd() async {
    final ad = _interstitialAd;
    if (ad == null) {
      initInterstitialAd();
      return false;
    }

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        initInterstitialAd();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitialAd = null;
        initInterstitialAd();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );
    await ad.show();
    return completer.future;
  }

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return 'unused';
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return 'unused';
  }
}

class MedamBannerAd extends StatefulWidget {
  const MedamBannerAd({super.key});

  @override
  State<MedamBannerAd> createState() => _MedamBannerAdState();
}

class _MedamBannerAdState extends State<MedamBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = AdManager.instance.initBannerAd(
      onLoaded: () {
        if (mounted) {
          setState(() => _isLoaded = true);
        }
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _bannerAd;
    if (!_isLoaded || banner == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      ),
    );
  }
}
