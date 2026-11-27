import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Read-only display values. The cataloguing record is never modified.
class BookDetailRow {
  final String en;
  final String ar;
  final List<String> values;
  const BookDetailRow(this.en, this.ar, this.values);
}

class BookDetailSection {
  final String en;
  final String ar;
  final IconData icon;
  final List<BookDetailRow> rows;
  const BookDetailSection(this.en, this.ar, this.icon, this.rows);
}

class BookDisplayData {
  final String title;
  final String subtitle;
  final String author;
  final String responsibility;
  final List<BookDetailSection> sections;

  const BookDisplayData({
    required this.title,
    required this.subtitle,
    required this.author,
    required this.responsibility,
    required this.sections,
  });

  static String _clean(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceFirst(RegExp(r'[\s/,:;،؛]+$'), '')
        .trim();
  }

  static List<Map<String, String>> fields(Map<String, dynamic> record, String tag) {
    final raw = record['field_' + tag];
    if (raw == null) return [];
    final values = raw is List ? raw : [raw];
    final result = <Map<String, String>>[];
    for (final value in values) {
      for (final line in value.toString().split('\n')) {
        if (line.trim().isEmpty) continue;
        final matches = RegExp(r'[$‡]([a-z0-9])', caseSensitive: false)
            .allMatches(line)
            .toList();
        final data = <String, String>{};
        if (matches.isEmpty) {
          final plain = _clean(line.replaceFirst(
              RegExp(r'^\s*\d{3}\s+[\d#\\]{1,2}\s*'), ''));
          if (plain.isNotEmpty) data['a'] = plain;
        } else {
          for (var i = 0; i < matches.length; i++) {
            final current = matches[i];
            final until = i + 1 < matches.length ? matches[i + 1].start : line.length;
            final code = current.group(1)!.toLowerCase();
            final text = _clean(line.substring(current.end, until));
            if (text.isNotEmpty) {
              data[code] = data.containsKey(code)
                  ? data[code]! + ' ' + text
                  : text;
            }
          }
        }
        if (data.isNotEmpty) result.add(data);
      }
    }
    return result;
  }

  static String _name(String value) {
    final cleaned = _clean(value).replaceFirst(RegExp(r'[.]$'), '');
    final separator = cleaned.contains('،') ? '،' : (cleaned.contains(',') ? ',' : '');
    if (separator.isEmpty) return cleaned;
    final segments = cleaned.split(separator).map((x) => x.trim()).toList();
    if (segments.length != 2 || segments.any((x) => x.isEmpty)) return cleaned;
    return segments[1] + ' ' + segments[0];
  }

  static List<String> values(
    Map<String, dynamic> record,
    String tag,
    List<String> codes, {
    bool people = false,
    String separator = ' · ',
  }) {
    return fields(record, tag).map((field) {
      final items = <String>[];
      for (final code in codes) {
        final value = field[code];
        if (value == null || value.isEmpty) continue;
        items.add(people && code == 'a' ? _name(value) : value);
      }
      return items.join(separator);
    }).where((text) => text.isNotEmpty).toList();
  }

  static String first(Map<String, dynamic> record, String tag, String code) {
    final list = values(record, tag, [code]);
    return list.isEmpty ? '' : list.first;
  }

