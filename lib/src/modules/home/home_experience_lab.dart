import 'package:flutter/material.dart';
import 'package:cv_apps/src/modules/home/home_copy.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'home_motion.dart';

const _ink = Color(0xFF080D18);
const _surface = Color(0xFF111B2C);
const _muted = Color(0xFFB8C8DA);

class HomeExperienceLab extends StatefulWidget {
  const HomeExperienceLab({super.key});

  @override
  State<HomeExperienceLab> createState() => _HomeExperienceLabState();
}

class _HomeExperienceLabState extends State<HomeExperienceLab> {
  int _selected = 0;

  List<_LabItem> _itemsFor(BuildContext context) => [
    _LabItem(
      label: homeText(context, 'Mobile app'),
      eyebrow: 'FLUTTER / IOS / ANDROID',
      title: homeText(context, 'Pengalaman mobile yang terasa natural.'),
      description: homeText(
        context,
        'Antarmuka responsif, navigasi jelas, dan interaksi yang membantu pengguna menyelesaikan tugasnya.',
      ),
      icon: FontAwesomeIcons.mobileScreenButton,
      accent: Color(0xFF67D4FF),
    ),
    _LabItem(
      label: homeText(context, 'Web platform'),
      eyebrow: 'WEB / UI / DATA',
      title: homeText(context, 'Web yang informatif dan mudah digunakan.'),
      description: homeText(
        context,
        'Tata letak yang menyesuaikan layar, komponen konsisten, dan informasi penting yang cepat ditemukan.',
      ),
      icon: FontAwesomeIcons.laptopCode,
      accent: Color(0xFFB49BFF),
    ),
    _LabItem(
      label: homeText(context, 'Delivery'),
      eyebrow: 'API / QUALITY / RELEASE',
      title: homeText(context, 'Dari ide sampai siap dipakai.'),
      description: homeText(
        context,
        'Alur kerja yang menghubungkan kebutuhan, implementasi, pengujian, dan rilis menjadi satu produk.',
      ),
      icon: FontAwesomeIcons.rocket,
      accent: Color(0xFF79E4BA),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 420);
    final item = _itemsFor(context)[_selected];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                homeText(context, 'INTERACTIVE CAPABILITIES'),
                style: TextStyle(
                  color: Color(0xFF67D4FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                homeText(context, 'Lihat cara saya berpikir dan membangun.'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.sizeOf(context).width < 600 ? 31 : 42,
                  fontWeight: FontWeight.w900,
                  height: 1.13,
                  letterSpacing: -1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                homeText(
                  context,
                  'Pilih area keahlian untuk melihat gambaran interaktif dari pendekatan yang saya gunakan.',
                ),
                style: TextStyle(color: _muted, fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < _itemsFor(context).length; i++)
                    _LabTab(
                      key: ValueKey('lab-tab-$i'),
                      item: _itemsFor(context)[i],
                      selected: _selected == i,
                      duration: duration,
                      onTap: () => setState(() => _selected = i),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              AnimatedContainer(
                width: double.infinity,
                duration: duration,
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: item.accent.withValues(alpha: 0.37),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: item.accent.withValues(alpha: 0.10),
                      blurRadius: 42,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: AnimatedSwitcher(
                  duration: duration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.035, 0.02),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _LabPanel(
                    key: ValueKey('lab-panel-$_selected'),
                    item: item,
                    index: _selected,
                  ),
                ),
              ),
              SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 850 ? 3 : 1;
                  final cardWidth =
                      (constraints.maxWidth - (columns - 1) * 14) / columns;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (final detail in [
                        (
                          '01',
                          homeText(context, 'Responsif'),
                          homeText(context, 'Rapi di ponsel hingga desktop.'),
                          FontAwesomeIcons.laptop,
                        ),
                        (
                          '02',
                          homeText(context, 'Interaktif'),
                          homeText(context, 'Gerak yang memberi umpan balik.'),
                          FontAwesomeIcons.handPointer,
                        ),
                        (
                          '03',
                          homeText(context, 'Siap rilis'),
                          homeText(
                            context,
                            'Dibangun dengan alur kerja yang jelas.',
                          ),
                          FontAwesomeIcons.circleCheck,
                        ),
                      ])
                        SizedBox(
                          width: cardWidth,
                          child: HomeHoverLift(
                            glow: item.accent,
                            child: Container(
                              padding: const EdgeInsets.all(19),
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(19),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Center(
                                      child: FaIcon(
                                        detail.$4,
                                        color: item.accent,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          detail.$2,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          detail.$3,
                                          style: const TextStyle(
                                            color: _muted,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    detail.$1,
                                    style: TextStyle(
                                      color: item.accent.withValues(alpha: 0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabItem {
  final String label;
  final String eyebrow;
  final String title;
  final String description;
  final FaIconData icon;
  final Color accent;
  const _LabItem({
    required this.label,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });
}

class _LabTab extends StatelessWidget {
  final _LabItem item;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;
  const _LabTab({
    super.key,
    required this.item,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: duration,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? item.accent : _surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? item.accent
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                child: Center(
                  child: FaIcon(
                    item.icon,
                    size: 15,
                    color: selected ? _ink : _muted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: TextStyle(
                  color: selected ? _ink : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LabPanel extends StatelessWidget {
  final _LabItem item;
  final int index;
  const _LabPanel({super.key, required this.item, required this.index});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 760;
      final copy = Padding(
        padding: EdgeInsets.all(compact ? 22 : 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FaIcon(item.icon, color: item.accent, size: 20),
            ),
            const SizedBox(height: 20),
            Text(
              item.eyebrow,
              style: TextStyle(
                color: item.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 11),
            Text(
              item.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 25 : 32,
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 11),
            Text(
              item.description,
              style: const TextStyle(color: _muted, fontSize: 14, height: 1.6),
            ),
          ],
        ),
      );
      final visual = Container(
        constraints: BoxConstraints(minHeight: compact ? 260 : 360),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [item.accent.withValues(alpha: 0.15), _ink],
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(22),
        child: switch (index) {
          0 => _MobilePreview(accent: item.accent),
          1 => _WebPreview(accent: item.accent),
          _ => _DeliveryPreview(accent: item.accent),
        },
      );
      return compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, visual],
            )
          : Row(
              children: [
                Expanded(flex: 5, child: copy),
                Expanded(flex: 6, child: visual),
              ],
            );
    },
  );
}

class _MobilePreview extends StatelessWidget {
  final Color accent;
  const _MobilePreview({required this.accent});

  @override
  Widget build(BuildContext context) => Container(
    width: 190,
    height: 430,
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: const Color(0xFF050910),
      borderRadius: BorderRadius.circular(31),
      border: Border.all(color: Colors.white.withValues(alpha: 0.38), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x88000000),
          blurRadius: 30,
          offset: Offset(0, 15),
        ),
      ],
    ),
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF13233B),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF050910),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            homeText(context, 'Good morning,'),
            style: TextStyle(color: _muted, fontSize: 10),
          ),
          Text(
            homeText(context, 'Your dashboard'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 120,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.5)],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homeText(context, 'ACTIVE PROJECT'),
                  style: TextStyle(
                    color: _ink,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  homeText(context, 'Build great apps'),
                  style: TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 0.68),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 850),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 4,
                    backgroundColor: _ink.withValues(alpha: 0.18),
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          for (final icon in [
            Icons.auto_awesome_outlined,
            Icons.layers_outlined,
            Icons.check_circle_outline,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(icon, color: accent, size: 14),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _WebPreview extends StatelessWidget {
  final Color accent;
  const _WebPreview({required this.accent});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 480),
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111B2C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 26,
            offset: Offset(0, 13),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: const BoxDecoration(
              color: Color(0xFF1B2940),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                for (final color in const [
                  Color(0xFFFF8275),
                  Color(0xFFFFC86D),
                  Color(0xFF69D6A2),
                ]) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                const Spacer(),
                const Text(
                  'dashboard.app',
                  style: TextStyle(color: _muted, fontSize: 10),
                ),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homeText(context, 'Overview'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
                          height: 45,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 4,
                                color: accent.withValues(alpha: 0.7),
                              ),
                              const Spacer(),
                              Container(
                                width: 42,
                                height: 7,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 17),
                SizedBox(
                  height: 95,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final height in [
                        0.35,
                        0.56,
                        0.42,
                        0.78,
                        0.6,
                        0.95,
                        0.72,
                        0.88,
                      ])
                        Expanded(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.04, end: height),
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 720),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) =>
                                FractionallySizedBox(
                                  heightFactor: value,
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: height),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _DeliveryPreview extends StatelessWidget {
  final Color accent;
  const _DeliveryPreview({required this.accent});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 430),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 4; i++) ...[
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : Duration(milliseconds: 380 + i * 100),
            curve: Curves.easeOutCubic,
            builder: (context, progress, child) => Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - progress)),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF17263A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.30)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      [
                        homeText(context, 'Discovery'),
                        homeText(context, 'Development'),
                        homeText(context, 'Quality check'),
                        homeText(context, 'Release'),
                      ][i],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    i == 3 ? Icons.check_circle_outline : Icons.arrow_forward,
                    color: accent,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
          if (i < 3)
            Container(
              width: 2,
              height: 12,
              color: accent.withValues(alpha: 0.5),
            ),
        ],
      ],
    ),
  );
}
