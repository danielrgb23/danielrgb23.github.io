import 'package:daniel_portfolio/data/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preloadAvatar warms the cache entry Image.asset will use',
      (tester) async {
    // A context to build the same ImageConfiguration a real Image.asset gets.
    // No Image widget exists yet, so nothing else can populate the cache.
    late ImageConfiguration config;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            config = createLocalImageConfiguration(context);
            return const SizedBox();
          },
        ),
      ),
    );
    const provider = AssetImage(avatarAsset);
    final key = await provider.obtainKey(config);

    imageCache.clear();
    expect(imageCache.containsKey(key), isFalse, reason: 'control: cold cache');

    await tester.runAsync(preloadAvatar);
    expect(imageCache.containsKey(key), isTrue);
  });
}
