import '../../../core/data/pending_image.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/state/cms_list_controller.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../data/testimonial_repository.dart';
import '../domain/testimonial.dart';

/// Testimonials CMS: publish/feature toggles, reorder and avatar upload.
class TestimonialController extends CmsListController<Testimonial> {
  TestimonialController(super.repository) : super(filterField: 'published');

  /// Feature repository (adds avatar uploads to the generic list API).
  TestimonialRepository get _repository => repository as TestimonialRepository;

  @override
  String get entityLabel => 'Testimonial';

  @override
  String idOf(Testimonial item) => item.id;

  @override
  Map<String, dynamic> toMapOf(Testimonial item) => item.toMap();

  @override
  int orderOf(Testimonial item) => item.order;

  Future<bool> togglePublished(Testimonial item) =>
      patch(item.id, {'published': !item.published});

  Future<bool> toggleFeatured(Testimonial item) =>
      patch(item.id, {'featured': !item.featured});

  /// Creates or updates a testimonial, uploading a staged avatar on submit.
  Future<bool> saveTestimonial(
    Testimonial draft, {
    PendingImage? avatar,
    String? removedUrl,
  }) async {
    if (saving.value) return false;
    saving.value = true;
    final editing = draft.id.isNotEmpty;
    String? createdId;
    String? uploadedUrl;
    try {
      final now = DateTime.now();
      if (!editing) {
        createdId = await repository.create({
          ...draft.toMap(),
          'createdAt': now,
          'updatedAt': now,
        });
      }
      final id = editing ? draft.id : createdId!;
      var saved = editing ? draft : draft.withId(id);

      if (avatar != null) {
        uploadedUrl = await _repository.uploadAvatar(
          testimonialId: id,
          bytes: avatar.bytes,
          fileName: avatar.fileName,
        );
        saved = saved.copyWith(imageUrl: uploadedUrl);
      }

      await repository.update(id, {...saved.toMap(), 'updatedAt': now});
      if (editing) upsert(saved);

      if (editing && removedUrl != null && removedUrl.isNotEmpty) {
        final failed = await _repository.removeFiles([removedUrl]);
        if (failed.isNotEmpty) {
          AppSnackbar.warning(
            'Testimonial saved, but the old image could not be removed from storage.',
          );
          return true;
        }
      }

      AppSnackbar.success(editing ? 'Testimonial updated' : 'Testimonial created');
      if (!editing) await reload();
      return true;
    } catch (e) {
      if (!editing && createdId != null) {
        try {
          await repository.delete(createdId);
        } catch (_) {}
      }
      if (uploadedUrl != null) {
        try {
          await _repository.removeFiles([uploadedUrl]);
        } catch (_) {}
      }
      AppSnackbar.error(ErrorMessages.describe(e));
      return false;
    } finally {
      saving.value = false;
    }
  }

  @override
  Future<void> performDelete(String id) async {
    final item = items.where((element) => element.id == id).firstOrNull;
    if (item == null) {
      await _repository.delete(id);
      return;
    }
    final failed = await _repository.deleteTestimonial(item);
    if (failed.isNotEmpty) {
      AppSnackbar.warning('${failed.length} stored file(s) could not be removed.');
    }
  }
}
