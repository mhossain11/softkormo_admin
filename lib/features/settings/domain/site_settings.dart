import '../../../core/utils/map_reader.dart';

/// Global website settings stored in the single document `settings/site`.
class SiteSettings {
  const SiteSettings({
    required this.companyName,
    required this.tagline,
    required this.email,
    required this.phone,
    required this.address,
    required this.facebook,
    required this.linkedin,
    required this.github,
    required this.youtube,
    required this.logoUrl,
    this.updatedAt,
  });

  static const String collection = 'settings';
  static const String documentId = 'site';
  static const String path = '$collection/$documentId';

  final String companyName;
  final String tagline;
  final String email;
  final String phone;
  final String address;
  final String facebook;
  final String linkedin;
  final String github;
  final String youtube;
  final String logoUrl;
  final DateTime? updatedAt;

  factory SiteSettings.empty() => const SiteSettings(
        companyName: '',
        tagline: '',
        email: '',
        phone: '',
        address: '',
        facebook: '',
        linkedin: '',
        github: '',
        youtube: '',
        logoUrl: '',
      );

  factory SiteSettings.fromMap(Map<String, dynamic> map) {
    final reader = MapReader(map);
    return SiteSettings(
      companyName: reader.getString('companyName'),
      tagline: reader.getString('tagline'),
      email: reader.getString('email'),
      phone: reader.getString('phone'),
      address: reader.getString('address'),
      facebook: reader.getString('facebook'),
      linkedin: reader.getString('linkedin'),
      github: reader.getString('github'),
      youtube: reader.getString('youtube'),
      logoUrl: reader.getString('logoUrl'),
      updatedAt: reader.getDate('updatedAt'),
    );
  }

  Map<String, dynamic> toMap() => {
        'companyName': companyName,
        'tagline': tagline,
        'email': email,
        'phone': phone,
        'address': address,
        'facebook': facebook,
        'linkedin': linkedin,
        'github': github,
        'youtube': youtube,
        'logoUrl': logoUrl,
        'updatedAt': updatedAt,
      };
}
