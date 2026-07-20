import 'package:latlong2/latlong.dart';

/// City-centroid fallback so every open job shows on the map even when the
/// employer never dropped an exact pin. Real jobs frequently have a `city` but
/// null `lat/lng`; without this they silently vanish from the map (the invariant
/// is "a posted job is visible everywhere immediately"). Such jobs are plotted
/// at their city centre with a small deterministic jitter so same-city jobs fan
/// out instead of stacking. Mirrors the web `uz-geo.ts` — same table, same hash
/// — so both clients place a pinless job at the same point.

/// Centroids for Uzbekistan's cities + regional capitals (WGS84).
const Map<String, LatLng> _centroids = {
  'toshkent': LatLng(41.3111, 69.2797),
  'samarqand': LatLng(39.6542, 66.9597),
  'buxoro': LatLng(39.7747, 64.4286),
  'andijon': LatLng(40.7821, 72.3442),
  'namangan': LatLng(40.9983, 71.6726),
  'fargona': LatLng(40.3894, 71.7843),
  'nukus': LatLng(42.4531, 59.6103),
  'qarshi': LatLng(38.86, 65.7847),
  'termiz': LatLng(37.2242, 67.2783),
  'jizzax': LatLng(40.1158, 67.8422),
  'guliston': LatLng(40.4897, 68.7842),
  'navoiy': LatLng(40.0844, 65.3792),
  'urganch': LatLng(41.55, 60.6333),
  'xiva': LatLng(41.3783, 60.3639),
  'qoqon': LatLng(40.5286, 70.9425),
  'margilon': LatLng(40.4711, 71.7247),
  'chirchiq': LatLng(41.4689, 69.5822),
  'angren': LatLng(41.0167, 70.1436),
  'olmaliq': LatLng(40.8447, 69.5981),
  'bekobod': LatLng(40.2206, 69.2697),
  'zarafshon': LatLng(41.5725, 64.2036),
  'shahrisabz': LatLng(39.0578, 66.8306),
  'denov': LatLng(38.2678, 67.8942),
  'kogon': LatLng(39.7222, 64.5528),
};

/// Common uz/ru/en spellings → canonical [_centroids] key.
const Map<String, String> _aliases = {
  'tashkent': 'toshkent',
  'ташкент': 'toshkent',
  'samarkand': 'samarqand',
  'самарканд': 'samarqand',
  'bukhara': 'buxoro',
  'бухара': 'buxoro',
  'andijan': 'andijon',
  'андижан': 'andijon',
  'наманган': 'namangan',
  'fergana': 'fargona',
  'ferghana': 'fargona',
  'фергана': 'fargona',
  'karshi': 'qarshi',
  'qashqadaryo': 'qarshi',
  'карши': 'qarshi',
  'termez': 'termiz',
  'термез': 'termiz',
  'jizzakh': 'jizzax',
  'джизак': 'jizzax',
  'gulistan': 'guliston',
  'chirchik': 'chirchiq',
  'чирчик': 'chirchiq',
  'ангрен': 'angren',
  'almalyk': 'olmaliq',
  'алмалык': 'olmaliq',
  'bekabad': 'bekobod',
  'zarafshan': 'zarafshon',
  'shakhrisabz': 'shahrisabz',
  // Tashkent city districts + nearby Tashkent-region towns → Tashkent.
  'chilonzor': 'toshkent',
  'чиланзар': 'toshkent',
  'yunusobod': 'toshkent',
  'юнусабад': 'toshkent',
  'mirzoulugbek': 'toshkent',
  'yakkasaroy': 'toshkent',
  'sergeli': 'toshkent',
  'uchtepa': 'toshkent',
  'shayxontohur': 'toshkent',
  'olmazor': 'toshkent',
  'bektemir': 'toshkent',
  'yashnobod': 'toshkent',
  'mirobod': 'toshkent',
  'yangihayot': 'toshkent',
  'nurafshon': 'toshkent',
  'yangiyol': 'toshkent',
};

/// Admin-marker words dropped so "Toshkent shahri" / "г. Ташкент" /
/// "Chilonzor tumani" collapse to the bare place name.
const Set<String> _adminWords = {
  'shahri',
  'shahar',
  'shahridagi',
  'tumani',
  'tuman',
  'viloyati',
  'viloyat',
  'gorod',
  'город',
  'g',
  'область',
  'обл',
  'район',
  'rayon',
  'region',
};

/// Lowercase, drop apostrophes + admin-marker words, keep letters.
String _normalize(String city) {
  final cleaned = city.toLowerCase().replaceAll(RegExp("['`ʻʼʹ‘’]"), '');
  return cleaned
      .split(RegExp('[^a-zа-я]+'))
      .where((w) => w.isNotEmpty && !_adminWords.contains(w))
      .join();
}

/// Centroid for a city name (any common spelling), or null if unknown.
LatLng? cityLatLng(String? city) {
  if (city == null || city.isEmpty) return null;
  final key = _normalize(city);
  final canonical = _aliases[key] ?? key;
  return _centroids[canonical];
}

/// Deterministic 32-bit FNV-1a hash — stable jitter per job (matches web).
int _hash(String s) {
  var h = 2166136261;
  for (var i = 0; i < s.length; i++) {
    h ^= s.codeUnitAt(i);
    h = (h * 16777619) & 0xFFFFFFFF;
  }
  return h;
}

/// The map coordinate for a job: its exact pin if set, else its city centroid
/// (jittered by id so same-city jobs fan out ~±1.6 km), else Tashkent. An open
/// job is **never** dropped from the map.
LatLng jobLatLng({double? lat, double? lng, String? city, required String id}) {
  if (lat != null && lng != null) return LatLng(lat, lng);
  final centroid = cityLatLng(city) ?? _centroids['toshkent']!;
  final h = _hash(id);
  final dLat = ((h % 1000) / 1000 - 0.5) * 0.03;
  final dLng = (((h >> 10) % 1000) / 1000 - 0.5) * 0.03;
  return LatLng(centroid.latitude + dLat, centroid.longitude + dLng);
}
