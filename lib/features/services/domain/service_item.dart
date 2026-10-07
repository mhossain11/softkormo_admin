import '../../../core/utils/map_reader.dart';

/// Service offering managed in the CMS (`services` collection).
class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.description,
    required this.icon,
    required this.features,
    required this.order,
    required this.published,
    this.createdAt,
    this.updatedAt,
  });

  static const String collection = 'services';

  final String id;
  final String title;
  final String shortDescription;
  final String description;
  final String icon;
  final List<String> features;
  final int order;
  final bool published;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ServiceItem.fromMap(Map<String, dynamic> map, {String id = ''}) {
    final reader = MapReader(map);
    return ServiceItem(
      id: id,
      title: reader.getString('title'),
      shortDescription: reader.getString('shortDescription'),
      description: reader.getString('description'),
      icon: reader.getString('icon'),
      features: reader.getStringList('features'),
      order: reader.getInt('order'),
      published: reader.getBool('published'),
      createdAt: reader.getDate('createdAt'),
      updatedAt: reader.getDate('updatedAt'),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'shortDescription': shortDescription,
        'description': description,
        'icon': icon,
        'features': features,
        'order': order,
        'published': published,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  ServiceItem copyWith({
    String? title,
    String? shortDescription,
    String? description,
    String? icon,
    List<String>? features,
    int? order,
    bool? published,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ServiceItem(
        id: id,
        title: title ?? this.title,
        shortDescription: shortDescription ?? this.shortDescription,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        features: features ?? this.features,
        order: order ?? this.order,
        published: published ?? this.published,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
