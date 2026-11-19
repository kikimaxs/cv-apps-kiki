import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_experience_lab.dart';
import 'home_fx.dart';
import 'home_motion.dart';
import 'home_project_wall.dart';
import 'home_showreel.dart';

/// Glyphs used only by home_showreel.dart and home_experience_lab.dart.
///
/// `flutter build web --release` shrinks the Font Awesome fonts to the glyphs
/// its icon tree shaker can see, and (observed with font_awesome_flutter 11)
/// it does not see icons that are referenced only from those two files, so
/// they showed up as empty boxes on the web. Listing them here, as constants,
/// keeps them in the shrunken font. Add any new icon used only there too.
const List<FaIconData> kHomeFaIcons = [
  FontAwesomeIcons.play,
  FontAwesomeIcons.pause,
  FontAwesomeIcons.arrowLeft,
  FontAwesomeIcons.clock,
  FontAwesomeIcons.volumeHigh,
  FontAwesomeIcons.volumeXmark,
  FontAwesomeIcons.xmark,
  FontAwesomeIcons.triangleExclamation,
  FontAwesomeIcons.laptop,
  FontAwesomeIcons.circleCheck,
  FontAwesomeIcons.handPointer,
  // Used by the portfolio page (contact list, PDF export, back-to-top).
  FontAwesomeIcons.discord,
  FontAwesomeIcons.filePdf,
  FontAwesomeIcons.arrowUp,
  // Used by home_project_wall.dart.
  FontAwesomeIcons.quoteLeft,
  FontAwesomeIcons.arrowRight,
];

/// Text font for the whole Home page: Carlito, the open-licence,
/// metric-compatible twin of Calibri (same glyph widths, so it lays out
/// exactly like Calibri). Calibri itself is a licensed Microsoft font and
/// cannot be bundled; Carlito is already in assets/fonts (regular, bold,
/// italic, bold italic), also used by the portfolio page and its PDF.
const String kHomeFontFamily = 'Carlito';

class HomeMain extends StatefulWidget {
  const HomeMain({super.key});

  @override
  State<HomeMain> createState() => _HomeMainState();
}

class _HomeMainState extends State<HomeMain> {
  static const _background = Color(0xFF080D18);
  static const _surface = Color(0xFF111B2C);
  static const _accent = Color(0xFF67D4FF);
  final PageController _pageController = PageController();

  static const int _pageCount = 3;
  final ValueNotifier<int> _currentPage = ValueNotifier<int>(0);
  bool _isPageTransitioning = false;
  int? _pendingPageDirection;

