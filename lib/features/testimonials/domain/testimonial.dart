import '../../../core/utils/map_reader.dart';

/// Customer testimonial managed in the CMS (`testimonials` collection).
class Testimonial {
  const Testimonial({
    required this.id,
    required this.name,
    required this.designation,
    required this.company,
    required this.message,
    required this.rating,
    required this.imageUrl,
    required this.featured,
    required this.published,
    required this.order,
    this.createdAt,
    this.updatedAt,
  });

  static const String collection = 'testimonials';
  static const int minRating = 1;
  static const int maxRating = 5;

  final String id;
  final String name;
  final String designation;
  final String company;
  final String message;
  final int rating;
  final String imageUrl;
  final bool featured;
  final bool published;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Testimonial.fromMap(Map<String, dynamic> map, {String id = ''}) {
    final reader = MapReader(map);
    var rating = reader.getInt('rating', 5);
    if (rating < minRating) rating = minRating;
    if (rating > maxRating) rating = maxRating;
    return Testimonial(
      id: id,
      name: reader.getString('name'),
      designation: reader.getString('designation'),
      company: reader.getString('company'),
      message: reader.getString('message'),
      rating: rating,
      imageUrl: reader.getString('imageUrl'),
      featured: reader.getBool('featured'),
      published: reader.getBool('published'),
      order: reader.getInt('order'),
      createdAt: reader.getDate('createdAt'),
      updatedAt: reader.getDate('updatedAt'),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'designation': designation,
        'company': company,
        'message': message,
        'rating': rating,
        'imageUrl': imageUrl,
        'featured': featured,
        'published': published,
        'order': order,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  Testimonial copyWith({
    String? id,
    String? name,
    String? designation,
    String? company,
    String? message,
    int? rating,
    String? imageUrl,
    bool? featured,
    bool? published,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Testimonial(
        id: id ?? this.id,
        name: name ?? this.name,
        designation: designation ?? this.designation,
        company: company ?? this.company,
        message: message ?? this.message,
        rating: rating ?? this.rating,
        imageUrl: imageUrl ?? this.imageUrl,
        featured: featured ?? this.featured,
        published: published ?? this.published,
        order: order ?? this.order,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Returns a copy pointing to [id] - used after the document is created.
  Testimonial withId(String id) => copyWith(id: id);
}
