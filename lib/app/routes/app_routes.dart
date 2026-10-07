/// Application route names.
///
/// Root routes: [login] and [admin]. Everything else is rendered inside the
/// admin shell's own navigator, so the shell is never rebuilt while
/// navigating between CMS pages.
class Routes {
  const Routes._();

  static const String login = '/login';
  static const String admin = '/admin';

  static const String dashboard = '/dashboard';
  static const String contacts = '/contacts';

  static const String projects = '/projects';
  static const String projectNew = '/projects/new';
  static const String projectEdit = '/projects/edit';

  static const String services = '/services';
  static const String serviceNew = '/services/new';
  static const String serviceEdit = '/services/edit';

  static const String packages = '/packages';
  static const String packageNew = '/packages/new';
  static const String packageEdit = '/packages/edit';

  static const String testimonials = '/testimonials';
  static const String testimonialNew = '/testimonials/new';
  static const String testimonialEdit = '/testimonials/edit';

  static const String settings = '/settings';
}
