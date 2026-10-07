import '../../../core/errors/error_messages.dart';
import '../../../core/state/cms_list_controller.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../data/project_repository.dart';
import '../domain/project.dart';
import '../domain/project_input.dart';

/// Project CMS: search, category filter, publish/feature toggles, reorder,
/// Storage uploads and deletion with cleanup.
class ProjectController extends CmsListController<Project> {
  ProjectController(super.repository) : super(filterField: 'category');

  /// Feature repository (adds Storage handling to the generic list API).
  ProjectRepository get _repository => repository as ProjectRepository;

  @override
  String get entityLabel => 'Project';

  @override
  String idOf(Project item) => item.id;

  @override
  Map<String, dynamic> toMapOf(Project item) => item.toMap();

  @override
  int orderOf(Project item) => item.order;

  /// Categories found on the currently loaded page (no extra reads).
  List<String> get categories {
    final values = <String>{};
    for (final item in items) {
      if (item.category.trim().isNotEmpty) values.add(item.category.trim());
    }
    final sorted = values.toList()..sort();
    return sorted;
  }

  Future<bool> togglePublished(Project item) => patch(item.id, {'published': !item.published});

  Future<bool> toggleFeatured(Project item) => patch(item.id, {'featured': !item.featured});

  /// Creates or updates a project, uploading staged images on submit.
  Future<bool> saveProject(ProjectInput input) async {
    if (saving.value) return false;
    saving.value = true;
    final editing = input.project.id.isNotEmpty;
    String? createdId;
    final uploaded = <String>[];
    try {
      if (!editing) {
        createdId = await _repository.addProject(input.project);
      }
      final id = editing ? input.project.id : createdId!;
      var thumbnail = input.project.thumbnail;
      final images = List<String>.from(input.project.images);

      final pendingThumbnail = input.thumbnail;
      if (pendingThumbnail != null) {
        thumbnail = await _repository.uploadThumbnail(
          projectId: id,
          bytes: pendingThumbnail.bytes,
          fileName: pendingThumbnail.fileName,
        );
        uploaded.add(thumbnail);
      }
      for (final file in input.gallery) {
        final url = await _repository.uploadGalleryImage(
          projectId: id,
          bytes: file.bytes,
          fileName: file.fileName,
        );
        images.add(url);
        uploaded.add(url);
      }

      final now = DateTime.now();
      var saved = editing ? input.project : input.project.withId(id);
      if (!editing) saved = saved.copyWith(createdAt: now);
      saved = saved.copyWith(thumbnail: thumbnail, images: images, updatedAt: now);
      await _repository.saveProject(saved, now: now);

      if (editing) upsert(saved);
      await _afterSave(input, editing: editing, uploaded: uploaded);
      return true;
    } catch (e) {
      await _rollback(createdId, uploaded);
      AppSnackbar.error(ErrorMessages.describe(e));
      return false;
    } finally {
      saving.value = false;
    }
  }

  Future<void> _afterSave(
    ProjectInput input, {
    required bool editing,
    required List<String> uploaded,
  }) async {
    if (editing && input.removedUrls.isNotEmpty) {
      final failed = await _repository.removeFiles(input.removedUrls);
      if (failed.isNotEmpty) {
        AppSnackbar.warning(
          'Project saved, but ${failed.length} stored file(s) could not be removed.',
        );
        return;
      }
    }
    AppSnackbar.success(editing ? 'Project updated' : 'Project created');
    if (!editing) await reload();
  }

  /// Removes work that did not complete so no orphan documents or files stay.
  Future<void> _rollback(String? createdId, List<String> uploaded) async {
    if (createdId != null) {
      try {
        await _repository.delete(createdId);
      } catch (_) {}
    }
    if (uploaded.isNotEmpty) {
      try {
        await _repository.removeFiles(uploaded);
      } catch (_) {}
    }
  }

  @override
  Future<void> performDelete(String id) async {
    final project = items.where((item) => item.id == id).firstOrNull;
    if (project == null) {
      await _repository.delete(id);
      return;
    }
    final failed = await _repository.deleteProject(project);
    if (failed.isNotEmpty) {
      AppSnackbar.warning('${failed.length} stored file(s) could not be removed.');
    }
  }
}
