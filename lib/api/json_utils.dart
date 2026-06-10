// Tolerant JSON helpers — the API field names are not fully specified in the
// sheet, so readers accept several common aliases and coerce types defensively.

dynamic _first(Map m, List<String> keys) {
  for (final k in keys) {
    if (m.containsKey(k) && m[k] != null) return m[k];
  }
  return null;
}

String pickString(Map? m, List<String> keys, {String fallback = ''}) {
  if (m == null) return fallback;
  final v = _first(m, keys);
  return v == null ? fallback : v.toString();
}

num pickNum(Map? m, List<String> keys, {num fallback = 0}) {
  if (m == null) return fallback;
  final v = _first(m, keys);
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? fallback;
  return fallback;
}

int pickInt(Map? m, List<String> keys, {int fallback = 0}) => pickNum(m, keys, fallback: fallback).toInt();

double pickDouble(Map? m, List<String> keys, {double fallback = 0}) => pickNum(m, keys, fallback: fallback).toDouble();

bool pickBool(Map? m, List<String> keys, {bool fallback = false}) {
  if (m == null) return fallback;
  final v = _first(m, keys);
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return fallback;
}

String? pickId(Map? m, [List<String> keys = const ['id', '_id', 'uuid']]) {
  if (m == null) return null;
  final v = _first(m, keys);
  return v?.toString();
}

/// Normalises a list payload that may arrive as a bare array, or nested under
/// `items` / `data` / `rows` / `results`.
List<Map<String, dynamic>> asList(dynamic data) {
  dynamic list = data;
  if (data is Map) {
    list = _first(data, ['items', 'data', 'rows', 'results', 'records']) ?? data['list'];
  }
  if (list is List) {
    return list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
  return const [];
}

Map<String, dynamic>? asMap(dynamic data) {
  if (data is Map) return data.cast<String, dynamic>();
  return null;
}
