import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dpa_marc_app/catalogue_showcase_panel.dart';

void main() {
  Widget showcase({
    List<String> files = const [],
    String provisionalTitle = '',
    Map<String, dynamic>? record,
    bool approved = false,
    bool analyzing = false,
    bool arabic = false,
    List<Map<String, dynamic>> completed = const [],
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CatalogueShowcasePanel(
            arabic: arabic,
            uploadedNames: files,
            previewImage: null,
            previewTitle: provisionalTitle,
            onPreviewTitleChanged: (_) {},
            currentRecord: record,
            isAnalyzing: analyzing,
            isApproved: approved,
            completedRecords: completed,
            recordTitle: (r) => r['field_245']?.toString() ?? '',
            recordAuthor: (r) => r['field_100']?.toString() ?? '',
          ),
        ),
      ),
    );
  }

  test('parses all supplied bibliographic details, not MARC labels', () {
    final book = BookDisplayData.fromRecord({
      'field_245': r'245 10 $a The Book of Knowledge : $b a short guide / $c Yasar Jarrar.',
      'field_100': r'100 1# $a Jarrar, Yasar.',
      'field_020': [r'020 ## $a 9781785961106', r'020 ## $a 1785961101'],
      'field_264': r'264 #1 $a London : $b Example Press, $c 2025.',
      'field_300': r'300 ## $a 260 pages : $b illustrations ; $c 24 cm.',
      'field_650': [r'650 #0 $a Leadership.', r'650 #0 $a Management.'],
      'field_520': r'520 ## $a A guide to leadership.',
    });
    expect(book.title, 'The Book of Knowledge');
    expect(book.subtitle, 'a short guide');
    expect(book.author, 'Yasar Jarrar');
    expect(book.sections.any((s) => s.en == 'Publication details'), isTrue);
    final allValues = book.sections.expand((s) => s.rows)
        .expand((r) => r.values).join(' | ');
    expect(allValues, contains('Example Press'));
    expect(allValues, contains('9781785961106'));
    expect(allValues, contains('Leadership'));
    expect(allValues, contains('A guide to leadership'));
    expect(allValues, isNot(contains(r'$a')));
    expect(allValues, isNot(contains('650 #0')));
  });

  testWidgets('shows animated loading while analysing', (tester) async {
    await tester.pumpWidget(showcase(files: const ['front-cover.jpg'],
        analyzing: true));
    expect(find.byKey(const Key('showcase-loading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('shows upload without inventing book title', (tester) async {
    await tester.pumpWidget(showcase(files: const ['front-cover.jpg']));
    expect(find.text('Title awaiting identification'), findsOneWidget);
    expect(find.text('Book uploaded'), findsOneWidget);
  });

  testWidgets('shows readable title author and sections', (tester) async {
    await tester.pumpWidget(showcase(
      files: const ['cover.jpg'],
      record: {
        'field_245': r'245 10 $a The Book of Knowledge / $c Yasar Jarrar.',
        'field_100': r'100 1# $a Jarrar, Yasar.',
        'field_264': r'264 #1 $a London : $b Example Press, $c 2025.',
      },
    ));
    expect(find.text('The Book of Knowledge'), findsWidgets);
    expect(find.text('Yasar Jarrar'), findsWidgets);
    expect(find.text('Publication details'), findsOneWidget);
    expect(find.text('Example Press'), findsOneWidget);
    expect(find.text('Book details ready'), findsOneWidget);
  });

  testWidgets('keeps catalogued books visible in session', (tester) async {
    await tester.pumpWidget(showcase(
      completed: const [{
        'field_245': r'245 10 $a Completed Book / $c Scholar.',
        'field_100': r'100 1# $a Scholar.',
      }],
    ));
    expect(find.text('Completed Book'), findsOneWidget);
  });

  testWidgets('shows approved state for current book', (tester) async {
    await tester.pumpWidget(showcase(
      files: const ['title.pdf'],
      record: {'field_245': r'245 10 $a Approved Title'},
      approved: true,
    ));
    expect(find.text('Approved Title'), findsWidgets);
    expect(find.text('Approved'), findsOneWidget);
  });

  testWidgets('supports right-to-left Arabic display', (tester) async {
    await tester.pumpWidget(showcase(
      files: const ['title.jpg'],
      arabic: true,
      record: {
        'field_245': r'245 10 $a كتاب القيادة',
        'field_100': r'100 1# $a العبادي، أحمد عبد الزهرة محمد',
      },
    ));
    expect(find.text('كتاب القيادة'), findsWidgets);
    expect(find.text('أحمد عبد الزهرة محمد العبادي'), findsWidgets);
    expect(find.text('استعراض بيانات الكتاب'), findsOneWidget);
  });
}
