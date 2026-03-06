import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';

import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/voting_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: MusicPartyApp()));
}

class MusicPartyApp extends StatefulWidget {
  const MusicPartyApp({super.key});

  @override
  State<MusicPartyApp> createState() => _MusicPartyAppState();
}

class _MusicPartyAppState extends State<MusicPartyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // App abierta desde deep link cuando estaba cerrada
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }
    // App ya abierta recibe deep link
    _appLinks.uriLinkStream.listen(_handleLink);
  }

  // musicparty://evento/<eventId>
  void _handleLink(Uri uri) {
    if (uri.scheme == 'musicparty' && uri.host == 'evento') {
      final eventId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      if (eventId != null && eventId.isNotEmpty) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => VotingScreen(eventId: eventId),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MusicParty',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      home: const HomeScreen(),
    );
  }
}
