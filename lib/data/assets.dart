import 'dart:async';
import 'package:flutter/widgets.dart';

/// Profile photo, shared by the hero screen and the startup preloader.
const avatarAsset = 'assets/img/profile_image.jpg';

/// Fetches and decodes the profile photo before the first frame.
///
/// On the web an `Image.asset` only starts downloading once it is built, so
/// without this the loading screen would disappear and the photo would pop in
/// a moment later. Waiting here keeps the splash up until it is ready (the
/// image cache then serves the exact same image to `Image.asset`).
Future<void> preloadAvatar() {
  final done = Completer<void>();
  final stream =
      const AssetImage(avatarAsset).resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!done.isCompleted) done.complete();
      stream.removeListener(listener);
    },
    onError: (Object _, StackTrace? __) {
      if (!done.isCompleted) done.complete(); // never block startup on this
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return done.future.timeout(const Duration(seconds: 5), onTimeout: () {});
}
