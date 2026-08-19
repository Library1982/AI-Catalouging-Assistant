import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;


// ============================================================
// GLOBAL LANGUAGE
// false = English
// true  = Arabic
// ============================================================

final ValueNotifier<bool> appArabic =
    ValueNotifier<bool>(false);


// ============================================================
// TRANSLATION HELPER
// ============================================================

String tr(
  bool ar,
  String en,
  String arabic,
) {
  return ar ? arabic : en;
}


// ============================================================
// MAIN
// ============================================================

void main() {
  runApp(
    const DpaMarcApp(),
  );
}


// ============================================================
// APPLICATION
// ============================================================

class DpaMarcApp extends StatelessWidget {
  const DpaMarcApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable:
          appArabic,
      builder: (
        context,
        isArabic,
        child,
      ) {
        return MaterialApp(
          debugShowCheckedModeBanner:
              false,

          title:
              'DPA MARC AI Assistant',

          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed:
                Colors.indigo,
            scaffoldBackgroundColor:
                const Color(
              0xfff7f7fb,
            ),
          ),

          builder: (
            context,
            child,
          ) {
            return Directionality(
              textDirection:
                  isArabic
                      ? TextDirection.rtl
                      : TextDirection.ltr,
              child:
                  child ??
                      const SizedBox(),
            );
          },

          home:
              const HomePage(),
        );
      },
    );
  }
}


// ============================================================
// LANGUAGE BUTTON
// ============================================================

class LanguageButton
    extends StatelessWidget {

  final bool isArabic;

  const LanguageButton({
    super.key,
    required this.isArabic,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 6,
      ),
      child: TextButton.icon(
        onPressed: () {
          appArabic.value =
              !appArabic.value;
        },
        icon:
            const Icon(
          Icons.language,
        ),
        label:
            Text(
          isArabic
              ? 'English'
              : 'العربية',
        ),
      ),
    );
  }
}


// ============================================================
// REVIEW RESULT
// ============================================================

class ReviewResult {

  final Map<String, dynamic>
      record;

  final bool approved;

  ReviewResult({
    required this.record,
    required this.approved,
  });
}


// ============================================================
// CUSTOM MARC FIELD
// ============================================================

class CustomMarcField {

  String tag;

  String indicators;

  String value;

  CustomMarcField({
    required this.tag,
    required this.indicators,
    required this.value,
  });

  Map<String, dynamic>
      toJson() {
    return {
      'tag': tag,
      'indicators':
          indicators,
      'value': value,
    };
  }

  factory CustomMarcField.fromJson(
    Map<String, dynamic> json,
  ) {
    return CustomMarcField(
      tag:
          json['tag']
                  ?.toString() ??
              '',
      indicators:
          json['indicators']
                  ?.toString() ??
              '##',
      value:
          json['value']
                  ?.toString() ??
              '',
    );
  }
}


// ============================================================
// HOME PAGE
// ============================================================

class HomePage
    extends StatefulWidget {

  const HomePage({
    super.key,
  });

  @override
  State<HomePage>
      createState() =>
          _HomePageState();
}


