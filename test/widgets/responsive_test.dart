import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softkormoadmin/core/theme/app_breakpoints.dart';
import 'package:softkormoadmin/core/widgets/admin_page_header.dart';
import 'package:softkormoadmin/core/widgets/app_button.dart';
import 'package:softkormoadmin/core/widgets/app_pagination.dart';
import 'package:softkormoadmin/core/widgets/app_text_field.dart';
import 'package:softkormoadmin/core/widgets/form_section.dart';
import 'package:softkormoadmin/core/widgets/list_toolbar.dart';
import 'package:softkormoadmin/core/widgets/responsive.dart';
import 'package:softkormoadmin/core/widgets/status_chip.dart';

/// Representative samples of every layout that must never overflow.
class _HeaderSample extends StatelessWidget {
  const _HeaderSample();

  @override
  Widget build(BuildContext context) {
    return AdminPageHeader(
      title: 'Projects',
      subtitle: 'Everything visitors see on the website',
      showBack: true,
      onBack: () {},
      actions: [
        AppButton(label: 'Export', variant: AppButtonVariant.outline, onPressed: () {}),
        AppButton(label: 'New', icon: Icons.add_rounded, onPressed: () {}),
      ],
    );
  }
}

class _ToolbarSample extends StatelessWidget {
  const _ToolbarSample(this.searchController);

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return ListToolbar(
      searchController: searchController,
      onSearchChanged: (_) {},
      searchHint: 'Search projects...',
      hasActiveFilters: true,
      onClearFilters: () {},
      filter: StatusChip.of('published', icon: Icons.public_rounded),
    );
  }
}

class _FormSample extends StatelessWidget {
  const _FormSample();

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Basics',
      description: 'Shown on the public website',
      children: [
        FormRow(children: const [
          AppTextField(label: 'Title', required: true),
          AppTextField(label: 'Slug'),
        ]),
        FormRow(children: const [
          AppTextField(label: 'Client', hint: 'ACME'),
          AppTextField(label: 'Year', keyboardType: TextInputType.number),
        ]),
        FormActions(
          onSave: () {},
          onCancel: () {},
          deleteAction: () {},
          saveLabel: 'Save project',
        ),
      ],
    );
  }
}

class _PaginationSample extends StatelessWidget {
  const _PaginationSample();

  @override
  Widget build(BuildContext context) {
    return AppPagination(
      currentPage: 2,
      totalPages: 5,
      hasPrevious: true,
      hasNext: true,
      onPrevious: () {},
      onNext: () {},
      totalItems: 87,
      pageSize: 20,
    );
  }
}

class _BreakpointSample extends StatelessWidget {
  const _BreakpointSample(this.report);

  final void Function(String variant, bool mobile, bool tablet, bool desktop, bool large) report;

  @override
  Widget build(BuildContext context) {
    report(
      Responsive.value(context, mobile: 'mobile', tablet: 'tablet', desktop: 'desktop'),
      Responsive.isMobile(context),
      Responsive.isTablet(context),
      Responsive.isDesktop(context),
      Responsive.isLargeDesktop(context),
    );
    return const SizedBox.shrink();
  }
}

class _VariantSample extends StatelessWidget {
  const _VariantSample();

  @override
  Widget build(BuildContext context) {
    return const ResponsiveBuilder(
      mobile: _mobile,
      tablet: _tablet,
      desktop: _desktop,
    );
  }
}

Widget _mobile(BuildContext context) => const Text('mobile-variant');

Widget _tablet(BuildContext context) => const Text('tablet-variant');

Widget _desktop(BuildContext context) => const Text('desktop-variant');

void main() {
  const widths = [360.0, 768.0, 1024.0, 1440.0, 1920.0];

  Future<void> pumpAt(WidgetTester tester, double width, Widget child) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    await tester.pump();
  }

  testWidgets('breakpoint constants stay in sync with the documented ranges',
      (WidgetTester tester) async {
    expect(AppBreakpoints.mobile, 768);
    expect(AppBreakpoints.tablet, 1024);
    expect(AppBreakpoints.desktop, 1440);
  });

  group('Responsive', () {
    testWidgets('reports the correct variant for every supported width',
        (WidgetTester tester) async {
      for (final width in widths) {
        String variant = '';
        var mobile = false;
        var tablet = false;
        var desktop = false;
        var large = false;

        await pumpAt(
          tester,
          width,
          _BreakpointSample((v, m, t, d, l) {
            variant = v;
            mobile = m;
            tablet = t;
            desktop = d;
            large = l;
          }),
        );
        expect(tester.takeException(), isNull, reason: 'layout at ${width.toInt()}px');

        if (width < AppBreakpoints.mobile) {
          expect(variant, 'mobile', reason: 'width ${width.toInt()}');
          expect(mobile, isTrue);
        } else if (width < AppBreakpoints.tablet) {
          expect(variant, 'tablet', reason: 'width ${width.toInt()}');
          expect(tablet, isTrue);
        } else {
          expect(variant, 'desktop', reason: 'width ${width.toInt()}');
          expect(desktop, isTrue);
        }
        expect(large, width >= AppBreakpoints.desktop);
        expect(mobile && tablet, isFalse);
      }
    });

    testWidgets('ResponsiveBuilder builds exactly one variant',
        (WidgetTester tester) async {
      await pumpAt(tester, 360, const _VariantSample());
      expect(find.text('mobile-variant'), findsOneWidget);
      expect(find.text('tablet-variant'), findsNothing);
      expect(find.text('desktop-variant'), findsNothing);

      await pumpAt(tester, 768, const _VariantSample());
      expect(find.text('tablet-variant'), findsOneWidget);
      expect(find.text('mobile-variant'), findsNothing);

      await pumpAt(tester, 1024, const _VariantSample());
      expect(find.text('desktop-variant'), findsOneWidget);
      expect(find.text('tablet-variant'), findsNothing);

      await pumpAt(tester, 1920, const _VariantSample());
      expect(find.text('desktop-variant'), findsOneWidget);
    });
  });

  group('layout at 360 / 768 / 1024 / 1440 / 1920', () {
    testWidgets('AdminPageHeader never overflows', (WidgetTester tester) async {
      for (final width in widths) {
        await pumpAt(tester, width, const _HeaderSample());
        expect(tester.takeException(), isNull, reason: 'header at ${width.toInt()}px');
        expect(find.text('Projects'), findsOneWidget);
      }
    });

    testWidgets('ListToolbar never overflows', (WidgetTester tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      for (final width in widths) {
        await pumpAt(tester, width, _ToolbarSample(controller));
        expect(tester.takeException(), isNull, reason: 'toolbar at ${width.toInt()}px');
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Clear'), findsOneWidget);
      }
    });

    testWidgets('FormRow and FormActions never overflow', (WidgetTester tester) async {
      for (final width in widths) {
        await pumpAt(tester, width, const _FormSample());
        expect(tester.takeException(), isNull, reason: 'form at ${width.toInt()}px');
        expect(find.text('Basics'), findsOneWidget);
        expect(find.text('Save project'), findsOneWidget);
      }
    });

    testWidgets('AppPagination never overflows', (WidgetTester tester) async {
      for (final width in widths) {
        await pumpAt(tester, width, const _PaginationSample());
        expect(tester.takeException(), isNull, reason: 'pagination at ${width.toInt()}px');
        expect(find.text('Showing 21–40 of 87'), findsOneWidget);
      }
    });
  });
}
