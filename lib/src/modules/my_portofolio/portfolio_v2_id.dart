import 'portfolio_slides_data.dart';

// Indonesian copy for the portfolio v2 page (the ID mode of the header switch).
// The English copy is the default and comes from portfolio_slides_data.dart.
//
// Slide text is keyed by (page index, text index among that page's text
// blocks). Markup is kept as in the English: **bold**, ++bold++, and
// [[label|url]] links. Technology names stay the same in both languages, so
// the tech strip and the bold terms are identical.

/// Slide text in Indonesian, keyed by (page, text index).
const Map<(int, int), String> kIdLines = {
  (0, 1): "PORTOFOLIO",

  (2, 0): "Tentang Aplikasi MOLA TV",
  (
    2,
    1,
  ): "MOLA adalah aplikasi streaming video langsung lintas platform untuk Android "
      "dan iOS, dibangun dengan **React Native** dan bahasa pemrograman **Javascript**. "
      "Kontennya didominasi olahraga seperti sepak bola dan UFC, serta film populer "
      "untuk dewasa dan anak-anak. Selain di ponsel, MOLA juga hadir di perangkat "
      "khusus, yaitu MOLA TV box, dan aplikasinya sudah dirilis di "
      "[[Playstore|https://play.google.com/store/apps/details?id=com.molatvbox.public&hl=id]] "
      "serta Appstore.",
  (2, 2): "Pencapaian di MOLA TV",
  (
    2,
    3,
  ): "Di Indonesia, aplikasi ini telah diunduh 700 ribu kali (iOS & Android sejak "
      "2020) dan ditonton 2,3 juta pengguna saat pertandingan Euro 2022 antara "
      "Inggris dan Spanyol.",

  (3, 0): "Tantangan terbesar selama bekerja di MOLA",
  (
    3,
    1,
  ): "Saya mengembangkan fitur kuis langsung di MOLA. Fitur ini mengelola pengiriman "
      "soal dan jawaban melalui WebSocket, dengan penyimpanan sementara sebelum data "
      "dikirim ke API agar tidak hilang. Masalah utama muncul saat server mati di tengah "
      "sesi, sehingga pengguna tidak dapat mengikuti kuis. Solusinya adalah mode "
      "pemeliharaan sementara sambil berkoordinasi dengan tim Mobile, Backend, dan Infra, "
      "lalu menjadwalkan ulang kuis yang terdampak setelah sistem kembali normal.",

  (5, 0): "Tentang Aplikasi Durioo+",
  (
    5,
    1,
  ): "Durioo+ adalah aplikasi streaming video lintas platform (Android & iOS) yang "
      "dibangun dengan **React Native Expo** dan **TypeScript**. Aplikasi ini menghadirkan "
      "konten anak-anak yang ramah nilai Islami, dilengkapi kontrol orang tua untuk "
      "mengatur tontonan. Aplikasi juga tersedia di Android TV dan Samsung TV, dan dapat "
      "diunduh di [[Play Store|https://play.google.com/store/apps/details?id=ott.durioo1&hl=id]] "
      "serta [[App Store|https://apps.apple.com/id/app/durioo-by-omar-hana-makers/id1605538612?l=id]].",
  (5, 2): "Pencapaian di Durioo+",
  (
    5,
    3,
  ): "Sejak Maret 2024, aplikasi ini telah diunduh 60 ribu kali (iOS & Android) di "
      "Malaysia, dengan lebih dari 3 juta penayangan video berdasarkan data backend. "
      "Saat ini aplikasi terus berkembang ke pasar internasional, dengan angka yang "
      "lebih tinggi di sejumlah negara.",

  (6, 0): "Tantangan terbesar selama bekerja di Durioo+",
  (
    6,
    1,
  ): "Saya mengembangkan video player menggunakan Expo AV untuk Durioo App V1. Fiturnya "
      "meliputi casting ke TV, unduh offline, subtitle, pemilihan kualitas video, serta "
      "pemutaran berikutnya dan sebelumnya. Tantangan utamanya adalah error pemutaran "
      "karena format ASF, yang dipakai untuk streaming adaptif, tidak didukung. Solusinya, "
      "aplikasi beralih ke MP4 dengan kualitas tertinggi ketika ASF gagal dimuat.",

  (8, 0): "Tentang Aplikasi HadIR",
  (
    8,
    1,
  ): "HadIR adalah aplikasi internal untuk memantau produktivitas dan aktivitas harian "
      "karyawan. Karyawan dapat mengelola kehadiran (WFA/WFO), mencatat aktivitas seperti "
      "rapat atau pelatihan, serta melakukan check-in yang tervalidasi dengan koordinat "
      "peta, termasuk deteksi GPS palsu. Manajer dan HRD dapat memantau kinerja, sementara "
      "fitur pemesanan ruang rapat, lembur, dan klaim biaya (makan dan transportasi) juga "
      "tersedia. Jika karyawan lupa check-in atau check-out, mereka dapat mengajukan laporan "
      "untuk divalidasi atasan.",

  (10, 0): "Tentang Aplikasi LifelineConnect",
  (
    10,
    1,
  ): "LifeLine adalah aplikasi ekosistem kesehatan dan keselamatan yang dibangun dengan "
      "Flutter, dengan manajemen state menggunakan Bloc, Provider, dan Cubit. Aplikasi ini "
      "menghubungkan perangkat seperti smartwatch, dispenser obat digital, AirPods, dan "
      "kunci pintar ke ponsel. Data kesehatan dikumpulkan, lokasi dilacak, dan informasinya "
      "dibagikan kepada dokter atau keluarga dalam Care Circle. Aplikasi ini juga dilengkapi "
      "chat, panggilan, dan alarm pengingat.\n"
      "Proyek lintas platform (iOS & Android) ini dikembangkan untuk klien di Tiongkok, "
      "sebuah perusahaan milik negara, dengan perangkat IoT bermerek sendiri yang serupa "
      "dengan Xiaomi dan Huawei. Tujuannya menghadirkan ekosistem lengkap bagi pengguna "
      "lanjut usia dalam satu grup Care Circle. Proyek ini masih berjalan dan belum dirilis "
      "di App Store maupun Play Store.",

  (11, 2): "Tentang Saya",
  (
    11,
    3,
  ): "Saya Kiki Triansyah, Software Developer Apps Mobile dengan pengalaman 6 tahun dalam "
      "membangun aplikasi yang skalabel dan berdampak. Keahlian utama saya ada di "
      "**React Native**, **JavaScript**, dan **TypeScript**, dengan pengalaman tambahan di "
      "**Swift (SwiftUI)** dan **Flutter**. Saya juga berpengalaman di sisi backend dengan "
      "**Node.js**, **Express.js**, serta database seperti **MySQL** dan **SQLite**.\n"
      "Di luar pengembangan, saya fokus membangun produk yang meningkatkan keterlibatan "
      "pengguna dan nilai bisnis, serta bekerja sama erat dengan tim agar solusi teknis "
      "selaras dengan tujuan produk dan pemasaran.",
  (
    11,
    4,
  ): "Saya memegang gelar sarjana dan saat ini terbuka untuk peluang baru. Saya siap "
      "berkontribusi ++secepatnya++ atau ++ASAP++, baik dengan posisi ++On-site++ maupun "
      "++Remote++, di Indonesia maupun secara global.",
  (11, 5): "Kontak",
};