  @override
  void dispose() {
    _pageController.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  void _scrollToNextPage() {
    _animateToPage(
      _currentPage.value + 1,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _animateToPage(
    int targetPage, {
    Duration duration = const Duration(milliseconds: 650),
    Curve curve = Curves.easeInOutCubic,
  }) async {
    if (!mounted ||
        targetPage < 0 ||
        targetPage >= _pageCount ||
        !_pageController.hasClients ||
        _isPageTransitioning) {
      return;
    }

    _isPageTransitioning = true;
    try {
      await _pageController.animateToPage(
        targetPage,
        duration: duration,
        curve: curve,
      );
    } finally {
      _isPageTransitioning = false;
    }
  }

  bool _onPageScrollNotification(
    int pageIndex,
    ScrollNotification notification,
  ) {
    if (notification.metrics.axis != Axis.vertical ||
        notification.depth != 0 ||
        pageIndex != _currentPage.value) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      _pendingPageDirection = null;
    } else if (notification is OverscrollNotification &&
        !_isPageTransitioning) {
      if (notification.overscroll > 0 &&
          notification.metrics.extentAfter == 0) {
        _pendingPageDirection = 1;
      } else if (notification.overscroll < 0 &&
          notification.metrics.extentBefore == 0) {
        _pendingPageDirection = -1;
      }
    } else if (notification is ScrollEndNotification) {
      final direction = _pendingPageDirection;
      _pendingPageDirection = null;
      if (direction != null) {
        _animateToPage(_currentPage.value + direction);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    assert(kHomeFaIcons.isNotEmpty);
    // Every Text on the page (hero, showreel, lab, footer, buttons, dialogs
    // opened from here) inherits the Calibri-metric font through the theme
    // and the Scaffold's default text style; explicit TextStyles that do not
    // name a family pick it up too.
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: kHomeFontFamily),
        primaryTextTheme: theme.primaryTextTheme.apply(
          fontFamily: kHomeFontFamily,
        ),
      ),
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: _background,
      body: CursorGlow(
        background: const Stack(
          fit: StackFit.expand,
          children: [_HomeBackdrop(), AuroraBackground()],
        ),
        child: Stack(
          children: [
            // Scrollable Content using PageView for snapping effect
            PageView(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                _currentPage.value = index;
                _pendingPageDirection = null;
              },
              children: [
                // PAGE 1: INTRODUCTION & INTERACTIVE CAPABILITIES
                _buildPageWrapper(
                  child: _buildScrollablePage(
                    pageIndex: 0,
                    child: Column(
                      children: [
                        const SizedBox(height: 112),
                        RepaintBoundary(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildHeroSection(),
                          ),
                        ),
                        const SizedBox(height: 64),
                        const HomeShowreel(),
                        const SizedBox(height: 88),
                        const Reveal(
                          child: RepaintBoundary(child: HomeExperienceLab()),
                        ),
                        const SizedBox(height: 40),
                        const _AnimatedScrollIndicator(),
                        const SizedBox(height: 52),
                      ],
                    ),
                  ),
                ),

                // PAGE 2: SERVICES & CAPABILITIES
                _buildPageWrapper(
                  child: _buildScrollablePage(
                    pageIndex: 1,
                    padding: const EdgeInsets.only(top: 96, bottom: 40),
                    child: ValueListenableBuilder<int>(
                      valueListenable: _currentPage,
                      child: RepaintBoundary(
                        child: _buildDetailedServices(context),
                      ),
                      builder: (context, currentPage, child) =>
                          _buildAnimatedSection(
                            isVisible: currentPage == 1,
                            child: child!,
                          ),
                    ),
                  ),
                ),

                // PAGE 3: CONTACT FOOTER
                _buildPageWrapper(
                  useSafeArea: false,
                  child: _buildScrollablePage(
                    pageIndex: 2,
                    padding: const EdgeInsets.only(top: 96),
                    child: ValueListenableBuilder<int>(
                      valueListenable: _currentPage,
                      child: RepaintBoundary(
                        child: Column(
                          children: [
                            const ProjectWall(),
                            const SizedBox(height: 56),
                            _buildContactFooter(context),
                          ],
                        ),
                      ),
                      builder: (context, currentPage, child) =>
                          _buildAnimatedSection(
                            isVisible: currentPage == 2,
                            child: child!,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 1000;
    return SafeArea(
      bottom: false,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: mobile ? 14 : 32,
          vertical: 12,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 16 : 22,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xF2101928),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
          boxShadow: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 24),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Text(
                    'K.',
                    style: TextStyle(
                      color: _background,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
                if (width >= 430) ...[
                  const SizedBox(width: 10),
                  const Text(
                    'KIKI TRIANSYAH',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
                const Spacer(),
                if (!mobile) ...[
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    onPressed: () => _animateToPage(0),
                    child: const Text('Beranda'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    onPressed: () => _animateToPage(1),
                    child: const Text('Keahlian'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    onPressed: () => context.go('/my_portofolio'),
                    child: const Text('Portofolio'),
                  ),
                  TextButton(
                    key: const ValueKey('nav-cv-button'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    onPressed: () => context.go('/my_cv'),
                    child: const Text('CV'),
                  ),
                  const SizedBox(width: 14),
                ],
                FilledButton.icon(
                  onPressed: () => _animateToPage(2),
                  icon: FaIcon(
                    mobile
                        ? FontAwesomeIcons.paperPlane
                        : FontAwesomeIcons.comments,
                    size: 16,
                  ),
                  label: Text(mobile ? 'Kontak' : 'Mari bicara'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _background,
                    padding: EdgeInsets.symmetric(
                      horizontal: mobile ? 12 : 18,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageWrapper({required Widget child, bool useSafeArea = true}) {
    if (useSafeArea) {
      return SafeArea(child: Center(child: child));
    }
    return Center(child: child);
  }

  Widget _buildScrollablePage({
    required int pageIndex,
    required Widget child,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          NotificationListener<ScrollNotification>(
            onNotification: (notification) =>
                _onPageScrollNotification(pageIndex, notification),
            child: SingleChildScrollView(
              key: PageStorageKey<int>(pageIndex),
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
    );
  }

  Widget _buildAnimatedSection({
    required Widget child,
    Key? key,
    bool isVisible = true,
  }) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 850);
    return AnimatedOpacity(
      key: key,
      opacity: isVisible ? 1.0 : 0.0,
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 0.08),
        duration: duration,
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }

  Widget _buildHeroSection() {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 800;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final introduction = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _staggerIn(reducedMotion, [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.09),
            border: Border.all(color: _accent.withValues(alpha: 0.26)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'SOFTWARE DEVELOPER  /  FLUTTER SPECIALIST',
            style: TextStyle(
              color: _accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        AnimatedHeadline(
          text: 'Membangun produk digital yang terasa tepat.',
          highlight: const {4, 5},
          style: TextStyle(
            color: Colors.white,
            fontSize: mobile ? 39 : 64,
            height: 1.06,
            fontWeight: FontWeight.w900,
            letterSpacing: mobile ? -1.8 : -3.2,
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: const Text(
            'Saya Kiki Triansyah. Saya merancang dan mengembangkan aplikasi mobile serta website, dari ide awal sampai siap digunakan orang banyak.',
            style: TextStyle(
              color: Color(0xFFB8C8DA),
              fontSize: 16,
              height: 1.65,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => _animateToPage(2),
              icon: const FaIcon(FontAwesomeIcons.arrowRight, size: 15),
              label: const Text('Diskusikan proyek'),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _background,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/my_portofolio'),
              icon: const FaIcon(FontAwesomeIcons.briefcase, size: 15),
              label: const Text('Lihat portofolio'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF41536A)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
            OutlinedButton.icon(
              key: const ValueKey('hero-cv-button'),
              onPressed: () => context.go('/my_cv'),
              icon: const FaIcon(FontAwesomeIcons.fileLines, size: 15),
              label: const Text('Lihat CV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF41536A)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Wrap(
          spacing: 22,
          runSpacing: 8,
          children: [
            _HeroProof(
              icon: FontAwesomeIcons.mobileScreenButton,
              label: 'Mobile & web',
            ),
            _HeroProof(
              icon: FontAwesomeIcons.rocket,
              label: 'Dari ide hingga rilis',
            ),
            _HeroProof(
              icon: FontAwesomeIcons.wandMagicSparkles,
              label: 'Detail yang terasa',
            ),
          ],
        ),
      ]),
    );
    final orbitSize = mobile ? math.min(width - 48, 340.0) : 420.0;
    final orbit = Center(child: HeroOrbit(size: orbitSize));
    final hero = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1180),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [introduction, const SizedBox(height: 36), orbit],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: introduction),
                const SizedBox(width: 64),
                orbit,
              ],
            ),
    );
    return hero;
  }

  /// Staggered fade-and-rise entrance for the hero copy. The headline
  /// animates its own words, so it is passed through untouched.
  List<Widget> _staggerIn(bool reducedMotion, List<Widget> children) {
    if (reducedMotion) return children;
    return [
      for (var i = 0; i < children.length; i++)
        children[i] is AnimatedHeadline
            ? children[i]
            : children[i]
                  .animate(delay: (i * 80).ms)
                  .fadeIn(duration: 550.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
    ];
  }

  Widget _buildDetailedServices(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1180),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'APA YANG SAYA KERJAKAN',
              'Solusi yang dibangun untuk kebutuhan nyata.',
            ),
            const SizedBox(height: 14),
            const Text(
              'Dari tampilan yang mudah dipakai hingga sistem yang mendukungnya, setiap bagian dibuat agar bekerja sebagai satu produk.',
              style: TextStyle(
                color: Color(0xFFB8C8DA),
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: constraints.maxWidth < 820
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 32) / 3,
                    child: _buildServiceCard(
                      title: "Web & Mobile Development",
                      description:
                          "Saya bisa membuat project Web dan Mobile Cross-platform maupun Native iOS & Android dengan performa tinggi dan desain responsif.",
                      icons: [
                        'flutter-svgrepo-com.svg',
                        'android-svgrepo-com.svg',
                        'ios-svgrepo-com.svg',
                        'react-svgrepo-com.svg',
                      ],
                      gradient: [Colors.blue, Colors.cyan],
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth < 820
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 32) / 3,
                    child: _buildServiceCard(
                      title: "Backend & API Architecture",
                      description:
                          "Membangun data endpoint yang robust menggunakan Node JS, Express JS, dan Laravel untuk kebutuhan integrasi sistem Anda.",
                      icons: [
                        'node-js-svgrepo-com.svg',
                        'laravel-1-logo-svgrepo-com.svg',
                      ],
                      gradient: [Colors.greenAccent, Colors.teal],
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth < 820
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 32) / 3,
                    child: _buildServiceCard(
                      title: "Database Management",
                      description:
                          "Pengelolaan database berskala besar menggunakan MySQL dan SQL Server dengan optimasi query yang efisien.",
                      icons: ['mysql-logo-svgrepo-com.svg'],
                      gradient: [Colors.orangeAccent, Colors.deepOrange],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 70),
            // Tools & Environment integrated here
            _buildTechStackCategories(),
            const SizedBox(height: 64),
            _buildEndToEndFocus(),
            const SizedBox(height: 56),
            Center(
              child: FilledButton.icon(
                onPressed: () => _animateToPage(2),
                icon: const FaIcon(FontAwesomeIcons.arrowRight, size: 16),
                label: const Text('Punya proyek? Mari berbicara'),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: _background,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String subtitle, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle.toUpperCase(),
          style: TextStyle(
            color: _accent,
            letterSpacing: 2,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.sizeOf(context).width < 600 ? 30 : 42,
            fontWeight: FontWeight.w900,
            height: 1.12,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(width: 40, height: 3, color: Colors.white24),
      ],
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String description,
    required List<String> icons,
    required List<Color> gradient,
  }) {
    return HomeHoverLift(
      glow: gradient.first,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: icons
                  .map(
                    (icon) => SvgPicture.asset(
                      'assets/svg/skill/$icon',
                      width: 36,
                      height: 36,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndToEndFocus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.wandMagicSparkles,
                color: Colors.cyanAccent,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'End-to-End Solutions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Saya menangani seluruh siklus pengembangan aplikasi, memastikan hasil akhir yang sempurna dan siap tayang.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 40),

          _buildTrackingStep(
            icon: FontAwesomeIcons.lightbulb,
            title: "Ide & Konsultasi",
            description:
                "Analisis kebutuhan, pembuatan mock-up, dan perencanaan fitur sesuai target bisnis Anda.",
            isFirst: true,
          ),
          _buildTrackingStep(
            icon: FontAwesomeIcons.code,
            title: "Development & Coding",
            description:
                "Proses coding menggunakan tech stack terbaru dengan clean code dan performa tinggi.",
          ),
          _buildTrackingStep(
            icon: FontAwesomeIcons.clipboardCheck,
            title: "Testing & QC",
            description:
                "Uji coba menyeluruh di berbagai device (iOS/Android/Web) untuk memastikan tidak ada bug.",
          ),
          _buildTrackingStep(
            icon: FontAwesomeIcons.rocket,
            title: "Deployment & Public Release",
            description:
                "Rilis ke App Store, Play Store, dan Hosting Web hingga aplikasi bisa diakses publik.",
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStep({
    required FaIconData icon,
    required String title,
    required String description,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: FaIcon(icon, color: Colors.cyanAccent, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.cyanAccent.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                if (!isLast) const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechStackCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'ENGINEERING STACK',
          'Teknologi yang saya gunakan.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Fondasi teknis untuk merancang antarmuka, menghubungkan data, dan merilis produk.',
          style: TextStyle(color: Color(0xFFB8C8DA), fontSize: 15, height: 1.6),
        ),
        const SizedBox(height: 30),
        _buildStackCategory('Mobile & frontend', [
          _stackItem('Flutter', FontAwesomeIcons.flutter),
          _stackItem('React', FontAwesomeIcons.react),
          _stackItem('Next.js', FontAwesomeIcons.globe),
          _stackItem('Responsive UI', FontAwesomeIcons.laptopCode),
        ]),
        const SizedBox(height: 20),
        _buildStackCategory('Backend & data', [
          _stackItem('Node.js', FontAwesomeIcons.nodeJs),
          _stackItem('Laravel', FontAwesomeIcons.laravel),
          _stackItem('MySQL', FontAwesomeIcons.database),
          _stackItem('Firebase', FontAwesomeIcons.fire),
        ]),
        const SizedBox(height: 20),
        _buildStackCategory('Design & delivery', [
          _stackItem('Figma', FontAwesomeIcons.figma),
          _stackItem('Git', FontAwesomeIcons.gitAlt),
          _stackItem('Testing & QC', FontAwesomeIcons.clipboardCheck),
          _stackItem('App Store / Play Store', FontAwesomeIcons.googlePlay),
        ]),
      ],
    );
  }

  Widget _buildStackCategory(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 12, children: items),
      ],
    );
  }

  Widget _stackItem(String label, FaIconData icon) {
    return HomeHoverLift(
      glow: _accent,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              child: Center(
                child: FaIcon(icon, color: Colors.white70, size: 15),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 58, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101F33), _background],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LANGKAH SELANJUTNYA',
                style: TextStyle(
                  color: _accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Ide bagus layak menjadi produk yang hebat.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.sizeOf(context).width < 600 ? 39 : 62,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Ceritakan kebutuhan Anda. Saya siap membantu merancang, membangun, dan merilis pengalaman digital yang berguna.',
                style: TextStyle(
                  color: Color(0xFFB8C8DA),
                  fontSize: 16,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => _openLink(
                      'mailto:kiki.triansyah93@gmail.com?subject=Diskusi%20proyek',
                    ),
                    icon: const FaIcon(FontAwesomeIcons.envelope, size: 16),
                    label: const Text('Kirim email'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: _background,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 18,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openLink('https://wa.me/6287728020907'),
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                    label: const Text('Chat via WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF53647A)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Divider(color: Colors.white.withValues(alpha: 0.14)),
              const SizedBox(height: 26),
              LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth < 700
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 16) / 2,
                      child: _buildContactItem(
                        FontAwesomeIcons.envelope,
                        'Email',
                        'kiki.triansyah93@gmail.com',
                        'mailto:kiki.triansyah93@gmail.com',
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth < 700
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 16) / 2,
                      child: _buildContactItem(
                        FontAwesomeIcons.linkedin,
                        'LinkedIn',
                        'Kiki Triansyah',
                        'https://www.linkedin.com/in/kiki-triansyah/',
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth < 700
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 16) / 2,
                      child: _buildContactItem(
                        FontAwesomeIcons.github,
                        'GitHub',
                        '@kikimaxs',
                        'https://github.com/kikimaxs',
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth < 700
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 16) / 2,
                      child: _buildContactItem(
                        FontAwesomeIcons.gitlab,
                        'GitLab',
                        '@kikitriansyah',
                        'https://gitlab.com/kikitriansyah',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 64),
              Divider(color: Colors.white.withValues(alpha: 0.14)),
              const SizedBox(height: 20),
              // Back-to-top and copyright stacked on the footer's centre line
              // at every width (phone, tablet, desktop).
              const SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _AnimatedBackToTop(),
                    SizedBox(height: 20),
                    Text(
                      '© 2026 Kiki Triansyah',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8EA3B8), fontSize: 12),
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

  Widget _buildContactItem(
    FaIconData icon,
    String label,
    String value,
    String url,
  ) {
    return HomeHoverLift(
      glow: _accent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openLink(url),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Center(child: FaIcon(icon, color: _accent, size: 22)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const FaIcon(
                FontAwesomeIcons.arrowUpRightFromSquare,
                color: _accent,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroProof extends StatelessWidget {
  final FaIconData icon;
  final String label;
  const _HeroProof({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: Row(
      children: [
        SizedBox(
          width: 20,
          child: Center(
            child: FaIcon(icon, color: const Color(0xFF67D4FF), size: 15),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB8C8DA),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AnimatedScrollIndicator extends StatefulWidget {
  const _AnimatedScrollIndicator();

  @override
  State<_AnimatedScrollIndicator> createState() =>
      _AnimatedScrollIndicatorState();
}

class _AnimatedScrollIndicatorState extends State<_AnimatedScrollIndicator>
    with
        SingleTickerProviderStateMixin,
        AmbientAware<_AnimatedScrollIndicator> {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void onActiveChanged(bool active) => _syncPulse();

  void _syncPulse() {
    if (MediaQuery.disableAnimationsOf(context) || !isActive) {
      _pulseController.stop();
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = context.findAncestorStateOfType<_HomeMainState>();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () => homeState?._scrollToNextPage(),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final double scale = _isPressed ? 0.8 : (_isHovered ? 1.2 : 1.0);
            final double pulse = 15 * _pulseController.value;

            return Transform.translate(
              offset: Offset(0, pulse),
              child: Transform.scale(
                scale: scale,
                // Alpha lives in the colour: an Opacity widget would force an
                // offscreen layer on every frame of the pulse.
                child: FaIcon(
                  FontAwesomeIcons.anglesDown,
                  color: _isHovered
                      ? Colors.cyanAccent
                      : Colors.white.withValues(alpha: 0.8),
                  size: 40,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedBackToTop extends StatefulWidget {
  const _AnimatedBackToTop();

  @override
  State<_AnimatedBackToTop> createState() => _AnimatedBackToTopState();
}

class _AnimatedBackToTopState extends State<_AnimatedBackToTop> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final homeState = context.findAncestorStateOfType<_HomeMainState>();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          homeState?._animateToPage(
            0,
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOutExpo,
          );
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.9 : (_isHovered ? 1.2 : 1.0),
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: _isHovered
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.white24,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 15,
                          ),
                        ]
                      : [],
                ),
                child: FaIcon(
                  FontAwesomeIcons.anglesUp,
                  color: _isHovered ? Colors.white : Colors.white70,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: _isHovered ? Colors.white : Colors.white38,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
                ),
                child: const Text("BACK TO TOP"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Static backdrop behind the whole Home page: a collage of app screens Kiki
/// has built (rasterised from the old assets/img/svg/cover_home.svg, which
/// was 3.4 MB). It sits under the aurora and a dark wash so the copy stays
/// readable, is decoded at screen width only, and never repaints.
class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final decodeWidth = (media.size.width * media.devicePixelRatio)
        .clamp(480, 1280)
        .round();
    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/img/home_backdrop.jpg',
              fit: BoxFit.cover,
              cacheWidth: decodeWidth,
              filterQuality: FilterQuality.low,
              excludeFromSemantics: true,
            ),
            ColoredBox(
              color: _HomeMainState._background.withValues(alpha: 0.86),
            ),
          ],
        ),
      ),
    );
  }
}
