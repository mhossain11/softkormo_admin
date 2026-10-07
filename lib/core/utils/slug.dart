/// URL / slug helpers used by CMS forms.
class SlugHelper {
  const SlugHelper._();

  /// Builds a URL friendly slug from a title.
  static String from(String title) {
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-');
    return slug;
  }
}
