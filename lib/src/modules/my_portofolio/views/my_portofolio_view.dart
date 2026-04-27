import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;

class MyPortofolioView extends StatelessWidget {
  const MyPortofolioView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Project Mobile Portofolio'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: PageView(
        scrollDirection: Axis.vertical,
        children: [
          // Halaman 1: Desain Original (SVG Background)
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final fit = BoxFit.cover;
              final align = Alignment.center;
              return DecoratedBox(
                decoration: const BoxDecoration(color: Colors.black),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRect(
                        child: SvgPicture.asset(
                          'assets/img/svg/1.svg',
                          fit: fit,
                          alignment: align,
                          placeholderBuilder: (context) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                    if (isMobile)
                      Positioned(
                        top: constraints.maxHeight * 0.30,
                        left: constraints.maxWidth * 0.08,
                        right: constraints.maxWidth * 0.08,
                        child: Container(
                          height: math.min(160, constraints.maxHeight * 0.18),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Project Mobile Portofolio',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  fontSize: (constraints.maxWidth * 0.06)
                                      .clamp(20, 26)
                                      .toDouble(),
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x22000000),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'By KIKI TRIANSYAH',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x22000000),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                  letterSpacing: 1.0,
                                  fontSize: (constraints.maxWidth * 0.045)
                                      .clamp(14, 18)
                                      .toDouble(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (kIsWeb && !isMobile)
                      Positioned(
                        top: kToolbarHeight + 24,
                        left: 0,
                        right: 0,
                        child: Text(
                          'Project Mobile Portofolio',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: constraints.maxWidth >= 1280
                                ? 64
                                : constraints.maxWidth >= 1024
                                ? 56
                                : constraints.maxWidth >= 800
                                ? 48
                                : 40,
                            shadows: const [
                              Shadow(
                                color: Color(0x1A000000),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          
          // Halaman 2: Background Gradien Biru
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  Color(0xFF021B35), // Biru sangat gelap ujung kiri bawah
                  Color(0xFF095AAB), // Biru tengah
                  Color(0xFF00E5FF), // Cyan terang ujung kanan atas
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Page 2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Area ini menyesuaikan dengan warna gradien yang Anda mau.\nTambahkan konten portofolio di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 18,
                        height: 1.5,
                      ),
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
