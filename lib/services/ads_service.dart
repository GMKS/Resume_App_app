import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'subscription_service.dart';

final myBannerAd = BannerAd(
  size: AdSize.banner,
  adUnitId: 'your-ad-unit-id',
  listener: BannerAdListener(),
  request: AdRequest(),
)..load();

Widget buildAdBanner() {
  if (isPremiumUser) return const SizedBox.shrink();
  return SizedBox(
    width: myBannerAd.size.width.toDouble(),
    height: myBannerAd.size.height.toDouble(),
    child: AdWidget(ad: myBannerAd),
  );
}