  static BookDisplayData fromRecord(Map<String, dynamic> record) {
    final title = first(record, '245', 'a');
    final subtitle = first(record, '245', 'b');
    final authorList = values(record, '100', ['a', 'd', 'e'], people: true);
    final corpList = values(record, '110', ['a', 'b']);
    final author = authorList.isNotEmpty ? authorList.first
        : (corpList.isNotEmpty ? corpList.first : '');
    final responsibility = first(record, '245', 'c');
    final publicationTag = fields(record, '264').isNotEmpty ? '264' : '260';
    final sections = <BookDetailSection>[];

    BookDetailRow? row(String en, String ar, List<String> values) {
      final distinct = values.where((v) => v.trim().isNotEmpty).toSet().toList();
      if (distinct.isEmpty) return null;
      return BookDetailRow(en, ar, distinct);
    }

    void section(String en, String ar, IconData icon, List<BookDetailRow?> potential) {
      final rows = potential.whereType<BookDetailRow>().toList();
      if (rows.isNotEmpty) sections.add(BookDetailSection(en, ar, icon, rows));
    }

    section('About this book', 'عن الكتاب', Icons.menu_book_outlined, [
      row('Full title', 'العنوان الكامل',
          [title, subtitle].where((v) => v.isNotEmpty).toList()),
      row('Main author', 'المؤلف الرئيسي', authorList),
      row('Institutional author', 'المؤلف المؤسسي', corpList),
      row('Statement of responsibility', 'بيان المسؤولية',
          values(record, '245', ['c'])),
      row('Other authors and contributors', 'مؤلفون ومساهمون آخرون',
          values(record, '700', ['a', 'd', 'e'], people: true)),
      row('Contributing organizations', 'الهيئات المشاركة',
          values(record, '710', ['a', 'b', 'e'])),
      row('Edition', 'الطبعة', values(record, '250', ['a', 'b'])),
      row('Series and volume', 'السلسلة والجزء',
          values(record, '490', ['a', 'v'])),
      row('Thesis or dissertation', 'الرسالة أو الأطروحة',
          values(record, '502', ['a'])),
    ]);

    section('Publication details', 'بيانات النشر', Icons.apartment_outlined, [
      row('Place of publication', 'مكان النشر', values(record, publicationTag, ['a'])),
      row('Publisher', 'الناشر', values(record, publicationTag, ['b'])),
      row('Publication year', 'سنة النشر', values(record, publicationTag, ['c'])),
      row('Language', 'اللغة', values(record, '041', ['a', 'd'])),
      row('ISBN', 'الرقم الدولي للكتاب', values(record, '020', ['a'])),
      row('Other ISBN details', 'تفاصيل أخرى للرقم الدولي',
          values(record, '020', ['q', 'c'])),
    ]);

    section('Physical description', 'الوصف المادي', Icons.auto_stories_outlined, [
      row('Pages or volumes', 'الصفحات أو المجلدات', values(record, '300', ['a'])),
      row('Illustrations', 'الإيضاحات', values(record, '300', ['b'])),
      row('Size', 'الحجم', values(record, '300', ['c'])),
      row('Accompanying material', 'المواد المصاحبة', values(record, '300', ['e'])),
    ]);

    section('Classification and location', 'التصنيف والموقع',
        Icons.library_books_outlined, [
      row('Dewey classification', 'تصنيف ديوي العشري', values(record, '082', ['a', 'b'])),
      row('Library of Congress classification', 'تصنيف مكتبة الكونغرس',
          values(record, '050', ['a', 'b'])),
      row('Library call number', 'رقم الاستدعاء',
          values(record, '949', ['a', 'b', 'c'])),
    ]);

    section('Subjects and discovery', 'الموضوعات والاكتشاف',
        Icons.sell_outlined, [
      row('Subject headings', 'رؤوس الموضوعات',
          values(record, '650', ['a', 'x', 'y', 'z', 'v'], separator: ' — ')),
      row('People as subjects', 'الأشخاص كموضوعات',
          values(record, '600', ['a', 'x', 'y', 'z', 'v'], separator: ' — ')),
      row('Organizations as subjects', 'الهيئات كموضوعات',
          values(record, '610', ['a', 'x', 'y', 'z', 'v'], separator: ' — ')),
      row('Geographical subjects', 'الموضوعات الجغرافية',
          values(record, '651', ['a', 'x', 'y', 'z', 'v'], separator: ' — ')),
    ]);

    section('Summary and contents', 'الملخص والمحتويات',
        Icons.summarize_outlined, [
      row('Summary or abstract', 'الملخص أو المستخلص',
          values(record, '520', ['a', 'b'])),
      row('Table of contents', 'جدول المحتويات',
          values(record, '505', ['a', 't', 'r', 'g'])),
    ]);

    section('Notes and access', 'الملاحظات والوصول',
        Icons.notes_outlined, [
      row('General notes', 'ملاحظات عامة', values(record, '500', ['a'])),
      row('Bibliographical references', 'المراجع الببليوجرافية',
          values(record, '504', ['a'])),
      row('Online access', 'الوصول الإلكتروني',
          values(record, '856', ['y', 'u', 'z'])),
    ]);

    final custom = record['custom_fields'];
    if (custom is List) {
      final extra = <String>[];
      for (final item in custom) {
        if (item is! Map) continue;
        final text = item['value']?.toString() ?? '';
        if (text.trim().isEmpty) continue;
        final pseudo = <String, dynamic>{'field_999': text};
        final words = values(pseudo, '999', ['a', 'b', 'c', 'd', 'e', 't', 'u', 'x', 'y', 'z']);
        extra.addAll(words.isNotEmpty ? words : [text.replaceAll(
            RegExp(r'[$‡][a-z0-9]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim()]);
      }
      section('Additional book information', 'بيانات إضافية عن الكتاب',
          Icons.info_outline, [
        row('Other information', 'معلومات أخرى', extra),
      ]);
    }

    return BookDisplayData(
      title: title,
      subtitle: subtitle,
      author: author,
      responsibility: responsibility,
      sections: sections,
    );
  }
}

class CatalogueShowcasePanel extends StatefulWidget {
  final bool arabic;
  final List<String> uploadedNames;
  final Uint8List? previewImage;
  final String previewTitle;
  final ValueChanged<String> onPreviewTitleChanged;
  final Map<String, dynamic>? currentRecord;
  final bool isAnalyzing;
  final bool isApproved;
  final List<Map<String, dynamic>> completedRecords;
  final String Function(Map<String, dynamic>) recordTitle;
  final String Function(Map<String, dynamic>) recordAuthor;

  const CatalogueShowcasePanel({
    super.key,
    required this.arabic,
    required this.uploadedNames,
    required this.previewImage,
    required this.previewTitle,
    required this.onPreviewTitleChanged,
    required this.currentRecord,
    required this.isAnalyzing,
    required this.isApproved,
    required this.completedRecords,
    required this.recordTitle,
    required this.recordAuthor,
  });

  @override
  State<CatalogueShowcasePanel> createState() => _CatalogueShowcasePanelState();
}

class _CatalogueShowcasePanelState extends State<CatalogueShowcasePanel> {
  String _tr(String en, String ar) => widget.arabic ? ar : en;
  bool get _hasUpload => widget.uploadedNames.isNotEmpty;

  Widget _chip(String text, {Color background = const Color(0xFFEFF2FC),
      Color foreground = const Color(0xFF334155), IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, color: foreground, size: 16),
          const SizedBox(width: 6),
        ],
        Text(text, style: TextStyle(color: foreground,
            fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }

  Widget _cover({double width = 180, double height = 238}) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(color: Color(0x241E1B4B),
              blurRadius: 22, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: width, height: height,
          child: widget.previewImage == null
              ? Container(
                  color: const Color(0xFFCBD5FF),
                  child: const Icon(Icons.auto_stories_rounded,
                      color: Color(0xFF3730A3), size: 76),
                )
              : Image.memory(widget.previewImage!, fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFCBD5FF),
                    child: const Icon(Icons.menu_book_outlined, size: 64),
                  )),
        ),
      ),
    );
  }

