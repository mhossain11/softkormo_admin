import '../../../core/utils/map_reader.dart';

/// Pricing package managed in the CMS (`packages` collection).
/// Any number of packages can be created - nothing is hardcoded.
class PackagePlan {
  const PackagePlan({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.currency,
    required this.billingLabel,
    required this.description,
    required this.features,
    required this.recommended,
    required this.active,
    required this.order,
    required this.ctaLabel,
    this.createdAt,
    this.updatedAt,
  });

  static const String collection = 'packages';

  final String id;
  final String name;
  final String subtitle;

  /// Stored as number; numeric strings from legacy data are accepted.
  final num price;
  final String currency;
  final String billingLabel;
  final String description;
  final List<String> features;
  final bool recommended;
  final bool active;
  final int order;
  final String ctaLabel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PackagePlan.fromMap(Map<String, dynamic> map, {String id = ''}) {
    final reader = MapReader(map);
    return PackagePlan(
      id: id,
      name: reader.getString('name'),
      subtitle: reader.getString('subtitle'),
      price: reader.getNum('price'),
      currency: reader.getString('currency', 'USD'),
      billingLabel: reader.getString('billingLabel'),
      description: reader.getString('description'),
      features: reader.getStringList('features'),
      recommended: reader.getBool('recommended'),
      active: reader.getBool('active'),
      order: reader.getInt('order'),
      ctaLabel: reader.getString('ctaLabel', 'Get started'),
      createdAt: reader.getDate('createdAt'),
      updatedAt: reader.getDate('updatedAt'),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'subtitle': subtitle,
        'price': price,
        'currency': currency,
        'billingLabel': billingLabel,
        'description': description,
        'features': features,
        'recommended': recommended,
        'active': active,
        'order': order,
        'ctaLabel': ctaLabel,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  PackagePlan copyWith({
    String? name,
    String? subtitle,
    num? price,
    String? currency,
    String? billingLabel,
    String? description,
    List<String>? features,
    bool? recommended,
    bool? active,
    int? order,
    String? ctaLabel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PackagePlan(
        id: id,
        name: name ?? this.name,
        subtitle: subtitle ?? this.subtitle,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        billingLabel: billingLabel ?? this.billingLabel,
        description: description ?? this.description,
        features: features ?? this.features,
        recommended: recommended ?? this.recommended,
        active: active ?? this.active,
        order: order ?? this.order,
        ctaLabel: ctaLabel ?? this.ctaLabel,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
