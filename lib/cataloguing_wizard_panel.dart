import 'package:flutter/material.dart';

/// User-controlled wizard: HomePage owns the MARC data and API actions.
class CataloguingWizardPanel extends StatelessWidget {
  final bool arabic;
  final int step;
  final int maxAvailableStep;
  final bool busy;
  final List<String> filenames;
  final bool hasMarcRecord;
  final bool approved;
  final int cartCount;
  final VoidCallback uploadFiles;
  final ValueChanged<int> removeFile;
  final VoidCallback clearFiles;
  final VoidCallback generateMarc;
  final VoidCallback generateSummary;
  final VoidCallback skipSummary;
  final VoidCallback review;
  final VoidCallback addToCart;
  final VoidCallback openCart;
  final ValueChanged<int> goToStep;

  const CataloguingWizardPanel({
    super.key, required this.arabic, required this.step,
    required this.maxAvailableStep, required this.busy,
    required this.filenames, required this.hasMarcRecord,
    required this.approved, required this.cartCount,
    required this.uploadFiles, required this.removeFile,
    required this.clearFiles, required this.generateMarc,
    required this.generateSummary, required this.skipSummary,
    required this.review, required this.addToCart,
    required this.openCart, required this.goToStep,
  });

  String _tr(String en, String ar) => arabic ? ar : en;
  static const _en = ['Upload book', 'Generate record', 'AI summary',
    'Review and approve', 'Finish cataloguing'];
  static const _ar = ['رفع الكتاب', 'إنشاء التسجيلة', 'الملخص الذكي',
    'المراجعة والاعتماد', 'إكمال الفهرسة'];

  Widget _action(String en, String ar, IconData icon, VoidCallback? fn,
      {bool secondary = false}) {
    final label = Text(_tr(en, ar));
    final onPressed = busy ? null : fn;
    return secondary
        ? OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon), label: label)
        : FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: label);
  }

  Widget _files() {
    if (filenames.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_tr('Attached files: ', 'الملفات المرفقة: ') + filenames.length.toString(),
          style: const TextStyle(fontWeight: FontWeight.w700)),
      for (var i = 0; i < filenames.length; i++)
        ListTile(
          dense: true, contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.insert_drive_file_outlined),
          title: Text(filenames[i], maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: step <= 1 ? IconButton(
            tooltip: _tr('Remove', 'حذف'),
            onPressed: busy ? null : () => removeFile(i),
            icon: const Icon(Icons.close),
          ) : null,
        ),
      if (step <= 1)
        Wrap(spacing: 8, children: [
          TextButton.icon(
            onPressed: busy ? null : uploadFiles,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_tr('Add pages', 'إضافة صفحات')),
          ),
          TextButton.icon(
            onPressed: busy ? null : clearFiles,
            icon: const Icon(Icons.delete_outline),
            label: Text(_tr('Clear files', 'مسح الملفات')),
          ),
        ]),
    ]);
  }

  Widget _stage() {
    switch (step) {
      case 0:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_tr('Upload the cover, title page and any other pages of one book.',
              'ارفع غلاف الكتاب وصفحة العنوان وأي صفحات أخرى للكتاب نفسه.')),
          const SizedBox(height: 14),
          _action('Upload images or PDF', 'رفع الصور أو PDF',
              Icons.cloud_upload_outlined, uploadFiles),
          if (filenames.isNotEmpty) ...[
            _files(),
            _action('Continue', 'متابعة', Icons.arrow_forward,
                () => goToStep(1)),
          ],
        ]);
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_tr('AI analyses all uploaded pages as one book. You approve the result later.',
              'يحلل الذكاء الاصطناعي جميع الصفحات ككتاب واحد، ثم تراجع النتيجة لاحقاً.')),
          const SizedBox(height: 10),
          _files(),
          if (busy) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          _action(hasMarcRecord ? 'Regenerate record' : 'Generate record',
              'إنشاء تسجيلة الفهرسة', Icons.auto_awesome,
              filenames.isNotEmpty ? generateMarc : null),
          if (hasMarcRecord)
            _action('Next: summary', 'التالي: الملخص', Icons.arrow_forward,
                () => goToStep(2), secondary: true),
        ]);
      case 2:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_tr('Create an optional abstract, or skip to review.',
              'يمكن إنشاء ملخص اختياري أو تخطيه للانتقال إلى المراجعة.')),
          const SizedBox(height: 14),
          if (busy) const LinearProgressIndicator(),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _action('Generate AI summary', 'إنشاء الملخص الذكي',
                Icons.summarize_outlined, generateSummary),
            _action('Skip and continue', 'تخطي والمتابعة',
                Icons.skip_next, skipSummary, secondary: true),
          ]),
        ]);
      case 3:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_tr('Compare the uploaded picture and readable book details against '
                  'the editable MARC record. Correct and approve before continuing.',
                  'قارن صورة الكتاب وبياناته المقروءة مع تسجيلة MARC القابلة للتعديل '
                  'ثم صحح المعلومات واعتمدها للمتابعة.')),
          const SizedBox(height: 15),
          _action('Open two-panel final review', 'فتح المراجعة النهائية بلوحتين',
              Icons.fact_check_outlined, hasMarcRecord ? review : null),
        ]);
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_tr(approved
                  ? 'Approved. Add to the Master Cart to complete this book and start the next.'
                  : 'Approval is required before adding the book.',
              approved
                  ? 'تم الاعتماد. أضف التسجيلة إلى السلة لإنهاء هذا الكتاب والبدء بكتاب جديد.'
                  : 'يجب اعتماد التسجيلة قبل إضافتها إلى السلة.')),
          const SizedBox(height: 15),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _action('Finish — add book', 'إنهاء وإضافة الكتاب',
                Icons.add_shopping_cart, approved ? addToCart : null),
            _action('Master Cart (' + cartCount.toString() + ')',
                'السلة الرئيسية (' + cartCount.toString() + ')',
                Icons.inventory_2_outlined, openCart, secondary: true),
          ]),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('cataloguing-wizard'),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_tr('ONE-STEP CATALOGUING', 'الفهرسة خطوة بخطوة'),
            style: const TextStyle(
                color: Color(0xFF4338CA), fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(_tr('Step ', 'الخطوة ') + (step + 1).toString()
            + _tr(' of 5 — ', ' من ٥ — ')
            + (arabic ? _ar[step] : _en[step]),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                color: Color(0xFF172554))),
        const SizedBox(height: 16),
        Wrap(spacing: 7, runSpacing: 7, children: [
          for (var i = 0; i < 5; i++)
            OutlinedButton.icon(
              onPressed: !busy && i <= maxAvailableStep
                  ? () => goToStep(i) : null,
              icon: Icon(i < step ? Icons.check_circle
                  : Icons.circle_outlined, size: 16),
              label: Text((i + 1).toString() + '. '
                  + (arabic ? _ar[i] : _en[i])),
              style: OutlinedButton.styleFrom(
                backgroundColor: i == step ? const Color(0xFFE0E7FF) : null,
                foregroundColor: i == step
                    ? const Color(0xFF4338CA) : const Color(0xFF475569),
              ),
            ),
        ]),
        const Divider(height: 30),
        _stage(),
        if (step > 0) ...[
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: busy ? null : () => goToStep(step - 1),
            icon: const Icon(Icons.arrow_back),
            label: Text(_tr('Previous step', 'الخطوة السابقة')),
          ),
        ],
      ]),
    );
  }
}
