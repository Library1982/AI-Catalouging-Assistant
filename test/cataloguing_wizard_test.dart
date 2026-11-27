import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dpa_marc_app/cataloguing_wizard_panel.dart';
import 'package:dpa_marc_app/book_review_preview_pane.dart';

void main() {
  Widget wizard({
    int step = 0,
    int maxStep = 0,
    List<String> files = const [],
    bool hasRecord = false,
    bool approved = false,
    VoidCallback? next,
  }) {
    return MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: CataloguingWizardPanel(
        arabic: false, step: step, maxAvailableStep: maxStep,
        busy: false, filenames: files, hasMarcRecord: hasRecord,
        approved: approved, cartCount: 0,
        uploadFiles: () {}, removeFile: (_) {}, clearFiles: () {},
        generateMarc: () {}, generateSummary: () {},
        skipSummary: next ?? () {}, review: () {},
        addToCart: () {}, openCart: () {},
        goToStep: (_) {},
      ),
    )));
  }

  testWidgets('only first cataloguing step shows initially', (tester) async {
    await tester.pumpWidget(wizard());
    expect(find.byKey(const Key('cataloguing-wizard')), findsOneWidget);
    expect(find.text('Upload images or PDF'), findsOneWidget);
    expect(find.text('Generate record'), findsNothing);
  });

  testWidgets('summary step supports skip and continue', (tester) async {
    var skipped = false;
    await tester.pumpWidget(wizard(
        step: 2, maxStep: 3, hasRecord: true,
        files: const ['title.jpg'], next: () => skipped = true));
    await tester.tap(find.text('Skip and continue'));
    expect(skipped, isTrue);
  });

  testWidgets('final step requires approval to add to cart', (tester) async {
    await tester.pumpWidget(wizard(step: 4, maxStep: 4,
        files: const ['cover.jpg'], hasRecord: true));
    final add = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Finish — add book'));
    expect(add.onPressed, isNull);
  });

  testWidgets('preview reflects changes to title without changing MARC', (tester) async {
    final fields = <String, TextEditingController>{
      'field_245': TextEditingController(
          text: r'245 10 $a Original book title'),
      'field_100': TextEditingController(
          text: r'100 1# $a العبادي، أحمد عبد الزهرة محمد'),
      'field_300': TextEditingController(
          text: r'300 ## $a 180 pages'),
    };
    addTearDown(() {
      for (final c in fields.values) { c.dispose(); }
    });
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(
      width: 420, height: 600,
      child: SingleChildScrollView(child: BookReviewPreviewPane(
        arabic: false, controllers: fields,
      )),
    ))));
    expect(find.text('Original book title'), findsOneWidget);
    expect(find.text('أحمد عبد الزهرة محمد العبادي'), findsOneWidget);
    fields['field_245']!.text = r'245 10 $a Corrected book title';
    await tester.pump();
    expect(find.text('Corrected book title'), findsOneWidget);
    expect(find.text('Original book title'), findsNothing);
  });
}
