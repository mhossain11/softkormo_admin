import 'package:get/get.dart';

import '../../../core/data/pending_image.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../data/settings_repository.dart';
import '../domain/site_settings.dart';

/// Loads and saves the single `settings/site` document.
class SettingsController extends GetxController {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  final Rxn<SiteSettings> settings = Rxn<SiteSettings>();
  final RxBool loading = false.obs;
  final RxBool saving = false.obs;
  final RxnString errorMessage = RxnString();

  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> ensureLoaded({bool force = false}) async {
    if (_loaded && !force) return;
    loading.value = true;
    errorMessage.value = null;
    try {
      settings.value = await _repository.fetch();
      _loaded = true;
    } catch (e) {
      errorMessage.value = ErrorMessages.describe(e);
    } finally {
      loading.value = false;
    }
  }

  Future<bool> save(SiteSettings value, {PendingImage? logo, String? removedLogo}) async {
    if (saving.value) return false;
    saving.value = true;
    String? uploadedUrl;
    try {
      var next = value;
      if (logo != null) {
        uploadedUrl = await _repository.uploadLogo(bytes: logo.bytes, fileName: logo.fileName);
        next = _copyWithLogo(next, uploadedUrl);
      }
      await _repository.save(next);
      settings.value = next;

      if (removedLogo != null && removedLogo.isNotEmpty) {
        final failed = await _repository.removeLogo(removedLogo);
        if (failed.isNotEmpty) {
          AppSnackbar.warning('Settings saved, but the old logo could not be removed.');
          return true;
        }
      }
      AppSnackbar.success('Settings saved');
      return true;
    } catch (e) {
      if (uploadedUrl != null) {
        try {
          await _repository.removeLogo(uploadedUrl);
        } catch (_) {}
      }
      AppSnackbar.error(ErrorMessages.describe(e));
      return false;
    } finally {
      saving.value = false;
    }
  }

  SiteSettings _copyWithLogo(SiteSettings value, String url) => SiteSettings(
        companyName: value.companyName,
        tagline: value.tagline,
        email: value.email,
        phone: value.phone,
        address: value.address,
        facebook: value.facebook,
        linkedin: value.linkedin,
        github: value.github,
        youtube: value.youtube,
        logoUrl: url,
        updatedAt: value.updatedAt,
      );
}
