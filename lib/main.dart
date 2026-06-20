import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MobileAds.instance.initialize();
  runApp(const GamingWallpaperApp());
}

const bannerAdUnitId = 'ca-app-pub-9819570141591797/8311390422';
const adminEmail = 'ritiksharma5563@gmail.com';
const downloadsChannel = MethodChannel('rxt_gaming/downloads');
const liveWallpaperChannel = MethodChannel('rxt_gaming/live_wallpaper');
const ringtoneChannel = MethodChannel('rxt_gaming/ringtone');

bool isAdminEmail(String? email) {
  return email?.trim().toLowerCase() == adminEmail;
}

const premiumBackground = Color(0xFF070A12);
const premiumPanel = Color(0xFF101827);
const premiumCyan = Color(0xFF00E5FF);
const premiumPink = Color(0xFFFF2D92);
const premiumViolet = Color(0xFF7C4DFF);
const premiumGreen = Color(0xFF00FFC6);

const premiumGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [premiumCyan, premiumViolet, premiumPink],
);

PageRouteBuilder<T> smoothRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final secondaryCurve = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0.04),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.03, 0),
            ).animate(secondaryCurve),
            child: child,
          ),
        ),
      );
    },
  );
}

class PremiumActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  const PremiumActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: filled ? premiumGradient : null,
          color: filled ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: filled
                ? Colors.white.withValues(alpha: 0.18)
                : premiumCyan.withValues(alpha: 0.28),
          ),
          boxShadow: enabled && filled
              ? [
                  BoxShadow(
                    color: premiumCyan.withValues(alpha: 0.24),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 19),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: selected ? premiumGradient : null,
        color: selected
            ? null
            : isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? Colors.white.withValues(alpha: 0.2)
              : isDark
                  ? Colors.white.withValues(alpha: 0.09)
                  : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: selected || !isDark
            ? [
                BoxShadow(
                  color: selected
                      ? premiumCyan.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: selected ? 18 : 12,
                  offset: Offset(0, selected ? 8 : 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : isDark
                        ? Colors.white.withValues(alpha: 0.76)
                        : const Color(0xFF111827),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShimmerLoadingGrid extends StatefulWidget {
  const ShimmerLoadingGrid({super.key});

  @override
  State<ShimmerLoadingGrid> createState() => _ShimmerLoadingGridState();
}

class _ShimmerLoadingGridState extends State<ShimmerLoadingGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 620
                ? 3
                : 2;

        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          itemCount: crossAxisCount * 3,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (_, __) => ShimmerWallpaperCard(animation: controller),
        );
      },
    );
  }
}

class ShimmerWallpaperCard extends StatelessWidget {
  final Animation<double> animation;

  const ShimmerWallpaperCard({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(-1.4 + animation.value * 2.8, -1),
                end: Alignment(-0.4 + animation.value * 2.8, 1),
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.06),
                ],
                stops: const [0.25, 0.5, 0.75],
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: premiumPanel,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class GamingWallpaperApp extends StatefulWidget {
  const GamingWallpaperApp({super.key});

  @override
  State<GamingWallpaperApp> createState() => _GamingWallpaperAppState();
}

class _GamingWallpaperAppState extends State<GamingWallpaperApp> {
  bool isDark = true;

  @override
  void initState() {
    super.initState();
    loadSavedTheme();
  }

  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      isDark = prefs.getBool('isDarkTheme') ?? true;
    });
  }

  Future<void> toggleTheme() async {
    final nextValue = !isDark;
    setState(() {
      isDark = nextValue;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', nextValue);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gaming Wallpapers',
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF00E5FF),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF111827),
          titleTextStyle: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: premiumCyan, width: 1.2),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF00E5FF),
        scaffoldBackgroundColor: premiumBackground,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: premiumBackground.withValues(alpha: 0.94),
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: premiumCyan, width: 1.2),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: SplashScreen(
        isDark: isDark,
        onToggleTheme: toggleTheme,
      ),
    );
  }
}

class Wallpaper {
  final String title;
  final String image;
  final String category;

  const Wallpaper({
    required this.title,
    required this.image,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'name': title,
      'image': image,
      'category': category,
    };
  }

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      title: (json['title'] ?? json['name'] ?? 'Untitled').toString(),
      image: (json['image'] ?? '').toString(),
      category: (json['category'] ?? 'Gaming').toString(),
    );
  }

  factory Wallpaper.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Wallpaper.fromJson(doc.data() ?? {});
  }
}

class LiveWallpaperStyle {
  final String title;
  final int colorOne;
  final int colorTwo;
  final int colorThree;
  final double speed;
  final double intensity;
  final String videoUrl;
  final String videoAsset;

  const LiveWallpaperStyle({
    required this.title,
    required this.colorOne,
    required this.colorTwo,
    required this.colorThree,
    this.speed = 1,
    this.intensity = 1,
    this.videoUrl = '',
    this.videoAsset = '',
  });

  bool get isVideo => videoUrl.trim().isNotEmpty || videoAsset.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'colorOne': colorOne,
      'colorTwo': colorTwo,
      'colorThree': colorThree,
      'speed': speed,
      'intensity': intensity,
      'videoUrl': videoUrl,
      'videoAsset': videoAsset,
      'type': isVideo ? 'video' : 'neon',
    };
  }

  factory LiveWallpaperStyle.fromJson(Map<String, dynamic> json) {
    return LiveWallpaperStyle(
      title: (json['title'] ?? 'RXT Neon').toString(),
      colorOne: (json['colorOne'] as num?)?.toInt() ?? premiumCyan.value,
      colorTwo: (json['colorTwo'] as num?)?.toInt() ?? premiumPink.value,
      colorThree: (json['colorThree'] as num?)?.toInt() ?? premiumViolet.value,
      speed:
          ((json['speed'] as num?)?.toDouble().clamp(0.5, 1.6) ?? 1).toDouble(),
      intensity: ((json['intensity'] as num?)
                  ?.toDouble()
                  .clamp(0.6, 1.5) ??
              1)
          .toDouble(),
      videoUrl: (json['videoUrl'] ?? '').toString(),
      videoAsset: (json['videoAsset'] ?? '').toString(),
    );
  }

  factory LiveWallpaperStyle.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return LiveWallpaperStyle.fromJson(doc.data() ?? {});
  }
}

class Ringtone {
  final String title;
  final String audioUrl;
  final String category;
  final String coverImage;
  final int durationSeconds;

  const Ringtone({
    required this.title,
    required this.audioUrl,
    required this.category,
    this.coverImage = '',
    this.durationSeconds = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'audioUrl': audioUrl,
      'category': category,
      'coverImage': coverImage,
      'durationSeconds': durationSeconds,
    };
  }

  factory Ringtone.fromJson(Map<String, dynamic> json) {
    return Ringtone(
      title: (json['title'] ?? 'Untitled').toString(),
      audioUrl: (json['audioUrl'] ?? '').toString(),
      category: (json['category'] ?? 'Gaming').toString(),
      coverImage: (json['coverImage'] ?? '').toString(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  factory Ringtone.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Ringtone.fromJson(doc.data() ?? {});
  }
}

const ringtoneCategories = [
  'Gaming',
  'Action',
  'Epic',
  'Funny',
  'Notification',
];

const wallpaperCategories = [
  'GTA',
  'Forza',
  'Anime',
  'Cars',
  'Gaming Setup',
  'Cyberpunk',
];

const defaultWallpapers = [];

const defaultLiveWallpapers = [
  LiveWallpaperStyle(
    title: 'RXT Local Motion',
    colorOne: 0xFF00E5FF,
    colorTwo: 0xFFFF2D92,
    colorThree: 0xFF7C4DFF,
    videoAsset: 'assets/videos/276544.mp4',
  ),
  LiveWallpaperStyle(
    title: 'RXT Neon Flow',
    colorOne: 0xFF00E5FF,
    colorTwo: 0xFFFF2D92,
    colorThree: 0xFF7C4DFF,
    speed: 1,
    intensity: 1,
  ),
  LiveWallpaperStyle(
    title: 'Cyber Grid',
    colorOne: 0xFF00FFC6,
    colorTwo: 0xFF00E5FF,
    colorThree: 0xFF7C4DFF,
    speed: 0.9,
    intensity: 1.1,
  ),
  LiveWallpaperStyle(
    title: 'Crimson Pulse',
    colorOne: 0xFFFF2D92,
    colorTwo: 0xFFFF5252,
    colorThree: 0xFFFFC107,
    speed: 1.15,
    intensity: 0.95,
  ),
];

class AppData {
  static Future<List<Wallpaper>> loadWallpapers() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('customWallpapers') ?? [];
    final custom = saved.map((item) {
      return Wallpaper.fromJson(jsonDecode(item) as Map<String, dynamic>);
    }).where((wallpaper) {
      return wallpaper.image.isNotEmpty;
    }).toList();

    final firestoreWallpapers = <Wallpaper>[];
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('wallpapers').get();

      for (final doc in snapshot.docs) {
        final wallpaper = Wallpaper.fromFirestore(doc);
        if (wallpaper.image.isNotEmpty) {
          firestoreWallpapers.add(wallpaper);
        }
      }
    } catch (_) {
      // Local/default wallpapers still keep the app usable if Firestore fails.
    }

    final byImage = <String, Wallpaper>{};
    for (final wallpaper in [
      ...firestoreWallpapers,
      ...defaultWallpapers,
      ...custom,
    ]) {
      byImage[wallpaper.image] = wallpaper;
    }

    return byImage.values.toList();
  }

  static Future<void> addWallpaper(Wallpaper wallpaper) async {
    await FirebaseFirestore.instance.collection('wallpapers').add({
      ...wallpaper.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> addLocalWallpaper(Wallpaper wallpaper) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('customWallpapers') ?? [];
    saved.add(jsonEncode(wallpaper.toJson()));
    await prefs.setStringList('customWallpapers', saved);
  }

  static Future<List<LiveWallpaperStyle>> loadLiveWallpapers() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('customLiveWallpapers') ?? [];
    final custom = saved.map((item) {
      return LiveWallpaperStyle.fromJson(
        jsonDecode(item) as Map<String, dynamic>,
      );
    }).toList();

    final firestoreStyles = <LiveWallpaperStyle>[];
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('liveWallpapers').get();

      for (final doc in snapshot.docs) {
        firestoreStyles.add(LiveWallpaperStyle.fromFirestore(doc));
      }
    } catch (_) {
      // Defaults/local live wallpapers still keep the app usable offline.
    }

    final byTitle = <String, LiveWallpaperStyle>{};
    for (final style in [
      ...firestoreStyles,
      ...defaultLiveWallpapers,
      ...custom,
    ]) {
      byTitle[style.title.trim().toLowerCase()] = style;
    }

    return byTitle.values.toList();
  }

  static Future<void> addLiveWallpaper(LiveWallpaperStyle style) async {
    await FirebaseFirestore.instance.collection('liveWallpapers').add({
      ...style.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> addLocalLiveWallpaper(LiveWallpaperStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('customLiveWallpapers') ?? [];
    saved.add(jsonEncode(style.toJson()));
    await prefs.setStringList('customLiveWallpapers', saved);
  }

  static Future<List<String>> getStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }

  static Future<void> saveStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  // ── Ringtones ──────────────────────────────────────────────────────────

  static Future<List<Ringtone>> loadRingtones() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('customRingtones') ?? [];
    final custom = saved.map((item) {
      return Ringtone.fromJson(jsonDecode(item) as Map<String, dynamic>);
    }).where((r) => r.audioUrl.isNotEmpty).toList();

    final firestoreRingtones = <Ringtone>[];
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('ringtones').get();
      for (final doc in snapshot.docs) {
        final r = Ringtone.fromFirestore(doc);
        if (r.audioUrl.isNotEmpty) firestoreRingtones.add(r);
      }
    } catch (_) {
      // Keep app usable offline; rely on local ringtones only.
    }

    final byUrl = <String, Ringtone>{};
    for (final r in [...firestoreRingtones, ...custom]) {
      byUrl[r.audioUrl] = r;
    }
    return byUrl.values.toList();
  }

