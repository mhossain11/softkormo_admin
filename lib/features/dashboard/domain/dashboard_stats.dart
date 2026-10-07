/// Aggregated dashboard numbers.
class DashboardStats {
  const DashboardStats({
    required this.totalContacts,
    required this.newContacts,
    required this.projects,
    required this.services,
    required this.packages,
    required this.testimonials,
  });

  final int totalContacts;
  final int newContacts;
  final int projects;
  final int services;
  final int packages;
  final int testimonials;
}

/// Labelled number used by dashboard charts.
class LabelCount {
  const LabelCount({required this.label, required this.count});

  final String label;
  final int count;
}