  Widget _loadingWidget() {
    return Container(
      key: const Key('showcase-loading'),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 610),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(children: [
        const SizedBox(height: 28, width: 28,
            child: CircularProgressIndicator(strokeWidth: 3)),
        const SizedBox(height: 12),
        Text(_tr('AI is reading and cataloguing your book',
                    'الذكاء الاصطناعي يقرأ كتابك ويفهرسه'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800,
                color: Color(0xFF4C1D95), fontSize: 16)),
        const SizedBox(height: 14),
        const LinearProgressIndicator(minHeight: 6),
        const SizedBox(height: 9),
        Text(_tr('Preparing book details. This animation does not represent a percentage.',
            'جارٍ تجهيز بيانات الكتاب. مؤشر التحميل لا يمثل نسبة مئوية.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6D28D9), fontSize: 12)),
      ]),
    );
  }

  Widget _hero(BookDisplayData? book) {
    final title = book?.title.isNotEmpty == true
        ? book!.title : (widget.previewTitle.trim().isNotEmpty
            ? widget.previewTitle.trim() :
            _tr('Title awaiting identification', 'العنوان بانتظار التعرّف عليه'));
    final state = widget.isAnalyzing
        ? _tr('Analysing your book', 'جارٍ تحليل الكتاب')
        : widget.isApproved
            ? _tr('Approved', 'معتمد')
            : book != null
                ? _tr('Book details ready', 'بيانات الكتاب جاهزة')
                : _hasUpload
                    ? _tr('Book uploaded', 'تم رفع الكتاب')
                    : _tr('Ready to begin', 'جاهز للبدء');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 29),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F6FF), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(children: [
        _chip(_tr('BOOK TITLE PAGE', 'صفحة عنوان الكتاب'),
            icon: Icons.auto_stories_rounded,
            background: const Color(0xFFE0E7FF),
            foreground: const Color(0xFF312E81)),
        const SizedBox(height: 23),
        Center(child: _cover()),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SelectableText(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, height: 1.28,
                  fontWeight: FontWeight.w900, color: Color(0xFF172554))),
        ),
        if (book != null && book.subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          SelectableText(book.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20,
                  color: Color(0xFF475569), height: 1.35)),
        ],
        if (book != null && book.author.isNotEmpty) ...[
          const SizedBox(height: 12),
          SelectableText(book.author,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19,
                  color: Color(0xFF334155), fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 16),
        Wrap(alignment: WrapAlignment.center, spacing: 9, runSpacing: 9, children: [
          _chip(state,
              icon: widget.isAnalyzing ? Icons.hourglass_top_rounded :
                  book != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
              background: widget.isApproved
                  ? const Color(0xFFDCFCE7) : const Color(0xFFEDE9FE),
              foreground: widget.isApproved
                  ? const Color(0xFF166534) : const Color(0xFF5B21B6)),
          if (_hasUpload) _chip(_tr(
            widget.uploadedNames.length.toString() + ' source file(s)',
            'عدد الملفات: ' + widget.uploadedNames.length.toString())),
          _chip(_tr(widget.completedRecords.length.toString() + ' completed',
              widget.completedRecords.length.toString() + ' مكتمل')),
        ]),
        if (widget.isAnalyzing) ...[
          const SizedBox(height: 24),
          _loadingWidget(),
        ] else if (_hasUpload && book == null) ...[
          const SizedBox(height: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: TextFormField(
              key: ValueKey('showcase-title-' + widget.uploadedNames.first),
              initialValue: widget.previewTitle,
              onChanged: widget.onPreviewTitleChanged,
              decoration: InputDecoration(
                labelText: _tr('Optional display title before analysis',
                    'عنوان مؤقت للعرض قبل التحليل (اختياري)'),
                prefixIcon: const Icon(Icons.edit_outlined),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ] else if (!_hasUpload && book == null) ...[
          const SizedBox(height: 18),
          Text(_tr('Upload a cover or title page to start the book showcase.',
                      'ارفع غلاف الكتاب أو صفحة العنوان لبدء العرض.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 15)),
        ],
      ]),
    );
  }

  Widget _detailRow(BookDetailRow row) {
    final title = _tr(row.en, row.ar);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Color(0xFF64748B),
                  fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          for (var i = 0; i < row.values.length; i++) ...[
            SelectableText(row.values[i],
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                )),
            if (i < row.values.length - 1)
              const Divider(color: Color(0xFFE2E8F0), height: 13),
          ],
        ],
      ),
    );
  }

  Widget _section(BookDetailSection section) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(section.icon, color: const Color(0xFF3730A3), size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(child: Text(_tr(section.en, section.ar),
              style: const TextStyle(
                  color: Color(0xFF172554), fontSize: 19,
                  fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 15),
        LayoutBuilder(builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool twoColumns = width >= 700;
          final double cellWidth = twoColumns ? (width - 12) / 2 : width;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            for (final row in section.rows)
              SizedBox(width: cellWidth, child: _detailRow(row)),
          ]);
        }),
      ]),
    );
  }

  Widget _completedList() {
    if (widget.completedRecords.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(17)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_tr('Completed books in this session', 'الكتب المكتملة في هذه الجلسة'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        for (final record in widget.completedRecords.reversed.take(8))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle, color: Color(0xFF047857)),
            title: Text(BookDisplayData.fromRecord(record).title.isNotEmpty
                ? BookDisplayData.fromRecord(record).title
                : _tr('Book record', 'تسجيلة كتاب')),
            subtitle: Text(BookDisplayData.fromRecord(record).author),
          ),
      ]),
    );
  }

  Widget _content({bool expanded = false}) {
    final book = widget.currentRecord == null
        ? null : BookDisplayData.fromRecord(widget.currentRecord!);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _hero(book),
      if (book != null && book.sections.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_tr('EXPLORE BOOK DETAILS', 'استعراض بيانات الكتاب'),
                style: const TextStyle(fontSize: 12,
                    letterSpacing: 1.4,
                    color: Color(0xFF4338CA),
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            for (final section in book.sections) _section(section),
          ]),
        ),
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
        child: _completedList(),
      ),
    ]);
  }

  void _showPresentation() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250, maxHeight: 850),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(children: [
                const Icon(Icons.auto_stories_rounded,
                    color: Color(0xFF3730A3)),
                const SizedBox(width: 10),
                Expanded(child: Text(_tr('Book Details Showcase', 'عرض بيانات الكتاب'),
                    style: const TextStyle(fontWeight: FontWeight.w800,
                        fontSize: 20))),
                IconButton(onPressed: () => Navigator.pop(dialogContext),
                    tooltip: _tr('Close', 'إغلاق'),
                    icon: const Icon(Icons.close)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(child: SingleChildScrollView(child: _content(expanded: true))),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x121E1B4B),
              blurRadius: 25, offset: Offset(0, 7)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF172554), Color(0xFF4338CA)]),
          ),
          child: Wrap(alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12, runSpacing: 12, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_tr('THE BOOK SHOWCASE', 'معرض الكتاب'),
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 19)),
              const SizedBox(height: 4),
              Text(_tr('A beautiful, readable catalogue experience',
                      'عرض شامل وسهل القراءة لبيانات الكتب'),
                  style: const TextStyle(color: Color(0xFFE0E7FF),
                      fontSize: 13)),
            ]),
            OutlinedButton.icon(
              onPressed: _showPresentation,
              icon: const Icon(Icons.open_in_full, size: 17),
              label: Text(_tr('Full showcase', 'العرض الكامل')),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ]),
        ),
        _content(),
      ]),
    );
  }
}
