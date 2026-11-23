import '../core/util/json.dart';

class OptionItem {
  const OptionItem(this.value, this.labelEn, this.labelFr);
  final String value;
  final String labelEn;
  final String labelFr;
  String label(String locale) => locale == 'fr' ? labelFr : labelEn;
}

/// `GET /profile-options`: the legal values for the ten structured fields.
/// The server validates against the same table, so these are never hardcoded.
class ProfileOptions {
  ProfileOptions(Json j)
      : fields = asMap(j['fields']).map((k, v) => MapEntry(
              k,
              asMapList(v)
                  .map((o) => OptionItem(asString(o['value']) ?? '', asString(o['label_en']) ?? '',
                      asString(o['label_fr']) ?? ''))
                  .toList(),
            ));

  final Map<String, List<OptionItem>> fields;

  List<OptionItem> of(String field) => fields[field] ?? const [];

  String? labelFor(String field, String? value, String locale) {
    if (value == null) return null;
    return of(field).where((o) => o.value == value).firstOrNull?.label(locale) ?? value;
  }

  static const fieldLabels = <String, String>{
    'eye_color': 'Eye colour',
    'hair_color': 'Hair colour',
    'body_type': 'Body type',
    'marital_status': 'Relationship status',
    'children': 'Children',
    'income_band': 'Income',
    'smoker': 'Smoking',
    'drinker': 'Drinking',
    'employment': 'Work',
    'education': 'Education',
  };
}
