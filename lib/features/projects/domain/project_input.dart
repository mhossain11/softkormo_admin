import '../../../core/data/pending_image.dart';
import 'project.dart';

/// Everything the controller needs to create or update a project.
class ProjectInput {
  const ProjectInput({
    required this.project,
    this.thumbnail,
    this.gallery = const [],
    this.removedUrls = const [],
  });

  /// Draft project. `id` is empty when creating.
  final Project project;

  /// Replacement thumbnail (not yet uploaded).
  final PendingImage? thumbnail;

  /// New gallery images (not yet uploaded).
  final List<PendingImage> gallery;

  /// Existing storage URLs the admin removed - deleted after a successful save.
  final List<String> removedUrls;
}
