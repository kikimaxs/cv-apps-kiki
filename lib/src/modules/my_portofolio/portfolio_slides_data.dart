import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// The 12 pages of the portfolio PDF ("Portofolio Kiki Triansyah 2026"), as
// positioned elements in the PDF's own 1366 x 768 units. Pictures and their
// crops come from the design; the text blocks, their line breaks and their
// positions come from the PDF itself. Each page renders at any width by
// scaling those units, so backgrounds run to the screen edges.
//
// Text markers: **x** bold italic, ++x++ bold, __x__ underline.
// ---------------------------------------------------------------------------

const double kSlideW = 1366;
const double kSlideH = 768;

class SlideBg {
  const SlideBg(this.colors, this.angle);

  /// Gradient stops, first to last.
  final List<Color> colors;

  /// Gradient angle in degrees: 90 runs left to right, 0 top to bottom.
  final double angle;
}

sealed class SlideItem {
  const SlideItem();
}

class SlideText extends SlideItem {
  const SlideText(
    this.top,
    this.left,
    this.width,
    this.text, {
    required this.size,
    this.weight = FontWeight.w400,
    this.color = const Color(0xFF000000),
    this.align = TextAlign.left,
    this.lh = 1.46,
    this.spacing = 0,
  });

  final double top;
  final double left;
  final double width;

  /// Lines are separated by \n, exactly as the PDF breaks them.
  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  final TextAlign align;

  /// Line height as a multiple of [size] (the PDF's line pitch).
  final double lh;

  /// Extra letter spacing in design units, to match the PDF's line lengths.
  final double spacing;
}

class SlideImage extends SlideItem {
  const SlideImage(
    this.top,
    this.left,
    this.width,
    this.height,
    this.mediaId, {
    this.rot = 0,
    this.imgTop = 0,
    this.imgLeft = 0,
    this.imgWidth,
    this.imgHeight,
    this.opacity = 1,
  });

  final double top;
  final double left;
  final double width;
  final double height;

  /// Canva media id; the file is listed in portfolio_slide_assets.dart.
  final String mediaId;

  /// Rotation in degrees, around the element's centre.
  final double rot;

  /// Where the picture sits inside the element box (the design crops the rest).
  final double imgTop;
  final double imgLeft;
  final double? imgWidth;
  final double? imgHeight;

  final double opacity;
}

class SlidePage {
  const SlidePage(this.bg, this.items);

  final SlideBg bg;
  final List<SlideItem> items;
}

const _grey = Color(0xFFA6A6A6);
const _white = Color(0xFFFFFFFF);
const _teal = Color(0xFF5DE0E6);
const _blue = Color(0xFF004AAD);
const _orange = Color(0xFFFF7A3C);
const _peach = Color(0xFFFFCE81);
const _plum = Color(0xFF431043);
const _rose = Color(0xFFD34681);
const _paper = Color(0xFFFEFFFF);
const _mist = Color(0xFFC5C5C5);
const _body = Color(0xFF2E2E2E);

