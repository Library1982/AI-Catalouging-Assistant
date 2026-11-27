import 'dart:typed_data';

import 'package:flutter/material.dart';

/// A live, session-based catalogue wall driven by the existing MARC workflow.
/// No additional backend calls or duplicate book records are created.
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
  bool _showAll = false;

  String _label(String english, String arabic) =>
      widget.arabic ? arabic : english;

  bool get _hasUpload => widget.uploadedNames.isNotEmpty;

  String get _currentTitle {
    final record = widget.currentRecord;
    if (record != null) {
      final title = widget.recordTitle(record).trim();
      if (title.isNotEmpty && title != 'Untitled MARC record') return title;
    }
    if (widget.previewTitle.trim().isNotEmpty) {
      return widget.previewTitle.trim();
    }
    return _label('Title awaiting identification', 'العنوان بانتظار التعرّف عليه');
  }

  String get _stageText {
    if (widget.currentRecord != null) {
      if (widget.isApproved) return _label('Approved', 'معتمدة');
      return _label('MARC generated', 'تم إنشاء MARC');
    }
    if (widget.isAnalyzing) return _label('Analysing', 'جارٍ التحليل');
    return _label('Uploaded', 'تم الرفع');
  }

  Color get _stageColor {
    if (widget.isApproved) return const Color(0xFF047857);
    if (widget.currentRecord != null) return const Color(0xFF1D4ED8);
    if (widget.isAnalyzing) return const Color(0xFF7C3AED);
    return const Color(0xFF92400E);
  }

  Widget _pill(String text, {Color? fill, Color? foreground}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: fill ?? const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: foreground ?? const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _cover() => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 74,
          height: 98,
          child: widget.previewImage == null
              ? Container(
                  color: const Color(0xFFE0E7FF),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF3730A3),
                    size: 36,
                  ),
                )
              : Image.memory(
                  widget.previewImage!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE0E7FF),
                    child: const Icon(Icons.menu_book_rounded),
                  ),
                ),
        ),
      );

  Widget _activeCard() {
    final record = widget.currentRecord;
    final author = record == null ? '' : widget.recordAuthor(record).trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        border: Border.all(color: const Color(0xFFC7D2FE)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _pill(_label('CURRENT BOOK', 'الكتاب الحالي'),
                  fill: const Color(0xFFE0E7FF),
                  foreground: const Color(0xFF3730A3)),
              _pill(_stageText,
                  fill: _stageColor.withValues(alpha: 0.10),
                  foreground: _stageColor),
              _pill(_label(
                '${widget.uploadedNames.length} source file(s)',
                'عدد الملفات: ${widget.uploadedNames.length}',
              )),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cover(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTitle,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                        color: Color(0xFF172554),
                      ),
                    ),
                    if (author.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        author,
                        style: const TextStyle(color: Color(0xFF475569)),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Text(
                      widget.uploadedNames.first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (record == null) ...[
            const SizedBox(height: 14),
            TextFormField(
              key: ValueKey('showcase-title-${widget.uploadedNames.first}'),
              initialValue: widget.previewTitle,
              onChanged: widget.onPreviewTitleChanged,
              decoration: InputDecoration(
                labelText: _label(
                  'Optional: enter a display title before MARC generation',
                  'اختياري: اكتب عنواناً للعرض قبل إنشاء MARC',
                ),
                hintText: _label('Book title', 'عنوان الكتاب'),
                prefixIcon: const Icon(Icons.edit_outlined),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _pill(_label('1 · Uploaded', '١ · تم الرفع'),
                  fill: const Color(0xFFDCFCE7),
                  foreground: const Color(0xFF166534)),
              _pill(_label('2 · MARC generated', '٢ · إنشاء MARC'),
                  fill: record != null
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9)),
              _pill(_label('3 · Approved', '٣ · الاعتماد'),
                  fill: widget.isApproved
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9)),
              _pill(_label('4 · Added to cart', '٤ · إضافة إلى السلة')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _completedRow(Map<String, dynamic> record, int number) {
    final title = widget.recordTitle(record);
    final author = widget.recordAuthor(record).trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFDCFCE7),
            child: const Icon(Icons.check, color: Color(0xFF047857), size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    )),
                if (author.isNotEmpty)
                  Text(author,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _pill(_label('Catalogued', 'تمت الفهرسة'),
              fill: const Color(0xFFDCFCE7),
              foreground: const Color(0xFF166534)),
        ],
      ),
    );
  }

  Widget _body({bool fullList = false}) {
    final completed = widget.completedRecords.reversed.toList();
    final shown = fullList || _showAll ? completed : completed.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasUpload) ...[
          _activeCard(),
          const SizedBox(height: 18),
        ],
        if (completed.isNotEmpty) ...[
          Text(
            _label('Completed book titles', 'عناوين الكتب المكتملة'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < shown.length; i++) ...[
            _completedRow(shown[i], i + 1),
            if (i < shown.length - 1) const Divider(height: 1),
          ],
          if (!fullList && completed.length > 6)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => setState(() => _showAll = !_showAll),
                icon: Icon(_showAll ? Icons.expand_less : Icons.expand_more),
                label: Text(_showAll
                    ? _label('Show fewer', 'عرض عدد أقل')
                    : _label('Show all ${completed.length} titles',
                        'عرض جميع العناوين (${completed.length})')),
              ),
            ),
        ] else if (!_hasUpload)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              _label(
                'Upload a book cover, title page or PDF. Its card will appear here immediately and update as cataloguing progresses.',
                'ارفع غلاف الكتاب أو صفحة العنوان أو ملف PDF. ستظهر بطاقة الكتاب هنا مباشرة وتتحدّث خلال مراحل الفهرسة.',
              ),
              style: const TextStyle(color: Color(0xFF64748B), height: 1.5),
            ),
          ),
      ],
    );
  }

  void _openPresentation() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920, maxHeight: 740),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_stories_rounded,
                        color: Color(0xFF4338CA)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _label('Live Catalogue Showcase', 'عرض الفهرسة المباشر'),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      tooltip: _label('Close', 'إغلاق'),
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(child: _body(fullList: true)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.completedRecords.length;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 22,
            offset: Offset(0, 7),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF172554), Color(0xFF4338CA)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              spacing: 10,
              runSpacing: 10,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label('LIVE BOOK TITLE SHOWCASE', 'لوحة عرض عناوين الكتب'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _label('From upload to approved MARC 21',
                          'من رفع الكتاب حتى اعتماد تسجيلة MARC 21'),
                      style: const TextStyle(color: Color(0xFFE0E7FF)),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _openPresentation,
                  icon: const Icon(Icons.open_in_full, size: 17),
                  label: Text(_label('Showcase view', 'وضع العرض')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(_label('$count catalogued in cart',
                        '$count كتاباً مفهرساً في السلة'),
                        fill: const Color(0xFFE0E7FF),
                        foreground: const Color(0xFF3730A3)),
                    if (_hasUpload)
                      _pill(_label('1 book in progress', 'كتاب واحد قيد الفهرسة'),
                          fill: const Color(0xFFFEF3C7),
                          foreground: const Color(0xFF92400E)),
                  ],
                ),
                const SizedBox(height: 14),
                _body(),
                const SizedBox(height: 8),
                Text(
                  _label(
                    'Titles are identified from the MARC record after analysis. The showcase follows the current session and Master MARC Cart.',
                    'يُستخرج العنوان من تسجيلة MARC بعد التحليل. تعرض اللوحة جلسة العمل الحالية والكتب في سلة MARC الرئيسية.',
                  ),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