  static Future<void> addRingtone(Ringtone ringtone) async {
    await FirebaseFirestore.instance.collection('ringtones').add({
      ...ringtone.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> addLocalRingtone(Ringtone ringtone) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('customRingtones') ?? [];
    saved.add(jsonEncode(ringtone.toJson()));
    await prefs.setStringList('customRingtones', saved);
  }
}

class SplashScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SplashScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    openNext();
  }

  Future<void> openNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final nextScreen = user != null
        ? HomeScreen(
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
          )
        : LoginScreen(
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
          );

    Navigator.pushReplacement(
      context,
      smoothRoute(nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: premiumBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.25,
                colors: [
                  Color(0x3329F3FF),
                  Color(0xFF080B16),
                  Color(0xFF03040A),
                ],
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: premiumPink.withValues(alpha: 0.16),
                boxShadow: [
                  BoxShadow(
                    color: premiumPink.withValues(alpha: 0.28),
                    blurRadius: 90,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      gradient: premiumGradient,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: premiumCyan.withValues(alpha: 0.45),
                          blurRadius: 42,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: premiumPink.withValues(alpha: 0.28),
                          blurRadius: 52,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.sports_esports_rounded,
                      color: Colors.white,
                      size: 58,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'RXT Gaming',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      shadows: [
                        Shadow(color: premiumCyan, blurRadius: 24),
                        Shadow(color: premiumPink, blurRadius: 32),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Premium Wallpapers',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(
                    width: 110,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: premiumCyan,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const LoginScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();

    if (FirebaseAuth.instance.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          smoothRoute(
            HomeScreen(
              isDark: widget.isDark,
              onToggleTheme: widget.onToggleTheme,
            ),
          ),
        );
      });
    }
  }

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String error = '';
  bool isLoading = false;
  bool isGoogleLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => error = 'Fill all fields');
      return;
    }

    try {
      setState(() {
        error = '';
        isLoading = true;
      });

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        smoothRoute(
          HomeScreen(
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.message ?? 'Login failed';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      setState(() {
        error = '';
        isGoogleLoading = true;
      });

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        smoothRoute(
          HomeScreen(
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.message ?? 'Google login failed';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'Google login failed';
      });
    } finally {
      if (mounted) {
        setState(() => isGoogleLoading = false);
      }
    }
  }

  void openRegister() {
    Navigator.push(
      context,
      smoothRoute(const RegisterScreen()),
    );
  }

  void openPhoneLogin() {
    Navigator.push(
      context,
      smoothRoute(
        PhoneAuthScreen(
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF00E5FF)),
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFF00E5FF),
                    size: 70,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: usernameController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: inputDecoration('Email', Icons.email_rounded),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: inputDecoration('Password', Icons.lock),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : openPhoneLogin,
                      icon: const Icon(Icons.phone_android_rounded),
                      label: const Text('Login with Phone'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed:
                        isLoading || isGoogleLoading ? null : loginWithGoogle,
                    icon: isGoogleLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Image.asset(
                            'assets/google.png',
                            height: 24,
                          ),
                    label: Text(
                      isGoogleLoading ? 'Signing in...' : 'Sign in with Google',
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : openRegister,
                    child: const Text('Create new account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PhoneAuthScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const PhoneAuthScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  String verificationId = '';
  String error = '';
  bool isSendingOtp = false;
  bool isVerifyingOtp = false;
  bool otpSent = false;
  int resendSeconds = 0;
  Timer? resendTimer;

  @override
  void dispose() {
    resendTimer?.cancel();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  String get formattedPhone {
    final raw = phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (raw.startsWith('+')) return raw;
    if (raw.startsWith('91') && raw.length == 12) return '+$raw';
    return '+91$raw';
  }

  void startResendTimer() {
    resendTimer?.cancel();
    setState(() => resendSeconds = 30);
    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (resendSeconds <= 1) {
        timer.cancel();
        setState(() => resendSeconds = 0);
      } else {
        setState(() => resendSeconds -= 1);
      }
    });
  }

  void openHome() {
    Navigator.pushReplacement(
      context,
      smoothRoute(
        HomeScreen(
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
        ),
      ),
    );
  }

  Future<void> sendOtp({bool resend = false}) async {
    final phone = formattedPhone;

    if (phone.length < 10) {
      setState(() => error = 'Enter a valid phone number');
      return;
    }

    setState(() {
      error = '';
      isSendingOtp = true;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (!mounted) return;
          openHome();
        } on FirebaseAuthException catch (e) {
          if (!mounted) return;
          setState(() => error = e.message ?? 'Phone login failed');
        }
      },
      verificationFailed: (e) {
        if (!mounted) return;
        setState(() {
          error = e.message ?? 'OTP send failed';
          isSendingOtp = false;
        });
      },
      codeSent: (id, token) {
        if (!mounted) return;
        setState(() {
          verificationId = id;
          otpSent = true;
          isSendingOtp = false;
          if (resend) {
            otpController.clear();
          }
        });
        startResendTimer();
      },
      codeAutoRetrievalTimeout: (id) {
        verificationId = id;
      },
    );
  }

  Future<void> verifyOtp() async {
    final smsCode = otpController.text.trim();

    if (verificationId.isEmpty) {
      setState(() => error = 'Please request OTP first');
      return;
    }

    if (smsCode.length < 6) {
      setState(() => error = 'Enter valid 6 digit OTP');
      return;
    }

    try {
      setState(() {
        error = '';
        isVerifyingOtp = true;
      });

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      openHome();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => error = e.message ?? 'OTP verification failed');
    } finally {
      if (mounted) {
        setState(() => isVerifyingOtp = false);
      }
    }
  }

  InputDecoration inputDecoration(String label, IconData icon, String? hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: premiumCyan),
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canResend = otpSent && resendSeconds == 0 && !isSendingOtp;

    return Scaffold(
      backgroundColor: premiumBackground,
      appBar: AppBar(title: const Text('Phone Login')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: premiumPanel,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: premiumCyan.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: premiumGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.phone_android_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Verify Phone',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    otpSent
                        ? 'Enter the OTP sent to ${formattedPhone}'
                        : 'Enter your phone number to receive OTP',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.66)),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: phoneController,
                    enabled: !otpSent && !isSendingOtp,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: inputDecoration(
                      'Phone Number',
                      Icons.phone_rounded,
                      '9876543210',
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: otpSent
                        ? Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: TextField(
                              controller: otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              style: const TextStyle(
                                color: Colors.white,
                                letterSpacing: 6,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: inputDecoration(
                                'OTP',
                                Icons.password_rounded,
                                '000000',
                              ).copyWith(counterText: ''),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: PremiumActionButton(
                      icon:
                          otpSent ? Icons.verified_rounded : Icons.sms_rounded,
                      label: otpSent ? 'Verify OTP' : 'Send OTP',
                      onPressed: isSendingOtp || isVerifyingOtp
                          ? null
                          : otpSent
                              ? () => verifyOtp()
                              : () => sendOtp(),
                    ),
                  ),
                  if (isSendingOtp || isVerifyingOtp) ...[
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(
                      minHeight: 3,
                      color: premiumCyan,
                      backgroundColor: Colors.white24,
                    ),
                  ],
                  if (otpSent) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: canResend ? () => sendOtp(resend: true) : null,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        canResend
                            ? 'Resend OTP'
                            : 'Resend OTP in ${resendSeconds}s',
                      ),
                    ),
                    TextButton(
                      onPressed: isSendingOtp || isVerifyingOtp
                          ? null
                          : () {
                              resendTimer?.cancel();
                              setState(() {
                                otpSent = false;
                                verificationId = '';
                                resendSeconds = 0;
                                otpController.clear();
                                error = '';
                              });
                            },
                      child: const Text('Change phone number'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  String error = '';
  bool isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final email = usernameController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => error = 'Fill all fields');
      return;
    }

    if (password != confirm) {
      setState(() => error = 'Passwords do not match');
      return;
    }

    try {
      setState(() {
        error = '';
        isLoading = true;
      });

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registered successfully')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.message ?? 'Registration failed';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF00E5FF)),
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              keyboardType: TextInputType.emailAddress,
              decoration: inputDecoration('Email', Icons.email_rounded),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: inputDecoration('Password', Icons.lock),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: inputDecoration(
                'Confirm Password',
                Icons.lock_reset,
              ),
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : register,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  List<Wallpaper> wallpapers = [];
  List<String> favorites = [];
  List<Ringtone> ringtones = [];
  List<String> ringtoneFavorites = [];
  bool isLoading = true;
  BannerAd? bannerAd;
  bool isBannerAdReady = false;
  Timer? bannerRetryTimer;
  int bannerRetryAttempt = 0;

  @override
  void initState() {
    super.initState();
    loadData();
    loadBannerAd();
  }

  @override
  void dispose() {
    bannerRetryTimer?.cancel();
    bannerAd?.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final loadedWallpapers = await AppData.loadWallpapers();
    final loadedFavorites = await AppData.getStringList('favorites');
    final loadedRingtones = await AppData.loadRingtones();
    final loadedRingtoneFavs = await AppData.getStringList('ringtoneFavorites');
    if (!mounted) return;
    setState(() {
      wallpapers = loadedWallpapers;
      favorites = loadedFavorites;
      ringtones = loadedRingtones;
      ringtoneFavorites = loadedRingtoneFavs;
      isLoading = false;
    });
  }

  void loadBannerAd() {
    bannerRetryTimer?.cancel();
    bannerAd?.dispose();
    isBannerAdReady = false;

    final ad = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) { ad.dispose(); return; }
          setState(() {
            bannerAd = ad as BannerAd;
            isBannerAdReady = true;
            bannerRetryAttempt = 0;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() { bannerAd = null; isBannerAdReady = false; });
          scheduleBannerRetry();
        },
      ),
    );
    bannerAd = ad;
    ad.load();
  }

  void scheduleBannerRetry() {
    if (bannerRetryAttempt >= 5) return;
    bannerRetryAttempt += 1;
    bannerRetryTimer?.cancel();
    bannerRetryTimer = Timer(Duration(seconds: bannerRetryAttempt * 10), () {
      if (!mounted || isBannerAdReady) return;
      loadBannerAd();
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      smoothRoute(LoginScreen(isDark: widget.isDark, onToggleTheme: widget.onToggleTheme)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = isAdminEmail(FirebaseAuth.instance.currentUser?.email);

    final tabs = [
      _WallpapersTab(
        wallpapers: wallpapers,
        favorites: favorites,
        isLoading: isLoading,
        onRefresh: loadData,
        onFavoritesChanged: (newFavs) => setState(() => favorites = newFavs),
        isAdmin: isAdmin,
        onToggleTheme: widget.onToggleTheme,
      ),
      _CategoriesTab(
        wallpapers: wallpapers,
        favorites: favorites,
        isLoading: isLoading,
        onRefresh: loadData,
      ),
      _RingtonesTab(
        ringtones: ringtones,
        favorites: ringtoneFavorites,
        isLoading: isLoading,
        isAdmin: isAdmin,
        onRefresh: loadData,
        onFavoritesChanged: (newFavs) => setState(() => ringtoneFavorites = newFavs),
      ),
      _FavoritesTab(
        wallpapers: wallpapers,
        favorites: favorites,
        ringtones: ringtones,
        ringtoneFavorites: ringtoneFavorites,
        onRefresh: loadData,
        onFavoritesChanged: (newFavs) => setState(() => favorites = newFavs),
        onRingtoneFavoritesChanged: (newFavs) => setState(() => ringtoneFavorites = newFavs),
      ),
      _ProfileTab(
        isDark: isDark,
        onToggleTheme: widget.onToggleTheme,
        isAdmin: isAdmin,
        onLogout: logout,
        onDataChanged: loadData,
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? premiumBackground : const Color(0xFFF3F4F6),
      body: tabs[_currentTab],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBannerAdReady && bannerAd != null)
            Container(
              alignment: Alignment.center,
              height: bannerAd!.size.height.toDouble(),
              color: isDark ? const Color(0xFF0A0D18) : Colors.white,
              child: SizedBox(
                width: bannerAd!.size.width.toDouble(),
                height: bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: bannerAd!),
              ),
            ),
          NavigationBar(
            selectedIndex: _currentTab,
            onDestinationSelected: (i) => setState(() => _currentTab = i),
            backgroundColor: isDark ? const Color(0xFF0A0D18) : Colors.white,
            indicatorColor: premiumCyan.withValues(alpha: 0.18),
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.grid_view_rounded),
                selectedIcon: Icon(Icons.grid_view_rounded, color: premiumCyan),
                label: 'Wallpapers',
              ),
              const NavigationDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category_rounded, color: premiumCyan),
                label: 'Categories',
              ),
              const NavigationDestination(
                icon: Icon(Icons.music_note_outlined),
                selectedIcon: Icon(Icons.music_note_rounded, color: premiumCyan),
                label: 'Ringtones',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: favorites.isNotEmpty,
                  label: Text('${favorites.length}', style: const TextStyle(fontSize: 10)),
                  backgroundColor: premiumPink,
                  child: const Icon(Icons.favorite_border_rounded),
                ),
                selectedIcon: Badge(
                  isLabelVisible: favorites.isNotEmpty,
                  label: Text('${favorites.length}', style: const TextStyle(fontSize: 10)),
                  backgroundColor: premiumPink,
                  child: const Icon(Icons.favorite_rounded, color: premiumCyan),
                ),
                label: 'Favourites',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: premiumCyan),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Wallpapers ────────────────────────────────────────────────────────