class _HomePageState
    extends State<HomePage> {

  // ==========================================================
  // PUBLIC RENDER BACKEND
  // ==========================================================

  static const String
      backendBaseUrl =
      'https://dpa-marc-api.onrender.com';


  // ==========================================================
  // DATA
  // ==========================================================

  final List<PlatformFile>
      selectedFiles = [];

  Map<String, dynamic>?
      marcRecord;

  final List<
          Map<String, dynamic>>
      marcCart = [];

  bool isAnalyzing = false;

  bool isReviewed = false;


  String statusEnglish =
      'Ready to catalogue a new item.';

  String statusArabic =
      'جاهز لفهرسة مادة جديدة.';


  // ==========================================================
  // STATUS
  // ==========================================================

  void setStatus(
    String en,
    String ar,
  ) {
    setState(() {
      statusEnglish = en;
      statusArabic = ar;
    });
  }


  // ==========================================================
  // PICK / ADD MULTIPLE FILES
  //
  // IMPORTANT MOBILE FIX:
  // New camera/photo selections are APPENDED.
  // They do not replace existing files.
  // ==========================================================

  Future<void> pickFiles(
    bool isArabic,
  ) async {

    try {

      final result =
          await FilePicker.platform
              .pickFiles(

        allowMultiple: true,

        type:
            FileType.custom,

        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'pdf',
        ],

        withData: true,
      );


      if (
        result == null ||
        result.files.isEmpty
      ) {
        return;
      }


      setState(() {

        // ====================================================
        // MOBILE CAMERA FIX
        //
        // OLD:
        // selectedFiles = result.files;
        //
        // NEW:
        // Append each new selection.
        // ====================================================

        selectedFiles.addAll(
          result.files,
        );

        marcRecord = null;

        isReviewed = false;


        statusEnglish =
            '${selectedFiles.length} file(s) selected for one bibliographic item. You can add more files before generating MARC.';

        statusArabic =
            'تم اختيار ${selectedFiles.length} ملف/ملفات لمادة ببليوجرافية واحدة. يمكنك إضافة المزيد قبل إنشاء MARC.';
      });

    } catch (error) {

      setStatus(
        'File selection error: $error',
        'خطأ في اختيار الملفات: $error',
      );
    }
  }


  // ==========================================================
  // REMOVE ONE FILE
  // ==========================================================

  void removeFile(
    int index,
  ) {

    setState(() {

      selectedFiles
          .removeAt(index);

      marcRecord = null;

      isReviewed = false;


      if (
        selectedFiles.isEmpty
      ) {

        statusEnglish =
            'No files selected.';

        statusArabic =
            'لم يتم اختيار أي ملفات.';

      } else {

        statusEnglish =
            '${selectedFiles.length} file(s) selected.';

        statusArabic =
            'تم اختيار ${selectedFiles.length} ملف/ملفات.';
      }
    });
  }


  // ==========================================================
  // CLEAR FILES
  // ==========================================================

  void clearFiles() {

    setState(() {

      selectedFiles.clear();

      marcRecord = null;

      isReviewed = false;

      statusEnglish =
          'Files cleared. Ready for a new item.';

      statusArabic =
          'تم مسح الملفات. جاهز لمادة جديدة.';
    });
  }


  // ==========================================================
  // GENERATE MARC
  // ==========================================================

  Future<void>
      generateMarcRecord(
    bool isArabic,
  ) async {

    if (
      selectedFiles.isEmpty
    ) {

      showMessage(
        tr(
          isArabic,
          'Please upload one or more bibliographic files first.',
          'يرجى رفع ملف ببليوجرافي واحد أو أكثر أولاً.',
        ),
      );

      return;
    }


    if (
      selectedFiles.any(
        (file) =>
            file.bytes == null,
      )
    ) {

      showMessage(
        tr(
          isArabic,
          'Unable to read one or more selected files.',
          'تعذر قراءة ملف واحد أو أكثر من الملفات المحددة.',
        ),
      );

      return;
    }


    setState(() {

      isAnalyzing = true;

      isReviewed = false;

      statusEnglish =
          'AI is analysing ${selectedFiles.length} supplied file(s)...';

      statusArabic =
          'يقوم الذكاء الاصطناعي بتحليل ${selectedFiles.length} ملف/ملفات...';
    });


    try {

      final request =
          http.MultipartRequest(

        'POST',

        Uri.parse(
          '$backendBaseUrl/marc/analyze',
        ),
      );


      for (
        final file
        in selectedFiles
      ) {

        request.files.add(

          http.MultipartFile
              .fromBytes(

            'files',

            file.bytes!,

            filename:
                file.name,
          ),
        );
      }


      final streamedResponse =
          await request.send();


      final responseBody =
          await streamedResponse
              .stream
              .bytesToString();


      dynamic decoded;

      try {
        decoded =
            jsonDecode(
          responseBody,
        );
      } catch (_) {
        decoded = null;
      }


      if (
        streamedResponse
                .statusCode !=
            200
      ) {

        final message =
            decoded is Map
                ? decoded[
                            'message']
                        ?.toString() ??
                    'Server error.'
                : 'Server error.';


        setStatus(
          'Server error: $message',
          'خطأ في الخادم: $message',
        );


        showMessage(
          tr(
            isArabic,
            'Unable to generate MARC record: $message',
            'تعذر إنشاء تسجيلة MARC: $message',
          ),
        );

        return;
      }


      if (
        decoded is! Map
      ) {

        showMessage(
          tr(
            isArabic,
            'The backend returned an invalid response.',
            'أرجع الخادم استجابة غير صالحة.',
          ),
        );

        return;
      }


      final Map<String, dynamic>
          data =
          Map<String, dynamic>
              .from(
        decoded,
      );


      if (
        data['success'] ==
                true &&
        data['record'] != null
      ) {

        final receivedRecord =
            Map<String, dynamic>
                .from(

          data['record']
              as Map,
        );


        receivedRecord
            .putIfAbsent(

          'custom_fields',

          () => [],
        );


        setState(() {

          marcRecord =
              receivedRecord;

          statusEnglish =
              'MARC 21 record generated successfully. Librarian review is required.';

          statusArabic =
              'تم إنشاء تسجيلة MARC 21 بنجاح. يلزم مراجعة أمين المكتبة.';
        });


        showMessage(
          tr(
            isArabic,
            'MARC 21 record generated successfully.',
            'تم إنشاء تسجيلة MARC 21 بنجاح.',
          ),
        );

      } else {

        final message =
            data['message']
                    ?.toString() ??
                'Unable to generate MARC record.';


        setStatus(
          message,
          'تعذر إنشاء تسجيلة MARC: $message',
        );


        showMessage(
          isArabic
              ? 'تعذر إنشاء تسجيلة MARC: $message'
              : message,
        );
      }

    } catch (error) {

      setStatus(
        'Analysis error: $error',
        'خطأ أثناء التحليل: $error',
      );


      showMessage(
        tr(
          isArabic,
          'Analysis error: $error',
          'حدث خطأ أثناء التحليل: $error',
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          isAnalyzing =
              false;
        });
      }
    }
  }


  // ==========================================================
  // REVIEW MARC
  // ==========================================================

  Future<void>
      reviewMarcRecord(
    bool isArabic,
  ) async {

    if (
      marcRecord == null
    ) {

      showMessage(
        tr(
          isArabic,
          'Generate a MARC record first.',
          'قم بإنشاء تسجيلة MARC أولاً.',
        ),
      );

      return;
    }


    final result =
        await Navigator.of(
      context,
    ).push<ReviewResult>(

      MaterialPageRoute(

        builder:
            (context) =>
                MarcReviewPage(

          record:
              Map<String, dynamic>
                  .from(
            marcRecord!,
          ),
        ),
      ),
    );


    if (
      result == null
    ) {
      return;
    }


    setState(() {

      marcRecord =
          result.record;

      isReviewed =
          result.approved;


      if (
        result.approved
      ) {

        statusEnglish =
            'MARC record reviewed and approved. Ready to add to Master Cart.';

        statusArabic =
            'تمت مراجعة واعتماد تسجيلة MARC. جاهزة للإضافة إلى السلة الرئيسية.';

      } else {

        statusEnglish =
            'MARC changes saved. Approval is still required.';

        statusArabic =
            'تم حفظ تعديلات MARC. ما زال الاعتماد مطلوباً.';
      }
    });


    showMessage(
      result.approved
          ? tr(
              isArabic,
              'MARC record approved.',
              'تم اعتماد تسجيلة MARC.',
            )
          : tr(
              isArabic,
              'MARC changes saved.',
              'تم حفظ تعديلات MARC.',
            ),
    );
  }


  // ==========================================================
  // RECORD TITLE
  // ==========================================================

  String recordTitle(
    Map<String, dynamic>
        record,
  ) {

    String text =
        record['field_245']
                ?.toString()
                .trim() ??
            '';


    if (
      text.isEmpty
    ) {
      return 'Untitled MARC record';
    }


    text =
        text.replaceFirst(

      RegExp(
        r'^245\s+\S+\s+',
      ),

      '',
    );


    text =
        text.replaceFirst(

      RegExp(
        r'^\$a\s*',
      ),

      '',
    );


    final slash =
        text.indexOf(
      r'/$c',
    );


    if (
      slash >= 0
    ) {

      text =
          text.substring(
        0,
        slash,
      );
    }


    return text
        .replaceAll(
          r'$b',
          ' ',
        )
        .replaceAll(
          r'$c',
          ' ',
        )
        .trim();
  }


  // ==========================================================
  // RECORD AUTHOR
  // ==========================================================

  String recordAuthor(
    Map<String, dynamic>
        record,
  ) {

    String text =
        record['field_100']
                ?.toString()
                .trim() ??
            '';


    if (
      text.isEmpty
    ) {
      return '';
    }


    text =
        text.replaceFirst(

      RegExp(
        r'^100\s+\S+\s+',
      ),

      '',
    );


    text =
        text.replaceFirst(

      RegExp(
        r'^\$a\s*',
      ),

      '',
    );


    return text.trim();
  }


  // ==========================================================
  // DUPLICATE KEY
  // ==========================================================

  String recordKey(
    Map<String, dynamic>
        record,
  ) {

    final isbn =
        record['field_020'];


    if (
      isbn is List &&
      isbn.isNotEmpty
    ) {

      final value =
          isbn
              .map(
                (item) =>
                    item
                        .toString(),
              )
              .join('|')
              .trim()
              .toLowerCase();


      if (
        value.isNotEmpty
      ) {

        return 'ISBN:$value';
      }
    }


    final title =
        record['field_245']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';


    final author =
        record['field_100']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';


    return (
      'TA:$title|$author'
    );
  }


  // ==========================================================
  // ADD APPROVED RECORD TO CART
  // ==========================================================

  void addApprovedRecordToCart(
    bool isArabic,
  ) {

    if (
      marcRecord == null
    ) {

      showMessage(
        tr(
          isArabic,
          'Generate a MARC record first.',
          'قم بإنشاء تسجيلة MARC أولاً.',
        ),
      );

      return;
    }


    if (
      !isReviewed
    ) {

      showMessage(
        tr(
          isArabic,
          'Review and approve the MARC record first.',
          'يرجى مراجعة واعتماد تسجيلة MARC أولاً.',
        ),
      );

      return;
    }


    final key =
        recordKey(
      marcRecord!,
    );


    final duplicate =
        marcCart.any(

      (record) =>
          recordKey(
            record,
          ) ==
          key,
    );


    if (
      duplicate
    ) {

      showMessage(
        tr(
          isArabic,
          'This record is already in the Master MARC Cart.',
          'هذه التسجيلة موجودة بالفعل في سلة MARC الرئيسية.',
        ),
      );

      return;
    }


    final copy =
        Map<String, dynamic>
            .from(
      marcRecord!,
    );


    if (
      copy['custom_fields']
      is List
    ) {

      copy['custom_fields'] =
          List<dynamic>.from(
        copy['custom_fields'],
      );
    }


    setState(() {

      marcCart.add(
        copy,
      );

      selectedFiles.clear();

      marcRecord = null;

      isReviewed = false;


      statusEnglish =
          'Approved record added to Master MARC Cart. Ready for the next item.';

      statusArabic =
          'تمت إضافة التسجيلة المعتمدة إلى سلة MARC الرئيسية. جاهز للمادة التالية.';
    });


    showMessage(
      tr(
        isArabic,
        'Record added to Master MARC Cart.',
        'تمت إضافة التسجيلة إلى سلة MARC الرئيسية.',
      ),
    );
  }


  // ==========================================================
  // OPEN CART
  // ==========================================================

  Future<void>
      openCart() async {

    await Navigator.of(
      context,
    ).push(

      MaterialPageRoute(

        builder:
            (context) =>
                MarcCartPage(

          records:
              marcCart,

          backendBaseUrl:
              backendBaseUrl,

          recordTitle:
              recordTitle,

          recordAuthor:
              recordAuthor,

          onCartChanged:
              () {

            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );


    if (
      mounted &&
      marcCart.isEmpty
    ) {

      setStatus(
        'Master MARC Cart is empty. Ready for the next batch.',
        'سلة MARC الرئيسية فارغة. جاهز للدفعة التالية.',
      );
    }
  }


  // ==========================================================
  // MESSAGE
  // ==========================================================

  void showMessage(
    String message,
  ) {

    if (!mounted) {
      return;
    }


    ScaffoldMessenger.of(
      context,
    ).showSnackBar(

      SnackBar(
        content:
            Text(
          message,
        ),
      ),
    );
  }


  // ==========================================================
  // ACTION CARD
  // ==========================================================

  Widget actionCard({

    required IconData icon,

    required String title,

    required String subtitle,

    required VoidCallback?
        onTap,

    bool loading = false,

    Widget? trailing,

  }) {

    final enabled =
        onTap != null;


    return Card(

      elevation:
          enabled ? 2 : 0,

      margin:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),

      child: InkWell(

        borderRadius:
            BorderRadius.circular(
          14,
        ),

        onTap:
            onTap,

        child: Padding(

          padding:
              const EdgeInsets.all(
            18,
          ),

          child: Row(

            children: [

              Container(

                width: 56,

                height: 56,

                decoration:
                    BoxDecoration(

                  color: enabled
                      ? Theme.of(
                          context,
                        )
                          .colorScheme
                          .primaryContainer
                      : Colors
                          .grey
                          .shade200,

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                child:
                    loading
                        ? const Padding(
                            padding:
                                EdgeInsets.all(
                              15,
                            ),
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : Icon(
                            icon,
                            size: 30,
                          ),
              ),


              const SizedBox(
                width: 16,
              ),


              Expanded(

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [

                    Text(

                      title,

                      style:
                          const TextStyle(

                        fontSize:
                            17,

                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),


                    const SizedBox(
                      height: 4,
                    ),


                    Text(

                      subtitle,

                      style:
                          TextStyle(

                        color:
                            Colors
                                .grey
                                .shade700,
                      ),
                    ),
                  ],
                ),
              ),


              trailing ??
                  const Icon(
                    Icons
                        .arrow_forward_ios,
                    size: 17,
                  ),
            ],
          ),
        ),
      ),
    );
  }


  // ==========================================================
  // HOME BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return ValueListenableBuilder<
        bool>(

      valueListenable:
          appArabic,

      builder: (
        context,
        isArabic,
        child,
      ) {

        return Scaffold(

          appBar: AppBar(

            title: Text(
              tr(
                isArabic,
                'DPA MARC AI Assistant',
                'مساعد MARC الذكي للمكتبة',
              ),
            ),

            centerTitle:
                true,

            actions: [

              LanguageButton(
                isArabic:
                    isArabic,
              ),


              Badge(

                label:
                    Text(
                  marcCart.length
                      .toString(),
                ),

                isLabelVisible:
                    marcCart
                        .isNotEmpty,

                child:
                    IconButton(

                  tooltip:
                      tr(
                    isArabic,
                    'Master MARC Cart',
                    'سلة MARC الرئيسية',
                  ),

                  icon:
                      const Icon(
                    Icons
                        .shopping_cart_outlined,
                  ),

                  onPressed:
                      openCart,
                ),
              ),


              const SizedBox(
                width: 8,
              ),
            ],
          ),


          body:
              SingleChildScrollView(

            padding:
                const EdgeInsets.all(
              20,
            ),

            child: Center(

              child:
                  ConstrainedBox(

                constraints:
                    const BoxConstraints(
                  maxWidth:
                      800,
                ),

                child: Column(

                  children: [

                    Container(

                      width: 105,

                      height: 105,

                      decoration:
                          BoxDecoration(

                        color:
                            Theme.of(
                          context,
                        )
                                .colorScheme
                                .primaryContainer,

                        shape:
                            BoxShape
                                .circle,
                      ),

                      child:
                          const Icon(
                        Icons
                            .local_library_outlined,
                        size: 58,
                      ),
                    ),


                    const SizedBox(
                      height: 22,
                    ),


                    Text(

                      tr(
                        isArabic,
                        'AI MARC 21 Cataloguing Assistant',
                        'مساعد الفهرسة الذكي MARC 21',
                      ),

                      textAlign:
                          TextAlign
                              .center,

                      style:
                          const TextStyle(

                        fontSize:
                            28,

                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),


                    const SizedBox(
                      height: 8,
                    ),


                    Text(

                      tr(
                        isArabic,
                        'Arabic & English Books, Theses and Dissertations',
                        'الكتب والرسائل والأطروحات باللغة العربية والإنجليزية',
                      ),

                      textAlign:
                          TextAlign
                              .center,
                    ),


                    const SizedBox(
                      height: 8,
                    ),


                    Text(

                      tr(
                        isArabic,
                        'Upload all bibliographic pages for one item, generate MARC, review and approve the record, then add it to the Master Cart.',
                        'ارفع جميع الصفحات الببليوجرافية الخاصة بمادة واحدة، ثم أنشئ MARC وراجع التسجيلة واعتمدها وأضفها إلى السلة الرئيسية.',
                      ),

                      textAlign:
                          TextAlign
                              .center,

                      style:
                          TextStyle(
                        color:
                            Colors
                                .grey
                                .shade700,
                      ),
                    ),


                    const SizedBox(
                      height: 30,
                    ),


                    // =========================================
                    // STEP 1
                    // =========================================

                    actionCard(

                      icon:
                          Icons
                              .cloud_upload_outlined,

                      title:
                          tr(
                        isArabic,
                        '1. Upload / Add Bibliographic Files',
                        '1. رفع / إضافة الملفات الببليوجرافية',
                      ),

                      subtitle:
                          tr(
                        isArabic,
                        'Take or select photos/PDFs. Open this again to add more pages without losing earlier files.',
                        'التقط أو اختر صوراً وملفات PDF. افتح هذا الخيار مرة أخرى لإضافة صفحات أخرى دون فقد الملفات السابقة.',
                      ),

                      onTap:
                          () =>
                              pickFiles(
                        isArabic,
                      ),
                    ),


                    // =========================================
                    // SELECTED FILE LIST
                    // =========================================

                    if (
                      selectedFiles
                          .isNotEmpty
                    )

                      Card(

                        margin:
                            const EdgeInsets.only(
                          top: 8,
                          bottom:
                              12,
                        ),

                        child:
                            Padding(

                          padding:
                              const EdgeInsets.all(
                            12,
                          ),

                          child:
                              Column(

                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .stretch,

                            children: [

                              Padding(

                                padding:
                                    const EdgeInsets.all(
                                  8,
                                ),

                                child:
                                    Text(

                                  tr(
                                    isArabic,
                                    '${selectedFiles.length} file(s) currently selected',
                                    'عدد الملفات المحددة حالياً: ${selectedFiles.length}',
                                  ),

                                  style:
                                      const TextStyle(

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),


                              for (
                                int index =
                                    0;
                                index <
                                    selectedFiles
                                        .length;
                                index++
                              )

                                ListTile(

                                  leading:
                                      Icon(

                                    selectedFiles[index]
                                                .extension
                                                ?.toLowerCase() ==
                                            'pdf'
                                        ? Icons
                                            .picture_as_pdf_outlined
                                        : Icons
                                            .image_outlined,
                                  ),

                                  title:
                                      Text(

                                    selectedFiles[
                                            index]
                                        .name,

                                    maxLines:
                                        2,

                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                  ),

                                  trailing:
                                      IconButton(

                                    tooltip:
                                        tr(
                                      isArabic,
                                      'Remove file',
                                      'حذف الملف',
                                    ),

                                    icon:
                                        const Icon(
                                      Icons
                                          .close,
                                    ),

                                    onPressed:
                                        () {

                                      removeFile(
                                        index,
                                      );
                                    },
                                  ),
                                ),


                              const SizedBox(
                                height: 8,
                              ),


                              Wrap(

                                alignment:
                                    WrapAlignment
                                        .center,

                                spacing: 8,

                                runSpacing: 8,

                                children: [

                                  FilledButton
                                      .tonalIcon(

                                    onPressed:
                                        () =>
                                            pickFiles(
                                      isArabic,
                                    ),

                                    icon:
                                        const Icon(
                                      Icons
                                          .add_photo_alternate_outlined,
                                    ),

                                    label:
                                        Text(
                                      tr(
                                        isArabic,
                                        'Add More Photos / PDFs',
                                        'إضافة صور / ملفات PDF أخرى',
                                      ),
                                    ),
                                  ),


                                  TextButton
                                      .icon(

                                    onPressed:
                                        clearFiles,

                                    icon:
                                        const Icon(
                                      Icons
                                          .delete_outline,
                                    ),

                                    label:
                                        Text(
                                      tr(
                                        isArabic,
                                        'Clear All Files',
                                        'مسح جميع الملفات',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),


                    // =========================================
                    // STEP 2
                    // =========================================

                    actionCard(

                      icon:
                          Icons
                              .auto_awesome,

                      title:
                          tr(
                        isArabic,
                        '2. Generate MARC Record',
                        '2. إنشاء تسجيلة MARC',
                      ),

                      subtitle:
                          tr(
                        isArabic,
                        'AI analyses all selected pages together and creates one MARC 21 record',
                        'يحلل الذكاء الاصطناعي جميع الصفحات المحددة معاً وينشئ تسجيلة MARC 21 واحدة',
                      ),

                      loading:
                          isAnalyzing,

                      onTap:
                          isAnalyzing
                              ? null
                              : () =>
                                  generateMarcRecord(
                                    isArabic,
                                  ),
                    ),


                    // =========================================
                    // STEP 3
                    // =========================================

                    actionCard(

                      icon:
                          Icons
                              .fact_check_outlined,

                      title:
                          tr(
                        isArabic,
                        '3. Review & Edit MARC',
                        '3. مراجعة وتعديل MARC',
                      ),

                      subtitle:
                          tr(
                        isArabic,
                        'Librarian verifies, corrects, adds fields and approves the record',
                        'يقوم أمين المكتبة بالمراجعة والتصحيح وإضافة الحقول واعتماد التسجيلة',
                      ),

                      onTap:
                          marcRecord ==
                                  null
                              ? null
                              : () =>
                                  reviewMarcRecord(
                                    isArabic,
                                  ),
                    ),


                    // =========================================
                    // STEP 4
                    // =========================================

                    actionCard(

                      icon:
                          Icons
                              .add_shopping_cart,

                      title:
                          tr(
                        isArabic,
                        '4. Add Approved Record to Cart',
                        '4. إضافة التسجيلة المعتمدة إلى السلة',
                      ),

                      subtitle:
                          isReviewed
                              ? tr(
                                  isArabic,
                                  'Approved record is ready to add to the Master MARC Cart',
                                  'التسجيلة المعتمدة جاهزة للإضافة إلى سلة MARC الرئيسية',
                                )
                              : tr(
                                  isArabic,
                                  'Review and approve the MARC record first',
                                  'يرجى مراجعة واعتماد تسجيلة MARC أولاً',
                                ),

                      onTap:
                          isReviewed
                              ? () =>
                                  addApprovedRecordToCart(
                                    isArabic,
                                  )
                              : null,
                    ),


                    // =========================================
                    // STEP 5
                    // =========================================

                    actionCard(

                      icon:
                          Icons
                              .inventory_2_outlined,

                      title:
                          tr(
                        isArabic,
                        '5. View Master MARC Cart',
                        '5. عرض سلة MARC الرئيسية',
                      ),

                      subtitle:
                          marcCart
                                  .isEmpty
                              ? tr(
                                  isArabic,
                                  'No records currently in the cart',
                                  'لا توجد تسجيلات حالياً في السلة',
                                )
                              : tr(
                                  isArabic,
                                  '${marcCart.length} approved record(s) ready for final Excel download',
                                  '${marcCart.length} تسجيلة معتمدة جاهزة للتصدير النهائي إلى Excel',
                                ),

                      onTap:
                          openCart,

                      trailing:
                          CircleAvatar(

                        radius: 18,

                        child:
                            Text(
                          marcCart
                              .length
                              .toString(),
                        ),
                      ),
                    ),


                    const SizedBox(
                      height: 20,
                    ),


                    // =========================================
                    // STATUS
                    // =========================================

                    Container(

                      width:
                          double
                              .infinity,

                      padding:
                          const EdgeInsets.all(
                        14,
                      ),

                      decoration:
                          BoxDecoration(

                        color:
                            Colors
                                .white,

                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),

                        border:
                            Border.all(
                          color:
                              Colors
                                  .grey
                                  .shade300,
                        ),
                      ),

                      child: Row(

                        children: [

                          Icon(
                            isReviewed
                                ? Icons
                                    .verified_outlined
                                : Icons
                                    .info_outline,
                          ),


                          const SizedBox(
                            width: 10,
                          ),


                          Expanded(

                            child:
                                Text(

                              isArabic
                                  ? statusArabic
                                  : statusEnglish,
                            ),
                          ),
                        ],
                      ),
                    ),


                    if (
                      marcCart
                          .isNotEmpty
                    ) ...[

                      const SizedBox(
                        height: 15,
                      ),


                      Container(

                        width:
                            double
                                .infinity,

                        padding:
                            const EdgeInsets.all(
                          16,
                        ),

                        decoration:
                            BoxDecoration(

                          color:
                              Theme.of(
                            context,
                          )
                                  .colorScheme
                                  .primaryContainer,

                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),

                        child:
                            Wrap(

                          alignment:
                              WrapAlignment
                                  .spaceBetween,

                          crossAxisAlignment:
                              WrapCrossAlignment
                                  .center,

                          spacing:
                              12,

                          runSpacing:
                              10,

                          children: [

                            Row(

                              mainAxisSize:
                                  MainAxisSize
                                      .min,

                              children: [

                                const Icon(
                                  Icons
                                      .shopping_cart_checkout,
                                ),


                                const SizedBox(
                                  width: 10,
                                ),


                                Text(

                                  tr(
                                    isArabic,
                                    '${marcCart.length} approved MARC record(s) in Master Cart.',
                                    '${marcCart.length} تسجيلة MARC معتمدة في السلة الرئيسية.',
                                  ),

                                  style:
                                      const TextStyle(

                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                              ],
                            ),


                            FilledButton(

                              onPressed:
                                  openCart,

                              child:
                                  Text(

                                tr(
                                  isArabic,
                                  'Open Cart',
                                  'فتح السلة',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],


                    const SizedBox(
                      height: 35,
                    ),


                    const Divider(),


                    const SizedBox(
                      height: 12,
                    ),


                    Text(

                      tr(
                        isArabic,
                        'DPA Library AI MARC Cataloguing Project',
                        'مشروع الفهرسة الذكية MARC للمكتبة',
                      ),

                      textAlign:
                          TextAlign
                              .center,

                      style:
                          const TextStyle(

                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),


                    const SizedBox(
                      height: 5,
                    ),


                    Text(

                      tr(
                        isArabic,
                        'Project by Yameen Abdullah',
                        'المشروع بواسطة يامين عبدالله',
                      ),
                    ),


                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


// ============================================================
// MASTER CART PAGE
// ============================================================

class MarcCartPage
    extends StatefulWidget {

  final List<
          Map<String, dynamic>>
      records;

  final String
      backendBaseUrl;

  final String Function(
    Map<String, dynamic>,
  ) recordTitle;

  final String Function(
    Map<String, dynamic>,
  ) recordAuthor;

  final VoidCallback
      onCartChanged;


  const MarcCartPage({

    super.key,

    required this.records,

    required this.backendBaseUrl,

    required this.recordTitle,

    required this.recordAuthor,

    required this.onCartChanged,
  });


  @override
  State<MarcCartPage>
      createState() =>
          _MarcCartPageState();
}


class _MarcCartPageState
    extends State<MarcCartPage> {

  bool exporting =
      false;


  // ==========================================================
  // EXPORT ALL
  // ==========================================================

  Future<void>
      exportAllRecords(
    bool isArabic,
  ) async {

    if (
      widget.records.isEmpty
    ) {

      showMessage(
        tr(
          isArabic,
          'The Master MARC Cart is empty.',
          'سلة MARC الرئيسية فارغة.',
        ),
      );

      return;
    }


    final numberOfRecords =
        widget.records.length;


    final confirmed =
        await showDialog<bool>(

      context:
          context,

      builder:
          (context) =>
              AlertDialog(

        title:
            Text(
          tr(
            isArabic,
            'Download Master MARC Excel',
            'تنزيل ملف Excel الرئيسي لـ MARC',
          ),
        ),

        content:
            Text(

          tr(
            isArabic,
            'Create one Excel workbook containing all $numberOfRecords approved MARC record(s)?\n\nAfter a successful download, the Master MARC Cart will automatically be cleared.',
            'هل تريد إنشاء ملف Excel واحد يحتوي على جميع تسجيلات MARC المعتمدة وعددها $numberOfRecords؟\n\nبعد نجاح التنزيل سيتم تفريغ سلة MARC الرئيسية تلقائياً.',
          ),
        ),

        actions: [

          TextButton(

            onPressed:
                () =>
                    Navigator.pop(
              context,
              false,
            ),

            child:
                Text(
              tr(
                isArabic,
                'Cancel',
                'إلغاء',
              ),
            ),
          ),


          FilledButton.icon(

            onPressed:
                () =>
                    Navigator.pop(
              context,
              true,
            ),

            icon:
                const Icon(
              Icons
                  .download_outlined,
            ),

            label:
                Text(
              tr(
                isArabic,
                'Download Excel',
                'تنزيل Excel',
              ),
            ),
          ),
        ],
      ),
    );


    if (
      confirmed != true
    ) {
      return;
    }


    setState(() {
      exporting = true;
    });


    try {

      final response =
          await http.post(

        Uri.parse(
          '${widget.backendBaseUrl}/marc/export-batch',
        ),

        headers: {
          'Content-Type':
              'application/json',
        },

        body:
            jsonEncode({
          'records':
              widget.records,
        }),
      );


      if (
        response.statusCode !=
            200
      ) {

        String message =
            tr(
          isArabic,
          'Unable to create Excel workbook.',
          'تعذر إنشاء ملف Excel.',
        );


        try {

          final data =
              jsonDecode(
            response.body,
          );


          if (
            data is Map &&
            data['message'] !=
                null
          ) {

            message =
                data['message']
                    .toString();
          }

        } catch (_) {}


        showMessage(
          message,
        );

        return;
      }


      final contentType =
          response.headers[
                  'content-type'] ??
              '';


      if (
        !contentType.contains(
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        )
      ) {

        showMessage(
          tr(
            isArabic,
            'The server did not return an Excel workbook.',
            'لم يُرجع الخادم ملف Excel صالحاً.',
          ),
        );

        return;
      }


      // ======================================================
      // FILENAME
      // ======================================================

      String filename =
          'DPA_MARC_Master.xlsx';


      final disposition =
          response.headers[
              'content-disposition'];


      if (
        disposition != null
      ) {

        final match =
            RegExp(
          r'filename="?([^";]+)"?',
        ).firstMatch(
          disposition,
        );


        if (
          match != null &&
          match.group(1) !=
              null
        ) {

          filename =
              match.group(1)!;
        }
      }


      // ======================================================
      // BROWSER DOWNLOAD
      // ======================================================

      final Uint8List bytes =
          response.bodyBytes;


      final blob =
          web.Blob(

        <JSAny>[
          bytes.toJS,
        ].toJS,

        web.BlobPropertyBag(

          type:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      );


      final objectUrl =
          web.URL
              .createObjectURL(
        blob,
      );


      final anchor =
          web.HTMLAnchorElement();


      anchor.href =
          objectUrl;

      anchor.download =
          filename;

      anchor.style.display =
          'none';


      web.document.body
          ?.appendChild(
        anchor,
      );


      anchor.click();


      anchor.parentNode
          ?.removeChild(
        anchor,
      );


      web.URL
          .revokeObjectURL(
        objectUrl,
      );


      if (!mounted) {
        return;
      }


      // ======================================================
      // CLEAR CART AFTER SUCCESS
      // ======================================================

      setState(() {
        widget.records.clear();
      });


      widget
          .onCartChanged();


      await showDialog<void>(

        context:
            context,

        builder:
            (context) =>
                AlertDialog(

          title:
              Text(
            tr(
              isArabic,
              'Excel Download Successful',
              'تم تنزيل ملف Excel بنجاح',
            ),
          ),

          content:
              Column(

            mainAxisSize:
                MainAxisSize
                    .min,

            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [

              Text(
                tr(
                  isArabic,
                  'Records exported: $numberOfRecords',
                  'عدد التسجيلات المصدرة: $numberOfRecords',
                ),
              ),


              const SizedBox(
                height: 10,
              ),


              Text(

                tr(
                  isArabic,
                  'Downloaded file:',
                  'الملف الذي تم تنزيله:',
                ),

                style:
                    const TextStyle(

                  fontWeight:
                      FontWeight
                          .bold,
                ),
              ),


              const SizedBox(
                height: 5,
              ),


              SelectableText(
                filename,
              ),


              const SizedBox(
                height: 15,
              ),


              Text(

                tr(
                  isArabic,
                  'The Master MARC Cart has been cleared automatically and is ready for the next batch.',
                  'تم تفريغ سلة MARC الرئيسية تلقائياً وهي جاهزة للدفعة التالية.',
                ),
              ),
            ],
          ),

          actions: [

            FilledButton(

              onPressed:
                  () =>
                      Navigator.pop(
                context,
              ),

              child:
                  Text(
                tr(
                  isArabic,
                  'OK',
                  'موافق',
                ),
              ),
            ),
          ],
        ),
      );

    } catch (error) {

      showMessage(
        tr(
          isArabic,
          'Batch export error: $error',
          'خطأ في تصدير الدفعة: $error',
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          exporting =
              false;
        });
      }
    }
  }


  // ==========================================================
  // REMOVE RECORD
  // ==========================================================

  void removeRecord(
    int index,
    bool isArabic,
  ) {

    widget.records
        .removeAt(
      index,
    );


    setState(() {});


    widget
        .onCartChanged();


    showMessage(
      tr(
        isArabic,
        'Record removed from cart.',
        'تم حذف التسجيلة من السلة.',
      ),
    );
  }


  // ==========================================================
  // CLEAR CART
  // ==========================================================

  Future<void> clearCart(
    bool isArabic,
  ) async {

    if (
      widget.records.isEmpty
    ) {
      return;
    }


    final confirmed =
        await showDialog<bool>(

      context:
          context,

      builder:
          (context) =>
              AlertDialog(

        title:
            Text(
          tr(
            isArabic,
            'Clear Master MARC Cart',
            'تفريغ سلة MARC الرئيسية',
          ),
        ),

        content:
            Text(

          tr(
            isArabic,
            'Remove all ${widget.records.length} record(s) from the cart?',
            'هل تريد حذف جميع التسجيلات وعددها ${widget.records.length} من السلة؟',
          ),
        ),

        actions: [

          TextButton(

            onPressed:
                () =>
                    Navigator.pop(
              context,
              false,
            ),

            child:
                Text(
              tr(
                isArabic,
                'Cancel',
                'إلغاء',
              ),
            ),
          ),


          FilledButton(

            onPressed:
                () =>
                    Navigator.pop(
              context,
              true,
            ),

            child:
                Text(
              tr(
                isArabic,
                'Clear Cart',
                'تفريغ السلة',
              ),
            ),
          ),
        ],
      ),
    );


    if (
      confirmed != true
    ) {
      return;
    }


    setState(() {
      widget.records.clear();
    });


    widget
        .onCartChanged();
  }


  // ==========================================================
  // MESSAGE
  // ==========================================================

  void showMessage(
    String message,
  ) {

    if (!mounted) {
      return;
    }


    ScaffoldMessenger.of(
      context,
    ).showSnackBar(

      SnackBar(
        content:
            Text(
          message,
        ),
      ),
    );
  }


  // ==========================================================
  // CART BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return ValueListenableBuilder<
        bool>(

      valueListenable:
          appArabic,

      builder: (
        context,
        isArabic,
        child,
      ) {

        return Scaffold(

          appBar:
              AppBar(

            title:
                Text(
              tr(
                isArabic,
                'Master MARC Cart',
                'سلة MARC الرئيسية',
              ),
            ),

            actions: [

              LanguageButton(
                isArabic:
                    isArabic,
              ),


              if (
                widget.records
                    .isNotEmpty
              )

                IconButton(

                  tooltip:
                      tr(
                    isArabic,
                    'Clear Cart',
                    'تفريغ السلة',
                  ),

                  onPressed:
                      () =>
                          clearCart(
                    isArabic,
                  ),

                  icon:
                      const Icon(
                    Icons
                        .delete_sweep_outlined,
                  ),
                ),
            ],
          ),


          body:
              widget.records
                      .isEmpty
                  ? Center(

                      child:
                          SingleChildScrollView(

                        padding:
                            const EdgeInsets.all(
                          20,
                        ),

                        child:
                            Column(

                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [

                            Icon(

                              Icons
                                  .shopping_cart_outlined,

                              size: 80,

                              color:
                                  Colors
                                      .grey
                                      .shade400,
                            ),


                            const SizedBox(
                              height: 18,
                            ),


                            Text(

                              tr(
                                isArabic,
                                'Master MARC Cart is empty',
                                'سلة MARC الرئيسية فارغة',
                              ),

                              textAlign:
                                  TextAlign
                                      .center,

                              style:
                                  const TextStyle(

                                fontSize:
                                    22,

                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),


                            const SizedBox(
                              height: 8,
                            ),


                            Text(

                              tr(
                                isArabic,
                                'Ready for the next cataloguing batch.',
                                'جاهز لدفعة الفهرسة التالية.',
                              ),

                              textAlign:
                                  TextAlign
                                      .center,
                            ),


                            const SizedBox(
                              height: 20,
                            ),


                            FilledButton.icon(

                              onPressed:
                                  () =>
                                      Navigator.pop(
                                context,
                              ),

                              icon:
                                  const Icon(
                                Icons
                                    .arrow_back,
                              ),

                              label:
                                  Text(
                                tr(
                                  isArabic,
                                  'Return to Cataloguing',
                                  'العودة إلى الفهرسة',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )

                  : Column(

                      children: [

                        Container(

                          width:
                              double
                                  .infinity,

                          margin:
                              const EdgeInsets.all(
                            16,
                          ),

                          padding:
                              const EdgeInsets.all(
                            18,
                          ),

                          decoration:
                              BoxDecoration(

                            color:
                                Theme.of(
                              context,
                            )
                                    .colorScheme
                                    .primaryContainer,

                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),

                          child:
                              Row(

                            children: [

                              const Icon(
                                Icons
                                    .inventory_2_outlined,
                                size: 35,
                              ),


                              const SizedBox(
                                width: 14,
                              ),


                              Expanded(

                                child:
                                    Column(

                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [

                                    Text(

                                      tr(
                                        isArabic,
                                        'Approved MARC Records',
                                        'تسجيلات MARC المعتمدة',
                                      ),

                                      style:
                                          const TextStyle(

                                        fontSize:
                                            18,

                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),


                                    Text(

                                      tr(
                                        isArabic,
                                        '${widget.records.length} record(s) ready for final Excel download',
                                        '${widget.records.length} تسجيلة جاهزة للتنزيل النهائي إلى Excel',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),


                        Expanded(

                          child:
                              ListView.builder(

                            padding:
                                const EdgeInsets.symmetric(
                              horizontal:
                                  16,
                            ),

                            itemCount:
                                widget.records
                                    .length,

                            itemBuilder:
                                (
                              context,
                              index,
                            ) {

                              final record =
                                  widget.records[
                                      index];


                              return Card(

                                margin:
                                    const EdgeInsets.only(
                                  bottom:
                                      12,
                                ),

                                child:
                                    ListTile(

                                  leading:
                                      CircleAvatar(
                                    child:
                                        Text(
                                      '${index + 1}',
                                    ),
                                  ),

                                  title:
                                      Text(
                                    widget
                                        .recordTitle(
                                      record,
                                    ),
                                  ),

                                  subtitle:
                                      Column(

                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [

                                      if (
                                        widget
                                            .recordAuthor(
                                          record,
                                        )
                                            .isNotEmpty
                                      )

                                        Text(
                                          widget
                                              .recordAuthor(
                                            record,
                                          ),
                                        ),


                                      Text(
                                        '${record['material_type'] ?? ''} • ${record['language'] ?? ''}',
                                      ),
                                    ],
                                  ),

                                  trailing:
                                      IconButton(

                                    icon:
                                        const Icon(
                                      Icons
                                          .delete_outline,
                                    ),

                                    onPressed:
                                        () =>
                                            removeRecord(
                                      index,
                                      isArabic,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),


                        SafeArea(

                          top: false,

                          child:
                              Padding(

                            padding:
                                const EdgeInsets.all(
                              16,
                            ),

                            child:
                                SizedBox(

                              width:
                                  double
                                      .infinity,

                              child:
                                  FilledButton.icon(

                                onPressed:
                                    exporting
                                        ? null
                                        : () =>
                                            exportAllRecords(
                                              isArabic,
                                            ),

                                icon:
                                    exporting
                                        ? const SizedBox(
                                            width:
                                                20,
                                            height:
                                                20,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth:
                                                  2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons
                                                .download_outlined,
                                          ),

                                label:
                                    Padding(

                                  padding:
                                      const EdgeInsets.all(
                                    14,
                                  ),

                                  child:
                                      Text(

                                    exporting
                                        ? tr(
                                            isArabic,
                                            'Creating Excel Workbook...',
                                            'جارٍ إنشاء ملف Excel...',
                                          )
                                        : tr(
                                            isArabic,
                                            'Download All ${widget.records.length} Records as Excel',
                                            'تنزيل جميع التسجيلات وعددها ${widget.records.length} كملف Excel',
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}


// ============================================================
// REVIEW PAGE
// ============================================================

class MarcReviewPage
    extends StatefulWidget {

  final Map<String, dynamic>
      record;


  const MarcReviewPage({

    super.key,

    required this.record,
  });


  @override
  State<MarcReviewPage>
      createState() =>
          _MarcReviewPageState();
}


class _MarcReviewPageState
    extends State<MarcReviewPage> {

  final Map<
          String,
          TextEditingController>
      controllers = {};


  final List<
          CustomMarcField>
      customFields = [];


  final List<String>
      fields = [

    'field_020',
    'field_041',
    'field_050',
    'field_082',
    'field_100',
    'field_110',
    'field_245',
    'field_250',
    'field_264',
    'field_300',
    'field_490',
    'field_500',
    'field_502',
    'field_504',
    'field_505',
    'field_600',
    'field_610',
    'field_650',
    'field_651',
    'field_700',
    'field_710',
    'field_856',
    'field_949',
  ];


  final Set<String>
      listFields = {

    'field_020',
    'field_500',
    'field_600',
    'field_610',
    'field_650',
    'field_651',
    'field_700',
    'field_710',
    'field_856',
  };


  // ==========================================================
  // LABELS
  // ==========================================================

  String fieldLabel(
    String field,
    bool ar,
  ) {

    final labels = {

      'field_020':
          tr(
        ar,
        '020 — ISBN',
        '020 — الرقم الدولي المعياري للكتاب',
      ),

      'field_041':
          tr(
        ar,
        '041 — Language',
        '041 — اللغة',
      ),

      'field_050':
          tr(
        ar,
        '050 — LC Classification',
        '050 — تصنيف مكتبة الكونغرس',
      ),

      'field_082':
          tr(
        ar,
        '082 — Dewey Decimal Classification',
        '082 — تصنيف ديوي العشري',
      ),

      'field_100':
          tr(
        ar,
        '100 — Main Author',
        '100 — المؤلف الرئيسي',
      ),

      'field_110':
          tr(
        ar,
        '110 — Corporate Main Entry',
        '110 — المدخل الرئيسي للهيئة',
      ),

      'field_245':
          tr(
        ar,
        '245 — Title & Statement of Responsibility',
        '245 — العنوان وبيان المسؤولية',
      ),

      'field_250':
          tr(
        ar,
        '250 — Edition',
        '250 — الطبعة',
      ),

      'field_264':
          tr(
        ar,
        '264 — Publication / Production',
        '264 — النشر / الإنتاج',
      ),

      'field_300':
          tr(
        ar,
        '300 — Physical Description',
        '300 — الوصف المادي',
      ),

      'field_490':
          tr(
        ar,
        '490 — Series',
        '490 — السلسلة',
      ),

      'field_500':
          tr(
        ar,
        '500 — General Notes',
        '500 — الملاحظات العامة',
      ),

      'field_502':
          tr(
        ar,
        '502 — Thesis / Dissertation Note',
        '502 — ملاحظة الرسالة / الأطروحة',
      ),

      'field_504':
          tr(
        ar,
        '504 — Bibliographical References / Index',
        '504 — المراجع الببليوجرافية / الكشاف',
      ),

      'field_505':
          tr(
        ar,
        '505 — Contents Note',
        '505 — ملاحظة المحتويات',
      ),

      'field_600':
          tr(
        ar,
        '600 — Personal Name Subjects',
        '600 — رؤوس موضوعات أسماء الأشخاص',
      ),

      'field_610':
          tr(
        ar,
        '610 — Corporate Name Subjects',
        '610 — رؤوس موضوعات أسماء الهيئات',
      ),

      'field_650':
          tr(
        ar,
        '650 — Topical Subjects',
        '650 — رؤوس الموضوعات',
      ),

      'field_651':
          tr(
        ar,
        '651 — Geographic Subjects',
        '651 — الموضوعات الجغرافية',
      ),

      'field_700':
          tr(
        ar,
        '700 — Added Personal Entries',
        '700 — المداخل الإضافية للأشخاص',
      ),

      'field_710':
          tr(
        ar,
        '710 — Added Corporate Entries',
        '710 — المداخل الإضافية للهيئات',
      ),

      'field_856':
          tr(
        ar,
        '856 — Electronic Access',
        '856 — الوصول الإلكتروني',
      ),

      'field_949':
          tr(
        ar,
        '949 — Local Call Number',
        '949 — رقم الاستدعاء المحلي',
      ),
    };


    return labels[field] ??
        field;
  }


  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {

    super.initState();


    for (
      final field
      in fields
    ) {

      final value =
          widget.record[field];


      String text =
          '';


      if (
        value is List
      ) {

        text =
            value.join(
          '\n',
        );

      } else if (
        value != null
      ) {

        text =
            value.toString();
      }


      controllers[field] =
          TextEditingController(
        text:
            text,
      );
    }


    final custom =
        widget.record[
            'custom_fields'];


    if (
      custom is List
    ) {

      for (
        final item
        in custom
      ) {

        if (
          item is Map
        ) {

          customFields.add(

            CustomMarcField
                .fromJson(

              Map<String, dynamic>
                  .from(
                item,
              ),
            ),
          );
        }
      }
    }
  }


  // ==========================================================
  // CUSTOM FIELD VALIDATION
  // ==========================================================

  String? validateCustomField({

    required String tag,

    required String indicators,

    required String value,
  }) {

    if (
      !RegExp(
        r'^\d{3}$',
      ).hasMatch(
        tag,
      )
    ) {

      return 'MARC tag must contain exactly 3 digits.';
    }


    if (
      indicators.length >
          2
    ) {

      return 'Indicators may contain a maximum of 2 characters.';
    }


    if (
      value.trim().isEmpty
    ) {

      return 'Enter a MARC field value.';
    }


    final numericTag =
        int.tryParse(
          tag,
        ) ??
        0;


    if (
      numericTag >= 10 &&
      !value.contains(
        r'$',
      )
    ) {

      return 'This MARC field should normally contain a subfield such as \$a.';
    }


    if (
      tag == '650' &&
      !value.contains(
        r'$a',
      )
    ) {

      return '650 should contain \$a.';
    }


    return null;
  }


  // ==========================================================
  // ADD CUSTOM MARC FIELD
  // ==========================================================

  Future<void> addMarcField(
    bool isArabic,
  ) async {

    final tagController =
        TextEditingController();


    final indicatorsController =
        TextEditingController(
      text: '##',
    );


    final valueController =
        TextEditingController();


    final result =
        await showDialog<
            CustomMarcField>(

      context:
          context,

      builder:
          (context) =>
              AlertDialog(

        title:
            Text(
          tr(
            isArabic,
            'Add MARC Field',
            'إضافة حقل MARC',
          ),
        ),

        content:
            SizedBox(

          width: 500,

          child:
              Column(

            mainAxisSize:
                MainAxisSize
                    .min,

            children: [

              TextField(

                controller:
                    tagController,

                maxLength: 3,

                keyboardType:
                    TextInputType
                        .number,

                decoration:
                    InputDecoration(

                  labelText:
                      tr(
                    isArabic,
                    'MARC Tag',
                    'وسم MARC',
                  ),

                  hintText:
                      '590',

                  helperText:
                      tr(
                    isArabic,
                    'Example: 246, 520, 590, 650, 700',
                    'مثال: 246، 520، 590، 650، 700',
                  ),

                  border:
                      const OutlineInputBorder(),
                ),
              ),


              const SizedBox(
                height: 10,
              ),


              TextField(

                controller:
                    indicatorsController,

                maxLength: 2,

                decoration:
                    InputDecoration(

                  labelText:
                      tr(
                    isArabic,
                    'Indicators',
                    'المؤشرات',
                  ),

                  hintText:
                      '##',

                  border:
                      const OutlineInputBorder(),
                ),
              ),


              const SizedBox(
                height: 10,
              ),


              TextField(

                controller:
                    valueController,

                minLines: 2,

                maxLines: 5,

                decoration:
                    InputDecoration(

                  labelText:
                      tr(
                    isArabic,
                    'Subfields / Value',
                    'الحقول الفرعية / القيمة',
                  ),

                  hintText:
                      r'$a DPA Library local note.',

                  border:
                      const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),

        actions: [

          TextButton(

            onPressed:
                () =>
                    Navigator.pop(
              context,
            ),

            child:
                Text(
              tr(
                isArabic,
                'Cancel',
                'إلغاء',
              ),
            ),
          ),


          FilledButton.icon(

            onPressed:
                () {

              final tag =
                  tagController
                      .text
                      .trim();


              String indicators =
                  indicatorsController
                      .text
                      .trim();


              final value =
                  valueController
                      .text
                      .trim();


              if (
                indicators.isEmpty
              ) {

                indicators =
                    '##';
              }


              final validation =
                  validateCustomField(

                tag:
                    tag,

                indicators:
                    indicators,

                value:
                    value,
              );


              if (
                validation != null
              ) {

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(

                  SnackBar(
                    content:
                        Text(
                      validation,
                    ),
                  ),
                );

                return;
              }


              Navigator.pop(

                context,

                CustomMarcField(

                  tag:
                      tag,

                  indicators:
                      indicators,

                  value:
                      value,
                ),
              );
            },

            icon:
                const Icon(
              Icons.add,
            ),

            label:
                Text(
              tr(
                isArabic,
                'Add Field',
                'إضافة الحقل',
              ),
            ),
          ),
        ],
      ),
    );


    tagController
        .dispose();

    indicatorsController
        .dispose();

    valueController
        .dispose();


    if (
      result != null
    ) {

      setState(() {

        customFields.add(
          result,
        );
      });
    }
  }


  // ==========================================================
  // BUILD UPDATED RECORD
  // ==========================================================

  Map<String, dynamic>
      buildUpdatedRecord() {

    final updated =
        Map<String, dynamic>
            .from(
      widget.record,
    );


    for (
      final field
      in fields
    ) {

      final text =
          controllers[field]!
              .text
              .trim();


      if (
        listFields.contains(
          field,
        )
      ) {

        updated[field] =
            text.isEmpty
                ? []
                : text
                    .split(
                      '\n',
                    )
                    .map(
                      (
                        line,
                      ) =>
                          line
                              .trim(),
                    )
                    .where(
                      (
                        line,
                      ) =>
                          line
                              .isNotEmpty,
                    )
                    .toList();

      } else {

        updated[field] =
            text.isEmpty
                ? null
                : text;
      }
    }


    updated[
        'custom_fields'] =
        customFields
            .map(
              (
                item,
              ) =>
                  item
                      .toJson(),
            )
            .toList();


    return updated;
  }


  // ==========================================================
  // SAVE
  // ==========================================================

  void saveChanges(
    bool isArabic,
  ) {

    final updated =
        buildUpdatedRecord();


    widget.record
      ..clear()
      ..addAll(
        updated,
      );


    ScaffoldMessenger.of(
      context,
    ).showSnackBar(

      SnackBar(

        content:
            Text(
          tr(
            isArabic,
            'MARC changes saved.',
            'تم حفظ تعديلات MARC.',
          ),
        ),
      ),
    );
  }


  // ==========================================================
  // APPROVE
  // ==========================================================

  void approveRecord() {

    Navigator.pop(

      context,

      ReviewResult(

        record:
            buildUpdatedRecord(),

        approved:
            true,
      ),
    );
  }


  // ==========================================================
  // BACK WITHOUT APPROVAL
  // ==========================================================

  void closeWithoutApproval() {

    Navigator.pop(

      context,

      ReviewResult(

        record:
            buildUpdatedRecord(),

        approved:
            false,
      ),
    );
  }


  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {

    for (
      final controller
      in controllers.values
    ) {

      controller
          .dispose();
    }


    super.dispose();
  }


  // ==========================================================
  // FIELD WIDGET
  // ==========================================================

  Widget buildField(
    String field,
    bool isArabic,
  ) {

    return Card(

      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      child:
          Padding(

        padding:
            const EdgeInsets.all(
          14,
        ),

        child:
            Column(

          crossAxisAlignment:
              CrossAxisAlignment
                  .start,

          children: [

            Text(

              fieldLabel(
                field,
                isArabic,
              ),

              style:
                  const TextStyle(

                fontWeight:
                    FontWeight
                        .bold,

                fontSize:
                    15,
              ),
            ),


            const SizedBox(
              height: 8,
            ),


            TextField(

              controller:
                  controllers[
                      field],

              minLines:
                  listFields
                          .contains(
                            field,
                          )
                      ? 2
                      : 1,

              maxLines:
                  null,

              decoration:
                  InputDecoration(

                hintText:
                    listFields
                            .contains(
                              field,
                            )
                        ? tr(
                            isArabic,
                            'One MARC entry per line',
                            'إدخال MARC واحد في كل سطر',
                          )
                        : tr(
                            isArabic,
                            'Enter MARC field',
                            'أدخل حقل MARC',
                          ),

                border:
                    const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // REVIEW PAGE BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return ValueListenableBuilder<
        bool>(

      valueListenable:
          appArabic,

      builder: (
        context,
        isArabic,
        child,
      ) {

        return Scaffold(

          appBar:
              AppBar(

            leading:
                IconButton(

              icon:
                  const Icon(
                Icons
                    .arrow_back,
              ),

              onPressed:
                  closeWithoutApproval,
            ),

            title:
                Text(
              tr(
                isArabic,
                'Review & Edit MARC 21',
                'مراجعة وتعديل MARC 21',
              ),
            ),

            actions: [

              LanguageButton(
                isArabic:
                    isArabic,
              ),
            ],
          ),


          body:
              SingleChildScrollView(

            padding:
                const EdgeInsets.all(
              20,
            ),

            child:
                Center(

              child:
                  ConstrainedBox(

                constraints:
                    const BoxConstraints(
                  maxWidth:
                      900,
                ),

                child:
                    Column(

                  children: [

                    Card(

                      child:
                          Padding(

                        padding:
                            const EdgeInsets.all(
                          18,
                        ),

                        child:
                            Row(

                          children: [

                            const Icon(
                              Icons
                                  .fact_check_outlined,
                              size: 34,
                            ),


                            const SizedBox(
                              width: 14,
                            ),


                            Expanded(

                              child:
                                  Text(

                                tr(
                                  isArabic,
                                  'Review all AI-generated MARC fields. Correct them if required, add additional fields, then approve the record.',
                                  'راجع جميع حقول MARC التي أنشأها الذكاء الاصطناعي، وصححها عند الحاجة، وأضف الحقول الإضافية، ثم اعتمد التسجيلة.',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),


                    const SizedBox(
                      height: 18,
                    ),


                    for (
                      final field
                      in fields
                    )

                      buildField(
                        field,
                        isArabic,
                      ),


                    SizedBox(

                      width:
                          double
                              .infinity,

                      child:
                          FilledButton
                              .tonalIcon(

                        onPressed:
                            () =>
                                addMarcField(
                          isArabic,
                        ),

                        icon:
                            const Icon(
                          Icons
                              .add_card_outlined,
                        ),

                        label:
                            Padding(

                          padding:
                              const EdgeInsets.all(
                            13,
                          ),

                          child:
                              Text(

                            tr(
                              isArabic,
                              '+ Add MARC Field',
                              '+ إضافة حقل MARC',
                            ),
                          ),
                        ),
                      ),
                    ),


                    if (
                      customFields
                          .isNotEmpty
                    ) ...[

                      const SizedBox(
                        height: 18,
                      ),


                      Align(

                        alignment:
                            Alignment
                                .centerLeft,

                        child:
                            Text(

                          tr(
                            isArabic,
                            'Additional MARC Fields',
                            'حقول MARC الإضافية',
                          ),

                          style:
                              const TextStyle(

                            fontSize:
                                18,

                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),


                      const SizedBox(
                        height: 10,
                      ),


                      for (
                        int index =
                            0;
                        index <
                            customFields
                                .length;
                        index++
                      )

                        Card(

                          child:
                              ListTile(

                            leading:
                                const Icon(
                              Icons
                                  .add_card,
                            ),

                            title:
                                Text(
                              '${customFields[index].tag} ${customFields[index].indicators}',
                            ),

                            subtitle:
                                SelectableText(
                              customFields[
                                      index]
                                  .value,
                            ),

                            trailing:
                                IconButton(

                              icon:
                                  const Icon(
                                Icons
                                    .delete_outline,
                              ),

                              onPressed:
                                  () {

                                setState(
                                  () {

                                    customFields
                                        .removeAt(
                                      index,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                    ],


                    const SizedBox(
                      height: 20,
                    ),


                    SizedBox(

                      width:
                          double
                              .infinity,

                      child:
                          OutlinedButton
                              .icon(

                        onPressed:
                            () =>
                                saveChanges(
                          isArabic,
                        ),

                        icon:
                            const Icon(
                          Icons
                              .save_outlined,
                        ),

                        label:
                            Padding(

                          padding:
                              const EdgeInsets.all(
                            14,
                          ),

                          child:
                              Text(

                            tr(
                              isArabic,
                              'Save Changes',
                              'حفظ التعديلات',
                            ),
                          ),
                        ),
                      ),
                    ),


                    const SizedBox(
                      height: 12,
                    ),


                    SizedBox(

                      width:
                          double
                              .infinity,

                      child:
                          FilledButton
                              .icon(

                        onPressed:
                            approveRecord,

                        icon:
                            const Icon(
                          Icons
                              .verified_outlined,
                        ),

                        label:
                            Padding(

                          padding:
                              const EdgeInsets.all(
                            14,
                          ),

                          child:
                              Text(

                            tr(
                              isArabic,
                              'Approve MARC Record',
                              'اعتماد تسجيلة MARC',
                            ),
                          ),
                        ),
                      ),
                    ),


                    const SizedBox(
                      height: 25,
                    ),


                    const Divider(),


                    const SizedBox(
                      height: 10,
                    ),


                    Text(

                      tr(
                        isArabic,
                        'DPA Library AI MARC Cataloguing Project',
                        'مشروع الفهرسة الذكية MARC للمكتبة',
                      ),

                      textAlign:
                          TextAlign
                              .center,

                      style:
                          const TextStyle(

                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),


                    const SizedBox(
                      height: 5,
                    ),


                    Text(

                      tr(
                        isArabic,
                        'Project by Yameen Abdullah',
                        'المشروع بواسطة يامين عبدالله',
                      ),
                    ),


                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}