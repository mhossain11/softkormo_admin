import '../../../core/utils/map_reader.dart';

/// Lead submitted through the public website contact form.
class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.service,
    required this.message,
    required this.status,
    required this.source,
    this.createdAt,
  });

  static const String collection = 'contacts';
  static const List<String> statuses = ['new', 'contacted', 'qualified', 'converted', 'closed'];

  final String id;
  final String name;
  final String email;
  final String phone;
  final String service;
  final String message;
  final String status;
  final String source;
  final DateTime? createdAt;

  factory Contact.fromMap(Map<String, dynamic> map, {String id = ''}) {
    final reader = MapReader(map);
    var status = reader.getString('status', 'new').toLowerCase();
    if (!statuses.contains(status)) status = 'new';
    return Contact(
      id: id,
      name: reader.getString('name'),
      email: reader.getString('email'),
      phone: reader.getString('phone'),
      service: reader.getString('service'),
      message: reader.getString('message'),
      status: status,
      source: reader.getString('source', 'website'),
      createdAt: reader.getDate('createdAt'),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'service': service,
        'message': message,
        'status': status,
        'source': source,
        'createdAt': createdAt,
      };

  Contact copyWith({String? status}) => Contact(
        id: id,
        name: name,
        email: email,
        phone: phone,
        service: service,
        message: message,
        status: status ?? this.status,
        source: source,
        createdAt: createdAt,
      );
}