/// Interface labels in Indonesian, keyed by their English text.
const Map<String, String> kIdUi = {
  "Cover": "Awal",
  "Portfolio": "Portofolio",
  "Contact": "Kontak",
  "Back": "Kembali",
  "Download PDF": "Unduh PDF",
  "View projects": "Lihat proyek",
  "Overview": "Ringkasan",
  "Challenge": "Tantangan",
  "Project": "Proyek",
  "The PDF is ready to download.": "PDF siap diunduh.",
  "Couldn't create the PDF. Please try again.":
      "Gagal membuat PDF. Silakan coba lagi.",
};

/// A label in the chosen language. [en] is the English text, the key above.
String uiLabel(String en, {required bool id}) => id ? (kIdUi[en] ?? en) : en;

List<SlidePage>? _idSlidePages;

/// The 12 slide pages in the chosen language. The English pages are the
/// PDF's own; the Indonesian ones use [kIdLines] for every text block.
List<SlidePage> slidePagesFor({required bool id}) {
  if (!id) return kSlidePages;
  return _idSlidePages ??= [
    for (var page = 0; page < kSlidePages.length; page++) _idPage(page),
  ];
}

SlidePage _idPage(int page) {
  final source = kSlidePages[page];
  var text = 0;
  final items = <SlideItem>[];
  for (final item in source.items) {
    if (item is SlideText) {
      final id = kIdLines[(page, text)];
      text++;
      items.add(
        id == null
            ? item
            : SlideText(
                item.top,
                item.left,
                item.width,
                id,
                size: item.size,
                weight: item.weight,
                color: item.color,
                align: item.align,
                lh: item.lh,
                spacing: item.spacing,
              ),
      );
    } else {
      items.add(item);
    }
  }
  return SlidePage(source.bg, items);
}