const kSlidePages = <SlidePage>[
  // 1. Cover
  SlidePage(SlideBg([_grey, _white], 90), [
    SlideImage(405.2, 770.7, 58.5, 58.5, 'MAFi5nUvD3Q', rot: -4.9),
    SlideImage(401.7, 580.3, 155.1, 176.4, 'MAEzbtdaL9U',
        rot: -5.3, imgTop: -1.1, imgLeft: -14.4, imgWidth: 198.2, imgHeight: 198.2),
    SlideImage(0, 0, 1366, 765.8, 'MAGkxeWv44o',
        imgLeft: -101.5, imgWidth: 1569.0, imgHeight: 879.3),
    SlideImage(454.6, 503.7, 367.2, 217.2, 'MAGkxij3D6k',
        imgTop: -18.4, imgLeft: -34.3, imgWidth: 432.2, imgHeight: 243.0),
    SlideText(477.4, 1013.9, 212.1, 'KIKI TRIANSYAH', size: 24, lh: 1.2),
    SlideText(225.4, 378.8, 611.0, 'MY PORTOFOLIO',
        size: 82, weight: FontWeight.w700, align: TextAlign.center, lh: 1.2,
        spacing: 2.5),
  ]),

  // 2. MOLA TV screens
  SlidePage(SlideBg([_teal, _blue], 90), [
    SlideImage(58.7, 76.2, 683.0, 157.7, 'MAGkuS30vgU'),
    SlideImage(276.3, 294.5, 254.7, 452.8, 'MAGkucVfCV0'),
    SlideImage(276.3, 25.1, 254.7, 452.8, 'MAGkuXFxHdU'),
    SlideImage(276.3, 563.9, 253.2, 450.1, 'MAGkufQz0PU'),
    SlideImage(276.3, 1095.2, 253.7, 451.0, 'MAGkufxBG9U'),
    SlideImage(9.5, 892.6, 456.3, 256.7, 'MAGkuY6kHqs'),
    SlideImage(276.3, 830.0, 253.2, 450.1, 'MAGkxuh2CnY'),
  ]),

  // 3. What is MOLA TV
  SlidePage(SlideBg([_teal, _blue], 90), [
    SlideText(72.0, 68.0, 430.0, 'What is the MOLA TV Apps ?',
        size: 34, weight: FontWeight.w700, lh: 1.22),
    SlideText(128.0, 68.5, 595.0,
        'MOLA is a Live streaming video entertainment\n'
        'application, MOLA itself is cross-platform based\n'
        'including Android and iOS using **React Native**\n'
        'with **Javascript** programming language, MOLA has\n'
        'main content that is more about Sports such as\n'
        'Football, UFC and popular movie content for\n'
        'adults and children, besides mobile MOLA\n'
        'already has its own device using MOLA TV box,\n'
        'and the MOLA has been uploaded to [[Playstore|https://play.google.com/store/apps/details?id=com.molatvbox.public&hl=id]]\n'
        'and Appstore.',
        size: 23.99, spacing: 1.2),
    SlideImage(133.3, 742.7, 501.5, 501.5, 'MAGkxucbHAg'),
    SlideText(520.0, 68.0, 470.0, 'My Achievement at MOLA TV ?',
        size: 34, weight: FontWeight.w700, lh: 1.22),
    SlideText(582.7, 68.5, 600.0,
        'In Indonesia, The app reached 700K downloads\n'
        '(iOS & Android since 2020) and 2.3 million viewers\n'
        'during the Euro 2022 England vs Spain match.',
        size: 23.99, spacing: 1.2),
  ]),

  // 4. MOLA TV challenge
  SlidePage(SlideBg([_teal, _blue], 90), [
    SlideText(149.3, 49.3, 524.0,
        'What is the most challenging job\n'
        'during work in MOLA ?',
        size: 34, weight: FontWeight.w700, lh: 1.22),
    SlideText(246.7, 51.5, 588.0,
        'I worked on a live quiz feature at MOLA, handling\n'
        'quiz delivery and answer submission using\n'
        'WebSocket with temporary storage before\n'
        'sending data to the API to prevent data loss. A\n'
        'major issue occurred when the server went down\n'
        'during a live session, causing users to be unable\n'
        'to participate. The solution was to implement a\n'
        'temporary maintenance mode while coordinating\n'
        'with Mobile, Backend, and Infra teams, and\n'
        'reschedule the affected quiz once the system was\n'
        'restored.',
        size: 23.99, spacing: 1.2),
    SlideImage(120.9, 683.0, 296.0, 526.2, 'MAGkwuSB9l0'),
    SlideImage(120.9, 1007.0, 296.0, 526.2, 'MAGkwgDV7WQ'),
  ]),

  // 5. Durioo+ screens
  SlidePage(SlideBg([_orange, _peach], 45), [
    SlideImage(213.9, 31.9, 267.0, 477.3, 'MAGkudJgBcs',
        imgLeft: -0.8, imgWidth: 268.5, imgHeight: 477.3),
    SlideImage(218.5, 316.8, 272.2, 472.7, 'MAGkuT4jH1I',
        imgLeft: -0.2, imgWidth: 272.5, imgHeight: 484.5),
    SlideImage(213.9, 605.1, 269.7, 479.5, 'MAGkub-DPzc'),
    SlideImage(433.6, 886.8, 437.8, 257.6, 'MAGkuavDWb0',
        imgTop: -0.4, imgLeft: -14.5, imgWidth: 458.6, imgHeight: 258.0),
    SlideImage(21.7, 31.9, 557.1, 171.9, 'MAGkufuQY6I',
        imgTop: -212.0, imgLeft: -44.1, imgWidth: 601.2, imgHeight: 601.2),
    SlideImage(16.8, 886.1, 229.6, 394.2, 'MAGkuY8MdE8',
        imgTop: -13.4, imgWidth: 229.6, imgHeight: 408.1),
    SlideImage(16.8, 1126.7, 197.9, 394.2, 'MAGkuZMkhn8',
        imgLeft: -6.0, imgWidth: 221.7, imgHeight: 394.2),
    SlideImage(33.7, 665.9, 148.0, 148.0, 'MAGkxgws8Ew'),
  ]),

  // 6. What is Durioo+
  SlidePage(SlideBg([_orange, _peach], 45), [
    SlideImage(143.5, 659.1, 668.0, 375.9, 'MAGkxgRA6bY'),
    SlideText(81.3, 50.7, 430.0, 'What is the Durioo+ Apps ?',
        size: 34, weight: FontWeight.w700, lh: 1.22),
    SlideText(137.3, 52.0, 590.0,
        'Durioo+ is a cross-platform video streaming app\n'
        '(Android & iOS) built with **React Native Expo** and\n'
        '**TypeScript**, featuring Muslim-friendly children’s\n'
        'content. It includes parental controls to manage\n'
        'kids’ viewing and is also available on Android TV\n'
        'and Samsung TV (published on [[Play Store|https://play.google.com/store/apps/details?id=ott.durioo1&hl=id]] and\n'
        '[[App Store|https://apps.apple.com/id/app/durioo-by-omar-hana-makers/id1605538612?l=id]]).',
        size: 23.99, spacing: 1.2),
    SlideText(422.6, 50.7, 470.0, 'My Achievement at Durioo+ ?',
        size: 34, weight: FontWeight.w700, lh: 1.22),
    SlideText(488.0, 52.0, 600.0,
        'Since March 2024, the app has reached 60K\n'
        'downloads (iOS & Android) in Malaysia, with over\n'
        '3 million total video views based on backend\n'
        'tracking. It is now expanding internationally, with\n'
        'higher numbers across multiple countries.',
        size: 23.99, spacing: 1.2),
  ]),

  // 7. Durioo+ challenge
  SlidePage(SlideBg([_orange, _peach], 45), [
    SlideImage(30.3, 917.2, 403.1, 226.7, 'MAGkwgentno'),
    SlideImage(270.6, 917.2, 403.1, 226.7, 'MAGkwioR9GU'),
    SlideImage(511.4, 917.2, 403.1, 226.7, 'MAGkwtJEqHg'),
    SlideText(237.3, 50.7, 780.0,
        'What is the most challenging job during work in\n'
        'Durioo+ ?',
        size: 34, weight: FontWeight.w700, lh: 1.18),
    SlideText(333.3, 52.0, 880.0,
        'I developed a video player using Expo AV for the Durioo App V1, featuring\n'
        'TV casting, offline download, subtitles, video quality selection, and\n'
        'next/previous playback. The main challenge was playback errors due to\n'
        'unsupported ASF video format (used for adaptive streaming). The\n'
        'solution was to fallback to the highest quality MP4 when ASF fails to\n'
        'load.',
        size: 23.99, spacing: 1.2),
  ]),

  // 8. HadIR screens
  SlidePage(SlideBg([_orange, _peach], 45), [
    SlideImage(384.0, 318.1, 171.3, 369.5, 'MAGz-CliXE4'),
    SlideImage(18.5, 83.1, 201.9, 345.1, 'MAGz-CmIfgc'),
    SlideImage(361.6, 83.1, 201.9, 383.7, 'MAGz-JzleAg'),
    SlideImage(18.5, 318.1, 171.3, 368.2, 'MAGz-IdgTsY'),
    SlideImage(18.5, 504.9, 191.1, 408.7, 'MAGz-A6IFRQ'),
    SlideImage(18.5, 711.0, 190.0, 408.7, 'MAGz-AibnvE'),
    SlideImage(19.2, 916.0, 190.5, 408.0, 'MAGz-MPGUoc'),
    SlideImage(18.5, 1121.4, 210.1, 408.7, 'MAGz-bTLFKQ'),
    SlideImage(439.1, 504.9, 146.2, 314.4, 'MAGz-Yp2arw'),
    SlideImage(441.3, 666.1, 143.7, 309.9, 'MAGz-Qd0gBY'),
    SlideImage(508.6, 842.9, 510.2, 175.3, 'MAHFfKpSOic'),
  ]),

  // 9. What is HadIR
  SlidePage(SlideBg([_orange, _peach], 45), [
    SlideImage(9.1, 866.6, 201.9, 345.1, 'MAGz-CmIfgc'),
    SlideImage(354.1, 866.6, 201.9, 383.7, 'MAGz-JzleAg'),
    SlideImage(9.1, 1119.1, 210.1, 408.7, 'MAGz-bTLFKQ'),
    SlideImage(511.6, 1128.8, 190.7, 190.7, 'MAHFiCH6vdQ'),
    SlideText(204.0, 50.7, 420.0, 'What is the HadIR Apps ?',
        size: 34, weight: FontWeight.w700, lh: 1.22),
    SlideText(260.0, 52.0, 780.0,
        'HadIR is an internal application designed to monitor employee\n'
        'productivity and daily activities. It allows employees to manage\n'
        'attendance (WFA/WFO), track activities like meetings or training,\n'
        'and ensures valid check-ins using map coordinates (with fake\n'
        'GPS detection). Managers and HRD can monitor performance,\n'
        'while features like meeting room booking, overtime tracking, and\n'
        'expense claims (meals and transport) are also supported. If\n'
        'employees forget to check in/out, they can submit a report for\n'
        'supervisor validation.',
        size: 23.99, spacing: 1.2),
  ]),

  // 10. Lifeline screens
  SlidePage(SlideBg([_plum, _rose], 45), [
    SlideImage(28.6, 288.2, 156.8, 339.5, 'MAHFcSQtOZA'),
    SlideImage(22.8, 943.6, 158.4, 345.4, 'MAHFcX2tLO8',
        imgLeft: -1.8, imgWidth: 162.0, imgHeight: 345.4),
    SlideImage(399.6, 429.3, 147.2, 340.7, 'MAHFcS2QjQI'),
    SlideImage(27.5, 1109.9, 156.6, 340.7, 'MAHFfAL4vnI'),
    SlideImage(406.4, 116.7, 141.8, 327.1, 'MAHFfIoN29c'),
    SlideImage(405.5, 268.6, 150.7, 328.8, 'MAHFfJwzp3I'),
    SlideImage(41.0, 619.3, 154.3, 327.1, 'MAHFcbDpQEE'),
    SlideImage(28.6, 453.0, 158.3, 339.5, 'MAHFcVRSgWc'),
    SlideImage(518.0, 576.5, 779.2, 106.1, 'MAHFfAlbF2U',
        imgTop: -18.5, imgWidth: 779.2, imgHeight: 143.1),
    SlideImage(17.9, 116.7, 163.5, 350.2, 'MAHFgY27r_s'),
    SlideImage(37.2, 781.5, 154.0, 330.9, 'MAHFgeuyVbA'),
  ]),

  // 11. What is LifelineConnect
  SlidePage(SlideBg([_plum, _rose], 45), [
    SlideImage(411.6, 1194.0, 159.4, 339.9, 'MAHFcX2tLO8'),
    SlideImage(58.1, 1195.5, 158.0, 341.2, 'MAHFgUKDcG0'),
    SlideImage(58.1, 1018.2, 158.6, 341.2, 'MAHFgXxCKuc'),
    SlideImage(411.6, 1018.2, 160.1, 339.9, 'MAHFgXLXxQo'),
    SlideImage(300.6, 802.7, 196.5, 428.5, 'MAHFgbLC9ho'),
    SlideImage(91.0, 832.1, 137.7, 137.7, 'MAHFiLWkfvU'),
    SlideText(104.7, 45.4, 560.0, 'What is the LifelineConnect Apps ?',
        size: 34, weight: FontWeight.w700, color: _white, lh: 1.22),
    SlideText(165.4, 46.5, 800.0,
        'LifeLine is a health and safety ecosystem application built using\n'
        'Flutter, with state management using Bloc, Provider, and Cubit. It\n'
        'connects devices such as smartwatches, digital dispensers,\n'
        'AirPods, and smart locks to a smartphone, collecting health data,\n'
        'tracking location, and sharing it with doctors or family members\n'
        '(Care Circle). The app also includes chat, calling, and reminder\n'
        'alarms.\n'
        'This cross-platform project (iOS & Android) was developed for a\n'
        'client in China (a state-owned enterprise), featuring its own\n'
        'branded IoT devices (similar to Xiaomi and Huawei). It aims to\n'
        'provide a complete ecosystem for senior users within a single\n'
        'Care Circle group. The project is still ongoing and has not yet\n'
        'been released on the App Store or Play Store.',
        size: 23.99, color: _white, spacing: 1.2),
  ]),

  // 12. About and contact
  SlidePage(SlideBg([_paper, _mist], 180), [
    SlideImage(441.4, 687.1, 57.8, 57.8, 'MAGkx0oBYgM', opacity: 0.81),
    SlideImage(32.6, 243.3, 156.0, 200.4, 'MAHFgTnAz5s'),
    SlideImage(357.7, 689.3, 53.5, 55.5, 'MAElfbID1iE'),
    SlideImage(278.5, 691.3, 50.8, 51.2, 'MAGzNvNA4A8'),
    SlideImage(192.0, 686.5, 58.4, 58.4, 'MAHFh3mkuFE'),
    SlideImage(527.2, 685.6, 60.2, 55.3, 'MADnA61Y6l4'),
    SlideImage(615.4, 687.1, 61.7, 61.7, 'MAGzZ0yqbBM'),
    SlideText(258.6, 189.5, 284.2, 'KIKI TRIANSYAH',
        size: 37.33, weight: FontWeight.w700, align: TextAlign.center, lh: 1.0,
        spacing: -0.75),
    SlideText(306.7, 136.0, 390.8, 'Software Engineer| Mobile Developer',
        size: 24, align: TextAlign.center, lh: 1.2, spacing: 1.9),
    SlideText(352.0, 30.7, 330.0, 'About Me',
        size: 55.5, weight: FontWeight.w700, color: _body, lh: 1.15),
    SlideText(427.9, 30.7, 690.0,
        'I am Kiki Triansyah, a Software Engineer | Mobile Developer with 6\n'
        'years of experience delivering scalable, high-impact applications. I\n'
        'specialize in **React Native**, **JavaScript**, and **TypeScript**, with additional\n'
        'experience in **Swift (SwiftUI)** and **Flutter**. also have backend experience\n'
        'using **Node.js**, **Express.js**, and databases such as **MySQL** and **SQLite**.\n'
        'Beyond development, I focus on building products that drive user\n'
        'engagement and business value, collaborating closely with teams to\n'
        'align technical solutions with product and marketing goals.',
        size: 18.5, color: _body, lh: 1.44, spacing: 1.0),
    SlideText(670.7, 30.7, 690.0,
        'I hold a Bachelor’s degree and am currently open to new opportunities,\n'
        'ready to contribute ++Immediately++ or ++ASAP++ going to ++Onsite++ or ++Remote++,\n'
        'in Indonesia or globally.',
        size: 18.5, color: _body, lh: 1.44, spacing: 1.0),
    SlideText(97.3, 703.0, 260.0, 'Contact :',
        size: 56, weight: FontWeight.w700, color: _body, lh: 1.15),
    SlideText(208.0, 751.1, 400.0,
        '[[kiki.triansyah93@gmail.com|mailto:kiki.triansyah93@gmail.com]]',
        size: 29.33, lh: 1.4, spacing: 1.9),
    SlideText(292.0, 751.1, 620.0,
        '[[https://www.linkedin.com/in/kiki-triansyah/|https://www.linkedin.com/in/kiki-triansyah/]]',
        size: 29.33, lh: 1.4, spacing: 1.9),
    SlideText(372.0, 749.6, 250.0,
        '[[+6287728020907|https://wa.me/6287728020907]]',
        size: 29.33, lh: 1.4, spacing: 1.9),
    SlideText(456.1, 757.9, 150.0,
        '[[@kikimaxs|https://github.com/kikimaxs]]',
        size: 29.33, lh: 1.4, spacing: 1.9),
    SlideText(543.9, 757.9, 210.0,
        '[[@kikitriansyah|https://gitlab.com/kikitriansyah]]',
        size: 29.33, lh: 1.4, spacing: 1.9),
    SlideText(632.0, 757.9, 150.0, '@kikimaxs',
        size: 29.33, lh: 1.4, spacing: 1.9),
  ]),
];
