import 'package:cv_apps/src/modules/my_portofolio/portfolio_slide_assets.dart';
import 'package:cv_apps/src/modules/my_portofolio/portfolio_slides_data.dart';

/// What the home page shows first: its backdrop, its photo, its posters and
/// the tech logos that orbit the hero.
const kHomePreloadAssets = <String>[
  'assets/img/home_backdrop.jpg',
  'assets/img/photo_profile.jpg',
  'assets/img/durioo_poster.jpg',
  'assets/img/showcase_poster.jpg',
  'assets/svg/skill/flutter-svgrepo-com.svg',
  'assets/svg/skill/react-svgrepo-com.svg',
  'assets/svg/skill/kotlin-1-logo-svgrepo-com.svg',
  'assets/svg/skill/android-svgrepo-com.svg',
  'assets/svg/skill/swift-svgrepo-com.svg',
  'assets/svg/skill/js-svgrepo-com.svg',
  'assets/svg/skill/tailwind-svgrepo-com.svg',
  'assets/svg/skill/figma-svgrepo-com.svg',
  'assets/svg/skill/next-js-svgrepo-com.svg',
];

/// What the CV shows first: the profile photo and the contact icons.
const kCvPreloadAssets = <String>[
  'assets/img/photo_profile.jpg',
  'assets/svg/whatsapp.svg',
  'assets/svg/linkedin.svg',
];

/// The pictures of the first two portfolio pages (the cover and MOLA TV).
List<String> portfolioPreloadAssets() => [
  for (final page in kSlidePages.take(2))
    for (final item in page.items)
      if (item is SlideImage && kSlideAssets[item.mediaId] != null)
        kSlideAssets[item.mediaId]!,
];
