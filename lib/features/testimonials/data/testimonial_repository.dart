import 'dart:typed_data';

import '../../../core/data/list_repository.dart';
import '../../../core/data/media_storage.dart';
import '../domain/testimonial.dart';

/// Customer testimonials (`testimonials` collection).
class TestimonialRepository extends ListRepository<Testimonial> {
  TestimonialRepository(super.firestore, this._media)
      : super(
          collectionName: Testimonial.collection,
          parse: Testimonial.fromMap,
          orderField: 'order',
          searchField: 'name',
        );

  final MediaStorage _media;

  Future<String> uploadAvatar({
    required String testimonialId,
    required Uint8List bytes,
    required String fileName,
  }) {
    final safe = MediaStorage.safeName(fileName.isEmpty ? 'avatar.jpg' : fileName);
    return _media.uploadImage(
      path: 'testimonials/$testimonialId/$safe',
      bytes: bytes,
      fileName: fileName,
    );
  }

  Future<List<String>> removeFiles(List<String> urls) => _media.deleteUrls(urls);

  Future<List<String>> deleteTestimonial(Testimonial item) async {
    await delete(item.id);
    if (item.imageUrl.trim().isEmpty) return const [];
    return _media.deleteUrls([item.imageUrl]);
  }
}
