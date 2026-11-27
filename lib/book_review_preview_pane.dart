import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'catalogue_showcase_panel.dart';

/// Live, read-only book preview alongside the editable MARC review form.
/// Rebuilds from text controllers without changing cataloguing fields.
class BookReviewPreviewPane extends StatelessWidget {
  final bool arabic;
  final Map<String, TextEditingController> controllers;
  final Uint8List? cover;

  const BookReviewPreviewPane({
    super.key,
    required this.arabic,
    required this.controllers,
    this.cover,
  });

  String _tr(String en, String ar) => arabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(controllers.values.toList()),
      builder: (context, _) {
        final snapshot = <String, dynamic>{
          for (final item in controllers.entries) item.key: item.value.text,
        };
        final book = BookDisplayData.fromRecord(snapshot);
        return Container(
          key: const Key('review-book-preview'),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(_tr('BOOK PREVIEW', 'معاينة الكتاب'),
                  style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w900, color: Color(0xFF4338CA))),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 175,
                  height: 225,
                  child: cover == null
                      ? Container(
                          alignment: Alignment.center,
                          color: const Color(0xFFE0E7FF),
                          child: const Icon(Icons.auto_stories_rounded,
                              size: 70, color: Color(0xFF4338CA)),
                        )
                      : Image.memory(cover!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.auto_stories_rounded, size: 64)),
                ),
              ),
              const SizedBox(height: 18),
              SelectableText(
                book.title.isNotEmpty ? book.title :
                    _tr('Title not identified', 'العنوان غير محدد'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, height: 1.35,
                    color: Color(0xFF172554), fontWeight: FontWeight.w900),
              ),
              if (book.subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                SelectableText(book.subtitle, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15,
                        color: Color(0xFF475569))),
              ],
              if (book.author.isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(book.author, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 15),
              Text(_tr('Details update as you edit the MARC fields.',
                      'تتحدث البيانات مباشرة عند تعديل حقول MARC.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B),
                      fontSize: 12)),
              const Divider(height: 30),
              for (final section in book.sections) ...[
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(arabic ? section.ar : section.en,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900,
                          color: Color(0xFF3730A3))),
                ),
                const SizedBox(height: 9),
                for (final row in section.rows) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(arabic ? row.ar : row.en,
                        style: const TextStyle(fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 3),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SelectableText(row.values.join('\n'),
                        style: const TextStyle(fontSize: 13,
                            height: 1.45, color: Color(0xFF1E293B))),
                  ),
                  const SizedBox(height: 12),
                ],
                const Divider(height: 22),
              ],
            ],
          ),
        );
      },
    );
  }
}
