import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Human-readable MARC text for the catalogue display.
/// The original MARC authority headings and field values are never rewritten.
class MarcDisplayText {
  static String subfield(String? field, String code) {
    if (field == null || field.trim().isEmpty) return '';
    final firstLine = field.split('\n').first;
    final match = RegExp(
      '\\
      caseSensitive: false,
      dotAll: true,
      multiLine: false,
    ).firstMatch(firstLine);
    return match == null ? '' : _clean(match.group(1) ?? '');
  }

  static String _clean(String value) =>
      value.trim().replaceAll(RegExp(r'[\s/,:؛،.]+$'), '').trim();

  static String title(String? field) {
    final a = subfield(field, 'a');
    final b = subfield(field, 'b');
    if (a.isEmpty && b.isEmpty) return '';
    return [a, b].where((text) => text.isNotEmpty).join(' : ');
  }

  static String author(String? field) {
    final raw = subfield(field, 'a');
    if (raw.isEmpty) return '';
    final separator = raw.contains('،') ? '،' : (raw.contains(',') ? ',' : '');
    if (separator.isEmpty) return raw;
    final fragments = raw.split(separator).map((s) => s.trim()).toList();
    if (fragments.length != 2 ||
        fragments[0].isEmpty ||
        fragments[1].isEmpty) {
      return raw;
    }
    // Display only. Keep MARC 100/700 authority forms unchanged.
    return '${fragments[1]} ${fragments[0]}';
  }

  static String isbn(String? field) => subfield(field, 'a');
}

/// Prominent, continuously updating book-details panel on the MARC review page.
/// Reading the controllers makes edits to 245/100 visible before approval.
class MarcReviewTitlePanel extends StatelessWidget {
  final bool arabic;
  final TextEditingController titleController;
  final TextEditingController authorController;
  final TextEditingController isbnController;
  final Uint8List? previewImage;

  const MarcReviewTitlePanel({
    super.key,
    required this.arabic,
    required this.titleController,
    required this.authorController,
    required this.isbnController,
    this.previewImage,
  });

  String _tr(String en, String ar) => arabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [titleController, authorController, isbnController]),
      builder: (context, _) {
        final title = MarcDisplayText.title(titleController.text);
        final author = MarcDisplayText.author(authorController.text);
        final isbn = MarcDisplayText.isbn(isbnController.text);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5FF),
            border: Border.all(color: const Color(0xFFA5B4FC)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_stories_rounded,
                      color: Color(0xFF4338CA), size: 23),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _tr('BOOK TITLE SHOWCASE', 'لوحة عرض عنوان الكتاب'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF312E81),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: const Color(0xFFDBEAFE)),
                    child: Text(
                      _tr('Review in progress', 'قيد المراجعة'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 112,
                      width: 82,
                      child: previewImage == null
                          ? Container(
                              color: const Color(0xFFE0E7FF),
                              child: const Icon(Icons.menu_book_rounded,
                                  color: Color(0xFF3730A3), size: 38),
                            )
                          : Image.memory(
                              previewImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFE0E7FF),
                                child: const Icon(Icons.menu_book_rounded),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          title.isNotEmpty
                              ? title
                              : _tr('Title not identified',
                                  'العنوان غير محدد'),
                          style: const TextStyle(
                            fontSize: 23,
                            height: 1.25,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172554),
                          ),
                        ),
                        if (author.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SelectableText(author,
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 15,
                              )),
                        ],
                        if (isbn.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SelectableText('ISBN: $isbn',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                              )),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _tr(
                  'This panel updates instantly when you edit MARC 245, 100 or 020 below. Approve the record to add it to the catalogue showcase.',
                  'تتحدث هذه اللوحة مباشرة عند تعديل حقول 245 و100 و020 أدناه. اعتمد التسجيلة لإضافتها إلى لوحة الفهرسة.',
                ),
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
 + RegExp.escape(code) + r'\s*(.*?)(?=\s*\$[a-z0-9]|$)',
      caseSensitive: false,
      dotAll: true,
      multiLine: false,
    ).firstMatch(field);
    return match == null ? '' : _clean(match.group(1) ?? '');
  }

  static String _clean(String value) =>
      value.trim().replaceAll(RegExp(r'[\s/,:؛،.]+$'), '').trim();

  static String title(String? field) {
    final a = subfield(field, 'a');
    final b = subfield(field, 'b');
    if (a.isEmpty && b.isEmpty) return '';
    return [a, b].where((text) => text.isNotEmpty).join(' : ');
  }

  static String author(String? field) {
    final raw = subfield(field, 'a');
    if (raw.isEmpty) return '';
    final separator = raw.contains('،') ? '،' : (raw.contains(',') ? ',' : '');
    if (separator.isEmpty) return raw;
    final fragments = raw.split(separator).map((s) => s.trim()).toList();
    if (fragments.length != 2 ||
        fragments[0].isEmpty ||
        fragments[1].isEmpty) {
      return raw;
    }
    // Display only. Keep MARC 100/700 authority forms unchanged.
    return '${fragments[1]} ${fragments[0]}';
  }

  static String isbn(String? field) => subfield(field, 'a');
}

/// Prominent, continuously updating book-details panel on the MARC review page.
/// Reading the controllers makes edits to 245/100 visible before approval.
class MarcReviewTitlePanel extends StatelessWidget {
  final bool arabic;
  final TextEditingController titleController;
  final TextEditingController authorController;
  final TextEditingController isbnController;
  final Uint8List? previewImage;

  const MarcReviewTitlePanel({
    super.key,
    required this.arabic,
    required this.titleController,
    required this.authorController,
    required this.isbnController,
    this.previewImage,
  });

  String _tr(String en, String ar) => arabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [titleController, authorController, isbnController]),
      builder: (context, _) {
        final title = MarcDisplayText.title(titleController.text);
        final author = MarcDisplayText.author(authorController.text);
        final isbn = MarcDisplayText.isbn(isbnController.text);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5FF),
            border: Border.all(color: const Color(0xFFA5B4FC)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_stories_rounded,
                      color: Color(0xFF4338CA), size: 23),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _tr('BOOK TITLE SHOWCASE', 'لوحة عرض عنوان الكتاب'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF312E81),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: const Color(0xFFDBEAFE)),
                    child: Text(
                      _tr('Review in progress', 'قيد المراجعة'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 112,
                      width: 82,
                      child: previewImage == null
                          ? Container(
                              color: const Color(0xFFE0E7FF),
                              child: const Icon(Icons.menu_book_rounded,
                                  color: Color(0xFF3730A3), size: 38),
                            )
                          : Image.memory(
                              previewImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFE0E7FF),
                                child: const Icon(Icons.menu_book_rounded),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          title.isNotEmpty
                              ? title
                              : _tr('Title not identified',
                                  'العنوان غير محدد'),
                          style: const TextStyle(
                            fontSize: 23,
                            height: 1.25,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172554),
                          ),
                        ),
                        if (author.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SelectableText(author,
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 15,
                              )),
                        ],
                        if (isbn.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SelectableText('ISBN: $isbn',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                              )),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _tr(
                  'This panel updates instantly when you edit MARC 245, 100 or 020 below. Approve the record to add it to the catalogue showcase.',
                  'تتحدث هذه اللوحة مباشرة عند تعديل حقول 245 و100 و020 أدناه. اعتمد التسجيلة لإضافتها إلى لوحة الفهرسة.',
                ),
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