class _WallpapersTab extends StatefulWidget {
  final List<Wallpaper> wallpapers;
  final List<String> favorites;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final ValueChanged<List<String>> onFavoritesChanged;
  final bool isAdmin;
  final VoidCallback onToggleTheme;

  const _WallpapersTab({
    required this.wallpapers,
    required this.favorites,
    required this.isLoading,
    required this.onRefresh,
    required this.onFavoritesChanged,
    required this.isAdmin,
    required this.onToggleTheme,
  });

  @override
  State<_WallpapersTab> createState() => _WallpapersTabState();
}

class _WallpapersTabState extends State<_WallpapersTab> {
  String query = '';
  String selectedCategory = 'All';
  List<String> searchHistory = [];
  bool showHistory = false;
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _checkOnboarding();
    _searchFocus.addListener(() {
      setState(() => showHistory = _searchFocus.hasFocus && query.isEmpty && searchHistory.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final h = await AppData.getStringList('search_history');
    if (mounted) setState(() => searchHistory = h.reversed.take(6).toList());
  }

  Future<void> _saveSearchQuery(String q) async {
    if (q.trim().isEmpty) return;
    final h = await AppData.getStringList('search_history');
    h.remove(q);
    h.add(q);
    if (h.length > 10) h.removeAt(0);
    await AppData.saveStringList('search_history', h);
    if (mounted) setState(() => searchHistory = h.reversed.take(6).toList());
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_done') ?? false;
    if (!seen && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.push(context, smoothRoute(const OnboardingScreen()));
        }
      });
    }
  }

  Wallpaper? get _dailyWallpaper {
    if (widget.wallpapers.isEmpty) return null;
    final day = DateTime.now().day + DateTime.now().month * 31;
    return widget.wallpapers[day % widget.wallpapers.length];
  }

  List<Wallpaper> get _trendingWallpapers {
    if (widget.wallpapers.length <= 4) return widget.wallpapers;
    // Simulate trending: pick every 3rd starting from index 1
    final result = <Wallpaper>[];
    for (int i = 1; i < widget.wallpapers.length && result.length < 8; i += 3) {
      result.add(widget.wallpapers[i]);
    }
    return result;
  }

  List<String> get categories {
    final extra = widget.wallpapers
        .map((w) => w.category)
        .where((c) => !wallpaperCategories.contains(c))
        .toSet()
        .toList()
      ..sort();
    return ['All', ...wallpaperCategories, ...extra];
  }

  List<Wallpaper> get filtered {
    return widget.wallpapers.where((w) {
      final matchQ = w.title.toLowerCase().contains(query.toLowerCase());
      final matchC = selectedCategory == 'All' || w.category == selectedCategory;
      return matchQ && matchC;
    }).toList();
  }

  void openPreview(Wallpaper w) {
    Navigator.push(context, smoothRoute(PreviewScreen(wallpaper: w)))
        .then((_) => widget.onRefresh());
  }

  void openAdmin() {
    Navigator.push(context, smoothRoute(const AdminScreen()))
        .then((_) => widget.onRefresh());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visible = filtered;
    final isSearching = query.isNotEmpty || selectedCategory != 'All';
    final daily = _dailyWallpaper;
    final trending = _trendingWallpapers;

    return SafeArea(
      child: Column(
        children: [
          // ── App bar row ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: premiumGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: premiumCyan.withValues(alpha: 0.3), blurRadius: 16)],
                  ),
                  child: const Icon(Icons.sports_esports_rounded, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'RXT Gaming',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ),
                if (widget.isAdmin)
                  IconButton(
                    tooltip: 'Add wallpaper',
                    onPressed: openAdmin,
                    icon: const Icon(Icons.add_photo_alternate_rounded, color: premiumCyan),
                  ),
                // ── Dark / Light toggle ──────────────────────────────
                GestureDetector(
                  onTap: widget.onToggleTheme,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    width: 58,
                    height: 30,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: isDark
                          ? const LinearGradient(colors: [Color(0xFF1A1F35), Color(0xFF0A0F1C)])
                          : const LinearGradient(colors: [Color(0xFFFFD600), Color(0xFFFF8C00)]),
                      border: Border.all(
                        color: isDark ? premiumCyan.withValues(alpha: 0.35) : Colors.orange.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? premiumCyan.withValues(alpha: 0.18) : Colors.orange.withValues(alpha: 0.28),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 3, top: 0, bottom: 0,
                          child: Center(child: Icon(Icons.nightlight_round, size: 13,
                              color: isDark ? premiumCyan : Colors.white.withValues(alpha: 0.4))),
                        ),
                        Positioned(
                          right: 3, top: 0, bottom: 0,
                          child: Center(child: Icon(Icons.wb_sunny_rounded, size: 13,
                              color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.white)),
                        ),
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeInOut,
                          alignment: isDark ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? premiumCyan : Colors.white,
                              boxShadow: [BoxShadow(
                                color: isDark ? premiumCyan.withValues(alpha: 0.5) : Colors.orange.withValues(alpha: 0.4),
                                blurRadius: 8,
                              )],
                            ),
                            child: Icon(
                              isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                              size: 13,
                              color: isDark ? premiumBackground : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),

          // ── Search bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: premiumCyan.withValues(alpha: 0.2)),
                    boxShadow: [BoxShadow(color: premiumCyan.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: TextField(
                    focusNode: _searchFocus,
                    onChanged: (v) {
                      setState(() { query = v; showHistory = v.isEmpty && searchHistory.isNotEmpty; });
                    },
                    onSubmitted: (v) { if (v.isNotEmpty) _saveSearchQuery(v); },
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
                    decoration: InputDecoration(
                      hintText: 'Search wallpapers…',
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      prefixIcon: const Icon(Icons.search_rounded, color: premiumCyan),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () { setState(() { query = ''; showHistory = false; }); },
                              icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.black45),
                            ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                // ── Search history chips ──────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: (showHistory && query.isEmpty)
                      ? Padding(
                          key: const ValueKey('history'),
                          padding: const EdgeInsets.only(top: 10),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              ...searchHistory.map((h) => GestureDetector(
                                onTap: () {
                                  setState(() { query = h; showHistory = false; });
                                  _searchFocus.unfocus();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: premiumCyan.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.history_rounded, size: 13, color: isDark ? Colors.white54 : Colors.black45),
                                      const SizedBox(width: 5),
                                      Text(h, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white70 : Colors.black54)),
                                    ],
                                  ),
                                ),
                              )),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('no-history')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Category pills ──────────────────────────────────────
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = categories[i];
                return CategoryPill(
                  label: cat,
                  selected: selectedCategory == cat,
                  onTap: () => setState(() => selectedCategory = cat),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // ── Main scrollable content ─────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.onRefresh,
              color: premiumCyan,
              child: widget.isLoading
                  ? const ShimmerLoadingGrid()
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // ── Daily wallpaper (only when not searching)
                        if (!isSearching && daily != null)
                          SliverToBoxAdapter(child: _DailyWallpaperCard(
                            wallpaper: daily,
                            isDark: isDark,
                            onTap: () => openPreview(daily),
                          )),

                        // ── Stats strip (only when not searching)
                        if (!isSearching)
                          SliverToBoxAdapter(child: _StatsStrip(
                            totalWallpapers: widget.wallpapers.length,
                            totalFavourites: widget.favorites.length,
                            isDark: isDark,
                          )),

                        // ── Trending (only when not searching)
                        if (!isSearching && trending.isNotEmpty)
                          SliverToBoxAdapter(child: _TrendingStrip(
                            wallpapers: trending,
                            isDark: isDark,
                            onTap: openPreview,
                          )),

                        // ── Section title when searching
                        if (isSearching)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                              child: Text(
                                '${visible.length} result${visible.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.black45,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),

                        // ── All wallpapers header
                        if (!isSearching)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              child: Text(
                                'All Wallpapers',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF111827),
                                ),
                              ),
                            ),
                          ),

                        // ── Grid
                        visible.isEmpty
                            ? SliverFillRemaining(
                                child: Center(
                                  child: Text('No wallpapers found',
                                    style: TextStyle(
                                      color: isDark ? Colors.white54 : Colors.black45,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            : SliverPadding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                sliver: SliverGrid(
                                  delegate: SliverChildBuilderDelegate(
                                    (_, idx) {
                                      final w = visible[idx];
                                      // Mark last 5 as NEW
                                      final isNew = idx >= visible.length - 5;
                                      return WallpaperTile(
                                        wallpaper: w,
                                        isFavorite: widget.favorites.contains(w.image),
                                        animationIndex: idx,
                                        isNew: isNew,
                                        onTap: () => openPreview(w),
                                      );
                                    },
                                    childCount: visible.length,
                                  ),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: 0.68,
                                  ),
                                ),
                              ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Daily Wallpaper Card ─────────────────────────────────────────────────────

class _DailyWallpaperCard extends StatelessWidget {
  final Wallpaper wallpaper;
  final bool isDark;
  final VoidCallback onTap;

  const _DailyWallpaperCard({required this.wallpaper, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: premiumCyan.withValues(alpha: 0.22), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(wallpaper.image, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: premiumPanel)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.82)],
                    ),
                  ),
                ),
                // TOP badge
                Positioned(
                  top: 14, left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: premiumGradient,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wb_sunny_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 5),
                        Text('Daily Pick', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                // Tap to open hint
                Positioned(
                  top: 14, right: 14,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Icon(Icons.open_in_full_rounded, size: 16, color: Colors.white),
                  ),
                ),
                // Bottom info
                Positioned(
                  left: 14, right: 14, bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(wallpaper.title,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.1),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.auto_awesome_rounded, color: premiumCyan, size: 13),
                        const SizedBox(width: 5),
                        Text(wallpaper.category,
                          style: const TextStyle(color: Color(0xFFB9F6FF), fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stats Strip ─────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final int totalWallpapers;
  final int totalFavourites;
  final bool isDark;

  const _StatsStrip({required this.totalWallpapers, required this.totalFavourites, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          _StatCard(icon: Icons.image_rounded, label: 'Wallpapers', value: '$totalWallpapers',
              colorA: premiumCyan, colorB: premiumViolet, isDark: isDark),
          const SizedBox(width: 12),
          _StatCard(icon: Icons.favorite_rounded, label: 'Favourites', value: '$totalFavourites',
              colorA: premiumPink, colorB: premiumViolet, isDark: isDark),
          const SizedBox(width: 12),
          _StatCard(icon: Icons.category_rounded, label: 'Categories', value: '${wallpaperCategories.length}',
              colorA: premiumGreen, colorB: premiumCyan, isDark: isDark),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color colorA;
  final Color colorB;
  final bool isDark;

  const _StatCard({required this.icon, required this.label, required this.value,
    required this.colorA, required this.colorB, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          border: Border.all(color: colorA.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: colorA.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (r) => LinearGradient(colors: [colorA, colorB]).createShader(r),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF111827),
            )),
            Text(label, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black38,
            )),
          ],
        ),
      ),
    );
  }
}

