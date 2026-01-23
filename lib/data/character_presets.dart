import '../models/game_item.dart';

class CharacterPreset {
  final String name;
  final String description;
  final String imagePath;
  final String title;
  final Map<ItemType, String> activityTexts; 
  final Map<ItemType, Map<String, double>> multipliers;

  CharacterPreset({
    required this.name,
    required this.description,
    required this.imagePath,
    required this.title,
    required this.activityTexts,
    required this.multipliers,
  });
}

final List<CharacterPreset> allPresets = [
  // --- ANA KARAKTERLER ---
  CharacterPreset(
    name: "Eren",
    description: "Müziği ve kahveyi hayatının merkezi yapmış biri. Şımarık değil, sadece dürüst.",
    title: "Barista",
    imagePath: 'assets/eren.png',
    activityTexts: {
      ItemType.laptop: "Yeni playlistini düzenliyor... 🎧",
      ItemType.book: "Nota defterine bir şeyler karalıyor... 🎼",
    },
    multipliers: {
      ItemType.laptop: {'happiness': 0.1, 'xp': 20},
      ItemType.book: {'success': 0.05, 'xp': 40},
    },
  ),
  CharacterPreset(
    name: "Çınar",
    description: "Felsefe ve derin düşüncelerin insanı. Duygularını saklamayı sevmez.",
    title: "Klasik Çınar",
    imagePath: 'assets/cinar.png',
    activityTexts: {
      ItemType.laptop: "Karanlık temada kod yazıyor... 💻",
      ItemType.book: "Felsefe kitabı okuyup uzaklara dalıyor... 📖",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.25, 'happiness': -0.05, 'xp': 80},
      ItemType.book: {'happiness': 0.1, 'xp': 30},
    },
  ),
  CharacterPreset(
    name: "Dilay",
    description: "Gülümsemesinin ardında derin bir yalnızlık taşıyan bir sanatçı.",
    title: "Ressam",
    imagePath: 'assets/dilay.png',
    activityTexts: {
      ItemType.laptop: "Dijital çizim tabletiyle uğraşıyor... 🎨",
      ItemType.book: "Sanat tarihi kitabını inceliyor... 🖼️",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.15, 'xp': 50},
      ItemType.book: {'happiness': 0.2, 'love': 0.05, 'xp': 40},
    },
  ),

  // --- 15 YENİ KARAKTER ---
  CharacterPreset(
    name: "Selin",
    description: "Sürekli sınavlara hazırlanan, kafein bağımlısı bir tıp öğrencisi.",
    title: "Geleceğin Cerrahı",
    imagePath: 'assets/placeholder.png',
    activityTexts: {
      ItemType.laptop: "Anatomi slaytlarına bakıyor... 🏥",
      ItemType.book: "Kalın bir tıp kitabında kaybolmuş... 📚",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.2, 'xp': 60},
      ItemType.book: {'success': 0.3, 'happiness': -0.1, 'xp': 100},
    },
  ),
  CharacterPreset(
    name: "Mert",
    description: "Her an yeni bir 'startup' fikriyle gelen heyecanlı bir girişimci.",
    title: "Startup Kurucusu",
    imagePath: 'assets/placeholder.png',
    activityTexts: {
      ItemType.laptop: "Yatırımcı sunumu hazırlıyor... 📈",
      ItemType.book: "Biyografi okuyup ilham alıyor... 💡",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.4, 'happiness': 0.1, 'xp': 120},
      ItemType.book: {'xp': 30},
    },
  ),
  CharacterPreset(
    name: "İpek",
    description: "İnsanları gözlemleyip romanı için notlar alan sessiz bir yazar.",
    title: "Gizli Yazar",
    imagePath: 'assets/placeholder.png',
    activityTexts: {
      ItemType.laptop: "Yeni bölümün taslağını yazıyor... ✍️",
      ItemType.book: "Klasik bir roman okuyor... 📜",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.1, 'xp': 40},
      ItemType.book: {'happiness': 0.25, 'xp': 60},
    },
  ),
  CharacterPreset(
    name: "Kerem",
    description: "Gürültücü ama sevimli, sürekli Twitch yayınlarını takip eden bir genç.",
    title: "Hardcore Gamer",
    imagePath: 'assets/placeholder.png',
    activityTexts: {
      ItemType.laptop: "Strateji oyunu kurguluyor... 🎮",
      ItemType.book: "Oyun tasarımı dergisi karıştırıyor... 🕹️",
    },
    multipliers: {
      ItemType.laptop: {'happiness': 0.4, 'success': -0.2, 'xp': 20},
      ItemType.book: {'xp': 15},
    },
  ),
  CharacterPreset(
    name: "Bade",
    description: "Herkesin derdini dinleyen, dükkanın psikolojik danışmanı gibi.",
    title: "Psikolog",
    imagePath: 'assets/placeholder.png',
    activityTexts: {
      ItemType.laptop: "Danışan notlarını düzenliyor... 🧠",
      ItemType.book: "Freud okuyup kafa sallıyor... 🧐",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.15, 'xp': 50},
      ItemType.book: {'happiness': 0.1, 'love': 0.1, 'xp': 40},
    },
  ),
  CharacterPreset(
    name: "Can",
    description: "Minimalist yaşayan, sadece siyah giyen bir grafik tasarımcı.",
    title: "Freelancer",
    imagePath: 'assets/placeholder.png',
    activityTexts: {
      ItemType.laptop: "Logo revizyonu yapıyor... (yine) 📐",
      ItemType.book: "Tipografi kataloğu inceliyor... 🖊️",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.3, 'xp': 90},
      ItemType.book: {'happiness': 0.05, 'xp': 30},
    },
  ),
  CharacterPreset(
    name: "Melis",
    description: "Sağlıklı yaşam takıntılı, her kahveye yulaf sütü isteyen biri.",
    title: "Wellness Koçu",
    imagePath: 'assets/placeholder.png',
    activityTexts: {
      ItemType.laptop: "Detoks programı hazırlıyor... 🍏",
      ItemType.book: "Yoga felsefesi okuyor... 🧘",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.2, 'xp': 50},
      ItemType.book: {'happiness': 0.3, 'xp': 70},
    },
  ),
  CharacterPreset(
    name: "Ozan",
    description: "Hangi devirde yaşadığını şaşırmış gibi görünen bir tarih öğrencisi.",
    title: "Tarihçi",
    imagePath: 'assets/placeholder.png',
    activityTexts: {
      ItemType.laptop: "Makale taraması yapıyor... 🏛️",
      ItemType.book: "Eski bir haritayı inceliyor... 🗺️",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.1, 'xp': 40},
      ItemType.book: {'success': 0.2, 'happiness': 0.15, 'xp': 80},
    },
  ),
  CharacterPreset(
    name: "Deniz",
    description: "Sırt çantasıyla dünyayı gezen, sadece şarj için kafeye uğrayan biri.",
    title: "Gezgin",
    imagePath: 'assets/placeholder.png',
    activityTexts: {
      ItemType.laptop: "Blogu için fotoğraf düzenliyor... 📸",
      ItemType.book: "Güney Amerika rehberine bakıyor... ✈️",
    },
    multipliers: {
      ItemType.laptop: {'happiness': 0.2, 'xp': 40},
      ItemType.book: {'happiness': 0.2, 'xp': 40},
    },
  ),
  CharacterPreset(
    name: "Ece",
    description: "Sürekli defterine kıyafet taslakları çizen havalı bir moda tasarımcısı.",
    title: "Stilist",
    imagePath: 'assets/placeholder.png',
    activityTexts: {
      ItemType.laptop: "Defile videoları izliyor... 👠",
      ItemType.book: "Vogue dergisinin eski sayılarına bakıyor... 👗",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.15, 'xp': 45},
      ItemType.book: {'happiness': 0.2, 'xp': 55},
    },
  ),
  CharacterPreset(
    name: "Burak",
    description: "Karmaşık formülleri peçetelere yazan bir mühendislik dâhisi.",
    title: "Mühendis",
    imagePath: 'assets/placeholder.png',
    activityTexts: {
      ItemType.laptop: "3D modelleme yapıyor... ⚙️",
      ItemType.book: "Kuantum fiziği üzerine okuyor... 🌌",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.35, 'xp': 100},
      ItemType.book: {'success': 0.1, 'xp': 50},
    },
  ),
  CharacterPreset(
    name: "Nil",
    description: "Kulağında hep kulaklık olan, kendi dünyasında yaşayan bir müzisyen.",
    title: "Söz Yazarı",
    imagePath: 'assets/placeholder.png',
    activityTexts: {
      ItemType.laptop: "Beat hazırlıyor... 🎹",
      ItemType.book: "Şiir kitaplarından ilham alıyor... 🖋️",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.2, 'xp': 60},
      ItemType.book: {'happiness': 0.3, 'love': 0.1, 'xp': 50},
    },
  ),
  CharacterPreset(
    name: "Arda",
    description: "Popüler kültürden nefret eden, sadece plak dinleyen bir entelektüel.",
    title: "Antikacı",
    imagePath: 'assets/placeholder.png',
    activityTexts: {
      ItemType.laptop: "Müzayede sitelerini geziyor... 🏺",
      ItemType.book: "Ciltli, eski bir ansiklopedi okuyor... 📖",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.05, 'xp': 20},
      ItemType.book: {'happiness': 0.4, 'xp': 90},
    },
  ),
  CharacterPreset(
    name: "Yasemin",
    description: "Kafeye sadece huzur bulmaya gelen, bitki çayı aşığı biri.",
    title: "Modern Sufi",
    imagePath: 'assets/placeholder.png',
    activityTexts: {
      ItemType.laptop: "Meditasyon uygulaması geliştiriyor... 🧘‍♀️",
      ItemType.book: "Mevlana'nın eserlerini okuyor... ✨",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.1, 'xp': 30},
      ItemType.book: {'happiness': 0.5, 'xp': 100},
    },
  ),
  CharacterPreset(
    name: "Emre",
    description: "Kod yazarken dünyayı unutan, dükkanın en sessiz müşterisi.",
    title: "Backend Geliştirici",
    imagePath: 'assets/placeholder.png',
    activityTexts: {
      ItemType.laptop: "Database optimizasyonu yapıyor... 🗄️",
      ItemType.book: "Algoritma karmaşıklığı çalışıyor... 🧮",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.45, 'happiness': -0.1, 'xp': 150},
      ItemType.book: {'xp': 40},
    },
  ),
];