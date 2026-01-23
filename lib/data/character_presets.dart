import '../models/game_item.dart';

class CharacterPreset {
  final String name;
  final String description;
  final String imagePath;
  final String title;
  final List<String> thoughts;
  final Map<ItemType, String> activityTexts; 
  final Map<ItemType, Map<String, double>> multipliers;

  CharacterPreset({
    required this.name,
    required this.description,
    required this.imagePath,
    required this.title,
    required this.activityTexts,
    required this.multipliers,
    this.thoughts = const [],
  });
}

final List<CharacterPreset> allPresets = [
  // --- ANA KARAKTERLER ---
  CharacterPreset(
    name: "Eren",
    title: "Barista",
    description: "Mutlu olduğuma dair kendimi kandırmıyorum sadece şımarık değilim.",
    imagePath: 'assets/eren.png',
    thoughts: [
      "Yemek söylicem istiyonuz mu?",
      "Dükkan çok boş bugün",
      "Kahve yapayım mı?",
      "Hoşgeldiniz",
      "Akşam olsa da eve gitsek mi?"
    ],
    activityTexts: {
      ItemType.laptop: "Openfront oynuyor",
      ItemType.book: "Nota defterine bir şeyler karalıyor... 🎼",
    },
    multipliers: {
      ItemType.laptop: {'happiness': 0.1, 'xp': 20},
      ItemType.book: {'success': 0.05, 'xp': 40},
    },
  ),
  CharacterPreset(
    name: "Çınar",
    title: "Klasik Çınar",
    description: "Overreact vermiyorum, aslında herşeyi de o kadar umursadığım yok.",
    imagePath: 'assets/cinar.png',
    thoughts: [
      "Sessiz kalmak senin tercihin. Tabi politik değilse.",
      "Akşam napıyorsun",
      "Bize gelsene müzik yapalım",
      "I'M AA CREEEP",
      "Göstermediğim şeyler de var"
    ],
    activityTexts: {
      ItemType.laptop: "Karanlık temada kod yazıyor... 💻",
      ItemType.book: "Suç ve ceza okuyor",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.25, 'happiness': -0.05, 'xp': 80},
      ItemType.book: {'happiness': 0.1, 'xp': 30},
    },
  ),
  CharacterPreset(
    name: "Dilay",
    title: "Ressam",
    description: "Gülüyorum ama  sanırım yalnız hissediyorum.",
    imagePath: 'assets/dilay.png',
    thoughts: [
      "Ben grafiker değilim!",
      "Kaçıngan bağlanıyorum ve kardeşim yok.",
      "Gülümsemek, bazen en zor sanat eseridir.",
      "Yalnızlık bazen en iyi ilham kaynağıdır.",
      "Dijital fırçalar gerçek olanların yerini tutar mı?"
    ],
    activityTexts: {
      ItemType.laptop: "Dijital çizim tabletiyle uğraşıyor... 🎨",
      ItemType.book: "Camus'a sövüyor",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.15, 'xp': 50},
      ItemType.book: {'happiness': 0.2, 'love': 0.05, 'xp': 40},
    },
  ),

  // --- 15 YENİ KARAKTER ---
  CharacterPreset(
    name: "Selin",
    title: "Geleceğin Cerrahı",
    description: "Sürekli sınavlara hazırlanan, kafein bağımlısı bir tıp öğrencisi.",
    imagePath: 'assets/placeholder.png',
    thoughts: [
      "Anatomi atlası neden bu kadar ağır?",
      "Günde 5. kahvemi mi içiyorum? Sayamadım.",
      "Uyku bir lüks mü, yoksa biyolojik bir ihtiyaç mı?",
      "Şu dükkandaki herkes ne kadar sağlıklı görünüyor...",
      "Sınav yaklaştıkça stres seviyem tavan yapıyor."
    ],
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
    title: "Startup Kurucusu",
    description: "Her an yeni bir 'startup' fikriyle gelen heyecanlı bir girişimci.",
    imagePath: 'assets/placeholder.png',
    thoughts: [
      "Bu kafe konseptini nasıl ölçekleyebiliriz?",
      "Yatırımcı sunumundaki 12. slayt biraz zayıf mı kaldı?",
      "Bir sonraki 'unicorn' neden buradan çıkmasın?",
      "Networking için harika bir gün.",
      "Risk almayan, kahve bile içememeli."
    ],
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
    title: "Gizli Yazar",
    description: "İnsanları gözlemleyip romanı için notlar alan sessiz bir yazar.",
    imagePath: 'assets/placeholder.png',
    thoughts: [
      "Şu masadaki adam kesinlikle bir roman karakteri.",
      "Sessizlik, en gürültülü kelimelerden daha anlamlıdır.",
      "Kendi dünyamda yaşamak dışarıdan daha güvenli.",
      "Kelimeler bazen bir kalkan gibi koruyor beni.",
      "Gözlemlemek, yaşamanın en saf halidir."
    ],
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
    title: "Hardcore Gamer",
    description: "Gürültücü ama sevimli, sürekli Twitch yayınlarını takip eden bir genç.",
    imagePath: 'assets/placeholder.png',
    thoughts: [
      "Ping değerim yine yükseldi, Wi-Fi mı sorunlu?",
      "Twitch sohbetindeki o dramayı kaçırmamalıyım.",
      "Yeni sezon metası kahvelerden daha karışık.",
      "Gece 3'teki o raid çok heyecanlıydı.",
      "Level atlamak gerçek hayattan daha tatmin edici."
    ],
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
    title: "Psikolog",
    description: "Herkesin derdini dinleyen, dükkanın psikolojik danışmanı gibi.",
    imagePath: 'assets/placeholder.png',
    thoughts: [
      "İnsanlar neden sürekli bir şeylerden kaçıyor?",
      "Her sessizliğin altında yatan bir travma vardır.",
      "Beni dinleyen biri olsaydı anlatır mıydım?",
      "Bilinçaltı, bu kahve köpüğü kadar karmaşık.",
      "Empati kurmak bazen çok yorucu olabiliyor."
    ],
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
    title: "Freelancer",
    description: "Minimalist yaşayan, sadece siyah giyen bir grafik tasarımcı.",
    imagePath: 'assets/placeholder.png',
    thoughts: [
      "Siyah giymek kararsızlığı yok ediyor.",
      "Şu logonun kerning ayarı beni çıldırtacak.",
      "Freelance hayat: Özgürlük mü, sonsuz mesai mi?",
      "Minimalizm, karmaşadan kurtulmanın tek yolu.",
      "Yeni bir revizyon gelirse dükkandan kaçacağım."
    ],
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
    title: "Wellness Koçu",
    description: "Sağlıklı yaşam takıntılı, her kahveye yulaf sütü isteyen biri.",
    imagePath: 'assets/placeholder.png',
    thoughts: [
      "Yulaf sütü yoksa günüme başlayamam.",
      "Derin nefes al, Melis. Sadece derin nefes...",
      "Vücudum bir tapınak ve ben ona iyi bakmalıyım.",
      "Yoga matımı evde mi unuttum acaba?",
      "Pozitif enerji her kapıyı açar."
    ],
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
    title: "Tarihçi",
    description: "Hangi devirde yaşadığını şaşırmış gibi görünen bir tarih öğrencisi.",
    imagePath: 'assets/placeholder.png',
    thoughts: [
      "200 yıl önce bu dükkanın yerinde ne vardı?",
      "Tarih tekerrürden ibaret, bu kahve de dünkü gibi.",
      "Eski haritalardaki gizemli yerleri bulmalıyım.",
      "Makale yazmak, tarihi yeniden yaşamak gibi.",
      "Modern dünya bazen çok hızlı geliyor."
    ],
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
    title: "Gezgin",
    description: "Sırt çantasıyla dünyayı gezen, sadece şarj için kafeye uğrayan biri.",
    imagePath: 'assets/placeholder.png',
    thoughts: [
      "Priz kenarı bir masa bulduğum için çok şanslıyım.",
      "Bir sonraki uçak biletimi ne zaman almalıyım?",
      "Fotoğraflar anıları saklamanın tek yolu.",
      "Sırt çantam benim evim, dükkan ise oturma odam.",
      "Dünyayı gezmek, ruhu besleyen en büyük eylem."
    ],
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
    title: "Stilist",
    description: "Sürekli defterine kıyafet taslakları çizen havalı bir moda tasarımcısı.",
    imagePath: 'assets/placeholder.png',
    thoughts: [
      "Şu masadaki kadının kombini tam bir stil hatası.",
      "Vogue'un bu sayısı tam bir ilham bombası.",
      "Kendi koleksiyonumu çıkarmak için gün sayıyorum.",
      "Moda geçicidir, stil ise karakterin aynasıdır.",
      "Kumaşların dokusu bana her zaman huzur verir."
    ],
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
    title: "Mühendis",
    description: "Karmaşık formülleri peçetelere yazan bir mühendislik dâhisi.",
    imagePath: 'assets/placeholder.png',
    thoughts: [
      "Bu dükkanın havalandırma sistemi verimsiz.",
      "Denklemler asla yalan söylemez, insanlar söyler.",
      "3D baskı bittikten sonra montaja başlamalıyım.",
      "Kuantum fiziği okurken vaktin nasıl geçtiğini anlamıyorum.",
      "Verimlilik, hayatın en önemli parametresidir."
    ],
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
    title: "Söz Yazarı",
    description: "Kulağında hep kulaklık olan, kendi dünyasında yaşayan bir müzisyen.",
    imagePath: 'assets/placeholder.png',
    thoughts: [
      "Şu ritim kesinlikle yeni parçamın temeli olacak.",
      "Şiirlerdeki o melodi kahvenin tadında saklı.",
      "Söz yazmak, ruhunu kağıda dökmektir.",
      "Kulaklıklarım takılıyken dünya çok daha güzel.",
      "Nota bilmek yetmez, hissetmek lazım."
    ],
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
    title: "Antikacı",
    description: "Popüler kültürden nefret eden, sadece plak dinleyen bir entelektüel.",
    imagePath: 'assets/placeholder.png',
    thoughts: [
      "Plakların o cızırtısı dijitalden daha iyi.",
      "Popüler olan her şey bir gün unutulmaya mahkumdur.",
      "Ansiklopediler, Google'dan daha güvenilir.",
      "Eski eşyaların bir ruhu olduğuna inanıyorum.",
      "Entelektüel olmak sürüden ayrılmayı gerektirir."
    ],
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
    title: "Modern Sufi",
    description: "Kafeye sadece huzur bulmaya gelen, bitki çayı aşığı biri.",
    imagePath: 'assets/placeholder.png',
    thoughts: [
      "Huzur dışarıda değil, içimizdeki o sessizlikte.",
      "Bitki çayının kokusu ruhumu dinginleştiriyor.",
      "Mevlana'nın sözleri her zaman yolumu aydınlatır.",
      "Şu dükkanın karmaşasında bile bir sükunet var.",
      "Meditasyon, zihni temizlemenin en iyi yolu."
    ],
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
    title: "Backend Geliştirici",
    description: "Kod yazarken dünyayı unutan, dükkanın en sessiz müşterisi.",
    imagePath: 'assets/placeholder.png',
    thoughts: [
      "Database query'leri optimize etmeden uyuyamam.",
      "Algoritmalar dünyayı yönetiyor, biz sadece yazıyoruz.",
      "Sessizlik, en verimli çalışma arkadaşım.",
      "Stack Overflow olmasaydı ne yapardık?",
      "Backend, görünmeyen ama en önemli temeldir."
    ],
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