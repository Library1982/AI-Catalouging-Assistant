import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dpa_marc_app/marc_review_title_panel.dart';

void main() {
  test('reads human friendly title and author from MARC fields', () {
    expect(
      MarcDisplayText.title(r'245 10 $a Artificial intelligence : $b a guide / $c Yasir Jarrar.'),
      'Artificial intelligence : a guide',
    );
    expect(MarcDisplayText.author(r'100 1# $a العبادي، أحمد عبد الزهرة محمد.'),
        'أحمد عبد الزهرة محمد العبادي');
    expect(MarcDisplayText.author(r'100 1# $a Jarrar, Yasar.'),
        'Yasar Jarrar');
  });

  test('takes first ISBN when multiple MARC 020 entries are present', () {
    expect(
      MarcDisplayText.isbn('020 ## \\$a 9781785961106\\n020 ## \\$a 1785961101'),
      '9781785961106',
    );
  });

  testWidgets('editing MARC title updates review panel instantly', (tester) async {
    final title = TextEditingController(text: r'245 10 $a First title / $c Author.');
    final author = TextEditingController(text: r'100 1# $a Scholar, Jane.');
    final isbn = TextEditingController(text: r'020 ## $a 9781234567897');
    addTearDown(() {
      title.dispose();
      author.dispose();
      isbn.dispose();
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MarcReviewTitlePanel(
          arabic: false,
          titleController: title,
          authorController: author,
          isbnController: isbn,
        ),
      ),
    ));
    expect(find.text('First title'), findsOneWidget);
    expect(find.text('Jane Scholar'), findsOneWidget);
    title.text = r'245 10 $a Updated book title / $c Author.';
    await tester.pump();
    expect(find.text('Updated book title'), findsOneWidget);
    expect(find.text('First title'), findsNothing);
  });
}
