import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dpa_marc_app/catalogue_showcase_panel.dart';

void main() {
  Widget showcase({
    List<String> files = const [],
    String provisionalTitle = '',
    Map<String, dynamic>? record,
    bool approved = false,
    List<Map<String, dynamic>> completed = const [],
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CatalogueShowcasePanel(
            arabic: false,
            uploadedNames: files,
            previewImage: null,
            previewTitle: provisionalTitle,
            onPreviewTitleChanged: (_) {},
            currentRecord: record,
            isAnalyzing: false,
            isApproved: approved,
            completedRecords: completed,
            recordTitle: (r) => r['title']?.toString() ?? 'Untitled MARC record',
            recordAuthor: (r) => r['author']?.toString() ?? '',
          ),
        ),
      ),
    );
  }

  testWidgets('shows the upload immediately without inventing a title', (tester) async {
    await tester.pumpWidget(
      showcase(files: const ['front-cover.jpg']),
    );
    expect(find.text('Title awaiting identification'), findsOneWidget);
    expect(find.text('front-cover.jpg'), findsOneWidget);
    expect(find.text('Uploaded'), findsOneWidget);
  });

  testWidgets('displays MARC title and author after generation', (tester) async {
    await tester.pumpWidget(showcase(
      files: const ['front-cover.jpg'],
      provisionalTitle: 'Provisional',
      record: {'title': 'The Book of Knowledge', 'author': 'A. Author'},
    ));
    expect(find.text('The Book of Knowledge'), findsOneWidget);
    expect(find.text('A. Author'), findsOneWidget);
    expect(find.text('MARC generated'), findsOneWidget);
    expect(find.text('Provisional'), findsNothing);
  });

  testWidgets('keeps catalogued books visible in the next session', (tester) async {
    await tester.pumpWidget(showcase(
      completed: const [{'title': 'Completed Book', 'author': 'Scholar'}],
    ));
    expect(find.text('Completed Book'), findsOneWidget);
    expect(find.text('Catalogued'), findsOneWidget);
  });

  testWidgets('shows approval state for current record', (tester) async {
    await tester.pumpWidget(showcase(
      files: const ['title.pdf'],
      record: {'title': 'Approved Title', 'author': 'Scholar'},
      approved: true,
    ));
    expect(find.text('Approved Title'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
  });
}
