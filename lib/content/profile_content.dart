// GENERATED from afroaffinity/web/content/{profile,cities}.ts — keep in step.
// The slugs are the API's (api/src/lib/profile.ts); these are only labels.

class InterestLabel {
  const InterestLabel(this.en, this.fr, this.emoji);
  final String en;
  final String fr;
  final String emoji;
  String label(String locale) => locale == 'fr' ? fr : en;
}

const interestLabels = <String, InterestLabel>{
  'afrobeats': InterestLabel("Afrobeats", "Afrobeats", '🎵'),
  'amapiano': InterestLabel("Amapiano", "Amapiano", '🎹'),
  'gospel': InterestLabel("Gospel", "Gospel", '🙌'),
  'hiphop': InterestLabel("Hip-hop", "Hip-hop", '🎤'),
  'jazz': InterestLabel("Jazz", "Jazz", '🎷'),
  'makossa': InterestLabel("Makossa", "Makossa", '🥁'),
  'bikutsi': InterestLabel("Bikutsi", "Bikutsi", '💃'),
  'coupe_decale': InterestLabel("Coup\u00e9-d\u00e9cal\u00e9", "Coup\u00e9-d\u00e9cal\u00e9", '🕺'),
  'jollof': InterestLabel("Jollof", "Jollof", '🍚'),
  'ndole': InterestLabel("Ndol\u00e9", "Ndol\u00e9", '🥘'),
  'cooking': InterestLabel("Cooking", "Cuisine", '👩‍🍳'),
  'foodie': InterestLabel("Foodie", "Gourmand\u00b7e", '🍽️'),
  'football': InterestLabel("Football", "Football", '⚽'),
  'basketball': InterestLabel("Basketball", "Basket", '🏀'),
  'gym': InterestLabel("Gym", "Sport en salle", '🏋️'),
  'running': InterestLabel("Running", "Course", '🏃'),
  'dance': InterestLabel("Dance", "Danse", '💃'),
  'movies': InterestLabel("Movies", "Cin\u00e9ma", '🎬'),
  'nollywood': InterestLabel("Nollywood", "Nollywood", '🎥'),
  'series': InterestLabel("Series", "S\u00e9ries", '📺'),
  'books': InterestLabel("Books", "Lecture", '📚'),
  'anime': InterestLabel("Anime", "Anime", '🎌'),
  'travel': InterestLabel("Travel", "Voyages", '✈️'),
  'detty_december': InterestLabel("Detty December", "Detty December", '🎉'),
  'church': InterestLabel("Church", "\u00c9glise", '⛪'),
  'mosque': InterestLabel("Mosque", "Mosqu\u00e9e", '🕌'),
  'family': InterestLabel("Family", "Famille", '👨‍👩‍👧'),
  'entrepreneur': InterestLabel("Entrepreneur", "Entrepreneur\u00b7e", '💼'),
  'tech': InterestLabel("Tech", "Tech", '💻'),
  'fashion': InterestLabel("Fashion", "Mode", '👗'),
  'art': InterestLabel("Art", "Art", '🎨'),
  'photography': InterestLabel("Photography", "Photo", '📷'),
  'gaming': InterestLabel("Gaming", "Jeux vid\u00e9o", '🎮'),
  'nature': InterestLabel("Nature", "Nature", '🌿'),
  'politics_free': InterestLabel("No politics", "Z\u00e9ro politique", '🤫'),
};

const languageLabels = <String, String>{
  'en': "English",
  'fr': "Fran\u00e7ais",
  'pidgin': "Pidgin",
  'duala': "Duala",
  'ewondo': "Ewondo",
  'bassa': "Bassa",
  'fulfulde': "Fulfulde",
  'bamileke': "Bamil\u00e9k\u00e9",
  'yoruba': "Yor\u00f9b\u00e1",
  'igbo': "Igbo",
  'hausa': "Hausa",
  'twi': "Twi",
  'swahili': "Kiswahili",
  'lingala': "Lingala",
  'wolof': "Wolof",
  'arabic': "\u0627\u0644\u0639\u0631\u0628\u064a\u0629",
  'es': "Espa\u00f1ol",
  'de': "Deutsch",
  'pt': "Portugu\u00eas",
  'it': "Italiano",
};

