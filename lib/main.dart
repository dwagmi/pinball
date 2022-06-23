import 'package:authentication_repository/authentication_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:leaderboard_repository/leaderboard_repository.dart';
import 'package:pinball/app/app.dart';
import 'package:pinball/bootstrap.dart';
import 'package:pinball/firebase_options.dart';
import 'package:pinball_audio/pinball_audio.dart';
import 'package:platform_helper/platform_helper.dart';
import 'package:share_repository/share_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await bootstrap((firestore, firebaseAuth) async {
    final leaderboardRepository = LeaderboardRepository(firestore);
    const shareRepository =
        ShareRepository(appUrl: ShareRepository.pinballGameUrl);
    final authenticationRepository = AuthenticationRepository(firebaseAuth);
    final pinballAudioPlayer = PinballAudioPlayer();
    final platformHelper = PlatformHelper();

    await authenticationRepository.authenticateAnonymously();
    return App(
      authenticationRepository: authenticationRepository,
      leaderboardRepository: leaderboardRepository,
      shareRepository: shareRepository,
      pinballAudioPlayer: pinballAudioPlayer,
      platformHelper: platformHelper,
    );
  });
}
