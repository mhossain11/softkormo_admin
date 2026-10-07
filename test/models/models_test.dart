import 'package:flutter_test/flutter_test.dart';
import 'package:softkormoadmin/features/auth/domain/admin_user.dart';
import 'package:softkormoadmin/features/contacts/domain/contact.dart';
import 'package:softkormoadmin/features/packages/domain/package_plan.dart';
import 'package:softkormoadmin/features/projects/domain/project.dart';
import 'package:softkormoadmin/features/services/domain/service_item.dart';
import 'package:softkormoadmin/features/settings/domain/site_settings.dart';
import 'package:softkormoadmin/features/testimonials/domain/testimonial.dart';

void main() {
  group('Contact', () {
    test('fromMap falls back to safe defaults for an empty document', () {
      final contact = Contact.fromMap(const {}, id: 'c1');
      expect(contact.id, 'c1');
      expect(contact.name, '');
      expect(contact.status, 'new');
      expect(contact.source, 'website');
      expect(contact.createdAt, isNull);
    });

    test('fromMap normalizes unknown statuses and keeps valid ones', () {
      expect(Contact.fromMap(const {'status': 'CONTACTED'}, id: 'c1').status, 'contacted');
      expect(Contact.fromMap(const {'status': 'archived'}, id: 'c1').status, 'new');
    });

    test('toMap round trips through fromMap', () {
      final createdAt = DateTime(2024, 6, 1, 9, 30);
      const contact = Contact(
        id: 'c1',
        name: 'Ada Lovelace',
        email: 'ada@softkormo.com',
        phone: '+8801700000000',
        service: 'Flutter Development',
        message: 'Need an admin panel.',
        status: 'qualified',
        source: 'contact-form',
      );

      final parsed = Contact.fromMap({...contact.toMap(), 'createdAt': createdAt}, id: 'c1');
      expect(parsed.name, 'Ada Lovelace');
      expect(parsed.email, 'ada@softkormo.com');
      expect(parsed.service, 'Flutter Development');
      expect(parsed.status, 'qualified');
      expect(parsed.source, 'contact-form');
      expect(parsed.createdAt!.millisecondsSinceEpoch, createdAt.millisecondsSinceEpoch);
      expect(contact.toMap().containsKey('id'), isFalse);
    });

    test('copyWith only replaces the requested field', () {
      final contact = Contact.fromMap(const {
        'name': 'Ada',
        'status': 'new',
      }, id: 'c1');
      final updated = contact.copyWith(status: 'closed');
      expect(updated.status, 'closed');
      expect(updated.name, 'Ada');
      expect(updated.id, 'c1');
    });
  });

  group('Project', () {
    test('fromMap tolerates missing fields', () {
      final project = Project.fromMap(const {'title': 'SoftKormo Website'}, id: 'p1');
      expect(project.id, 'p1');
      expect(project.title, 'SoftKormo Website');
      expect(project.slug, '');
      expect(project.images, isEmpty);
      expect(project.technologies, isEmpty);
      expect(project.featured, isFalse);
      expect(project.published, isFalse);
      expect(project.order, 0);
      expect(project.year, isNull);
      expect(project.createdAt, isNull);
    });

    test('fromMap accepts legacy string values', () {
      final project = Project.fromMap(const {
        'title': 'Legacy',
        'year': '2023',
        'order': '4',
        'featured': 'true',
        'published': 1,
        'technologies': 'Flutter, Firebase',
      });
      expect(project.year, 2023);
      expect(project.order, 4);
      expect(project.featured, isTrue);
      expect(project.published, isTrue);
      expect(project.technologies, ['Flutter', 'Firebase']);
    });

    test('toMap round trips through fromMap', () {
      final project = Project.fromMap(const {
        'title': 'Admin Panel',
        'slug': 'admin-panel',
        'shortDescription': 'A CMS.',
        'description': 'Full CMS for the website.',
        'category': 'Web',
        'year': 2024,
        'thumbnail': 'projects/p1/thumbnail.webp',
        'images': ['projects/p1/gallery/1.webp'],
        'technologies': ['Flutter', 'Firestore'],
        'client': 'SoftKormo',
        'githubUrl': 'https://github.com/softkormo/admin',
        'projectUrl': 'https://softkormo.com',
        'featured': true,
        'published': true,
        'order': 2,
      }, id: 'p1');

      final reparsed = Project.fromMap(project.toMap(), id: 'p1');
      expect(reparsed.title, 'Admin Panel');
      expect(reparsed.slug, 'admin-panel');
      expect(reparsed.images, ['projects/p1/gallery/1.webp']);
      expect(reparsed.technologies, ['Flutter', 'Firestore']);
      expect(reparsed.featured, isTrue);
      expect(reparsed.published, isTrue);
      expect(reparsed.order, 2);
      expect(reparsed.withId('p2').id, 'p2');
    });
  });

  group('AdminUser', () {
    test('fromMap defaults to an active admin', () {
      final admin = AdminUser.fromMap(const {'name': 'Faysal', 'email': 'a@b.com'}, uid: 'u1');
      expect(admin.uid, 'u1');
      expect(admin.role, AdminUser.roleAdmin);
      expect(admin.active, isTrue);
      expect(admin.isSuperAdmin, isFalse);
    });

    test('fromMap rejects unknown roles', () {
      expect(
        AdminUser.fromMap(const {'role': 'super_admin'}, uid: 'u1').role,
        AdminUser.roleSuperAdmin,
      );
      expect(
        AdminUser.fromMap(const {'role': 'owner'}, uid: 'u1').role,
        AdminUser.roleAdmin,
      );
      expect(AdminUser.fromMap(const {'active': false}, uid: 'u1').active, isFalse);
    });

    test('toMap never exposes the uid', () {
      final admin = AdminUser.fromMap(const {'name': 'Faysal'}, uid: 'u1');
      expect(admin.toMap().keys, ['name', 'email', 'role', 'active', 'createdAt']);
    });
  });

  group('Testimonial', () {
    test('clamps ratings into the supported range', () {
      expect(Testimonial.fromMap(const {'rating': 9}).rating, Testimonial.maxRating);
      expect(Testimonial.fromMap(const {'rating': 0}).rating, Testimonial.minRating);
      expect(Testimonial.fromMap(const {'rating': '4'}).rating, 4);
      expect(Testimonial.fromMap(const {}).rating, Testimonial.maxRating);
    });

    test('toMap round trips through fromMap', () {
      final testimonial = Testimonial.fromMap(const {
        'name': 'Client',
        'designation': 'CTO',
        'company': 'ACME',
        'message': 'Great team.',
        'rating': 5,
        'imageUrl': 'testimonials/t1/avatar.webp',
        'featured': true,
        'published': true,
        'order': 1,
      }, id: 't1');

      final reparsed = Testimonial.fromMap(testimonial.toMap(), id: 't1');
      expect(reparsed.name, 'Client');
      expect(reparsed.message, 'Great team.');
      expect(reparsed.featured, isTrue);
      expect(reparsed.published, isTrue);
      expect(reparsed.withId('t2').id, 't2');
    });
  });

  group('ServiceItem', () {
    test('fromMap falls back to safe defaults', () {
      final service = ServiceItem.fromMap(const {'title': 'Web Development'}, id: 's1');
      expect(service.features, isEmpty);
      expect(service.published, isFalse);
      expect(service.order, 0);
    });

    test('toMap round trips through fromMap', () {
      final service = ServiceItem.fromMap(const {
        'title': 'Mobile Apps',
        'shortDescription': 'Native feel.',
        'description': 'Full description.',
        'icon': 'phone_android',
        'features': ['Offline mode'],
        'order': 3,
        'published': true,
      }, id: 's1');

      final reparsed = ServiceItem.fromMap(service.toMap(), id: 's1');
      expect(reparsed.title, 'Mobile Apps');
      expect(reparsed.features, ['Offline mode']);
      expect(reparsed.order, 3);
      expect(reparsed.published, isTrue);
      expect(reparsed.copyWith(title: 'Changed').title, 'Changed');
      expect(reparsed.copyWith().id, 's1');
    });
  });

  group('PackagePlan', () {
    test('applies currency and call to action defaults', () {
      final plan = PackagePlan.fromMap(const {'name': 'Starter', 'price': '499'}, id: 'pk1');
      expect(plan.price, 499);
      expect(plan.currency, 'USD');
      expect(plan.ctaLabel, 'Get started');
      expect(plan.active, isFalse);
      expect(plan.recommended, isFalse);
    });

    test('toMap round trips through fromMap', () {
      final plan = PackagePlan.fromMap(const {
        'name': 'Business',
        'subtitle': 'For growing teams',
        'price': 1299.5,
        'currency': 'USD',
        'billingLabel': 'per month',
        'description': 'Everything included.',
        'features': ['Priority support'],
        'recommended': true,
        'active': true,
        'order': 2,
        'ctaLabel': 'Buy now',
      }, id: 'pk1');

      final reparsed = PackagePlan.fromMap(plan.toMap(), id: 'pk1');
      expect(reparsed.price, 1299.5);
      expect(reparsed.billingLabel, 'per month');
      expect(reparsed.recommended, isTrue);
      expect(reparsed.active, isTrue);
      expect(reparsed.ctaLabel, 'Buy now');
      expect(reparsed.copyWith(order: 7).order, 7);
    });
  });

  group('SiteSettings', () {
    test('reads the single settings document with defaults', () {
      final settings = SiteSettings.fromMap(const {});
      expect(settings.companyName, '');
      expect(settings.logoUrl, '');
      expect(settings.updatedAt, isNull);
      expect(SiteSettings.path, 'settings/site');
    });

    test('toMap round trips through fromMap', () {
      final updatedAt = DateTime(2024, 8, 10, 12);
      final settings = SiteSettings.fromMap(const {
        'companyName': 'SoftKormo',
        'tagline': 'Digital products.',
        'email': 'hello@softkormo.com',
        'phone': '+8801700000000',
        'address': 'Dhaka, Bangladesh',
        'facebook': 'https://facebook.com/softkormo',
        'linkedin': 'https://linkedin.com/company/softkormo',
        'github': 'https://github.com/softkormo',
        'youtube': 'https://youtube.com/@softkormo',
        'logoUrl': 'settings/logo/1.png',
      });

      expect(settings.companyName, 'SoftKormo');
      expect(settings.logoUrl, 'settings/logo/1.png');

      final reparsed = SiteSettings.fromMap({...settings.toMap(), 'updatedAt': updatedAt});
      expect(reparsed.tagline, 'Digital products.');
      expect(reparsed.updatedAt!.millisecondsSinceEpoch, updatedAt.millisecondsSinceEpoch);
      expect(SiteSettings.empty().companyName, '');
    });
  });
}