const promptsEN = <String>[
  "Jollof: Nigerian or Ghanaian? Defend it.",
  "The song that gets me on the dance floor",
  "My mum would describe me as",
  "A perfect Sunday looks like",
  "I will never say no to",
  "The last thing I laughed at",
  "Detty December plans",
  "Two truths and a lie",
  "Something I am proud of",
  "I am looking for someone who",
];

const promptsFR = <String>[
  "Le jollof : nig\u00e9rian ou ghan\u00e9en ? D\u00e9fends-toi.",
  "La chanson qui me met sur la piste",
  "Ma m\u00e8re dirait de moi que je suis",
  "Un dimanche parfait, c'est",
  "Je ne dis jamais non \u00e0",
  "La derni\u00e8re chose qui m'a fait rire",
  "Mes plans pour Detty December",
  "Deux v\u00e9rit\u00e9s et un mensonge",
  "Une chose dont je suis fier\u00b7\u00e8re",
  "Je cherche quelqu'un qui",
];

List<String> promptsFor(String locale) => locale == 'fr' ? promptsFR : promptsEN;

class City {
  const City(this.name, this.cc, this.lat, this.lng);
  final String name;
  final String cc;
  final double lat;
  final double lng;
}

const cities = <City>[
  City("Douala", 'CM', 4.0511, 9.7679),
  City("Yaound\u00e9", 'CM', 3.848, 11.5021),
  City("Bafoussam", 'CM', 5.4737, 10.4179),
  City("Bamenda", 'CM', 5.9631, 10.1591),
  City("Garoua", 'CM', 9.3017, 13.3921),
  City("Maroua", 'CM', 10.591, 14.3159),
  City("Ngaound\u00e9r\u00e9", 'CM', 7.3167, 13.5833),
  City("Bertoua", 'CM', 4.5772, 13.6846),
  City("Buea", 'CM', 4.1527, 9.241),
  City("Limbe", 'CM', 4.0186, 9.2056),
  City("Kribi", 'CM', 2.9405, 9.9098),
  City("Ed\u00e9a", 'CM', 3.8, 10.1333),
  City("Kumba", 'CM', 4.6363, 9.4469),
  City("Dschang", 'CM', 5.4442, 10.0531),
  City("Ebolowa", 'CM', 2.9, 11.15),
  City("Lagos", 'NG', 6.5244, 3.3792),
  City("Abuja", 'NG', 9.0765, 7.3986),
  City("Port Harcourt", 'NG', 4.8156, 7.0498),
  City("Accra", 'GH', 5.6037, -0.187),
  City("Kumasi", 'GH', 6.6885, -1.6244),
  City("Abidjan", 'CI', 5.36, -4.0083),
  City("Dakar", 'SN', 14.7167, -17.4677),
  City("Bamako", 'ML', 12.6392, -8.0029),
  City("Lom\u00e9", 'TG', 6.1319, 1.2228),
  City("Cotonou", 'BJ', 6.3703, 2.3912),
  City("Libreville", 'GA', 0.4162, 9.4673),
  City("Malabo", 'GQ', 3.75, 8.7833),
  City("Bangui", 'CF', 4.3947, 18.5582),
  City("Brazzaville", 'CG', -4.2634, 15.2429),
  City("Kinshasa", 'CD', -4.4419, 15.2663),
  City("Luanda", 'AO', -8.839, 13.2894),
  City("Nairobi", 'KE', -1.2921, 36.8219),
  City("Kampala", 'UG', 0.3476, 32.5825),
  City("Kigali", 'RW', -1.9441, 30.0619),
  City("Dar es Salaam", 'TZ', -6.7924, 39.2083),
  City("Addis Ababa", 'ET', 9.03, 38.74),
  City("Johannesburg", 'ZA', -26.2041, 28.0473),
  City("Cape Town", 'ZA', -33.9249, 18.4241),
  City("Casablanca", 'MA', 33.5731, -7.5898),
  City("Cairo", 'EG', 30.0444, 31.2357),
  City("Paris", 'FR', 48.8566, 2.3522),
  City("Lyon", 'FR', 45.764, 4.8357),
  City("Marseille", 'FR', 43.2965, 5.3698),
  City("Bruxelles", 'BE', 50.8503, 4.3517),
  City("London", 'GB', 51.5074, -0.1278),
  City("Manchester", 'GB', 53.4808, -2.2426),
  City("Berlin", 'DE', 52.52, 13.405),
  City("Hamburg", 'DE', 53.5511, 9.9937),
  City("Frankfurt", 'DE', 50.1109, 8.6821),
  City("Munich", 'DE', 48.1351, 11.582),
  City("Gen\u00e8ve", 'CH', 46.2044, 6.1432),
  City("Milano", 'IT', 45.4642, 9.19),
  City("Madrid", 'ES', 40.4168, -3.7038),
  City("Lisboa", 'PT', 38.7223, -9.1393),
  City("Amsterdam", 'NL', 52.3676, 4.9041),
  City("New York", 'US', 40.7128, -74.006),
  City("Houston", 'US', 29.7604, -95.3698),
  City("Atlanta", 'US', 33.749, -84.388),
  City("Washington", 'US', 38.9072, -77.0369),
  City("Montr\u00e9al", 'CA', 45.5017, -73.5673),
  City("Toronto", 'CA', 43.6532, -79.3832),
  City("Dubai", 'AE', 25.2048, 55.2708),
];

