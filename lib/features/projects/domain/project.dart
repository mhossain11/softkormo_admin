import '../../../core/utils/map_reader.dart';

/// Project entry managed in the CMS and rendered by the public website.
class Project {
  const Project({
    required this.id,
    required this.title,
    required this.slug,
    required this.shortDescription,
    required this.description,
    required this.category,
    this.year,
    required this.thumbnail,
    required this.images,
    required this.technologies,
    required this.client,
    required this.githubUrl,
    required this.projectUrl,
    required this.featured,
    required this.published,
    required this.order,
    this.createdAt,
    this.updatedAt,
  });

  static const String collection = 'projects';

  final String id;
  final String title;
  final String slug;
  final String shortDescription;
  final String description;
  final String category;
  final int? year;
  final String thumbnail;
  final List<String> images;
  final List<String> technologies;
  final String client;
  final String githubUrl;
  final String projectUrl;
  final bool featured;
  final bool published;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Project.fromMap(Map<String, dynamic> map, {String id = ''}) {
    final reader = MapReader(map);
    return Project(
      id: id,
      title: reader.getString('title'),
      slug: reader.getString('slug'),
      shortDescription: reader.getString('shortDescription'),
      description: reader.getString('description'),
      category: reader.getString('category'),
      year: reader.getIntOrNull('year'),
      thumbnail: reader.getString('thumbnail'),
      images: reader.getStringList('images'),
      technologies: reader.getStringList('technologies'),
      client: reader.getString('client'),
      githubUrl: reader.getString('githubUrl'),
      projectUrl: reader.getString('projectUrl'),
      featured: reader.getBool('featured'),
      published: reader.getBool('published'),
      order: reader.getInt('order'),
      createdAt: reader.getDate('createdAt'),
      updatedAt: reader.getDate('updatedAt'),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'slug': slug,
        'shortDescription': shortDescription,
        'description': description,
        'category': category,
        'year': year,
        'thumbnail': thumbnail,
        'images': images,
        'technologies': technologies,
        'client': client,
        'githubUrl': githubUrl,
        'projectUrl': projectUrl,
        'featured': featured,
        'published': published,
        'order': order,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  Project copyWith({
    String? id,
    String? title,
    String? slug,
    String? shortDescription,
    String? description,
    String? category,
    int? year,
    String? thumbnail,
    List<String>? images,
    List<String>? technologies,
    String? client,
    String? githubUrl,
    String? projectUrl,
    bool? featured,
    bool? published,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Project(
        id: id ?? this.id,
        title: title ?? this.title,
        slug: slug ?? this.slug,
        shortDescription: shortDescription ?? this.shortDescription,
        description: description ?? this.description,
        category: category ?? this.category,
        year: year ?? this.year,
        thumbnail: thumbnail ?? this.thumbnail,
        images: images ?? this.images,
        technologies: technologies ?? this.technologies,
        client: client ?? this.client,
        githubUrl: githubUrl ?? this.githubUrl,
        projectUrl: projectUrl ?? this.projectUrl,
        featured: featured ?? this.featured,
        published: published ?? this.published,
        order: order ?? this.order,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Returns a copy pointing to [id] - used after the document is created.
  Project withId(String id) => copyWith(id: id);
}
