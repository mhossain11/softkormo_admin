import 'dart:typed_data';

import '../../../core/data/list_repository.dart';
import '../../../core/data/media_storage.dart';
import '../domain/project.dart';

/// Project CRUD + Firebase Storage image handling.
///
/// Storage layout: `projects/{projectId}/thumbnail` and
/// `projects/{projectId}/gallery/{file}`.
class ProjectRepository extends ListRepository<Project> {
  ProjectRepository(super.firestore, this._media)
      : super(
          collectionName: Project.collection,
          parse: Project.fromMap,
          orderField: 'order',
          searchField: 'title',
        );

  final MediaStorage _media;

  Future<String> addProject(Project project, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    return create({
      ...project.toMap(),
      'createdAt': timestamp,
      'updatedAt': timestamp,
    });
  }

  Future<void> saveProject(Project project, {DateTime? now}) {
    return update(project.id, {
      ...project.toMap(),
      'updatedAt': now ?? DateTime.now(),
    });
  }

  Future<String> uploadThumbnail({
    required String projectId,
    required Uint8List bytes,
    required String fileName,
  }) =>
      _media.uploadImage(path: 'projects/$projectId/thumbnail', bytes: bytes, fileName: fileName);

  Future<String> uploadGalleryImage({
    required String projectId,
    required Uint8List bytes,
    required String fileName,
  }) {
    final safe = MediaStorage.safeName(fileName.isEmpty ? 'image.jpg' : fileName);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return _media.uploadImage(
      path: 'projects/$projectId/gallery/${stamp}_$safe',
      bytes: bytes,
      fileName: fileName,
    );
  }

  Future<List<String>> removeFiles(List<String> urls) => _media.deleteUrls(urls);

  /// Deletes the document first, then the related Storage files.
  /// Returns the URLs that could not be removed (empty = full success).
  Future<List<String>> deleteProject(Project project) async {
    await delete(project.id);
    final urls = [project.thumbnail, ...project.images]
        .where((url) => url.trim().isNotEmpty)
        .toList();
    if (urls.isEmpty) return const [];
    return _media.deleteUrls(urls);
  }
}