const countries = <String, (String, String)>{
  'CM': ("Cameroon", "Cameroun"),
  'NG': ("Nigeria", "Nig\u00e9ria"),
  'GH': ("Ghana", "Ghana"),
  'CI': ("C\u00f4te d'Ivoire", "C\u00f4te d'Ivoire"),
  'SN': ("Senegal", "S\u00e9n\u00e9gal"),
  'ML': ("Mali", "Mali"),
  'TG': ("Togo", "Togo"),
  'BJ': ("Benin", "B\u00e9nin"),
  'GA': ("Gabon", "Gabon"),
  'GQ': ("Equatorial Guinea", "Guin\u00e9e \u00e9quatoriale"),
  'TD': ("Chad", "Tchad"),
  'CF': ("Central African Republic", "Centrafrique"),
  'CG': ("Congo", "Congo"),
  'CD': ("DR Congo", "RD Congo"),
  'AO': ("Angola", "Angola"),
  'KE': ("Kenya", "Kenya"),
  'UG': ("Uganda", "Ouganda"),
  'RW': ("Rwanda", "Rwanda"),
  'TZ': ("Tanzania", "Tanzanie"),
  'ET': ("Ethiopia", "\u00c9thiopie"),
  'ZA': ("South Africa", "Afrique du Sud"),
  'MA': ("Morocco", "Maroc"),
  'EG': ("Egypt", "\u00c9gypte"),
  'FR': ("France", "France"),
  'BE': ("Belgium", "Belgique"),
  'GB': ("United Kingdom", "Royaume-Uni"),
  'DE': ("Germany", "Allemagne"),
  'CH': ("Switzerland", "Suisse"),
  'IT': ("Italy", "Italie"),
  'ES': ("Spain", "Espagne"),
  'PT': ("Portugal", "Portugal"),
  'NL': ("Netherlands", "Pays-Bas"),
  'US': ("United States", "\u00c9tats-Unis"),
  'CA': ("Canada", "Canada"),
  'AE': ("UAE", "\u00c9mirats arabes unis"),
};

String countryName(String? cc, [String locale = 'en']) {
  if (cc == null) return '';
  final c = countries[cc.toUpperCase()];
  return c == null ? cc : (locale == 'fr' ? c.$2 : c.$1);
}

String interestLabel(String slug, [String locale = 'en']) {
  final l = interestLabels[slug];
  return l == null ? slug.replaceAll('_', ' ') : '${l.emoji} ${l.label(locale)}';
}

const goalLabels = <String, String>{
  'relationship': 'A relationship',
  'friendship': 'Friendship',
  'marriage': 'Marriage',
  'open': 'Open to see',
};

const genderLabels = <String, String>{'man': 'Man', 'woman': 'Woman', 'couple': 'Couple'};