// ─── Trending Strip ───────────────────────────────────────────────────────────

class _TrendingStrip extends StatelessWidget {
  final List<Wallpaper> wallpapers;
  final bool isDark;
  final ValueChanged<Wallpaper> onTap;

  const _TrendingStrip({required this.wallpapers, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 6),
              Text('Trending', style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF111827),
              )),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: wallpapers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final w = wallpapers[i];
              return GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); onTap(w); },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 100,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(w.image, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: premiumPanel)),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6, left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('#${i + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                          ),
                        ),
                        Positioned(
                          left: 6, right: 6, bottom: 6,
                          child: Text(w.title,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, height: 1.2)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Onboarding Screen ────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _OnboardSlide(
      icon: Icons.sports_esports_rounded,
      title: 'Welcome to RXT Gaming',
      subtitle: 'Thousands of premium gaming wallpapers at your fingertips.',
      gradient: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
    ),
    _OnboardSlide(
      icon: Icons.favorite_rounded,
      title: 'Save Your Favourites',
      subtitle: 'Tap the heart on any wallpaper to save it to your collection.',
      gradient: [Color(0xFFFF2D92), Color(0xFF7C4DFF)],
    ),
    _OnboardSlide(
      icon: Icons.wallpaper_rounded,
      title: 'Set in One Tap',
      subtitle: 'Apply directly to home screen, lock screen, or both.',
      gradient: [Color(0xFF00FFC6), Color(0xFF00E5FF)],
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: premiumBackground,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _slides.length,
            itemBuilder: (_, i) => _OnboardPage(slide: _slides[i]),
          ),
          // Dots + button
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i ? premiumCyan : Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      )),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: premiumGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: premiumCyan.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (_page < _slides.length - 1) {
                              _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
                            } else {
                              _finish();
                            }
                          },
                          child: Text(
                            _page < _slides.length - 1 ? 'Next' : 'Get Started',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                    if (_page < _slides.length - 1)
                      TextButton(
                        onPressed: _finish,
                        child: const Text('Skip', style: TextStyle(color: Colors.white38)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardSlide {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  const _OnboardSlide({required this.icon, required this.title, required this.subtitle, required this.gradient});
}

class _OnboardPage extends StatelessWidget {
  final _OnboardSlide slide;
  const _OnboardPage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: slide.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [BoxShadow(color: slide.gradient[0].withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 16))],
            ),
            child: Icon(slide.icon, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 40),
          ShaderMask(
            shaderCallback: (r) => LinearGradient(colors: slide.gradient).createShader(r),
            child: Text(slide.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
          ),
          const SizedBox(height: 16),
          Text(slide.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5)),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

// ─── Rate Us Dialog ───────────────────────────────────────────────────────────

Future<void> maybeShowRateUs(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final downloads = prefs.getInt('total_downloads') ?? 0;
  final rated = prefs.getBool('rate_us_shown') ?? false;
  if (rated || downloads < 5) return;
  await prefs.setBool('rate_us_shown', true);
  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: premiumPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(gradient: premiumGradient, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 18),
            const Text('Enjoying RXT Gaming?',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('Rate us on Play Store to help us grow!',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Later'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: premiumGradient, borderRadius: BorderRadius.circular(14)),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () { Navigator.pop(context); /* launch store URL here */ },
                      child: const Text('Rate Now ⭐', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Tab 2: Categories ────────────────────────────────────────────────────────

// Category metadata: icon + gradient colors
const _categoryMeta = <String, _CatMeta>{
  'GTA':          _CatMeta(Icons.directions_car_filled_rounded,  Color(0xFFFF6B35), Color(0xFFFF2D92)),
  'Forza':        _CatMeta(Icons.speed_rounded,                  Color(0xFF00E5FF), Color(0xFF0072FF)),
  'Anime':        _CatMeta(Icons.auto_awesome_rounded,           Color(0xFFFF2D92), Color(0xFF7C4DFF)),
  'Cars':         _CatMeta(Icons.time_to_leave_rounded,          Color(0xFF00FFC6), Color(0xFF00E5FF)),
  'Gaming Setup': _CatMeta(Icons.sports_esports_rounded,         Color(0xFF7C4DFF), Color(0xFF00E5FF)),
  'Cyberpunk':    _CatMeta(Icons.electric_bolt_rounded,          Color(0xFFFFD600), Color(0xFFFF2D92)),
};

class _CatMeta {
  final IconData icon;
  final Color colorA;
  final Color colorB;
  const _CatMeta(this.icon, this.colorA, this.colorB);
}

class _CategoriesTab extends StatelessWidget {
  final List<Wallpaper> wallpapers;
  final List<String> favorites;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const _CategoriesTab({
    required this.wallpapers,
    required this.favorites,
    required this.isLoading,
    required this.onRefresh,
  });

  List<String> get allCategories {
    final extra = wallpapers
        .map((w) => w.category)
        .where((c) => !wallpaperCategories.contains(c))
        .toSet()
        .toList()
      ..sort();
    return [...wallpaperCategories, ...extra];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cats = allCategories;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              '${cats.length} categories',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const ShimmerLoadingGrid()
                : RefreshIndicator(
                    onRefresh: onRefresh,
                    color: premiumCyan,
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: cats.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.55,
                      ),
                      itemBuilder: (_, i) {
                        final cat = cats[i];
                        final count = wallpapers.where((w) => w.category == cat).length;
                        final meta = _categoryMeta[cat] ??
                            _CatMeta(
                              Icons.image_rounded,
                              premiumCyan,
                              premiumViolet,
                            );
                        return _CategoryCard(
                          name: cat,
                          count: count,
                          meta: meta,
                          onTap: () {
                            final filtered = wallpapers.where((w) => w.category == cat).toList();
                            Navigator.push(
                              context,
                              smoothRoute(
                                WallpaperListScreen(
                                  title: cat,
                                  wallpapers: filtered,
                                ),
                              ),
                            ).then((_) => onRefresh());
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final int count;
  final _CatMeta meta;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.count,
    required this.meta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                meta.colorA.withValues(alpha: 0.85),
                meta.colorB.withValues(alpha: 0.85),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: meta.colorA.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background icon (large, faded)
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  meta.icon,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(meta.icon, color: Colors.white, size: 22),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count wallpaper${count == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab: Ringtones ───────────────────────────────────────────────────────────

class _RingtonesTab extends StatefulWidget {
  final List<Ringtone> ringtones;
  final List<String> favorites;
  final bool isLoading;
  final bool isAdmin;
  final Future<void> Function() onRefresh;
  final ValueChanged<List<String>> onFavoritesChanged;

  const _RingtonesTab({
    required this.ringtones,
    required this.favorites,
    required this.isLoading,
    required this.isAdmin,
    required this.onRefresh,
    required this.onFavoritesChanged,
  });

  @override
  State<_RingtonesTab> createState() => _RingtonesTabState();
}

class _RingtonesTabState extends State<_RingtonesTab> {
  String query = '';
  String selectedCategory = 'All';
  final AudioPlayer _previewPlayer = AudioPlayer();
  String? _playingUrl;

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  List<String> get categories {
    final extra = widget.ringtones
        .map((r) => r.category)
        .where((c) => !ringtoneCategories.contains(c))
        .toSet()
        .toList()
      ..sort();
    return ['All', ...ringtoneCategories, ...extra];
  }

  List<Ringtone> get filtered {
    return widget.ringtones.where((r) {
      final matchQ = r.title.toLowerCase().contains(query.toLowerCase());
      final matchC = selectedCategory == 'All' || r.category == selectedCategory;
      return matchQ && matchC;
    }).toList();
  }

  Future<void> _togglePreview(Ringtone r) async {
    HapticFeedback.lightImpact();
    if (_playingUrl == r.audioUrl) {
      await _previewPlayer.stop();
      setState(() => _playingUrl = null);
      return;
    }
    if (r.audioUrl.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This ringtone has no audio file linked')),
        );
      }
      return;
    }
    try {
      await _previewPlayer.stop();
      setState(() => _playingUrl = r.audioUrl);
      await _previewPlayer.setUrl(r.audioUrl);
      await _previewPlayer.play();
      _previewPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() => _playingUrl = null);
        }
      });
    } catch (e) {
      debugPrint('Ringtone preview failed: $e');
      if (mounted) {
        setState(() => _playingUrl = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play: ${e.toString().split('\n').first}')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(Ringtone r) async {
    final favs = List<String>.from(widget.favorites);
    if (favs.contains(r.audioUrl)) {
      favs.remove(r.audioUrl);
    } else {
      favs.add(r.audioUrl);
      HapticFeedback.mediumImpact();
    }
    await AppData.saveStringList('ringtoneFavorites', favs);
    widget.onFavoritesChanged(favs);
  }

  void openPreview(Ringtone r) async {
    await _previewPlayer.stop();
    if (mounted) setState(() => _playingUrl = null);
    if (!mounted) return;
    Navigator.push(context, smoothRoute(RingtonePreviewScreen(ringtone: r)))
        .then((_) => widget.onRefresh());
  }

  void openAdmin() {
    Navigator.push(context, smoothRoute(const AdminRingtoneScreen()))
        .then((_) => widget.onRefresh());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visible = filtered;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Ringtones', style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  )),
                ),
                if (widget.isAdmin)
                  IconButton(
                    tooltip: 'Add ringtone',
                    onPressed: openAdmin,
                    icon: const Icon(Icons.add_circle_outline_rounded, color: premiumCyan),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text('${widget.ringtones.length} ringtones available',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38,
                  fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: premiumCyan.withValues(alpha: 0.2)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => query = v),
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
                decoration: InputDecoration(
                  hintText: 'Search ringtones…',
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                  prefixIcon: const Icon(Icons.search_rounded, color: premiumCyan),
                  suffixIcon: query.isEmpty ? null : IconButton(
                    onPressed: () => setState(() => query = ''),
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.black45),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = categories[i];
                return CategoryPill(
                  label: cat,
                  selected: selectedCategory == cat,
                  onTap: () => setState(() => selectedCategory = cat),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.onRefresh,
              color: premiumCyan,
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator(color: premiumCyan))
                  : visible.isEmpty
                      ? Center(
                          child: Text('No ringtones found',
                            style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w600)),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, idx) {
                            final r = visible[idx];
                            return RingtoneTile(
                              ringtone: r,
                              isFavorite: widget.favorites.contains(r.audioUrl),
                              isPlaying: _playingUrl == r.audioUrl,
                              onPlayToggle: () => _togglePreview(r),
                              onFavoriteToggle: () => _toggleFavorite(r),
                              onTap: () => openPreview(r),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class RingtoneTile extends StatelessWidget {
  final Ringtone ringtone;
  final bool isFavorite;
  final bool isPlaying;
  final VoidCallback? onPlayToggle;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  const RingtoneTile({
    super.key,
    required this.ringtone,
    required this.isFavorite,
    this.isPlaying = false,
    this.onPlayToggle,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPlaying ? premiumCyan.withValues(alpha: 0.5) : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
          ),
          boxShadow: isPlaying ? [BoxShadow(color: premiumCyan.withValues(alpha: 0.18), blurRadius: 16)] : null,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onPlayToggle,
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  gradient: premiumGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: premiumCyan.withValues(alpha: 0.3), blurRadius: 12)],
                ),
                child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ringtone.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF111827))),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.label_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 4),
                      Text(ringtone.category, style: TextStyle(
                        fontSize: 12, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onFavoriteToggle,
              icon: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite ? premiumPink : (isDark ? Colors.white38 : Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 3: Favourites ────────────────────────────────────────────────────────

class _FavoritesTab extends StatefulWidget {
  final List<Wallpaper> wallpapers;
  final List<String> favorites;
  final List<Ringtone> ringtones;
  final List<String> ringtoneFavorites;
  final Future<void> Function() onRefresh;
  final ValueChanged<List<String>> onFavoritesChanged;
  final ValueChanged<List<String>> onRingtoneFavoritesChanged;

  const _FavoritesTab({
    required this.wallpapers,
    required this.favorites,
    required this.ringtones,
    required this.ringtoneFavorites,
    required this.onRefresh,
    required this.onFavoritesChanged,
    required this.onRingtoneFavoritesChanged,
  });

  @override
  State<_FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<_FavoritesTab> {
  int _segment = 0; // 0 = wallpapers, 1 = ringtones

  Future<void> _toggleRingtoneFavorite(Ringtone r) async {
    final favs = List<String>.from(widget.ringtoneFavorites);
    if (favs.contains(r.audioUrl)) {
      favs.remove(r.audioUrl);
    } else {
      favs.add(r.audioUrl);
    }
    await AppData.saveStringList('ringtoneFavorites', favs);
    widget.onRingtoneFavoritesChanged(favs);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favWallpapers = widget.wallpapers.where((w) => widget.favorites.contains(w.image)).toList();
    final favRingtones = widget.ringtones.where((r) => widget.ringtoneFavorites.contains(r.audioUrl)).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Text(
              'Favourites',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),
          // ── Segment control ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      label: 'Wallpapers (${favWallpapers.length})',
                      icon: Icons.image_rounded,
                      selected: _segment == 0,
                      isDark: isDark,
                      onTap: () => setState(() => _segment = 0),
                    ),
                  ),
                  Expanded(
                    child: _SegmentButton(
                      label: 'Ringtones (${favRingtones.length})',
                      icon: Icons.music_note_rounded,
                      selected: _segment == 1,
                      isDark: isDark,
                      onTap: () => setState(() => _segment = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _segment == 0
                ? RefreshIndicator(
                    onRefresh: widget.onRefresh,
                    color: premiumCyan,
                    child: favWallpapers.isEmpty
                        ? _emptyState(isDark, Icons.favorite_border_rounded, 'No favourite wallpapers',
                            'Tap ♥ on any wallpaper to save it here')
                        : LayoutBuilder(builder: (ctx, constraints) {
                            final cols = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 620 ? 3 : 2;
                            return GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: favWallpapers.length,
                              cacheExtent: 900,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.68,
                              ),
                              itemBuilder: (_, idx) {
                                final w = favWallpapers[idx];
                                return WallpaperTile(
                                  wallpaper: w,
                                  isFavorite: true,
                                  animationIndex: idx,
                                  onTap: () => Navigator.push(
                                    context,
                                    smoothRoute(PreviewScreen(wallpaper: w)),
                                  ).then((_) => widget.onRefresh()),
                                );
                              },
                            );
                          }),
                  )
                : RefreshIndicator(
                    onRefresh: widget.onRefresh,
                    color: premiumCyan,
                    child: favRingtones.isEmpty
                        ? _emptyState(isDark, Icons.music_off_rounded, 'No favourite ringtones',
                            'Tap ♥ on any ringtone to save it here')
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: favRingtones.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, idx) {
                              final r = favRingtones[idx];
                              return RingtoneTile(
                                ringtone: r,
                                isFavorite: true,
                                onFavoriteToggle: () => _toggleRingtoneFavorite(r),
                                onTap: () => Navigator.push(
                                  context,
                                  smoothRoute(RingtonePreviewScreen(ringtone: r)),
                                ).then((_) => widget.onRefresh()),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(bool isDark, IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontWeight: FontWeight.w600, fontSize: 16,
          )),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(
            color: isDark ? Colors.white24 : Colors.black26, fontSize: 13,
          )),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label, required this.icon, required this.selected,
    required this.isDark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? premiumCyan.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: premiumCyan.withValues(alpha: 0.4)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? premiumCyan : (isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w800,
                  color: selected ? premiumCyan : (isDark ? Colors.white54 : Colors.black45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 3: Profile ───────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final bool isAdmin;
  final VoidCallback onLogout;
  final Future<void> Function() onDataChanged;

  const _ProfileTab({
    required this.isDark,
    required this.onToggleTheme,
    required this.isAdmin,
    required this.onLogout,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Gamer';
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: premiumCyan.withValues(alpha: 0.18),
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G',
                          style: const TextStyle(
                            color: premiumCyan,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (isAdmin)
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: premiumGradient,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Settings section ────────────────────────────────────
            _sectionLabel('Appearance', isDark),
            _SettingsTile(
              icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              label: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              isDark: isDark,
              onTap: onToggleTheme,
            ),
            const SizedBox(height: 20),

            _sectionLabel('Downloads', isDark),
            _SettingsTile(
              icon: Icons.history_rounded,
              label: 'Download History',
              isDark: isDark,
              onTap: () async {
                final history = await AppData.getStringList('history');
                if (!context.mounted) return;
                final allWallpapers = await AppData.loadWallpapers();
                final historyWallpapers = allWallpapers.where((w) => history.contains(w.image)).toList();
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  smoothRoute(WallpaperListScreen(title: 'Download History', wallpapers: historyWallpapers)),
                );
              },
            ),
            const SizedBox(height: 20),

            if (isAdmin) ...[
              _sectionLabel('Admin', isDark),
              _SettingsTile(
                icon: Icons.add_photo_alternate_rounded,
                label: 'Add Wallpaper',
                isDark: isDark,
                accent: premiumCyan,
                onTap: () => Navigator.push(context, smoothRoute(const AdminScreen()))
                    .then((_) => onDataChanged()),
              ),
              const SizedBox(height: 20),
            ],

            _sectionLabel('Account', isDark),
            _SettingsTile(
              icon: Icons.logout_rounded,
              label: 'Logout',
              isDark: isDark,
              accent: Colors.redAccent,
              onTap: onLogout,
            ),
            const SizedBox(height: 32),

            // ── App version footer ──────────────────────────────────
            Center(
              child: Text(
                'RXT Gaming Wallpapers • v1.0',
                style: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? accent;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? (isDark ? Colors.white70 : const Color(0xFF374151));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.black26),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class WallpaperTile extends StatelessWidget {
  final Wallpaper wallpaper;
  final bool isFavorite;
  final int animationIndex;
  final VoidCallback onTap;
  final bool isNew;

  const WallpaperTile({
    super.key,
    required this.wallpaper,
    required this.isFavorite,
    this.animationIndex = 0,
    required this.onTap,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: (animationIndex % 6) * 18);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: Transform.scale(
              scale: 0.96 + (0.04 * value),
              child: child,
            ),
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'wallpaper-${wallpaper.image}',
                    child: Image.network(
                      wallpaper.image,
                      fit: BoxFit.cover,
                      cacheWidth: 520,
                      filterQuality: FilterQuality.medium,
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOut,
                          child: child,
                        );
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            const ColoredBox(color: premiumPanel),
                            Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: premiumCyan.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      errorBuilder: (_, __, ___) {
                        return const ColoredBox(
                          color: Color(0xFF111827),
                          child: Icon(Icons.broken_image_rounded, size: 42),
                        );
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.86),
                        ],
                      ),
                    ),
                  ),
                  // NEW badge
                  if (isNew)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [premiumCyan, premiumViolet]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  // Favourite button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.32),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
                          key: ValueKey(isFavorite),
                          size: 19,
                          color: isFavorite ? Colors.redAccent : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            wallpaper.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, color: premiumCyan, size: 13),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  wallpaper.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFB9F6FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class WallpaperListScreen extends StatelessWidget {
  final String title;
  final List<Wallpaper> wallpapers;

  const WallpaperListScreen({
    super.key,
    required this.title,
    required this.wallpapers,
  });

  void openPreview(BuildContext context, Wallpaper wallpaper) {
    Navigator.push(
      context,
      smoothRoute(PreviewScreen(wallpaper: wallpaper)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: wallpapers.isEmpty
          ? const Center(child: Text('No wallpapers found'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 620
                        ? 3
                        : 2;

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                  itemCount: wallpapers.length,
                  cacheExtent: 900,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (context, index) {
                    final wallpaper = wallpapers[index];

                    return WallpaperTile(
                      wallpaper: wallpaper,
                      isFavorite: false,
                      animationIndex: index,
                      onTap: () => openPreview(context, wallpaper),
                    );
                  },
                );
              },
            ),
    );
  }
}

class PreviewScreen extends StatefulWidget {
  final Wallpaper wallpaper;

  const PreviewScreen({super.key, required this.wallpaper});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool isFavorite = false;
  bool isLoading = false;
  double _downloadProgress = 0;
  final TransformationController _zoomController = TransformationController();

  @override
  void initState() {
    super.initState();
    checkFavorite();
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  Future<void> checkFavorite() async {
    final favorites = await AppData.getStringList('favorites');
    if (!mounted) return;
    setState(() => isFavorite = favorites.contains(widget.wallpaper.image));
  }

  Future<void> toggleFavorite() async {
    HapticFeedback.mediumImpact();
    final favorites = await AppData.getStringList('favorites');
    if (favorites.contains(widget.wallpaper.image)) {
      favorites.remove(widget.wallpaper.image);
    } else {
      favorites.add(widget.wallpaper.image);
    }
    await AppData.saveStringList('favorites', favorites);
    if (!mounted) return;
    setState(() => isFavorite = favorites.contains(widget.wallpaper.image));
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: premiumPanel,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void showGalleryPermissionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Gallery permission denied'),
        action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
      ),
    );
  }

  String get safeWallpaperName {
    final safeName = widget.wallpaper.title
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .toLowerCase();
    return safeName.isEmpty ? 'rxt_gaming_wallpaper' : 'rxt_gaming_$safeName';
  }

  Future<File> downloadWallpaper() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$safeWallpaperName.jpg';
    final file = File(filePath);

    if (!await file.exists()) {
      await Dio().download(
        widget.wallpaper.image,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );
    }

    final history = await AppData.getStringList('history');
    if (!history.contains(widget.wallpaper.image)) {
      history.add(widget.wallpaper.image);
      await AppData.saveStringList('history', history);
    }
    return file;
  }

  Future<String> saveFileToPhoneDownloads(File sourceFile) async {
    final fileName = '$safeWallpaperName.jpg';
    if (Platform.isAndroid) {
      try {
        final savedPath = await downloadsChannel.invokeMethod<String>(
          'saveImageToDownloads',
          {'sourcePath': sourceFile.path, 'fileName': fileName},
        );
        if (savedPath != null && savedPath.isNotEmpty) return savedPath;
      } on PlatformException catch (e) {
        debugPrint('Android downloads save failed: ${e.message}');
      }
    }
    final downloadsDirectory = await getDownloadsDirectory();
    final targetDirectory = downloadsDirectory != null
        ? Directory('${downloadsDirectory.path}/RXT Gaming')
        : await getApplicationDocumentsDirectory();
    if (!await targetDirectory.exists()) await targetDirectory.create(recursive: true);
    final targetPath = '${targetDirectory.path}/$fileName';
    await sourceFile.copy(targetPath);
    return targetPath;
  }

  Future<void> downloadOnly() async {
    HapticFeedback.lightImpact();
    try {
      setState(() { isLoading = true; _downloadProgress = 0; });
      final file = await downloadWallpaper();
      final savedPath = await saveFileToPhoneDownloads(file);
      if (!mounted) return;
      // Increment download counter
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt('total_downloads') ?? 0) + 1;
      await prefs.setInt('total_downloads', count);
      HapticFeedback.heavyImpact();
      showMessage('Downloaded ✓');
      debugPrint('Saved to: $savedPath');
      if (mounted) maybeShowRateUs(context);
    } catch (_) {
      if (mounted) showMessage('Download failed');
    } finally {
      if (mounted) setState(() { isLoading = false; _downloadProgress = 0; });
    }
  }

  Future<bool> requestGalleryAccess() async {
    try {
      if (await Gal.hasAccess(toAlbum: true)) return true;
      return Gal.requestAccess(toAlbum: true);
    } catch (_) { return false; }
  }

  Future<void> saveToGallery() async {
    HapticFeedback.lightImpact();
    try {
      setState(() { isLoading = true; _downloadProgress = 0; });
      final hasAccess = await requestGalleryAccess();
      if (!hasAccess) {
        if (mounted) showGalleryPermissionMessage();
        return;
      }
      final file = await downloadWallpaper();
      await Gal.putImage(file.path, album: 'Gaming Wallpapers');
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      showMessage('Saved to Gallery ✓');
    } on GalException catch (e) {
      if (mounted) showMessage(e.type.message);
    } catch (_) {
      if (mounted) showMessage('Gallery save failed');
    } finally {
      if (mounted) setState(() { isLoading = false; _downloadProgress = 0; });
    }
  }

  Future<void> shareWallpaper() async {
    HapticFeedback.lightImpact();
    try {
      setState(() { isLoading = true; _downloadProgress = 0; });
      final file = await downloadWallpaper();
      await Share.shareXFiles([XFile(file.path)], text: widget.wallpaper.title);
    } catch (_) {
      if (mounted) showMessage('Share failed');
    } finally {
      if (mounted) setState(() { isLoading = false; _downloadProgress = 0; });
    }
  }

  Future<void> setWallpaper(int location) async {
    HapticFeedback.lightImpact();
    try {
      setState(() { isLoading = true; _downloadProgress = 0; });
      final file = await downloadWallpaper();
      final manager = WallpaperManagerFlutter();
      final success = await manager.setWallpaper(file, location);
      if (!mounted) return;
      if (success) HapticFeedback.heavyImpact();
      showMessage(success ? 'Wallpaper set ✓' : 'Wallpaper not set');
    } catch (_) {
      if (mounted) showMessage('Set wallpaper failed');
    } finally {
      if (mounted) setState(() { isLoading = false; _downloadProgress = 0; });
    }
  }

  void openWallpaperOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: premiumPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
              const Text('Set Wallpaper',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 16),
              _wallpaperOptionTile(Icons.home_rounded, 'Home Screen', WallpaperManagerFlutter.homeScreen),
              _wallpaperOptionTile(Icons.lock_rounded, 'Lock Screen', WallpaperManagerFlutter.lockScreen),
              _wallpaperOptionTile(Icons.smartphone_rounded, 'Both Screens', WallpaperManagerFlutter.bothScreens),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wallpaperOptionTile(IconData icon, String label, int location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        leading: Icon(icon, color: premiumCyan),
        title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
        onTap: () { Navigator.pop(context); setWallpaper(location); },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pinch-to-zoom image
          InteractiveViewer(
            transformationController: _zoomController,
            minScale: 1.0,
            maxScale: 4.0,
            child: Hero(
              tag: 'wallpaper-${widget.wallpaper.image}',
              child: Image.network(
                widget.wallpaper.image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                filterQuality: FilterQuality.high,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Colors.black,
                  child: Center(child: Icon(Icons.broken_image_rounded, color: Colors.white, size: 64)),
                ),
              ),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    children: [
                      _glassIconButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      // Zoom reset button (shows when zoomed in)
                      ValueListenableBuilder<Matrix4>(
                        valueListenable: _zoomController,
                        builder: (_, matrix, __) {
                          final isZoomed = matrix != Matrix4.identity();
                          return AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isZoomed ? 1 : 0,
                            child: _glassIconButton(
                              icon: Icons.zoom_out_map_rounded,
                              onPressed: isZoomed
                                  ? () => _zoomController.value = Matrix4.identity()
                                  : null,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _glassIconButton(
                        icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        onPressed: isLoading ? null : toggleFavorite,
                        color: isFavorite ? Colors.redAccent : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      _glassIconButton(
                        icon: Icons.share_rounded,
                        onPressed: isLoading ? null : shareWallpaper,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Bottom card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 28,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.wallpaper.title,
                              style: const TextStyle(
                                color: Colors.white, fontSize: 29,
                                height: 1.05, fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, color: premiumCyan, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  widget.wallpaper.category,
                                  style: const TextStyle(
                                    color: Color(0xFFB9F6FF), fontSize: 14, fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.zoom_in_rounded, color: Colors.white38, size: 14),
                                const SizedBox(width: 4),
                                const Text(
                                  'Pinch to zoom',
                                  style: TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                            // Download progress bar
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: isLoading
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 14, bottom: 2),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Downloading…',
                                                style: TextStyle(color: Colors.white60, fontSize: 12)),
                                              Text('${(_downloadProgress * 100).toInt()}%',
                                                style: const TextStyle(color: premiumCyan, fontSize: 12, fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: _downloadProgress > 0 ? _downloadProgress : null,
                                              minHeight: 4,
                                              color: premiumCyan,
                                              backgroundColor: Colors.white24,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox(height: 16),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: PremiumActionButton(
                                    icon: Icons.wallpaper_rounded,
                                    label: 'Set',
                                    onPressed: isLoading ? null : openWallpaperOptions,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: PremiumActionButton(
                                    icon: Icons.download_rounded,
                                    label: 'Download',
                                    filled: false,
                                    onPressed: isLoading ? null : downloadOnly,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: PremiumActionButton(
                                icon: Icons.photo_library_rounded,
                                label: 'Save to Gallery',
                                onPressed: isLoading ? null : saveToGallery,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    Color color = Colors.white,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            color: color,
          ),
        ),
      ),
    );
  }
}

class LiveWallpaperScreen extends StatefulWidget {
  const LiveWallpaperScreen({super.key});

  @override
  State<LiveWallpaperScreen> createState() => _LiveWallpaperScreenState();
}

class _LiveWallpaperScreenState extends State<LiveWallpaperScreen> {
  List<LiveWallpaperStyle> styles = [];
  bool isLoading = true;
  bool isSetting = false;
  double? downloadProgress;

  @override
  void initState() {
    super.initState();
    loadStyles();
  }

  Future<void> loadStyles() async {
    final loadedStyles = await AppData.loadLiveWallpapers();
    if (!mounted) return;
    setState(() {
      styles = loadedStyles;
      isLoading = false;
    });
  }

  Future<void> setLiveWallpaper(LiveWallpaperStyle style) async {
    try {
      setState(() {
        isSetting = true;
        downloadProgress = style.isVideo ? 0 : null;
      });
      final videoPath = style.isVideo ? await downloadLiveVideo(style) : '';
      debugPrint(
        'RXTLiveWallpaper Dart openPreview title=${style.title} '
        'isVideo=${style.isVideo} videoAsset=${style.videoAsset} '
        'videoUrl=${style.videoUrl} videoPath=$videoPath',
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        smoothRoute(
          LiveWallpaperSetPreviewScreen(
            style: style,
            videoPath: videoPath,
          ),
        ),
      );
    } on PlatformException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live wallpaper not supported here')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSetting = false;
          downloadProgress = null;
        });
      }
    }
  }

  Future<String> downloadLiveVideo(LiveWallpaperStyle style) async {
    final safeName = style.title
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .toLowerCase();
    final directory = await getApplicationDocumentsDirectory();
    final liveDirectory = Directory('${directory.path}/live_wallpapers');
    if (!await liveDirectory.exists()) {
      await liveDirectory.create(recursive: true);
    }

    final filePath =
        '${liveDirectory.path}/${safeName.isEmpty ? 'rxt_live' : safeName}.mp4';
    final file = File(filePath);
    if (style.videoAsset.trim().isNotEmpty) {
      final data = await rootBundle.load(style.videoAsset);
      final bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: true);
      debugPrint(
        'RXTLiveWallpaper Dart copied asset=${style.videoAsset} '
        'to=${file.path} assetBytes=${bytes.length} fileBytes=${await file.length()}',
      );
      return file.path;
    }

    if (await file.exists() && await file.length() > 0) {
      return file.path;
    }

    await Dio().download(
      style.videoUrl,
      filePath,
      onReceiveProgress: (received, total) {
        if (!mounted || total <= 0) return;
        setState(() => downloadProgress = received / total);
      },
    );
    debugPrint(
      'RXTLiveWallpaper Dart downloaded url=${style.videoUrl} '
      'to=${file.path} bytes=${await file.length()}',
    );
    return file.path;
  }

  void openAddLiveWallpaper() {
    Navigator.push(
      context,
      smoothRoute(const AddLiveWallpaperScreen()),
    ).then((_) => loadStyles());
  }

  Future<void> pickLocalMp4() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    final pickedPath = result.files.single.path;
    if (pickedPath == null) return;

    final file = File(pickedPath);
    if (!await file.exists() || await file.length() == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected file is not valid')),
      );
      return;
    }

    // Copy to app documents so service can always read it
    setState(() => isSetting = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final liveDir = Directory('${directory.path}/live_wallpapers');
      if (!await liveDir.exists()) await liveDir.create(recursive: true);

      final destPath = '${liveDir.path}/user_picked.mp4';
      await file.copy(destPath);

      final style = LiveWallpaperStyle(
        title: 'My Video',
        colorOne: premiumCyan.value,
        colorTwo: premiumPink.value,
        colorThree: premiumViolet.value,
        videoUrl: destPath, // reusing videoUrl field to carry local path
      );

      if (!mounted) return;
      await Navigator.push(
        context,
        smoothRoute(
          LiveWallpaperSetPreviewScreen(
            style: style,
            videoPath: destPath,
          ),
        ),
      );
    } catch (e) {
      debugPrint('RXTLiveWallpaper pickLocalMp4 error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load the selected video')),
      );
    } finally {
      if (mounted) setState(() => isSetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = isAdminEmail(FirebaseAuth.instance.currentUser?.email);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? premiumBackground : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Live Wallpapers'),
        actions: [
          IconButton(
            tooltip: 'Pick MP4 from phone',
            onPressed: isSetting ? null : pickLocalMp4,
            icon: const Icon(Icons.video_file_rounded),
          ),
          if (isAdmin)
            IconButton(
              tooltip: 'Add live wallpaper',
              onPressed: openAddLiveWallpaper,
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: premiumCyan))
          : RefreshIndicator(
              onRefresh: loadStyles,
              color: premiumCyan,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: styles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final style = styles[index];
                  return LiveWallpaperCard(
                    style: style,
                    isSetting: isSetting,
                    downloadProgress: downloadProgress,
                    onSet: () => setLiveWallpaper(style),
                  );
                },
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAdmin) ...[
            FloatingActionButton.small(
              heroTag: 'add_live',
              onPressed: openAddLiveWallpaper,
              backgroundColor: premiumViolet,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
            ),
            const SizedBox(height: 10),
          ],
          FloatingActionButton.extended(
            heroTag: 'pick_mp4',
            onPressed: isSetting ? null : pickLocalMp4,
            backgroundColor: premiumCyan,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.video_file_rounded),
            label: const Text(
              'Pick MP4',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveWallpaperCard extends StatelessWidget {
  final LiveWallpaperStyle style;
  final bool isSetting;
  final double? downloadProgress;
  final VoidCallback onSet;

  const LiveWallpaperCard({
    super.key,
    required this.style,
    required this.isSetting,
    required this.downloadProgress,
    required this.onSet,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Color(style.colorOne),
      Color(style.colorTwo),
      Color(style.colorThree),
    ];
    final subtitle = style.isVideo
        ? 'MP4 live wallpaper'
        : 'Speed ${style.speed.toStringAsFixed(1)} - Glow ${style.intensity.toStringAsFixed(1)}';
    final buttonIcon = style.isVideo ? Icons.movie_rounded : Icons.bolt_rounded;
    final buttonLabel = isSetting
        ? (style.isVideo ? 'Downloading...' : 'Opening...')
        : 'Set Live';

    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors[0].withValues(alpha: 0.22),
            const Color(0xFF080B16),
            colors[1].withValues(alpha: 0.28),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: style.isVideo
                ? LiveWallpaperVideoPreview(style: style)
                : CustomPaint(
                    painter: LiveWallpaperPreviewPainter(colors: colors),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isSetting && style.isVideo && downloadProgress != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14, right: 80),
                    child: LinearProgressIndicator(
                      value: downloadProgress,
                      minHeight: 3,
                      color: premiumCyan,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: PremiumActionButton(
                    icon: buttonIcon,
                    label: buttonLabel,
                    onPressed: isSetting ? null : onSet,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LiveWallpaperPreviewPainter extends CustomPainter {
  final List<Color> colors;

  const LiveWallpaperPreviewPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var line = 0; line < 3; line += 1) {
      final path = Path();
      final baseY = size.height * (0.28 + (line * 0.22));
      path.moveTo(0, baseY);
      for (var step = 1; step <= 8; step += 1) {
        final x = size.width * step / 8;
        final y = baseY + (step.isEven ? 18 : -18);
        path.lineTo(x, y);
      }

      paint
        ..color = colors[line].withValues(alpha: 0.82)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawPath(path, paint);
      paint.maskFilter = null;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LiveWallpaperPreviewPainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}

class LiveWallpaperVideoPreview extends StatefulWidget {
  final LiveWallpaperStyle style;

  const LiveWallpaperVideoPreview({super.key, required this.style});

  @override
  State<LiveWallpaperVideoPreview> createState() =>
      _LiveWallpaperVideoPreviewState();
}

class _LiveWallpaperVideoPreviewState extends State<LiveWallpaperVideoPreview> {
  VideoPlayerController? controller;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    setupController();
  }

  @override
  void didUpdateWidget(covariant LiveWallpaperVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style.videoAsset != widget.style.videoAsset ||
        oldWidget.style.videoUrl != widget.style.videoUrl) {
      setupController();
    }
  }

  Future<void> setupController() async {
    final oldController = controller;
    controller = null;
    await oldController?.dispose();

    setState(() => hasError = false);

    final nextController = widget.style.videoAsset.trim().isNotEmpty
        ? VideoPlayerController.asset(widget.style.videoAsset)
        : VideoPlayerController.networkUrl(Uri.parse(widget.style.videoUrl));

    try {
      await nextController.initialize();
      await nextController.setLooping(true);
      await nextController.setVolume(0);
      await nextController.play();
      if (!mounted) {
        await nextController.dispose();
        return;
      }
      setState(() => controller = nextController);
    } catch (error) {
      debugPrint('RXTLiveWallpaper preview error: $error');
      await nextController.dispose();
      if (mounted) {
        setState(() => hasError = true);
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentController = controller;

    if (hasError) {
      return const ColoredBox(
        color: Color(0xFF080B16),
        child: Center(
          child: Icon(Icons.videocam_off_rounded, color: Colors.white70),
        ),
      );
    }

    if (currentController == null || !currentController.value.isInitialized) {
      return const ColoredBox(
        color: Color(0xFF080B16),
        child: Center(
          child: CircularProgressIndicator(
            color: premiumCyan,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: currentController.value.size.width,
        height: currentController.value.size.height,
        child: VideoPlayer(currentController),
      ),
    );
  }
}

class LiveWallpaperSetPreviewScreen extends StatefulWidget {
  final LiveWallpaperStyle style;
  final String videoPath;

  const LiveWallpaperSetPreviewScreen({
    super.key,
    required this.style,
    required this.videoPath,
  });

  @override
  State<LiveWallpaperSetPreviewScreen> createState() =>
      _LiveWallpaperSetPreviewScreenState();
}

class _LiveWallpaperSetPreviewScreenState
    extends State<LiveWallpaperSetPreviewScreen> {
  VideoPlayerController? controller;
  bool isOpening = false;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    setupController();
  }

  Future<void> setupController() async {
    if (!widget.style.isVideo || widget.videoPath.trim().isEmpty) return;

    final file = File(widget.videoPath);
    debugPrint(
      'RXTLiveWallpaper Dart preview init title=${widget.style.title} '
      'videoPath=${widget.videoPath} exists=${await file.exists()} '
      'bytes=${await file.exists() ? await file.length() : -1}',
    );

    final nextController = VideoPlayerController.file(file);
    try {
      await nextController.initialize();
      await nextController.setLooping(true);
      await nextController.setVolume(0);
      await nextController.play();
      if (!mounted) {
        await nextController.dispose();
        return;
      }
      setState(() => controller = nextController);
    } catch (error) {
      debugPrint('RXTLiveWallpaper preview screen error: $error');
      await nextController.dispose();
      if (mounted) {
        setState(() => hasError = true);
      }
    }
  }

  Future<void> openSystemWallpaperPreview() async {
    try {
      setState(() => isOpening = true);
      debugPrint(
        'RXTLiveWallpaper Dart setFromPreview title=${widget.style.title} '
        'videoPath=${widget.videoPath} videoAsset=${widget.style.videoAsset}',
      );
      await liveWallpaperChannel.invokeMethod('setLiveWallpaperStyle', {
        'title': widget.style.title,
        'colorOne': widget.style.colorOne,
        'colorTwo': widget.style.colorTwo,
        'colorThree': widget.style.colorThree,
        'speed': widget.style.speed,
        'intensity': widget.style.intensity,
        'videoPath': widget.videoPath,
        'videoAsset': widget.style.videoAsset,
      });
      await liveWallpaperChannel.invokeMethod('openLiveWallpaper');
    } on PlatformException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live wallpaper not supported here')),
      );
    } finally {
      if (mounted) {
        setState(() => isOpening = false);
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      Color(widget.style.colorOne),
      Color(widget.style.colorTwo),
      Color(widget.style.colorThree),
    ];
    final currentController = controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.style.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.style.isVideo &&
              currentController != null &&
              currentController.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: currentController.value.size.width,
                height: currentController.value.size.height,
                child: VideoPlayer(currentController),
              ),
            )
          else if (hasError)
            const Center(
              child: Icon(
                Icons.videocam_off_rounded,
                color: Colors.white70,
                size: 58,
              ),
            )
          else if (widget.style.isVideo)
            const Center(
              child: CircularProgressIndicator(color: premiumCyan),
            )
          else
            CustomPaint(
              painter: LiveWallpaperPreviewPainter(colors: colors),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.style.isVideo
                        ? 'MP4 preview is using selected file'
                        : 'Neon preview',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PremiumActionButton(
                    icon: Icons.wallpaper_rounded,
                    label: isOpening ? 'Opening...' : 'Set Wallpaper',
                    onPressed: isOpening ? null : openSystemWallpaperPreview,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddLiveWallpaperScreen extends StatefulWidget {
  const AddLiveWallpaperScreen({super.key});

  @override
  State<AddLiveWallpaperScreen> createState() => _AddLiveWallpaperScreenState();
}

class _AddLiveWallpaperScreenState extends State<AddLiveWallpaperScreen> {
  final titleController = TextEditingController();
  final colorOneController = TextEditingController(text: '#00E5FF');
  final colorTwoController = TextEditingController(text: '#FF2D92');
  final colorThreeController = TextEditingController(text: '#7C4DFF');
  final videoUrlController = TextEditingController();
  bool useVideo = true;
  double speed = 1;
  double intensity = 1;
  bool isLoading = false;

  @override
  void dispose() {
    titleController.dispose();
    colorOneController.dispose();
    colorTwoController.dispose();
    colorThreeController.dispose();
    videoUrlController.dispose();
    super.dispose();
  }

  int? parseHexColor(String value) {
    final cleaned = value.trim().replaceAll('#', '').toUpperCase();
    if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(cleaned)) return null;
    return int.parse('FF$cleaned', radix: 16);
  }

  Future<void> addLiveWallpaper() async {
    if (!isAdminEmail(FirebaseAuth.instance.currentUser?.email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admin can add live wallpapers')),
      );
      return;
    }

    final title = titleController.text.trim();
    final videoUrl = videoUrlController.text.trim();
    final colorOne = parseHexColor(colorOneController.text);
    final colorTwo = parseHexColor(colorTwoController.text);
    final colorThree = parseHexColor(colorThreeController.text);

    final uri = Uri.tryParse(videoUrl);
    final isValidVideoUrl = !useVideo ||
        (uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty &&
            uri.path.toLowerCase().endsWith('.mp4'));

    if (title.isEmpty || !isValidVideoUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter title and valid MP4 URL')),
      );
      return;
    }

    if (!useVideo &&
        (colorOne == null || colorTwo == null || colorThree == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter title and valid hex colors')),
      );
      return;
    }

    final style = LiveWallpaperStyle(
      title: title,
      colorOne: colorOne ?? premiumCyan.value,
      colorTwo: colorTwo ?? premiumPink.value,
      colorThree: colorThree ?? premiumViolet.value,
      speed: speed,
      intensity: intensity,
      videoUrl: useVideo ? videoUrl : '',
    );

    try {
      setState(() => isLoading = true);
      await AppData.addLiveWallpaper(style);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live wallpaper added')),
      );
      Navigator.pop(context);
    } catch (_) {
      await AppData.addLocalLiveWallpaper(style);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved locally')),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdminEmail(FirebaseAuth.instance.currentUser?.email)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Live Wallpaper')),
        body: const Center(child: Text('Only admin can add live wallpapers')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Live Wallpaper')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: inputDecoration('Title', Icons.title),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Video live wallpaper'),
              subtitle: const Text('Use MP4 URL for your own animation'),
              value: useVideo,
              onChanged:
                  isLoading ? null : (value) => setState(() => useVideo = value),
            ),
            if (useVideo) ...[
              const SizedBox(height: 14),
              TextField(
                controller: videoUrlController,
                keyboardType: TextInputType.url,
                decoration: inputDecoration('MP4 video URL', Icons.movie),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: colorOneController,
              decoration: inputDecoration('Color 1 hex', Icons.palette),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: colorTwoController,
              decoration: inputDecoration('Color 2 hex', Icons.palette),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: colorThreeController,
              decoration: inputDecoration('Color 3 hex', Icons.palette),
            ),
            const SizedBox(height: 18),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Animation speed'),
              subtitle: Slider(
                value: speed,
                min: 0.5,
                max: 1.6,
                divisions: 11,
                label: speed.toStringAsFixed(1),
                onChanged: isLoading ? null : (value) => setState(() => speed = value),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Glow intensity'),
              subtitle: Slider(
                value: intensity,
                min: 0.6,
                max: 1.5,
                divisions: 9,
                label: intensity.toStringAsFixed(1),
                onChanged:
                    isLoading ? null : (value) => setState(() => intensity = value),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : addLiveWallpaper,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text('Add Live Wallpaper'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final titleController = TextEditingController();
  final imageController = TextEditingController();
  String selectedCategory = wallpaperCategories.first;
  bool isLoading = false;

  @override
  void dispose() {
    titleController.dispose();
    imageController.dispose();
    super.dispose();
  }

  Future<void> addWallpaper() async {
    if (!isAdminEmail(FirebaseAuth.instance.currentUser?.email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admin can upload wallpapers')),
      );
      return;
    }

    final title = titleController.text.trim();
    final image = imageController.text.trim();
    final category = selectedCategory;

    if (title.isEmpty || image.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    final uri = Uri.tryParse(image);
    final isValidImageUrl = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    if (!isValidImageUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid image URL')),
      );
      return;
    }

    final wallpaper = Wallpaper(
      title: title,
      image: image,
      category: category,
    );

    try {
      setState(() => isLoading = true);
      await AppData.addWallpaper(wallpaper);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallpaper added')),
      );
      Navigator.pop(context);
    } catch (_) {
      await AppData.addLocalWallpaper(wallpaper);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved locally')),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdminEmail(FirebaseAuth.instance.currentUser?.email)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Only admin can upload wallpapers',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Wallpaper'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: inputDecoration('Title', Icons.title),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: imageController,
              keyboardType: TextInputType.url,
              decoration: inputDecoration('Image URL', Icons.link),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: inputDecoration('Category', Icons.category),
              items: wallpaperCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: isLoading
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => selectedCategory = value);
                    },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : addWallpaper,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text('Add Wallpaper'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Admin: Add Ringtone ──────────────────────────────────────────────────────

class AdminRingtoneScreen extends StatefulWidget {
  const AdminRingtoneScreen({super.key});

  @override
  State<AdminRingtoneScreen> createState() => _AdminRingtoneScreenState();
}

class _AdminRingtoneScreenState extends State<AdminRingtoneScreen> {
  final titleController = TextEditingController();
  final audioController = TextEditingController();
  final coverController = TextEditingController();
  String selectedCategory = ringtoneCategories.first;
  bool isLoading = false;

  @override
  void dispose() {
    titleController.dispose();
    audioController.dispose();
    coverController.dispose();
    super.dispose();
  }

  Future<void> addRingtone() async {
    if (!isAdminEmail(FirebaseAuth.instance.currentUser?.email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admin can upload ringtones')),
      );
      return;
    }

    final title = titleController.text.trim();
    final audioUrl = audioController.text.trim();
    final coverImage = coverController.text.trim();
    final category = selectedCategory;

    if (title.isEmpty || audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill title and audio URL')),
      );
      return;
    }

    final uri = Uri.tryParse(audioUrl);
    final isValidUrl = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    if (!isValidUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid audio URL (.mp3)')),
      );
      return;
    }

    final ringtone = Ringtone(
      title: title,
      audioUrl: audioUrl,
      category: category,
      coverImage: coverImage,
    );

    try {
      setState(() => isLoading = true);
      await AppData.addRingtone(ringtone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ringtone added')),
      );
      Navigator.pop(context);
    } catch (_) {
      await AppData.addLocalRingtone(ringtone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved locally')),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdminEmail(FirebaseAuth.instance.currentUser?.email)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Only admin can upload ringtones', textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Ringtone')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: inputDecoration('Title', Icons.title),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: audioController,
              keyboardType: TextInputType.url,
              decoration: inputDecoration('Audio URL (.mp3)', Icons.audiotrack_rounded),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: coverController,
              keyboardType: TextInputType.url,
              decoration: inputDecoration('Cover Image URL (optional)', Icons.image_rounded),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: inputDecoration('Category', Icons.category),
              items: ringtoneCategories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: isLoading
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => selectedCategory = value);
                    },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : addRingtone,
                icon: isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add),
                label: const Text('Add Ringtone'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ringtone Preview Screen ──────────────────────────────────────────────────

class RingtonePreviewScreen extends StatefulWidget {
  final Ringtone ringtone;
  const RingtonePreviewScreen({super.key, required this.ringtone});

  @override
  State<RingtonePreviewScreen> createState() => _RingtonePreviewScreenState();
}

class _RingtonePreviewScreenState extends State<RingtonePreviewScreen> with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;
  bool isLoadingAudio = true;
  bool isFavorite = false;
  bool isBusy = false;
  bool _pendingRingtoneRetry = false;
  Duration position = Duration.zero;
  Duration totalDuration = Duration.zero;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;

  String get safeName => widget.ringtone.title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFavoriteStatus();
    _initPlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // User came back from the system "Modify system settings" screen.
    if (state == AppLifecycleState.resumed && _pendingRingtoneRetry) {
      _pendingRingtoneRetry = false;
      // Small delay so Android finishes applying the permission state.
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _setAsRingtone(isRetry: true);
      });
    }
  }

  Future<void> _loadFavoriteStatus() async {
    final favs = await AppData.getStringList('ringtoneFavorites');
    if (mounted) setState(() => isFavorite = favs.contains(widget.ringtone.audioUrl));
  }

  Future<void> _initPlayer() async {
    try {
      // Attach listeners BEFORE play() so no state events are missed.
      _posSub = _player.positionStream.listen((p) {
        if (mounted) setState(() => position = p);
      });
      _stateSub = _player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() => isPlaying = state.playing);
        if (state.processingState == ProcessingState.completed) {
          setState(() { isPlaying = false; position = Duration.zero; });
          _player.seek(Duration.zero);
        }
      });

      await _player.setUrl(widget.ringtone.audioUrl);
      totalDuration = _player.duration ?? Duration.zero;
      if (mounted) setState(() => isLoadingAudio = false);
      await _player.play();
      if (mounted) setState(() => isPlaying = true);
    } catch (e) {
      debugPrint('Ringtone load failed: $e');
      if (mounted) setState(() => isLoadingAudio = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _posSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.lightImpact();
    if (isPlaying) {
      setState(() => isPlaying = false);
      _player.pause();
    } else {
      setState(() => isPlaying = true);
      _player.play();
    }
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.mediumImpact();
    final favs = await AppData.getStringList('ringtoneFavorites');
    if (favs.contains(widget.ringtone.audioUrl)) {
      favs.remove(widget.ringtone.audioUrl);
    } else {
      favs.add(widget.ringtone.audioUrl);
    }
    await AppData.saveStringList('ringtoneFavorites', favs);
    if (mounted) setState(() => isFavorite = favs.contains(widget.ringtone.audioUrl));
  }

  Future<File> _downloadAudio({void Function(double)? onProgress}) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$safeName.mp3';
    final file = File(filePath);
    if (!await file.exists()) {
      await Dio().download(
        widget.ringtone.audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );
    }
    return file;
  }

  Future<void> _downloadOnly() async {
    if (isBusy) return;
    setState(() => isBusy = true);
    try {
      final file = await _downloadAudio();
      final fileName = '$safeName.mp3';
      String savedPath = file.path;
      if (Platform.isAndroid) {
        try {
          final result = await downloadsChannel.invokeMethod<String>(
            'saveAudioToDownloads',
            {'sourcePath': file.path, 'fileName': fileName},
          );
          if (result != null && result.isNotEmpty) savedPath = result;
        } on PlatformException catch (e) {
          debugPrint('Audio save to downloads failed: ${e.message}');
        }
      }
      debugPrint('Saved ringtone to: $savedPath');
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloaded ✓')));
    } catch (e) {
      debugPrint('Ringtone download failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download failed')));
      }
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> _setAsRingtone({bool isRetry = false}) async {
    if (isBusy) return;
    setState(() => isBusy = true);
    try {
      final file = await _downloadAudio();
      String status = 'failed';
      if (Platform.isAndroid) {
        try {
          final result = await ringtoneChannel.invokeMethod<Map>(
            'setRingtone',
            {'sourcePath': file.path, 'fileName': '$safeName.mp3', 'title': widget.ringtone.title},
          );
          status = (result?['status'] as String?) ?? 'failed';
        } on PlatformException catch (e) {
          debugPrint('setRingtone failed: ${e.message}');
        }
      }
      if (!mounted) return;

      if (status == 'success') {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ringtone set ✓')),
        );
      } else if (status == 'permission_needed') {
        // Native side has already opened the "Modify system settings" screen.
        // Remember to retry automatically once the user comes back.
        _pendingRingtoneRetry = true;
        if (!isRetry) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Allow "Modify system settings" for this app, then come back'),
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission still not granted — please allow it in Settings')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not set ringtone')),
        );
      }
    } catch (e) {
      debugPrint('Set ringtone error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to set ringtone')));
      }
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> _shareRingtone() async {
    try {
      final file = await _downloadAudio();
      await Share.shareXFiles([XFile(file.path)], text: 'Check out this ringtone: ${widget.ringtone.title}');
    } catch (e) {
      debugPrint('Share failed: $e');
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: premiumBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.ringtone.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? premiumPink : Colors.white70,
            ),
          ),
          IconButton(
            onPressed: _shareRingtone,
            icon: const Icon(Icons.share_rounded, color: Colors.white70),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // ── Cover / icon ──────────────────────────────
              Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  gradient: premiumGradient,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [BoxShadow(color: premiumCyan.withValues(alpha: 0.35), blurRadius: 50, offset: const Offset(0, 20))],
                  image: widget.ringtone.coverImage.isNotEmpty
                      ? DecorationImage(image: NetworkImage(widget.ringtone.coverImage), fit: BoxFit.cover)
                      : null,
                ),
                child: widget.ringtone.coverImage.isEmpty
                    ? const Icon(Icons.music_note_rounded, size: 90, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 32),
              Text(widget.ringtone.title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(widget.ringtone.category,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 28),

              // ── Progress ──────────────────────────────────
              if (isLoadingAudio)
                const CircularProgressIndicator(color: premiumCyan)
              else ...[
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    activeTrackColor: premiumCyan,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: premiumCyan,
                    overlayColor: premiumCyan.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: totalDuration.inMilliseconds > 0
                        ? position.inMilliseconds.clamp(0, totalDuration.inMilliseconds).toDouble()
                        : 0,
                    max: totalDuration.inMilliseconds > 0 ? totalDuration.inMilliseconds.toDouble() : 1,
                    onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(_formatDuration(totalDuration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: premiumGradient,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: premiumCyan.withValues(alpha: 0.4), blurRadius: 24)],
                    ),
                    child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 36),
                  ),
                ),
              ],

              const Spacer(),

              // ── Action buttons ────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : _downloadOnly,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: premiumGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: premiumCyan.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: isBusy ? null : _setAsRingtone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: isBusy
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.music_note_rounded, color: Colors.white),
                        label: const Text('Set as Ringtone', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
