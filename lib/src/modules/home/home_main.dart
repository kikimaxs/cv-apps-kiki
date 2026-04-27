import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';

class HomeMain extends StatefulWidget {
  const HomeMain({super.key});

  @override
  State<HomeMain> createState() => _HomeMainState();
}

class _HomeMainState extends State<HomeMain> {
  final PageController _pageController = PageController();

  // Track visibility states for reveal animations
  int _currentPage = 0;
  final PageController _carouselController = PageController(
    viewportFraction: 0.45,
    initialPage:
        600, // Start at a large index (multiple of 6) for infinite simulation
  );
  int _currentCarouselPage = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_carouselController.hasClients) {
        _carouselController.nextPage(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  void _scrollToNextPage() {
    _pageController.nextPage(
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/img/svg/cover_home.svg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withOpacity(0.85)),
          ),

          // Scrollable Content using PageView for snapping effect
          PageView(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            children: [
              // PAGE 1: HERO & CINEMATIC CAROUSEL
              _buildPageWrapper(
                usePadding: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: _buildHeroSection(),
                      ),
                      const SizedBox(height: 32),
                      _buildCinematicCarousel(context),
                      const SizedBox(height: 60),
                      // Scroll Down Indicator
                      _AnimatedScrollIndicator(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // PAGE 2: SERVICES & CAPABILITIES
              _buildPageWrapper(
                usePadding: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: _buildAnimatedSection(
                    isVisible: _currentPage == 1,
                    child: _buildDetailedServices(context),
                  ),
                ),
              ),

              // PAGE 3: CONTACT FOOTER
              _buildPageWrapper(
                usePadding: false,
                useSafeArea: false,
                child: _buildAnimatedSection(
                  isVisible: _currentPage == 2,
                  child: _buildContactFooter(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageWrapper({
    required Widget child,
    bool usePadding = true,
    bool useSafeArea = true,
  }) {
    Widget content = Padding(
      padding: usePadding
          ? const EdgeInsets.symmetric(horizontal: 24.0)
          : EdgeInsets.zero,
      child: child,
    );

    if (useSafeArea) {
      return SafeArea(child: Center(child: content));
    }
    return Center(child: content);
  }

  Widget _buildAnimatedSection({
    required Widget child,
    Key? key,
    bool isVisible = true,
  }) {
    return AnimatedOpacity(
      key: key,
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 0.4),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }

  Widget _buildHeroSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Text(
            'WELCOME TO',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              letterSpacing: 4,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'MY CV & PORTFOLIO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 60,
            height: 2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.cyanAccent, Colors.blueAccent],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Professional Software Developer specializing in End-to-End Enterprise Solutions.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        _buildGlassButton(
          context,
          label: 'VIEW MY CV',
          subtitle: 'Professional experience & skills',
          icon: Icons.description_outlined,
          onTap: () => context.go('/my_cv'),
          delay: 400,
        ),
        const SizedBox(height: 20),
        _buildGlassButton(
          context,
          label: 'MY PORTFOLIO',
          subtitle: 'Recent projects & creative work',
          icon: Icons.palette_outlined,
          onTap: () => context.go('/my_portofolio'),
          delay: 600,
        ),
      ],
    );
  }

  Widget _buildDetailedServices(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Keahlian Utama", "What I Can Build For You"),
          const SizedBox(height: 40),
          _buildServiceCard(
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
          const SizedBox(height: 20),
          _buildServiceCard(
            title: "Backend & API Architecture",
            description:
                "Membangun data endpoint yang robust menggunakan Node JS, Express JS, dan Laravel untuk kebutuhan integrasi sistem Anda.",
            icons: [
              'node-js-svgrepo-com.svg',
              'laravel-1-logo-svgrepo-com.svg',
            ],
            gradient: [Colors.greenAccent, Colors.teal],
          ),
          const SizedBox(height: 20),
          _buildServiceCard(
            title: "Database Management",
            description:
                "Pengelolaan database berskala besar menggunakan MySQL dan SQL Server dengan optimasi query yang efisien.",
            icons: ['mysql-logo-svgrepo-com.svg'],
            gradient: [Colors.orangeAccent, Colors.deepOrange],
          ),
          const SizedBox(height: 60),
          // Tools & Environment integrated here
          _buildTechStackCategories(),
          const SizedBox(height: 40),
          _buildEndToEndFocus(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String subtitle, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle.toUpperCase(),
          style: const TextStyle(
            color: Colors.cyanAccent,
            letterSpacing: 2,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
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
    );
  }

  Widget _buildEndToEndFocus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.cyanAccent,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                "End-to-End Solutions",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Saya menangani seluruh siklus pengembangan aplikasi, memastikan hasil akhir yang sempurna dan siap tayang.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 40),

          _buildTrackingStep(
            icon: Icons.lightbulb_outline,
            title: "Ide & Konsultasi",
            description:
                "Analisis kebutuhan, pembuatan mock-up, dan perencanaan fitur sesuai target bisnis Anda.",
            isFirst: true,
          ),
          _buildTrackingStep(
            icon: Icons.code,
            title: "Development & Coding",
            description:
                "Proses coding menggunakan tech stack terbaru dengan clean code dan performa tinggi.",
          ),
          _buildTrackingStep(
            icon: Icons.fact_check_outlined,
            title: "Testing & QC",
            description:
                "Uji coba menyeluruh di berbagai device (iOS/Android/Web) untuk memastikan tidak ada bug.",
          ),
          _buildTrackingStep(
            icon: Icons.rocket_launch_outlined,
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
    required IconData icon,
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
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                ),
                child: Icon(icon, color: Colors.cyanAccent, size: 22),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.cyanAccent.withOpacity(0.5),
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
                    color: Colors.white.withOpacity(0.5),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Tools & Environment", "Tech Stack & Ecosystem"),
          const SizedBox(height: 30),
          _buildStackCategory("Software Tools", [
            _stackItem("VS Code", Icons.code),
            _stackItem("Figma", Icons.draw),
            _stackItem("Postman", Icons.api),
            _stackItem("Git", Icons.account_tree),
          ]),
          const SizedBox(height: 20),
          _buildStackCategory("Hardware", [
            _stackItem("MacBook Pro", Icons.laptop_mac),
            _stackItem("Android Test Device", Icons.phone_android),
            _stackItem("iPhone Test Device", Icons.phone_iphone),
          ]),
          const SizedBox(height: 20),
          _buildStackCategory("Cloud & Hosting", [
            _stackItem("Firebase", Icons.cloud_queue),
            _stackItem("VPS / Hosting", Icons.dns),
            _stackItem("Play Console", Icons.shop_2),
            _stackItem("App Store Connect", Icons.apple),
          ]),
        ],
      ),
    );
  }

  Widget _buildStackCategory(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 12, children: items),
      ],
    );
  }

  Widget _stackItem(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCinematicCarousel(BuildContext context) {
    final List<Map<String, dynamic>> carouselData = [
      {
        'title': 'High-End Mobile Apps',
        'type': 'FLUTTER • IOS • ANDROID',
        'desc': 'Membangun aplikasi performa tinggi & responsif.',
        'icons': [
          'flutter-svgrepo-com.svg',
          'android-svgrepo-com.svg',
          'ios-svgrepo-com.svg',
        ],
        'color': const Color(0xFF0EA5E9),
        'logo': Icons.phone_iphone,
      },
      {
        'title': 'Scalable Web Projects',
        'type': 'REACT • NEXT.JS • UI/UX',
        'desc': 'Website modern & SEO friendly tingkat tinggi.',
        'icons': ['react-svgrepo-com.svg', 'next-js-svgrepo-com.svg'],
        'color': const Color(0xFF8B5CF6),
        'logo': Icons.web,
      },
      {
        'title': 'Durioo+: Released App',
        'type': 'MOBILE • PLAYSTORE • APPSTORE',
        'desc': 'Project rilis yang saya kerjakan dari awal hingga tayang publik.',
        'icons': [
          'flutter-svgrepo-com.svg',
          'android-svgrepo-com.svg',
          'ios-svgrepo-com.svg',
        ],
        'color': const Color(0xFF10B981),
        'logo': Icons.verified,
        'video': 'assets/video/durioo+_memang_berbaloi!.mp4',
      },
      {
        'title': 'Production Showcase 0411',
        'type': 'MOBILE • PLAYSTORE • APPSTORE',
        'desc': 'Digital product berkualitas tinggi yang sudah rilis di store.',
        'icons': [
          'flutter-svgrepo-com.svg',
          'android-svgrepo-com.svg',
          'ios-svgrepo-com.svg',
        ],
        'color': const Color(0xFFF59E0B),
        'logo': Icons.rocket_launch,
        'video': 'assets/video/0411.mp4',
      },
      {
        'title': 'End-to-End Release',
        'type': 'APPSTORE • PLAYSTORE • QC',
        'desc': 'Rilis dari nol sampai tayang di store publik.',
        'icons': ['figma-svgrepo-com.svg', 'sentry-svgrepo-com.svg'],
        'color': const Color(0xFFEC4899),
        'logo': Icons.rocket_launch,
      },
      {
        'title': 'Cloud & Hosting',
        'type': 'VPS • FIREBASE • DOMAIN',
        'desc': 'Integrasi server & live hosting proyek Anda.',
        'icons': ['tailwind-svgrepo-com.svg'],
        'color': const Color(0xFF6366F1),
        'logo': Icons.cloud_done,
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 430,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _carouselController,
                onPageChanged: (index) {
                  setState(
                    () => _currentCarouselPage = index % carouselData.length,
                  );
                },
                // Removed itemCount for infinite loop
                itemBuilder: (context, index) {
                  final int dataIndex = index % carouselData.length;
                  final item = carouselData[dataIndex];
                  final isCurrent = _currentCarouselPage == dataIndex;
                  return AnimatedScale(
                    scale: isCurrent ? 1.0 : 0.9,
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.grey[900],
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: (item['color'] as Color).withOpacity(
                                    0.2,
                                  ),
                                  blurRadius: 40,
                                  spreadRadius: -10,
                                ),
                              ]
                            : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: item.containsKey('video')
                                  ? _VideoCard(
                                      assetPath: item['video'],
                                      isCurrent: isCurrent,
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            (item['color'] as Color)
                                                .withOpacity(0.3),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.center,
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.95),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.3, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Strategic Call to Action on Specific Cards with Descriptive Full Text
                                  if (dataIndex == 1) // 2nd Card: CV
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Experience Details",
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 10,
                                            letterSpacing: 2,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          "Explore my professional journey in detail — from my technical skills and hands-on experience to the projects and roles that have shaped my career.",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            height: 1.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        _buildModernCardButton(
                                          context: context,
                                          text: "View Full My CV",
                                          color: item['color'],
                                          onTap: () => context.go('/my_cv'),
                                        ),
                                      ],
                                    )
                                  else if (dataIndex ==
                                      2) // 3rd Card: Released Product 1
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Released on Store",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            letterSpacing: 2,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          "Durioo+: I built this from ground zero to a successful release on both Play Store and App Store, ensuring high performance.",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            height: 1.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        _buildModernCardButton(
                                          context: context,
                                          text: "View Full Details",
                                          color: item['color'],
                                          onTap: () => _openVideoFull(
                                            context,
                                            item['video'],
                                            item['title'],
                                          ),
                                        ),
                                      ],
                                    )
                                  else if (dataIndex ==
                                      3) // 4th Card: Released Product 2
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Production Success",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            letterSpacing: 2,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          "Showcasing application stability and production-ready quality for enterprise-level deployment.",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            height: 1.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        _buildModernCardButton(
                                          context: context,
                                          text: "View Full Details",
                                          color: item['color'],
                                          onTap: () => _openVideoFull(
                                            context,
                                            item['video'],
                                            item['title'],
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    // Default layout for other skill cards
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          item['title'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item['type'],
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 80),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            // Only show icons/logo for non-CTA cards to keep CV/Portfolio clean
                            if (dataIndex != 1 &&
                                dataIndex != 2 &&
                                dataIndex != 3) ...[
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Icon(
                                  item['logo'],
                                  color: Colors.white.withOpacity(0.15),
                                  size: 32,
                                ),
                              ),
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Row(
                                  children: (item['icons'] as List<String>)
                                      .map(
                                        (icon) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          child: SvgPicture.asset(
                                            'assets/svg/skill/$icon',
                                            width: 16,
                                            height: 16,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Navigation Arrows
              Positioned(
                left: 12,
                child: _buildNavArrow(
                  icon: Icons.chevron_left,
                  onTap: () {
                    _carouselController.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ),
              Positioned(
                right: 12,
                child: _buildNavArrow(
                  icon: Icons.chevron_right,
                  onTap: () {
                    _carouselController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Modern Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(carouselData.length, (index) {
            final isSelected = _currentCarouselPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isSelected ? 32 : 8,
              height: 6,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Colors.cyanAccent, Colors.blueAccent],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
                border: isSelected
                    ? Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 0.5,
                      )
                    : Border.all(color: Colors.transparent),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNavArrow({required IconData icon, required VoidCallback onTap}) {
    return _CarouselNavButton(icon: icon, onTap: onTap);
  }

  Widget _buildGlassButton(
    BuildContext context, {
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.white.withOpacity(0.08),
              child: InkWell(
                onTap: onTap,
                splashColor: Colors.white10,
                highlightColor: Colors.white10,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.black,
        gradient: LinearGradient(
          colors: [Colors.black, Color(0xFF0F172A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSectionHeader("Get in Touch", "Let's Work Together"),
          const SizedBox(height: 40),

          // Contact Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildContactItem(
                  Icons.alternate_email,
                  "Gmail",
                  "kiki.triansyah93@gmail.com",
                  Colors.redAccent,
                ),
                _buildContactItem(
                  Icons.link_outlined,
                  "LinkedIn",
                  "linkedin.com/in/kiki-triansyah/",
                  Colors.blueAccent,
                ),
                _buildContactItem(
                  Icons.chat_bubble_outline,
                  "WhatsApp",
                  "+62 877 2802 0907",
                  Colors.greenAccent,
                ),
                _buildContactItem(
                  Icons.terminal,
                  "GitHub",
                  "@kikimaxs",
                  Colors.white70,
                ),
                _buildContactItem(
                  Icons.code_off,
                  "GitLab",
                  "@kikitriansyah",
                  Colors.orangeAccent,
                ),
                _buildContactItem(
                  Icons.discord,
                  "Discord",
                  "@kikimaxs",
                  Colors.indigoAccent,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Back to Top Button
          _AnimatedBackToTop(),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
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
          Icon(
            Icons.chevron_right,
            color: Colors.white.withOpacity(0.1),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildModernCardButton({
    required BuildContext context,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_circle_right_rounded,
              color: Colors.black,
              size: 40,
            ),
          ],
        ),
      ),
    );
  }

  void _openVideoFull(BuildContext context, String assetPath, String title) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Video Detail',
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: _VideoDetailModal(
            assetPath: assetPath,
            title: title,
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _VideoDetailModal extends StatefulWidget {
  final String assetPath;
  final String title;

  const _VideoDetailModal({required this.assetPath, required this.title});

  @override
  State<_VideoDetailModal> createState() => _VideoDetailModalState();
}

class _VideoDetailModalState extends State<_VideoDetailModal> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
            _controller.play();
          });
          _startHideTimer();
        }
      });
    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (mounted) {
      if (_controller.value.position >= _controller.value.duration &&
          !_controller.value.isPlaying) {
        if (!_showControls) setState(() => _showControls = true);
      }
      setState(() {}); // Update for time and replay icon
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onInteraction([dynamic _]) {
    if (mounted) {
      if (!_showControls) setState(() => _showControls = true);
      _startHideTimer();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final modalWidth = size.width > 900 ? 800.0 : size.width * 0.95;
    final isFinished = _initialized && 
        _controller.value.position >= _controller.value.duration;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: modalWidth,
        constraints: BoxConstraints(maxHeight: size.height * 0.9),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Video Section
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      MouseRegion(
                        onHover: _onInteraction,
                        onEnter: _onInteraction,
                        child: GestureDetector(
                          onTap: _onInteraction,
                          behavior: HitTestBehavior.opaque,
                          child: Stack(
                            children: [
                              _initialized
                                  ? VideoPlayer(_controller)
                                  : Container(
                                      color: Colors.black26,
                                      child: const Center(
                                          child: CircularProgressIndicator(
                                              color: Colors.cyanAccent)),
                                    ),
                              // Controls Overlay
                              AnimatedOpacity(
                                opacity: _showControls ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                child: IgnorePointer(
                                  ignoring: !_showControls,
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            if (isFinished) {
                                              _controller.seekTo(Duration.zero);
                                              _controller.play();
                                            } else {
                                              setState(() {
                                                _controller.value.isPlaying
                                                    ? _controller.pause()
                                                    : _controller.play();
                                              });
                                            }
                                            _onInteraction();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: const BoxDecoration(
                                              color: Colors.black45,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isFinished
                                                  ? Icons.replay_rounded
                                                  : (_controller.value.isPlaying
                                                      ? Icons.pause_rounded
                                                      : Icons.play_arrow_rounded),
                                              color: Colors.white,
                                              size: 50,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                Colors.black87
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                          child: _buildProgressBar(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Close Button
                      Positioned(
                        top: 20,
                        right: 20,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "2024",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "HD",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Portfolio Project",
                            style: TextStyle(
                              color: Colors.cyanAccent.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "This is a highlight from my professional work history. "
                        "Developed using Flutter for high-performance cross-platform delivery, "
                        "this project was successfully released on both Play Store and App Store. "
                        "It features complex state management, custom animations, and seamless external API integrations.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const _DetailRow(label: "Genre:", value: "App Development, UI/UX, Flutter"),
                      const _DetailRow(label: "Role:", value: "Lead Mobile Developer"),
                      const _DetailRow(label: "Impact:", value: "10k+ Downloads, 4.8 Rating"),
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

  Widget _buildProgressBar() {
    return VideoProgressIndicator(
      _controller,
      allowScrubbing: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      colors: const VideoProgressColors(
        playedColor: Colors.cyanAccent,
        bufferedColor: Colors.white24,
        backgroundColor: Colors.white10,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselNavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CarouselNavButton({required this.icon, required this.onTap});

  @override
  State<_CarouselNavButton> createState() => _CarouselNavButtonState();
}

class _CarouselNavButtonState extends State<_CarouselNavButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.85 : (_isHovered ? 1.2 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.cyanAccent.withOpacity(0.2)
                  : Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isHovered
                    ? Colors.cyanAccent.withOpacity(0.5)
                    : Colors.white10,
                width: 1.5,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              widget.icon,
              color: _isHovered
                  ? Colors.cyanAccent
                  : Colors.white.withOpacity(0.8),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedScrollIndicator extends StatefulWidget {
  const _AnimatedScrollIndicator();

  @override
  State<_AnimatedScrollIndicator> createState() =>
      _AnimatedScrollIndicatorState();
}

class _AnimatedScrollIndicatorState extends State<_AnimatedScrollIndicator>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
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
                child: Opacity(
                  opacity: _isHovered ? 1.0 : 0.8,
                  child: Icon(
                    Icons.keyboard_double_arrow_down_rounded,
                    color: _isHovered ? Colors.cyanAccent : Colors.white,
                    size: 40,
                    shadows: _isHovered
                        ? [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.5),
                              blurRadius: 15,
                            ),
                          ]
                        : [],
                  ),
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
          homeState?._pageController.animateToPage(
            0,
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOutExpo,
          );
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.9 : (_isHovered ? 1.2 : 1.0),
          duration: const Duration(milliseconds: 200),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? Colors.white.withOpacity(0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: _isHovered
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white24,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 15,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  Icons.keyboard_double_arrow_up_rounded,
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

class _VideoCard extends StatefulWidget {
  final String assetPath;
  final bool isCurrent;

  const _VideoCard({required this.assetPath, required this.isCurrent});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
            _controller.setLooping(true);
            _controller.setVolume(0); // Muted for auto-play
            if (widget.isCurrent) {
              _controller.play();
            }
          });
        }
      });
  }

  @override
  void didUpdateWidget(_VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_initialized) {
      if (widget.isCurrent) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(
        color: Colors.black26,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white24,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return FadeInWidget(
      child: Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FadeInWidget extends StatefulWidget {
  final Widget child;
  const FadeInWidget({required this.child});

  @override
  _FadeInWidgetState createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}
