import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

final ValueNotifier<bool> appArabic =
    ValueNotifier<bool>(false);

String tr(
  bool ar,
  String en,
  String arText,
) =>
    ar ? arText : en;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://umszqlxnptewnxsljozw.supabase.co',
    publishableKey: 'sb_publishable_enDOJJSkwbR0ygKlx4wAcg_qz3gGiu7',
  );

  runApp(const DpaMarcApp());
}

class DpaMarcApp extends StatelessWidget {
  const DpaMarcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appArabic,
      builder: (context, isArabic, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MARC AI Assistant',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          scaffoldBackgroundColor: const Color(0xfff7f7fb),
        ),
        builder: (context, child) => Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox(),
        ),
        home: const LandingPage(),
      ),
    );
  }
}

// ============================================================
// COMMERCIAL LANDING PAGE
// ============================================================

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();

    _checkCurrentUserStatus();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      _checkCurrentUserStatus();
    });
  }

  Future<void> _checkCurrentUserStatus() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _currentUser = null;
      });

      return;
    }

  try {
    final profile = await Supabase.instance.client
        .from('user_profiles')
        .select('account_status, role')
        .eq('id', user.id)
        .maybeSingle();

    if (!mounted) return;

    final status =
        profile?['account_status']?.toString() ?? 'disabled';

    final role =
        profile?['role']?.toString() ?? 'user';

    // Super Admin is allowed
    if (role == 'super_admin') {
      setState(() {
        _currentUser = user;
      });
      return;
    }

    // Normal active user
    if (status == 'active') {
      setState(() {
        _currentUser = user;
      });
      return;
    }

    // Suspended or disabled user
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    setState(() {
      _currentUser = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'suspended'
                ? 'Account suspended. Please contact the administrator.'
                : 'Account disabled. Please contact the administrator.',
          ),
        ),
      );
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _currentUser = null;
    });
  }
}

  static const navy = Color(0xFF071A33);
  static const accent = Color(0xFFF4F7CFF);

  final homeKey = GlobalKey();
  final aboutKey = GlobalKey();
  final featuresKey = GlobalKey();
  final howKey = GlobalKey();
  final pricingKey = GlobalKey();
  final faqKey = GlobalKey();

  void scrollTo(GlobalKey key) {
    final c = key.currentContext;
    if (c == null) return;
    Scrollable.ensureVisible(
      c,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOut,
    );
  }

  Future<void> launchApp() async {
  final user = Supabase.instance.client.auth.currentUser;

  // Not signed in -> go to login
  if (user == null) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AuthPage(),
      ),
    );

    if (!mounted) return;

    await _checkCurrentUserStatus();
    return;
  }

  try {
    final profile = await Supabase.instance.client
        .from('user_profiles')
        .select('account_status, role')
        .eq('id', user.id)
        .maybeSingle();

    if (!mounted) return;

    final status =
        profile?['account_status']?.toString() ?? 'disabled';

    final role =
        profile?['role']?.toString() ?? 'user';

    // Super Admin always allowed
    if (role == 'super_admin') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
      return;
    }

    // Normal active user allowed
    if (status == 'active') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
      return;
    }

    // Suspended / disabled user -> block access
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    setState(() {
      _currentUser = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'suspended'
              ? 'Account suspended. Please contact the administrator.'
              : 'Account disabled. Please contact the administrator.',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to verify account access. Please try again.',
        ),
      ),
    );
  }
}
  void comingSoon(bool ar) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            ar,
            'Login, credits and online payment are being prepared for the Version 1.0 launch.',
            'يتم حالياً تجهيز تسجيل الدخول والرصيد والدفع الإلكتروني لإطلاق الإصدار 1.0.',
          ),
        ),
      ),
    );
  }

  Widget titleBlock(
    bool ar,
    String eyebrowEn,
    String eyebrowAr,
    String titleEn,
    String titleAr,
    String textEn,
    String textAr,
  ) {
    return Column(
      children: [
        Text(
          tr(ar, eyebrowEn, eyebrowAr).toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: accent,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          tr(ar, titleEn, titleAr),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: navy,
            fontSize: 36,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            tr(ar, textEn, textAr),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 17,
              height: 1.65,
            ),
          ),
        ),
      ],
    );
  }

  Widget infoCard(
    bool ar,
    IconData icon,
    String enTitle,
    String arTitle,
    String enText,
    String arText,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EAF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 16),
          Text(
            tr(ar, enTitle, arTitle),
            style: const TextStyle(
              color: navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(ar, enText, arText),
            style: TextStyle(color: Colors.grey.shade700, height: 1.55),
          ),
        ],
      ),
    );
  }

  Widget priceCard(
    bool ar,
    String title,
    String records,
    String price, {
    bool featured = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: featured ? navy : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: featured ? navy : const Color(0xFFE5EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: featured ? Colors.white : navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            price,
            style: TextStyle(
              color: featured ? Colors.white : navy,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            records,
            style: TextStyle(
              color: featured ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 20),
          _Check(
            text: tr(ar, 'AI MARC generation', 'إنشاء MARC بالذكاء الاصطناعي'),
            featured: featured,
          ),
          const SizedBox(height: 8),
          _Check(
            text: tr(ar, 'Arabic & English', 'العربية والإنجليزية'),
            featured: featured,
          ),
          const SizedBox(height: 8),
          _Check(
            text: tr(ar, 'Mobile + Desktop', 'الهاتف + الكمبيوتر'),
            featured: featured,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: featured
                ? FilledButton(
                    onPressed: () => comingSoon(ar),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: navy,
                    ),
                    child: Text(tr(ar, 'Choose Plan', 'اختر الخطة')),
                  )
                : OutlinedButton(
                    onPressed: () => comingSoon(ar),
                    child: Text(tr(ar, 'Choose Plan', 'اختر الخطة')),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appArabic,
      builder: (context, ar, _) {
        final width = MediaQuery.sizeOf(context).width;
        final desktop = width > 1000;

        return Scaffold(
          drawer: desktop
              ? null
              : Drawer(
                  child: SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        const ListTile(
                          leading: Icon(Icons.local_library_outlined),
                          title: Text(
                            'MARC AI',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const Divider(),
                        _DrawerNav(
                          label: tr(ar, 'Home', 'الرئيسية'),
                          onTap: () {
                            Navigator.pop(context);
                            scrollTo(homeKey);
                          },
                        ),
                        _DrawerNav(
                          label: tr(ar, 'About', 'من نحن'),
                          onTap: () {
                            Navigator.pop(context);
                            scrollTo(aboutKey);
                          },
                        ),
                        _DrawerNav(
                          label: tr(ar, 'Features', 'المزايا'),
                          onTap: () {
                            Navigator.pop(context);
                            scrollTo(featuresKey);
                          },
                        ),
                        _DrawerNav(
                          label: tr(ar, 'How It Works', 'كيف يعمل'),
                          onTap: () {
                            Navigator.pop(context);
                            scrollTo(howKey);
                          },
                        ),
                        _DrawerNav(
                          label: tr(ar, 'Pricing', 'الأسعار'),
                          onTap: () {
                            Navigator.pop(context);
                            scrollTo(pricingKey);
                          },
                        ),
                        _DrawerNav(
                          label: tr(ar, 'FAQ', 'الأسئلة الشائعة'),
                          onTap: () {
                            Navigator.pop(context);
                            scrollTo(faqKey);
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.login),
                          title: Text(tr(ar, 'Sign In', 'تسجيل الدخول')),
                          onTap: () {
  Navigator.pop(context);

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const AuthPage(),
    ),
  );
},
                        ),
                        ListTile(
                          leading: const Icon(Icons.rocket_launch_outlined),
                          title: Text(tr(ar, 'Launch App', 'تشغيل التطبيق')),
                          onTap: () {
                            Navigator.pop(context);
                            launchApp();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
          body: Builder(
            builder: (scaffoldContext) => SingleChildScrollView(
              child: Column(
                children: [
                  // HERO
                  Container(
                    key: homeKey,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF06172E),
                          Color(0xFF102A4C),
                          Color(0xFF173E68),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: desktop ? 48 : 16,
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 82,
                              child: Row(
                                children: [
                                  if (!desktop)
                                    IconButton(
                                      onPressed: () =>
                                          Scaffold.of(scaffoldContext)
                                              .openDrawer(),
                                      icon: const Icon(
                                        Icons.menu,
                                        color: Colors.white,
                                      ),
                                    ),
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: const Icon(
                                      Icons.local_library_outlined,
                                      color: navy,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'MARC AI',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        Text(
                                          tr(
                                            ar,
                                            'AI Cataloguing Assistant',
                                            'مساعد الفهرسة الذكي',
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (desktop) ...[
                                    _TopNav(
                                      label: tr(ar, 'Home', 'الرئيسية'),
                                      onTap: () => scrollTo(homeKey),
                                    ),
                                    _TopNav(
                                      label: tr(ar, 'About', 'من نحن'),
                                      onTap: () => scrollTo(aboutKey),
                                    ),
                                    _TopNav(
                                      label: tr(ar, 'Features', 'المزايا'),
                                      onTap: () => scrollTo(featuresKey),
                                    ),
                                    _TopNav(
                                      label:
                                          tr(ar, 'How It Works', 'كيف يعمل'),
                                      onTap: () => scrollTo(howKey),
                                    ),
                                    _TopNav(
                                      label: tr(ar, 'Pricing', 'الأسعار'),
                                      onTap: () => scrollTo(pricingKey),
                                    ),
                                    _TopNav(
                                      label:
                                          tr(ar, 'FAQ', 'الأسئلة الشائعة'),
                                      onTap: () => scrollTo(faqKey),
                                    ),
                                  ],
                                  IconButton(
                                    tooltip: tr(ar, 'Language', 'اللغة'),
                                    onPressed: () {
                                      appArabic.value = !appArabic.value;
                                    },
                                    icon: const Icon(
                                      Icons.language,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (desktop)
                                   OutlinedButton(
onPressed: () async {
  if (_currentUser == null) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AuthPage(),
      ),
    );
  } else {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AccountPage(),
      ),
    );

    if (!mounted) return;

    setState(() {
      _currentUser = Supabase.instance.client.auth.currentUser;
    });
  }
},
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: const BorderSide(
      color: Colors.white38,
    ),
  ),
child: Text(
  _currentUser != null
      ? tr(ar, 'Account', 'الحساب')
      : tr(ar, 'Sign In', 'تسجيل الدخول'),
),
),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: () async {
  if (_currentUser == null) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AuthPage(),
      ),
    );

    if (!mounted) return;

    setState(() {
      _currentUser = Supabase.instance.client.auth.currentUser;
    });

    return;
  }

  launchApp();
},
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: navy,
                                    ),
                                    child:
                                        Text(tr(ar, 'Launch App', 'تشغيل التطبيق')),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: desktop ? 90 : 55,
                              ),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 1250),
                                child: desktop
                                    ? Row(
                                        children: [
                                          Expanded(
                                            flex: 6,
                                            child: _HeroText(
                                              ar: ar,
                                              launchApp: launchApp,
                                              how: () => scrollTo(howKey),
                                            ),
                                          ),
                                          const SizedBox(width: 60),
                                          const Expanded(
                                            flex: 5,
                                            child: _HeroDemo(),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          _HeroText(
                                            ar: ar,
                                            launchApp: launchApp,
                                            how: () => scrollTo(howKey),
                                          ),
                                          const SizedBox(height: 40),
                                          const _HeroDemo(),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // TRUST
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFF7F9FC),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 30,
                      runSpacing: 18,
                      children: [
                        _Trust(
                          Icons.language,
                          tr(ar, 'Arabic + English', 'العربية + الإنجليزية'),
                        ),
                        _Trust(
                          Icons.fact_check_outlined,
                          tr(ar, 'Librarian Approval', 'اعتماد أمين المكتبة'),
                        ),
                        _Trust(
                          Icons.picture_as_pdf_outlined,
                          tr(ar, 'Images + PDF', 'الصور + PDF'),
                        ),
                        _Trust(
                          Icons.devices_outlined,
                          tr(ar, 'Desktop + Mobile', 'الكمبيوتر + الهاتف'),
                        ),
                        const _Trust(Icons.dataset_outlined, 'MARC 21'),
                      ],
                    ),
                  ),

                  // ABOUT
                  Container(
                    key: aboutKey,
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: desktop ? 60 : 20,
                      vertical: 95,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1150),
                        child: Column(
                          children: [
                            titleBlock(
                              ar,
                              'About the Platform',
                              'عن المنصة',
                              'Built to Assist Professional Cataloguers',
                              'مصمم لمساندة المفهرسين المتخصصين',
                              'Library cataloguing requires careful bibliographic examination. MARC AI Assistant reduces repetitive data-entry effort while preserving professional review, correction and approval.',
                              'تتطلب فهرسة المكتبات فحصاً ببليوجرافياً دقيقاً. يساعد MARC AI في تقليل أعمال الإدخال المتكررة مع الحفاظ على المراجعة والتصحيح والاعتماد المهني.',
                            ),
                            const SizedBox(height: 55),
                            LayoutBuilder(
                              builder: (context, c) {
                                final cols = c.maxWidth > 850 ? 3 : 1;
                                return GridView.count(
                                  crossAxisCount: cols,
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                  childAspectRatio: cols == 3 ? 1.18 : 2.2,
                                  children: [
                                    infoCard(
                                      ar,
                                      Icons.speed_outlined,
                                      'Faster Workflow',
                                      'سير عمل أسرع',
                                      'AI prepares the first structured MARC draft and reduces repetitive transcription.',
                                      'يُعد الذكاء الاصطناعي المسودة الأولى لتسجيلة MARC ويقلل الإدخال اليدوي المتكرر.',
                                    ),
                                    infoCard(
                                      ar,
                                      Icons.person_search_outlined,
                                      'Human in Control',
                                      'الإنسان في التحكم',
                                      'The librarian reviews, corrects and approves the final record before export.',
                                      'يقوم أمين المكتبة بمراجعة وتصحيح واعتماد التسجيلة النهائية قبل التصدير.',
                                    ),
                                    infoCard(
                                      ar,
                                      Icons.translate,
                                      'Bilingual by Design',
                                      'ثنائي اللغة',
                                      'Built for Arabic and English cataloguing environments.',
                                      'مصمم لبيئات الفهرسة باللغة العربية والإنجليزية.',
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // FEATURES
                  Container(
                    key: featuresKey,
                    width: double.infinity,
                    color: const Color(0xFFF6F8FC),
                    padding: EdgeInsets.symmetric(
                      horizontal: desktop ? 60 : 20,
                      vertical: 95,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1150),
                        child: Column(
                          children: [
                            titleBlock(
                              ar,
                              'Powerful Features',
                              'مزايا قوية',
                              'Everything Needed for AI-Assisted MARC Cataloguing',
                              'كل ما تحتاجه لفهرسة MARC بمساعدة الذكاء الاصطناعي',
                              'Version 1.0 combines AI analysis with professional librarian review in one responsive workflow.',
                              'يجمع الإصدار 1.0 بين تحليل الذكاء الاصطناعي والمراجعة المهنية لأمين المكتبة ضمن سير عمل متجاوب.',
                            ),
                            const SizedBox(height: 55),
                            LayoutBuilder(
                              builder: (context, c) {
                                final cols = c.maxWidth > 900
                                    ? 3
                                    : c.maxWidth > 600
                                        ? 2
                                        : 1;
                                return GridView.count(
                                  crossAxisCount: cols,
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                  childAspectRatio: cols == 3 ? 1.1 : 1.35,
                                  children: [
                                    infoCard(
                                      ar,
                                      Icons.auto_awesome,
                                      'AI MARC Generation',
                                      'إنشاء MARC بالذكاء الاصطناعي',
                                      'Generate structured MARC 21 drafts from bibliographic evidence.',
                                      'إنشاء مسودات MARC 21 منظمة من الأدلة الببليوجرافية.',
                                    ),
                                    infoCard(
                                      ar,
                                      Icons.collections_outlined,
                                      'Multiple Page Analysis',
                                      'تحليل صفحات متعددة',
                                      'Combine title pages, copyright pages, contents, images and PDFs.',
                                      'دمج صفحة العنوان وصفحة الحقوق والمحتويات والصور وملفات PDF.',
                                    ),
                                    infoCard(
                                      ar,
                                      Icons.edit_note_outlined,
                                      'Review & Edit',
                                      'مراجعة وتعديل',
                                      'Every AI-generated field remains editable before approval.',
                                      'يمكن تعديل كل حقل أنشأه الذكاء الاصطناعي قبل الاعتماد.',
                                    ),
                                    infoCard(
                                      ar,
                                      Icons.add_card_outlined,
                                      'Custom MARC Fields',
                                      'حقول MARC إضافية',
                                      'Add local or additional MARC fields when required.',
                                      'إضافة حقول MARC محلية أو إضافية عند الحاجة.',
                                    ),
                                    infoCard(
                                      ar,
                                      Icons.shopping_cart_checkout,
                                      'Master MARC Cart',
                                      'سلة MARC الرئيسية',
                                      'Collect multiple approved records for one batch export.',
                                      'تجميع تسجيلات متعددة معتمدة للتصدير في دفعة واحدة.',
                                    ),
                                    infoCard(
                                      ar,
                                      Icons.download_outlined,
                                      'Batch Excel Export',
                                      'تصدير Excel دفعة واحدة',
                                      'Download approved records in a structured workbook.',
                                      'تنزيل التسجيلات المعتمدة في ملف Excel منظم.',
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // HOW
                  Container(
                    key: howKey,
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: desktop ? 60 : 20,
                      vertical: 95,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFEAF0FF),
                          Color(0xFFF8FAFF),
                        ],
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1150),
                        child: Column(
                          children: [
                            titleBlock(
                              ar,
                              'How It Works',
                              'كيف يعمل',
                              'From Book Pages to Approved MARC',
                              'من صفحات الكتاب إلى تسجيلة MARC معتمدة',
                              'A simple workflow keeps AI speed and professional librarian judgement working together.',
                              'سير عمل بسيط يجمع بين سرعة الذكاء الاصطناعي والحكم المهني لأمين المكتبة.',
                            ),
                            const SizedBox(height: 50),
                            LayoutBuilder(
                              builder: (context, c) {
                                final cols = c.maxWidth > 900
                                    ? 5
                                    : c.maxWidth > 600
                                        ? 2
                                        : 1;
                                final steps = [
                                  (
                                    '01',
                                    Icons.cloud_upload_outlined,
                                    'Upload',
                                    'رفع الملفات',
                                    'Take photos or upload images and PDFs.',
                                    'التقط الصور أو ارفع الصور وملفات PDF.'
                                  ),
                                  (
                                    '02',
                                    Icons.psychology_outlined,
                                    'AI Analyse',
                                    'تحليل AI',
                                    'AI examines bibliographic evidence.',
                                    'يحلل الذكاء الاصطناعي الأدلة الببليوجرافية.'
                                  ),
                                  (
                                    '03',
                                    Icons.dataset_outlined,
                                    'Generate MARC',
                                    'إنشاء MARC',
                                    'A structured MARC 21 draft is prepared.',
                                    'يتم إعداد مسودة MARC 21 منظمة.'
                                  ),
                                  (
                                    '04',
                                    Icons.fact_check_outlined,
                                    'Review',
                                    'المراجعة',
                                    'The librarian edits and approves the record.',
                                    'يقوم أمين المكتبة بالتعديل والاعتماد.'
                                  ),
                                  (
                                    '05',
                                    Icons.download_done_outlined,
                                    'Export',
                                    'التصدير',
                                    'Approved records enter the cart and export.',
                                    'تدخل التسجيلات المعتمدة إلى السلة ثم يتم تصديرها.'
                                  ),
                                ];
                                return GridView.count(
                                  crossAxisCount: cols,
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: cols == 5 ? .78 : 1.3,
                                  children: [
                                    for (final s in steps)
                                      _StepCard(
                                        number: s.$1,
                                        icon: s.$2,
                                        title: tr(ar, s.$3, s.$4),
                                        text: tr(ar, s.$5, s.$6),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 40),
                            FilledButton.icon(
                              onPressed: launchApp,
                              style: FilledButton.styleFrom(
                                backgroundColor: navy,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 18,
                                ),
                              ),
                              icon: const Icon(Icons.rocket_launch_outlined),
                              label: Text(
                                tr(
                                  ar,
                                  'Launch MARC Assistant',
                                  'تشغيل مساعد MARC',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // PRICING
                  Container(
                    key: pricingKey,
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: desktop ? 60 : 20,
                      vertical: 95,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          children: [
                            titleBlock(
                              ar,
                              'Flexible Credits',
                              'رصيد مرن',
                              'Pay for the Cataloguing You Need',
                              'ادفع مقابل الفهرسة التي تحتاجها',
                              'Version 1.0 will introduce secure user accounts and MARC credits. Final prices will be confirmed after real AI usage-cost measurement.',
                              'سيقدم الإصدار 1.0 حسابات مستخدمين آمنة ورصيد MARC. سيتم اعتماد الأسعار النهائية بعد قياس تكلفة الاستخدام الفعلية للذكاء الاصطناعي.',
                            ),
                            const SizedBox(height: 55),
                            LayoutBuilder(
                              builder: (context, c) {
                                final cols = c.maxWidth > 850
                                    ? 4
                                    : c.maxWidth > 550
                                        ? 2
                                        : 1;
                                return GridView.count(
                                  crossAxisCount: cols,
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: cols == 4 ? .72 : 1.05,
                                  children: [
                                    priceCard(
                                      ar,
                                      tr(ar, 'Free Trial', 'تجربة مجانية'),
                                      tr(
                                        ar,
                                        '3 MARC records',
                                        '3 تسجيلات MARC',
                                      ),
                                      'AED 0',
                                    ),
                                    priceCard(
                                      ar,
                                      tr(ar, 'Starter', 'البداية'),
                                      tr(
                                        ar,
                                        '50 MARC credits',
                                        '50 رصيد MARC',
                                      ),
                                      'Coming Soon',
                                    ),
                                    priceCard(
                                      ar,
                                      tr(ar, 'Professional', 'احترافي'),
                                      tr(
                                        ar,
                                        '200 MARC credits',
                                        '200 رصيد MARC',
                                      ),
                                      'Coming Soon',
                                      featured: true,
                                    ),
                                    priceCard(
                                      ar,
                                      tr(ar, 'Library', 'المكتبة'),
                                      tr(
                                        ar,
                                        'Institutional credits',
                                        'رصيد للمؤسسات',
                                      ),
                                      tr(ar, 'Contact Us', 'تواصل معنا'),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // FAQ
                  Container(
                    key: faqKey,
                    width: double.infinity,
                    color: const Color(0xFFF6F8FC),
                    padding: EdgeInsets.symmetric(
                      horizontal: desktop ? 60 : 20,
                      vertical: 95,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Column(
                          children: [
                            titleBlock(
                              ar,
                              'FAQ',
                              'الأسئلة الشائعة',
                              'Questions Librarians May Ask',
                              'أسئلة قد يطرحها أمناء المكتبات',
                              'The platform is designed as an AI assistant with librarian review at the centre of the workflow.',
                              'تم تصميم المنصة كمساعد ذكي مع جعل مراجعة أمين المكتبة محور سير العمل.',
                            ),
                            const SizedBox(height: 38),
                            _Faq(
                              title: tr(
                                ar,
                                'Does AI replace the librarian?',
                                'هل يحل الذكاء الاصطناعي محل أمين المكتبة؟',
                              ),
                              text: tr(
                                ar,
                                'No. AI prepares a draft. The librarian reviews, edits and approves the final MARC record.',
                                'لا. يقوم الذكاء الاصطناعي بإعداد المسودة، بينما يراجع أمين المكتبة التسجيلة ويعدلها ويعتمدها.',
                              ),
                            ),
                            _Faq(
                              title: tr(
                                ar,
                                'Can I upload multiple pages for one book?',
                                'هل يمكن رفع عدة صفحات لكتاب واحد؟',
                              ),
                              text: tr(
                                ar,
                                'Yes. Title pages, copyright pages, contents, images and PDFs can be combined before MARC generation.',
                                'نعم. يمكن دمج صفحة العنوان وصفحة الحقوق والمحتويات والصور وملفات PDF قبل إنشاء MARC.',
                              ),
                            ),
                            _Faq(
                              title: tr(
                                ar,
                                'Does it support Arabic?',
                                'هل يدعم اللغة العربية؟',
                              ),
                              text: tr(
                                ar,
                                'Yes. The interface and cataloguing workflow support both Arabic and English.',
                                'نعم. تدعم الواجهة وسير عمل الفهرسة اللغتين العربية والإنجليزية.',
                              ),
                            ),
                            _Faq(
                              title: tr(
                                ar,
                                'Can records be exported?',
                                'هل يمكن تصدير التسجيلات؟',
                              ),
                              text: tr(
                                ar,
                                'Version 1.0 provides reviewed batch export to Excel. Native MARC and LMS integrations are planned for later versions.',
                                'يوفر الإصدار 1.0 تصدير التسجيلات المعتمدة إلى Excel، بينما تم التخطيط لتصدير MARC والتكامل مع أنظمة المكتبات في الإصدارات اللاحقة.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // CTA
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 80,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF071A33),
                          Color(0xFF173E68),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          tr(
                            ar,
                            'Ready to Modernise Your Cataloguing Workflow?',
                            'هل أنت مستعد لتحديث سير عمل الفهرسة؟',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr(
                            ar,
                            'Experience AI-assisted MARC cataloguing while keeping professional librarians in control.',
                            'اكتشف فهرسة MARC بمساعدة الذكاء الاصطناعي مع إبقاء التحكم المهني بيد أمناء المكتبات.',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          onPressed: launchApp,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: navy,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 18,
                            ),
                          ),
                          icon: const Icon(Icons.rocket_launch_outlined),
                          label: Text(
                            tr(ar, 'Launch Version 1.0', 'تشغيل الإصدار 1.0'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // FOOTER
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF041122),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 32,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'MARC AI Assistant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          tr(
                            ar,
                            'AI-Assisted MARC 21 Cataloguing',
                            'فهرسة MARC 21 بمساعدة الذكاء الاصطناعي',
                          ),
                          style: const TextStyle(color: Colors.white54),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Version 1.0',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopNav extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TopNav({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _DrawerNav extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DrawerNav({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(label), onTap: onTap);
  }
}

class _HeroText extends StatelessWidget {
  final bool ar;
  final VoidCallback launchApp;
  final VoidCallback how;
  const _HeroText({
    required this.ar,
    required this.launchApp,
    required this.how,
  });

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width > 1000;
    return Column(
      crossAxisAlignment:
          desktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.10),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            tr(
              ar,
              'VERSION 1.0 • AI FOR LIBRARIES',
              'الإصدار 1.0 • الذكاء الاصطناعي للمكتبات',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          tr(
            ar,
            'AI-Powered MARC 21 Cataloguing for Modern Libraries',
            'فهرسة MARC 21 بالذكاء الاصطناعي للمكتبات الحديثة',
          ),
          textAlign: desktop ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: desktop ? 58 : 38,
            height: 1.08,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Text(
            tr(
              ar,
              'Transform book pages, PDFs, theses and dissertations into structured MARC 21 records. AI accelerates the work while professional librarians remain in control of review and approval.',
              'حوّل صفحات الكتب وملفات PDF والرسائل والأطروحات إلى تسجيلات MARC 21 منظمة. يسرّع الذكاء الاصطناعي العمل مع بقاء المراجعة والاعتماد بيد أمين المكتبة المتخصص.',
            ),
            textAlign: desktop ? TextAlign.start : TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              height: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: desktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: launchApp,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _LandingPageState.navy,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              ),
              icon: const Icon(Icons.rocket_launch_outlined),
              label: Text(tr(ar, 'Try MARC Assistant', 'جرّب مساعد MARC')),
            ),
            OutlinedButton.icon(
              onPressed: how,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              ),
              icon: const Icon(Icons.play_circle_outline),
              label: Text(tr(ar, 'See How It Works', 'شاهد كيف يعمل')),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroDemo extends StatelessWidget {
  const _HeroDemo();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white24),
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DemoHeader(),
            SizedBox(height: 22),
            _MarcLine('100', r'1# $a Abdullah, Yameen.'),
            _MarcLine(
              '245',
              r'10 $a Artificial intelligence in libraries / $c Yameen Abdullah.',
            ),
            _MarcLine(
              '264',
              r'#1 $a Dubai : $b Library AI Press, $c 2026.',
            ),
            _MarcLine(
              '300',
              r'## $a 245 pages : $b illustrations ; $c 24 cm.',
            ),
            _MarcLine(
              '650',
              r'#4 $a Artificial intelligence $x Library applications.',
            ),
            SizedBox(height: 10),
            _Approved(),
          ],
        ),
      ),
    );
  }
}

class _DemoHeader extends StatelessWidget {
  const _DemoHeader();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _Dot(Color(0xFFFF6B6B)),
        const SizedBox(width: 7),
        const _Dot(Color(0xFFFFCC5C)),
        const SizedBox(width: 7),
        const _Dot(Color(0xFF45D483)),
        const Spacer(),
        Text(
          'MARC AI',
          style: TextStyle(
            color: _LandingPageState.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _MarcLine extends StatelessWidget {
  final String tag;
  final String text;
  const _MarcLine(this.tag, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE4EBFF),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF345EDB),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF26384E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Approved extends StatelessWidget {
  const _Approved();
  @override
  Widget build(BuildContext context) {
    final ar = appArabic.value;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: Color(0xFF14804A)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              tr(
                ar,
                'Librarian reviewed & approved',
                'تمت المراجعة والاعتماد بواسطة أمين المكتبة',
              ),
              style: const TextStyle(
                color: Color(0xFF14804A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Trust extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Trust(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _LandingPageState.accent),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF26384E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

class _Check extends StatelessWidget {
  final String text;
  final bool featured;
  const _Check({required this.text, required this.featured});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 20,
            color: featured ? Colors.white : _LandingPageState.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color:
                    featured ? Colors.white : _LandingPageState.navy,
              ),
            ),
          ),
        ],
      );
}

class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String text;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E9F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _LandingPageState.accent),
              ),
              const Spacer(),
              Text(
                number,
                style: TextStyle(
                  color: _LandingPageState.navy.withOpacity(.15),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: _LandingPageState.navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  final String title;
  final String text;
  const _Faq({required this.title, required this.text});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE4E9F1)),
        ),
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF071A33),
              fontWeight: FontWeight.w800,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
}

// ============================================================
// SHARED TYPES
// ============================================================

class LanguageButton extends StatelessWidget {
  final bool isArabic;
  const LanguageButton({
    super.key,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: TextButton.icon(
          onPressed: () => appArabic.value = !appArabic.value,
          icon: const Icon(Icons.language),
          label: Text(isArabic ? 'English' : 'العربية'),
        ),
      );
}

class ReviewResult {
  final Map<String, dynamic> record;
  final bool approved;
  ReviewResult({required this.record, required this.approved});
}

class CustomMarcField {
  String tag;
  String indicators;
  String value;

  CustomMarcField({
    required this.tag,
    required this.indicators,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'indicators': indicators,
        'value': value,
      };

  factory CustomMarcField.fromJson(Map<String, dynamic> json) {
    return CustomMarcField(
      tag: json['tag']?.toString() ?? '',
      indicators: json['indicators']?.toString() ?? '##',
      value: json['value']?.toString() ?? '',
    );
  }
}

// ============================================================
// MARC APP HOME
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const backendBaseUrl = 'https://dpa-marc-api.onrender.com';

  final List<PlatformFile> selectedFiles = [];
  Map<String, dynamic>? marcRecord;
  final List<Map<String, dynamic>> marcCart = [];

  bool isAnalyzing = false;
  bool isReviewed = false;
  String statusEnglish = 'Ready to catalogue a new item.';
  String statusArabic = 'جاهز لفهرسة مادة جديدة.';

  void setStatus(String en, String ar) {
    setState(() {
      statusEnglish = en;
      statusArabic = ar;
    });
  }

  Future<void> pickFiles(bool ar) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        selectedFiles.addAll(result.files);
        marcRecord = null;
        isReviewed = false;
        statusEnglish =
            '${selectedFiles.length} file(s) selected for one bibliographic item. You can add more files before generating MARC.';
        statusArabic =
            'تم اختيار ${selectedFiles.length} ملف/ملفات لمادة ببليوجرافية واحدة. يمكنك إضافة المزيد قبل إنشاء MARC.';
      });
    } catch (e) {
      setStatus(
        'File selection error: $e',
        'خطأ في اختيار الملفات: $e',
      );
    }
  }

  void removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
      marcRecord = null;
      isReviewed = false;
      if (selectedFiles.isEmpty) {
        statusEnglish = 'No files selected.';
        statusArabic = 'لم يتم اختيار أي ملفات.';
      } else {
        statusEnglish = '${selectedFiles.length} file(s) selected.';
        statusArabic = 'تم اختيار ${selectedFiles.length} ملف/ملفات.';
      }
    });
  }

  void clearFiles() {
    setState(() {
      selectedFiles.clear();
      marcRecord = null;
      isReviewed = false;
      statusEnglish = 'Files cleared. Ready for a new item.';
      statusArabic = 'تم مسح الملفات. جاهز لمادة جديدة.';
    });
  }

  Future<void> generateMarcRecord(bool ar) async {
    if (selectedFiles.isEmpty) {
      showMessage(
        tr(
          ar,
          'Please upload one or more bibliographic files first.',
          'يرجى رفع ملف ببليوجرافي واحد أو أكثر أولاً.',
        ),
      );
      return;
    }

    if (selectedFiles.any((f) => f.bytes == null)) {
      showMessage(
        tr(
          ar,
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
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendBaseUrl/marc/analyze'),
      );

      for (final f in selectedFiles) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            f.bytes!,
            filename: f.name,
          ),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      dynamic decoded;
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode != 200) {
        final message = decoded is Map
            ? decoded['message']?.toString() ?? 'Server error.'
            : 'Server error.';
        showMessage(
          tr(
            ar,
            'Unable to generate MARC record: $message',
            'تعذر إنشاء تسجيلة MARC: $message',
          ),
        );
        return;
      }

      if (decoded is! Map) {
        showMessage(
          tr(
            ar,
            'The backend returned an invalid response.',
            'أرجع الخادم استجابة غير صالحة.',
          ),
        );
        return;
      }

      final data = Map<String, dynamic>.from(decoded);
if (data['success'] == true && data['record'] != null) {
  final record = Map<String, dynamic>.from(data['record'] as Map);
  record.putIfAbsent('custom_fields', () => []);

  setState(() {
    marcRecord = record;
    statusEnglish =
        'MARC 21 record generated successfully. Librarian review is required.';
    statusArabic =
        'تم إنشاء سجل MARC 21 بنجاح. يلزم مراجعة أمين المكتبة.';
  });
  await Supabase.instance.client.rpc('increment_marc_usage');

  showMessage(
    tr(
      ar,
      'MARC 21 record generated successfully.',
      'تم إنشاء سجل MARC 21 بنجاح.',
    ),
  );
} else {
        final message =
            data['message']?.toString() ?? 'Unable to generate MARC record.';
        setStatus(message, 'تعذر إنشاء تسجيلة MARC: $message');
        showMessage(ar ? 'تعذر إنشاء تسجيلة MARC: $message' : message);
      }
    } catch (e) {
      setStatus('Analysis error: $e', 'خطأ أثناء التحليل: $e');
      showMessage(
        tr(ar, 'Analysis error: $e', 'حدث خطأ أثناء التحليل: $e'),
      );
    } finally {
      if (mounted) {
        setState(() => isAnalyzing = false);
      }
    }
  }

  Future<void> reviewMarcRecord(bool ar) async {
    if (marcRecord == null) {
      showMessage(
        tr(
          ar,
          'Generate a MARC record first.',
          'قم بإنشاء تسجيلة MARC أولاً.',
        ),
      );
      return;
    }

    final result = await Navigator.push<ReviewResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MarcReviewPage(
          record: Map<String, dynamic>.from(marcRecord!),
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      marcRecord = result.record;
      isReviewed = result.approved;
      if (result.approved) {
        statusEnglish =
            'MARC record reviewed and approved. Ready to add to Master Cart.';
        statusArabic =
            'تمت مراجعة واعتماد تسجيلة MARC. جاهزة للإضافة إلى السلة الرئيسية.';
      } else {
        statusEnglish = 'MARC changes saved. Approval is still required.';
        statusArabic = 'تم حفظ تعديلات MARC. ما زال الاعتماد مطلوباً.';
      }
    });
  }
Future<void> generateAiSummary(bool ar) async {
  if (selectedFiles.isEmpty) {
    showMessage(
      tr(
        ar,
        'Please upload one or more pages first.',
        'يرجى رفع صورة أو ملف PDF واحد على الأقل أولاً.',
      ),
    );
    return;
  }

  if (selectedFiles.any((f) => f.bytes == null)) {
    showMessage(
      tr(
        ar,
        'Unable to read one or more selected files.',
        'تعذر قراءة ملف واحد أو أكثر من الملفات المحددة.',
      ),
    );
    return;
  }

  setState(() {
    isAnalyzing = true;
    statusEnglish = 'AI is generating the summary / abstract...';
    statusArabic = 'يقوم الذكاء الاصطناعي بإنشاء الملخص...';
  });

  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$backendBaseUrl/marc/summary'),
    );

    // Send all uploaded images/PDFs
    for (final f in selectedFiles) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'files',
          f.bytes!,
          filename: f.name,
        ),
      );
    }

    request.fields['language'] = ar ? 'ar' : 'en';
    request.fields['length'] = 'standard';

    // Existing MARC record can help the AI understand the item
    if (marcRecord != null) {
      request.fields['marc_record'] = jsonEncode(marcRecord);
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    dynamic decoded;

    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw Exception('Invalid server response: $body');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded is Map && decoded['message'] != null
              ? decoded['message'].toString()
              : 'Summary generation failed.';

      throw Exception(message);
    }

    if (decoded is! Map) {
      throw Exception('Invalid summary response.');
    }

    final success = decoded['success'] == true;

    if (!success) {
      throw Exception(
        decoded['message']?.toString() ??
            'Unable to generate AI summary.',
      );
    }

    final summary = decoded['summary']?.toString().trim() ?? '';

    if (summary.isEmpty) {
      throw Exception('The AI returned an empty summary.');
    }

    setState(() {
      marcRecord ??= <String, dynamic>{};

      // MARC 21 field 520
      marcRecord!['field_520'] = '520 ## \$a $summary';

      isReviewed = false;

      statusEnglish =
          'AI Summary generated successfully and added to MARC field 520.';
      statusArabic =
          'تم إنشاء الملخص وإضافته بنجاح إلى حقل MARC 520.';
    });

    showMessage(
      tr(
        ar,
        'AI Summary generated and added to MARC 520.',
        'تم إنشاء الملخص وإضافته إلى حقل MARC 520.',
      ),
    );
  } catch (e) {
    if (!mounted) return;

    showMessage(
      tr(
        ar,
        'Unable to generate AI summary: $e',
        'تعذر إنشاء الملخص بالذكاء الاصطناعي: $e',
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isAnalyzing = false;
      });
    }
  }
}
  String recordTitle(Map<String, dynamic> record) {
    String t = record['field_245']?.toString().trim() ?? '';
    if (t.isEmpty) return 'Untitled MARC record';
    t = t.replaceFirst(RegExp(r'^245\s+\S+\s+'), '');
    t = t.replaceFirst(RegExp(r'^\$a\s*'), '');
    final slash = t.indexOf(r'/$c');
    if (slash >= 0) t = t.substring(0, slash);
    return t.replaceAll(r'$b', ' ').replaceAll(r'$c', ' ').trim();
  }

  String recordAuthor(Map<String, dynamic> record) {
    String t = record['field_100']?.toString().trim() ?? '';
    if (t.isEmpty) return '';
    t = t.replaceFirst(RegExp(r'^100\s+\S+\s+'), '');
    t = t.replaceFirst(RegExp(r'^\$a\s*'), '');
    return t.trim();
  }

  String recordKey(Map<String, dynamic> record) {
    final isbn = record['field_020'];
    if (isbn is List && isbn.isNotEmpty) {
      final v = isbn.map((e) => e.toString()).join('|').trim().toLowerCase();
      if (v.isNotEmpty) return 'ISBN:$v';
    }
    return 'TA:${record['field_245']?.toString().trim().toLowerCase() ?? ''}|${record['field_100']?.toString().trim().toLowerCase() ?? ''}';
  }

  void addApprovedRecordToCart(bool ar) {
    if (marcRecord == null || !isReviewed) {
      showMessage(
        tr(
          ar,
          'Review and approve the MARC record first.',
          'يرجى مراجعة واعتماد تسجيلة MARC أولاً.',
        ),
      );
      return;
    }

    final key = recordKey(marcRecord!);
    if (marcCart.any((r) => recordKey(r) == key)) {
      showMessage(
        tr(
          ar,
          'This record is already in the Master MARC Cart.',
          'هذه التسجيلة موجودة بالفعل في سلة MARC الرئيسية.',
        ),
      );
      return;
    }

    final copy = Map<String, dynamic>.from(marcRecord!);
    if (copy['custom_fields'] is List) {
      copy['custom_fields'] = List<dynamic>.from(copy['custom_fields']);
    }

    setState(() {
      marcCart.add(copy);
      selectedFiles.clear();
      marcRecord = null;
      isReviewed = false;
      statusEnglish =
          'Approved record added to Master MARC Cart. Ready for the next item.';
      statusArabic =
          'تمت إضافة التسجيلة المعتمدة إلى سلة MARC الرئيسية. جاهز للمادة التالية.';
    });
  }

  Future<void> openCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarcCartPage(
          records: marcCart,
          backendBaseUrl: backendBaseUrl,
          recordTitle: recordTitle,
          recordAuthor: recordAuthor,
          onCartChanged: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget actionCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap, {
    bool loading = false,
    Widget? trailing,
  }) {
    final enabled = onTap != null;
    return Card(
      elevation: enabled ? 2 : 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: enabled
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(15),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(icon, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.arrow_forward_ios, size: 17),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appArabic,
      builder: (context, ar, _) => Scaffold(
        appBar: AppBar(
          title: Text(
  tr(ar, 'MARC AI Assistant', 'مساعد MARC الذكي للمكتبة'),
),
          centerTitle: true,
          actions: [
            LanguageButton(isArabic: ar),
            Badge(
              label: Text(marcCart.length.toString()),
              isLabelVisible: marcCart.isNotEmpty,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: openCart,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_library_outlined, size: 58),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    tr(
                      ar,
                      'AI MARC 21 Cataloguing Assistant',
                      'مساعد الفهرسة الذكي MARC 21',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      ar,
                      'Arabic & English Books, Theses and Dissertations',
                      'الكتب والرسائل والأطروحات باللغة العربية والإنجليزية',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  actionCard(
                    Icons.cloud_upload_outlined,
                    tr(
                      ar,
                      '1. Upload / Add Bibliographic Files',
                      '1. رفع / إضافة الملفات الببليوجرافية',
                    ),
                    tr(
                      ar,
                      'Take or select photos/PDFs. Add more without losing earlier files.',
                      'التقط أو اختر صوراً وملفات PDF وأضف المزيد دون فقد الملفات السابقة.',
                    ),
                    () => pickFiles(ar),
                  ),
                  if (selectedFiles.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(
                              tr(
                                ar,
                                '${selectedFiles.length} file(s) currently selected',
                                'عدد الملفات المحددة حالياً: ${selectedFiles.length}',
                              ),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            for (int i = 0; i < selectedFiles.length; i++)
                              ListTile(
                                leading: Icon(
                                  selectedFiles[i]
                                              .extension
                                              ?.toLowerCase() ==
                                          'pdf'
                                      ? Icons.picture_as_pdf_outlined
                                      : Icons.image_outlined,
                                ),
                                title: Text(selectedFiles[i].name),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => removeFile(i),
                                ),
                              ),
                            Wrap(
                              spacing: 8,
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: () => pickFiles(ar),
                                  icon: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                  ),
                                  label: Text(
                                    tr(
                                      ar,
                                      'Add More Photos / PDFs',
                                      'إضافة صور / ملفات PDF أخرى',
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: clearFiles,
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(
                                    tr(ar, 'Clear All Files', 'مسح جميع الملفات'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  actionCard(
                    Icons.auto_awesome,
                    tr(
                      ar,
                      '2. Generate MARC Record',
                      '2. إنشاء تسجيلة MARC',
                    ),
                    tr(
                      ar,
                      'AI analyses all selected pages together and creates one MARC 21 record',
                      'يحلل الذكاء الاصطناعي جميع الصفحات المحددة معاً وينشئ تسجيلة MARC 21 واحدة',
                    ),
                    isAnalyzing
    ? null
    : () async {
        try {
          final result = await Supabase.instance.client
    .rpc('check_marc_credit');

final data = Map<String, dynamic>.from(result as Map);

final bool allowed = data['allowed'] == true;
final bool unlimited = data['unlimited'] == true;
final int used = (data['used'] as num?)?.toInt() ?? 0;
final int remaining = (data['remaining'] as num?)?.toInt() ?? 0;
final String packageName =
    data['package_name']?.toString() ?? 'Unknown';

if (!allowed) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        tr(
          ar,
          'Your $packageName MARC record limit has been reached.',
          'لقد وصلت إلى الحد الأقصى لسجلات MARC في باقة $packageName.',
        ),
      ),
    ),
  );

  return;
}

          

          await generateMarcRecord(ar);
  } catch (e, stackTrace) {
  debugPrint('MARC ACCESS ERROR TYPE: ${e.runtimeType}');
  debugPrint('MARC ACCESS ERROR: $e');
  debugPrint('MARC ACCESS STACK: $stackTrace');

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 10),
      content: Text(
        'MARC access error [${e.runtimeType}]: $e',
      ),
    ),
  );
}
},
loading: isAnalyzing,
                  ),
                  actionCard(
  Icons.summarize_outlined,
  tr(
    ar,
    '3. Generate AI Summary / Abstract',
    '3. إنشاء الملخص بالذكاء الاصطناعي',
  ),
 tr(
  ar,
  'AI creates a summary from the uploaded images/PDF and prepares MARC field 520.',
  'ينشئ الذكاء الاصطناعي ملخصاً من الصور أو ملفات PDF المرفوعة ويجهز حقل MARC 520.',
),
isAnalyzing
    ? null
    : () => generateAiSummary(ar),
),


                  actionCard(
                    Icons.fact_check_outlined,
                    tr(
                      ar,
                      '4. Review & Edit MARC',
                      '4. مراجعة وتعديل MARC',
                    ),
                    tr(
                      ar,
                      'Librarian verifies, corrects, adds fields and approves the record',
                      'يقوم أمين المكتبة بالمراجعة والتصحيح وإضافة الحقول واعتماد التسجيلة',
                    ),
                    marcRecord == null ? null : () => reviewMarcRecord(ar),
                  ),
                  actionCard(
                    Icons.add_shopping_cart,
                    tr(
                      ar,
                      '5. Add Approved Record to Cart',
                      '5. إضافة التسجيلة المعتمدة إلى السلة',
                    ),
                    isReviewed
                        ? tr(
                            ar,
                            'Approved record is ready for the Master MARC Cart',
                            'التسجيلة المعتمدة جاهزة للإضافة إلى سلة MARC الرئيسية',
                          )
                        : tr(
                            ar,
                            'Review and approve the MARC record first',
                            'يرجى مراجعة واعتماد تسجيلة MARC أولاً',
                          ),
                    isReviewed ? () => addApprovedRecordToCart(ar) : null,
                  ),
                  actionCard(
                    Icons.inventory_2_outlined,
                    tr(
                      ar,
                      '5. View Master MARC Cart',
                      '5. عرض سلة MARC الرئيسية',
                    ),
                    marcCart.isEmpty
                        ? tr(
                            ar,
                            'No records currently in the cart',
                            'لا توجد تسجيلات حالياً في السلة',
                          )
                        : tr(
                            ar,
                            '${marcCart.length} approved record(s) ready for Excel download',
                            '${marcCart.length} تسجيلة معتمدة جاهزة للتصدير إلى Excel',
                          ),
                    openCart,
                    trailing: CircleAvatar(
                      radius: 18,
                      child: Text(marcCart.length.toString()),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(ar ? statusArabic : statusEnglish),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CART PAGE
// ============================================================

class MarcCartPage extends StatefulWidget {
  final List<Map<String, dynamic>> records;
  final String backendBaseUrl;
  final String Function(Map<String, dynamic>) recordTitle;
  final String Function(Map<String, dynamic>) recordAuthor;
  final VoidCallback onCartChanged;

  const MarcCartPage({
    super.key,
    required this.records,
    required this.backendBaseUrl,
    required this.recordTitle,
    required this.recordAuthor,
    required this.onCartChanged,
  });

  @override
  State<MarcCartPage> createState() => _MarcCartPageState();
}

class _MarcCartPageState extends State<MarcCartPage> {
  bool exporting = false;

  void showMessage(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> exportAll(bool ar) async {
    if (widget.records.isEmpty) return;

    final count = widget.records.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          tr(
            ar,
            'Download Master MARC Excel',
            'تنزيل ملف Excel الرئيسي لـ MARC',
          ),
        ),
        content: Text(
          tr(
            ar,
            'Create one Excel workbook containing all $count approved record(s)? The cart will be cleared after successful download.',
            'هل تريد إنشاء ملف Excel واحد يحتوي على جميع التسجيلات المعتمدة وعددها $count؟ سيتم تفريغ السلة بعد نجاح التنزيل.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(ar, 'Cancel', 'إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(ar, 'Download Excel', 'تنزيل Excel')),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => exporting = true);

    try {
      final response = await http.post(
        Uri.parse('${widget.backendBaseUrl}/marc/export-batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'records': widget.records}),
      );

      if (response.statusCode != 200) {
        showMessage(
          tr(ar, 'Unable to create Excel workbook.', 'تعذر إنشاء ملف Excel.'),
        );
        return;
      }

      String filename = 'DPA_MARC_Master.xlsx';
      final disposition = response.headers['content-disposition'];
      if (disposition != null) {
        final match =
            RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
        if (match?.group(1) != null) filename = match!.group(1)!;
      }

      final Uint8List bytes = response.bodyBytes;
      final blob = web.Blob(
        <JSAny>[bytes.toJS].toJS,
        web.BlobPropertyBag(
          type:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      );
      final objectUrl = web.URL.createObjectURL(blob);
      final anchor = web.HTMLAnchorElement();
      anchor.href = objectUrl;
      anchor.download = filename;
      web.document.body?.appendChild(anchor);
      anchor.click();
      anchor.parentNode?.removeChild(anchor);
      web.URL.revokeObjectURL(objectUrl);

      setState(() => widget.records.clear());
      widget.onCartChanged();
    } catch (e) {
      showMessage(tr(ar, 'Export error: $e', 'خطأ في التصدير: $e'));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appArabic,
      builder: (context, ar, _) => Scaffold(
        appBar: AppBar(
          title: Text(tr(ar, 'Master MARC Cart', 'سلة MARC الرئيسية')),
          actions: [LanguageButton(isArabic: ar)],
        ),
        body: widget.records.isEmpty
            ? Center(
                child: Text(
                  tr(ar, 'Master MARC Cart is empty', 'سلة MARC الرئيسية فارغة'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.records.length,
                      itemBuilder: (_, i) {
                        final record = widget.records[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${i + 1}')),
                            title: Text(widget.recordTitle(record)),
                            subtitle: Text(widget.recordAuthor(record)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                setState(() => widget.records.removeAt(i));
                                widget.onCartChanged();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: exporting ? null : () => exportAll(ar),
                          icon: exporting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download_outlined),
                          label: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              tr(
                                ar,
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
      ),
    );
  }
}

// ============================================================
// REVIEW PAGE
// ============================================================

class MarcReviewPage extends StatefulWidget {
  final Map<String, dynamic> record;
  const MarcReviewPage({
    super.key,
    required this.record,
  });

  @override
  State<MarcReviewPage> createState() => _MarcReviewPageState();
}

class _MarcReviewPageState extends State<MarcReviewPage> {
  final Map<String, TextEditingController> controllers = {};
  final List<CustomMarcField> customFields = [];
  bool showEmptyFields = false;

  final fields = [
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
    'field_520',
    'field_600',
    'field_610',
    'field_650',
    'field_651',
    'field_700',
    'field_710',
    'field_856',
    'field_949',
  ];

  final repeatable = {
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

  String label(String f, bool ar) {
    final map = {
      'field_020': tr(ar, '020 — ISBN', '020 — الرقم الدولي المعياري للكتاب'),
      'field_041': tr(ar, '041 — Language', '041 — اللغة'),
      'field_050': tr(
        ar,
        '050 — LC Classification',
        '050 — تصنيف مكتبة الكونغرس',
      ),
      'field_082': tr(
        ar,
        '082 — Dewey Decimal Classification',
        '082 — تصنيف ديوي العشري',
      ),
      'field_100': tr(ar, '100 — Main Author', '100 — المؤلف الرئيسي'),
      'field_110': tr(
        ar,
        '110 — Corporate Main Entry',
        '110 — المدخل الرئيسي للهيئة',
      ),
      'field_245': tr(
        ar,
        '245 — Title & Statement of Responsibility',
        '245 — العنوان وبيان المسؤولية',
      ),
      'field_250': tr(ar, '250 — Edition', '250 — الطبعة'),
      'field_264': tr(
        ar,
        '264 — Publication / Production',
        '264 — النشر / الإنتاج',
      ),
      'field_300': tr(
        ar,
        '300 — Physical Description',
        '300 — الوصف المادي',
      ),
      'field_490': tr(ar, '490 — Series', '490 — السلسلة'),
      'field_500': tr(ar, '500 — General Notes', '500 — الملاحظات العامة'),
      'field_502': tr(
        ar,
        '502 — Thesis / Dissertation Note',
        '502 — ملاحظة الرسالة / الأطروحة',
      ),
      'field_504': tr(
        ar,
        '504 — Bibliographical References / Index',
        '504 — المراجع الببليوجرافية / الكشاف',
        
      ),
      
'field_520': tr(
  ar,
  '520 – Summary / Abstract',
  '520 – الملخص / المستخلص',
),
      'field_505': tr(ar, '505 — Contents Note', '505 — ملاحظة المحتويات'),
      'field_600': tr(
        ar,
        '600 — Personal Name Subjects',
        '600 — رؤوس موضوعات أسماء الأشخاص',
      ),
      'field_610': tr(
        ar,
        '610 — Corporate Name Subjects',
        '610 — رؤوس موضوعات أسماء الهيئات',
      ),
      'field_650': tr(ar, '650 — Topical Subjects', '650 — رؤوس الموضوعات'),
      'field_651': tr(
        ar,
        '651 — Geographic Subjects',
        '651 — الموضوعات الجغرافية',
      ),
      'field_700': tr(
        ar,
        '700 — Added Personal Entries',
        '700 — المداخل الإضافية للأشخاص',
      ),
      'field_710': tr(
        ar,
        '710 — Added Corporate Entries',
        '710 — المداخل الإضافية للهيئات',
      ),
      'field_856': tr(
        ar,
        '856 — Electronic Access',
        '856 — الوصول الإلكتروني',
      ),
      'field_949': tr(ar, '949 — Local Call Number', '949 — رقم الاستدعاء المحلي'),
    };
    return map[f] ?? f;
  }

  @override
  void initState() {
    super.initState();
    for (final f in fields) {
      final v = widget.record[f];
      controllers[f] = TextEditingController(
        text: v is List ? v.join('\n') : (v?.toString() ?? ''),
      );
    }
    final custom = widget.record['custom_fields'];
    if (custom is List) {
      for (final item in custom) {
        if (item is Map) {
          customFields.add(
            CustomMarcField.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
  }

  Map<String, dynamic> buildRecord() {
    final updated = Map<String, dynamic>.from(widget.record);
    for (final f in fields) {
      final text = controllers[f]!.text.trim();
      updated[f] = repeatable.contains(f)
          ? (text.isEmpty
              ? []
              : text
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList())
          : (text.isEmpty ? null : text);
    }
    updated['custom_fields'] =
        customFields.map((e) => e.toJson()).toList();
    return updated;
  }

  Future<void> addField(bool ar) async {
    final tag = TextEditingController();
    final ind = TextEditingController(text: '##');
    final val = TextEditingController();

    final result = await showDialog<CustomMarcField>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(ar, 'Add MARC Field', 'إضافة حقل MARC')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tag,
              maxLength: 3,
              decoration: const InputDecoration(
                labelText: 'MARC Tag',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ind,
              maxLength: 2,
              decoration: const InputDecoration(
                labelText: 'Indicators',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: val,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Subfields / Value',
                hintText: r'$a Local note.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(ar, 'Cancel', 'إلغاء')),
          ),
          FilledButton(
            onPressed: () {
              if (!RegExp(r'^\d{3}$').hasMatch(tag.text.trim()) ||
                  val.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(
                context,
                CustomMarcField(
                  tag: tag.text.trim(),
                  indicators:
                      ind.text.trim().isEmpty ? '##' : ind.text.trim(),
                  value: val.text.trim(),
                ),
              );
            },
            child: Text(tr(ar, 'Add Field', 'إضافة الحقل')),
          ),
        ],
      ),
    );

    tag.dispose();
    ind.dispose();
    val.dispose();

    if (result != null) setState(() => customFields.add(result));
  }

  void saveChanges(bool ar) {
    final updated = buildRecord();
    widget.record
      ..clear()
      ..addAll(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(ar, 'MARC changes saved.', 'تم حفظ تعديلات MARC.'),
        ),
      ),
    );
  }

  void backToMainMenu() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appArabic,
      builder: (context, ar, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            tr(ar, 'Review & Edit MARC 21', 'مراجعة وتعديل MARC 21'),
          ),
          actions: [
            IconButton(
              tooltip: tr(ar, 'Back to Main Menu', 'العودة إلى القائمة الرئيسية'),
              onPressed: backToMainMenu,
              icon: const Icon(Icons.home_outlined),
            ),
            LanguageButton(isArabic: ar),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.fact_check_outlined, size: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tr(
                                ar,
                                'Review the populated MARC fields below. Empty fields are hidden to keep the screen clean.',
                                'راجع حقول MARC المعبأة أدناه. تم إخفاء الحقول الفارغة للحفاظ على وضوح الشاشة.',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          showEmptyFields = !showEmptyFields;
                        });
                      },
                      icon: Icon(
                        showEmptyFields
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      label: Text(
                        showEmptyFields
                            ? tr(ar, 'Hide Empty MARC Fields', 'إخفاء حقول MARC الفارغة')
                            : tr(ar, 'Show Empty MARC Fields', 'إظهار حقول MARC الفارغة'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final f in fields)
                    if (showEmptyFields || controllers[f]!.text.trim().isNotEmpty)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label(f, ar),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: controllers[f],
                                minLines: repeatable.contains(f) ? 2 : 1,
                                maxLines: null,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => addField(ar),
                      icon: const Icon(Icons.add_card_outlined),
                      label: Text(
                        tr(ar, '+ Add MARC Field', '+ إضافة حقل MARC'),
                      ),
                    ),
                  ),
                  if (customFields.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    for (int i = 0; i < customFields.length; i++)
                      Card(
                        child: ListTile(
                          title: Text(
                            '${customFields[i].tag} ${customFields[i].indicators}',
                          ),
                          subtitle: SelectableText(customFields[i].value),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                setState(() => customFields.removeAt(i)),
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => saveChanges(ar),
                      icon: const Icon(Icons.save_outlined),
                      label: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(tr(ar, 'Save Changes', 'حفظ التعديلات')),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ReviewResult(
                            record: buildRecord(),
                            approved: true,
                          ),
                        );
                      },
                      icon: const Icon(Icons.verified_outlined),
                      label: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          tr(
                            ar,
                            'Approve MARC Record',
                            'اعتماد تسجيلة MARC',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: backToMainMenu,
                      icon: const Icon(Icons.home_outlined),
                      label: Text(
                        tr(ar, 'Back to Main Menu', 'العودة إلى القائمة الرئيسية'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Please enter email and password.';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _message = 'Password must be at least 8 characters.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      if (_isLogin) {
  // 1. Authenticate email + password
  final authResponse =
      await Supabase.instance.client.auth.signInWithPassword(
    email: email,
    password: password,
  );

  final user = authResponse.user;

  if (user == null) {
    throw Exception('Unable to authenticate this account.');
  }

  // 2. Read approval status from user_profiles
  final profile = await Supabase.instance.client
      .from('user_profiles')
      .select('account_status, role')
      .eq('id', user.id)
      .maybeSingle();

  if (profile == null) {
    await Supabase.instance.client.auth.signOut();
    throw Exception(
      'User profile was not found. Please contact the administrator.',
    );
  }

  final accountStatus =
      (profile['account_status'] ?? '').toString().toLowerCase();

  // 3. Block accounts that have not been approved
  if (accountStatus == 'pending') {
    await Supabase.instance.client.auth.signOut();

    throw Exception(
      'Your registration is awaiting administrator approval.',
    );
  }

  if (accountStatus == 'rejected') {
    await Supabase.instance.client.auth.signOut();

    throw Exception(
      'Your registration request has been rejected. Please contact the administrator.',
    );
  }

  if (accountStatus == 'suspended') {
    await Supabase.instance.client.auth.signOut();

    throw Exception(
      'Your account has been suspended. Please contact the administrator.',
    );
  }

  if (accountStatus != 'active' &&
    accountStatus != 'approved') {
  await Supabase.instance.client.auth.signOut();

  throw Exception(
    'Your account is not authorized to access this system.',
  );
}

  // 4. Only approved accounts reach here
  if (!mounted) return;

  setState(() {
    _message = 'Signed in successfully.';
  });

  Navigator.pop(context);
} else {
  final response = await Supabase.instance.client.auth.signUp(
    email: email,
    password: password,
  );

  final newUser = response.user;

  if (newUser == null) {
    throw Exception(
      'Unable to create the account. Please try again.',
    );
  }

  // If Supabase automatically created a session,
  // immediately sign the new user out.
  // The user must first be approved by an administrator.
  if (response.session != null) {
    await Supabase.instance.client.auth.signOut();
  }

  if (!mounted) return;

  setState(() {
    if (response.session == null) {
      _message =
          'Registration submitted successfully. '
          'Please confirm your email if required. '
          'Your account is awaiting administrator approval.';
    } else {
      _message =
          'Registration submitted successfully. '
          'Your account is awaiting administrator approval.';
    }
  });
}
    } on AuthException catch (e) {
      setState(() {
        _message = e.message;
      });
    } catch (e) {
      setState(() {
        _message = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = appArabic.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(
            ar,
            _isLogin ? 'Sign In' : 'Create Account',
            _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 460,
            ),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr(
                        ar,
                        _isLogin
                            ? 'Welcome Back'
                            : 'Create Your Create Your MARC AI Account',
                        _isLogin
                            ? 'مرحباً بعودتك'
                            : 'إنشاء حساب MARC AI',
                      ),
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(
                        ar,
                        _isLogin
                            ? 'Sign in to access the MARC AI Assistant.'
                            : 'Create an account to receive your free trial.',
                        _isLogin
                            ? 'سجل الدخول للوصول إلى مساعد MARC الذكي.'
                            : 'أنشئ حساباً للحصول على التجربة المجانية.',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: tr(
                          ar,
                          'Email',
                          'البريد الإلكتروني',
                        ),
                        prefixIcon:
                            const Icon(Icons.email_outlined),
                        border:
                            const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: tr(
                          ar,
                          'Password',
                          'كلمة المرور',
                        ),
                        prefixIcon:
                            const Icon(Icons.lock_outline),
                        border:
                            const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_message != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Text(
                          _message!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton(
                      onPressed:
                          _loading ? null : _submit,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                tr(
                                  ar,
                                  _isLogin
                                      ? 'Sign In'
                                      : 'Create Account',
                                  _isLogin
                                      ? 'تسجيل الدخول'
                                      : 'إنشاء حساب',
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() {
                                _isLogin =
                                    !_isLogin;
                                _message = null;
                              });
                            },
                      child: Text(
                        tr(
                          ar,
                          _isLogin
                              ? 'New user? Create an account'
                              : 'Already have an account? Sign in',
                          _isLogin
                              ? 'مستخدم جديد؟ أنشئ حساباً'
                              : 'لديك حساب بالفعل؟ سجل الدخول',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(
                        ar,
                        'Free trial: 3 MARC records per registered account.',
                        'التجربة المجانية: 3 سجلات MARC لكل حساب مسجل.',
                      ),
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ar = appArabic.value;
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(ar, 'My Account', 'حسابي'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.account_circle_outlined,
                      size: 72,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      tr(ar, 'MARC AI Account', 'حساب MARC AI'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 28),

                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: Text(
                        tr(ar, 'Email', 'البريد الإلكتروني'),
                      ),
                      subtitle: Text(
                        user?.email ?? '-',
                      ),
                    ),

                    const Divider(),

                    
FutureBuilder<Map<String, dynamic>>(
  future: () async {
    final currentUser =
        Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      return <String, dynamic>{
        'role': 'user',
        'package_name': 'No package',
        'used': 0,
        'remaining': 0,
        'unlimited': false,
      };
    }

    // Get role
    final profile = await Supabase.instance.client
        .from('user_profiles')
        .select('role')
        .eq('id', currentUser.id)
        .maybeSingle();

    final role =
        profile?['role']?.toString() ?? 'user';

    // Super Admin
    if (role == 'super_admin') {
      return <String, dynamic>{
        'role': role,
        'package_name': 'Administrator',
        'used': 0,
        'remaining': null,
        'unlimited': true,
      };
    }

    // Get active subscription
    final subscription =
        await Supabase.instance.client
            .from('user_subscriptions')
            .select(
              'package_id, records_used',
            )
            .eq('user_id', currentUser.id)
            .eq('active', true)
            .maybeSingle();

    if (subscription == null) {
      return <String, dynamic>{
        'role': role,
        'package_name': 'No package',
        'used': 0,
        'remaining': 0,
        'unlimited': false,
      };
    }

    final packageId =
        subscription['package_id'];

    final used =
        (subscription['records_used'] ?? 0) as int;

    // Get assigned package
    final package =
        await Supabase.instance.client
            .from('packages')
            .select()
            .eq('id', packageId)
            .maybeSingle();

    final packageName =
        package?['name']?.toString() ??
        package?['code']?.toString().toUpperCase() ??
        'Package';

    final unlimited =
        package?['unlimited'] == true;

    final dynamic limitValue =
        package?['record_limit'] ??
        package?['records_limit'] ??
        package?['marc_limit'];

    final int limit =
        limitValue is int
            ? limitValue
            : int.tryParse(
                  limitValue?.toString() ?? '',
                ) ??
                0;

    final remaining =
        unlimited
            ? null
            : (limit - used < 0
                ? 0
                : limit - used);

    return <String, dynamic>{
      'role': role,
      'package_name': packageName,
      'used': used,
      'remaining': remaining,
      'unlimited': unlimited,
    };
  }(),

  builder: (context, snapshot) {
    if (snapshot.connectionState ==
        ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final data =
        snapshot.data ??
        <String, dynamic>{};

    final packageName =
        data['package_name']?.toString() ??
        'No package';

    final used =
        data['used'] ?? 0;

    final unlimited =
        data['unlimited'] == true;

    final remaining =
        data['remaining'];

    return Column(
      children: [
        ListTile(
          leading: const Icon(
            Icons.workspace_premium_outlined,
          ),
          title: Text(
            tr(ar, 'Plan', 'الخطة'),
          ),
          subtitle: Text(packageName),
        ),

        const Divider(),

        ListTile(
          leading: const Icon(
            Icons.auto_awesome_outlined,
          ),
          title: Text(
            tr(
              ar,
              'MARC Records Access',
              'صلاحية سجلات MARC',
            ),
          ),
          subtitle: Text(
            unlimited
                ? tr(
                    ar,
                    'Unlimited MARC records',
                    'سجلات MARC غير محدودة',
                  )
                : tr(
                    ar,
                    'Used: $used • Remaining: ${remaining ?? 0}',
                    'المستخدم: $used • المتبقي: ${remaining ?? 0}',
                  ),
          ),
        ),

        const Divider(),
      ],
    );
  },
),
FutureBuilder<Map<String, dynamic>?>(
  future: Supabase.instance.client
      .from('user_profiles')
      .select('role')
      .eq(
        'id',
        Supabase.instance.client.auth.currentUser!.id,
      )
      .maybeSingle(),
  builder: (context, snapshot) {
    final profile = snapshot.data;
    final role = profile?['role']?.toString();

    final isAdmin =
        role == 'admin' ||
        role == 'super_admin';

    if (!isAdmin) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const AdminDashboardPage(),
              ),
            );
          },
          icon: const Icon(
            Icons.admin_panel_settings_outlined,
          ),
          label: Text(
            tr(
              ar,
              'Admin Dashboard',
              'لوحة تحكم المسؤول',
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  },
),

                    FilledButton.icon(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();

                        if (!context.mounted) return;

                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.logout),
                      label: Text(
                        tr(ar, 'Sign Out', 'تسجيل الخروج'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() =>
      _AdminDashboardPageState();
}

class _AdminDashboardPageState
    extends State<AdminDashboardPage> {
  bool loading = true;
  String? errorMessage;

  List<Map<String, dynamic>> users = [];

  final List<String> packageCodes = [
    'free',
    'basic',
    'professional',
    'institutional',
    'admin',
  ];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await Supabase.instance.client
          .rpc('admin_get_users');

      final List<dynamic> data =
          result as List<dynamic>;

      setState(() {
        users = data
            .map(
              (item) =>
                  Map<String, dynamic>.from(
                item as Map,
              ),
            )
            .toList();

        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> changePackage(
    Map<String, dynamic> user,
    String packageCode,
  ) async {
    try {
      await Supabase.instance.client.rpc(
        'admin_set_user_package',
        params: {
          'target_user_id':
              user['user_id'],
          'new_package_code':
              packageCode,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'User package updated successfully.',
          ),
        ),
      );

      await loadUsers();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to change package: $e',
          ),
        ),
      );
    }
  }

  Future<void> changeStatus(
    Map<String, dynamic> user,
    String status,
  ) async {
    try {
      await Supabase.instance.client.rpc(
        'admin_set_user_status',
        params: {
          'target_user_id':
              user['user_id'],
          'new_status':
              status,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'User status changed to $status.',
          ),
        ),
      );

      await loadUsers();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to change user status: $e',
          ),
        ),
      );
    }
  }

  Widget buildUserCard(
    Map<String, dynamic> user,
  ) {
    final bool unlimited =
        user['unlimited'] == true;
        final bool isSuperAdmin =
    user['role']?.toString() == 'super_admin';

    final int used =
        (user['records_used'] ?? 0) as int;

    final dynamic remaining =
        user['remaining_records'];

    final String packageName =
        user['package_name']
                ?.toString() ??
            'No package';

    final String packageCode =
        user['package_code']
                ?.toString() ??
            'free';

    final String status =
        user['account_status']
                ?.toString() ??
            'active';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child:
                      Icon(
                    Icons.person_outline,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['email']
                                ?.toString() ??
                            '-',
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        'Role: ${user['role'] ?? 'user'}',
                      ),
                    ],
                  ),
                ),

                Chip(
                  label: Text(
                    status.toUpperCase(),
                  ),
                ),
              ],
            ),

            const Divider(
              height: 30,
            ),

            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                Text(
                  'Package: $packageName',
                ),

                Text(
                  'Used: $used',
                ),

                Text(
                  unlimited
                      ? 'Remaining: Unlimited'
                      : 'Remaining: ${remaining ?? 0}',
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            DropdownButtonFormField<String>(
              value:
                  packageCodes.contains(
                packageCode,
              )
                      ? packageCode
                      : 'free',
              decoration:
                  const InputDecoration(
                labelText:
                    'Assign Package',
                border:
                    OutlineInputBorder(),
              ),
              items:
                  packageCodes
                      .map(
                        (code) =>
                            DropdownMenuItem(
                          value: code,
                          child: Text(
                            code.toUpperCase(),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: isSuperAdmin
    ? null
    : (value) async {
        if (value == null || value == packageCode) {
          return;
        }

        await changePackage(
          user,
          value,
        );
      },
            ),

            const SizedBox(
              height: 14,
            ),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: isSuperAdmin
    ? null
    : status == 'active'
        ? null
        : () => changeStatus(
              user,
              'active',
            ),
                  icon:
                      const Icon(
                    Icons.check_circle_outline,
                  ),
                  label:
                      const Text(
                    'Activate',
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: isSuperAdmin
    ? null
    : status == 'suspended'
        ? null
        : () => changeStatus(
              user,
              'suspended',
            ),
                  icon:
                      const Icon(
                    Icons.pause_circle_outline,
                  ),
                  label:
                      const Text(
                    'Suspend',
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: isSuperAdmin
    ? null
    : status == 'disabled'
        ? null
        : () => changeStatus(
              user,
              'disabled',
            ),
                  icon:
                      const Icon(
                    Icons.block_outlined,
                  ),
                  label:
                      const Text(
                    'Disable',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'MARC AI Admin Dashboard',
        ),
        actions: [
  IconButton(
    tooltip: 'User Management',
    icon: const Icon(Icons.manage_accounts_outlined),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminUserManagementPage(),
        ),
      );
    },
  ),

  IconButton(
    tooltip: 'Refresh',
    onPressed: loadUsers,
    icon: const Icon(
      Icons.refresh,
    ),
  ),
],
      ),

      body:
          loading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : errorMessage != null
                  ? Center(
                      child:
                          Padding(
                        padding:
                            const EdgeInsets.all(
                          24,
                        ),
                        child:
                            Text(
                          errorMessage!,
                          textAlign:
                              TextAlign.center,
                        ),
                      ),
                    )
                  : users.isEmpty
                      ? const Center(
                          child:
                              Text(
                            'No users found.',
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.all(
                            18,
                          ),
                          itemCount:
                              users.length,
                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            return buildUserCard(
                              users[index],
                            );
                          },
                        ),
    );
  }
}
class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState
    extends State<AdminUserManagementPage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final result =
          await Supabase.instance.client.rpc('admin_list_users');

      final data = List<Map<String, dynamic>>.from(result as List);

      if (!mounted) return;

      setState(() {
        users = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> changeStatus(
    String userId,
    String newStatus,
  ) async {
    try {
      await Supabase.instance.client.rpc(
        'admin_set_account_status',
        params: {
          'target_user_id': userId,
          'new_status': newStatus,
        },
      );

      await loadUsers();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update user: $e'),
        ),
      );
    }
  }

  String readableStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending approval';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'suspended':
        return 'Suspended';
      default:
        return status;
    }
  }

  Widget buildActions(Map<String, dynamic> user) {
    final id = user['id'].toString();
    final status = user['account_status']?.toString() ?? '';

    if (status == 'pending') {
      return Wrap(
        spacing: 8,
        children: [
          ElevatedButton(
            onPressed: () => changeStatus(id, 'approved'),
            child: const Text('Approve'),
          ),
          OutlinedButton(
            onPressed: () => changeStatus(id, 'rejected'),
            child: const Text('Reject'),
          ),
        ],
      );
    }

    if (status == 'approved') {
      return OutlinedButton(
        onPressed: () => changeStatus(id, 'suspended'),
        child: const Text('Suspend'),
      );
    }

    if (status == 'suspended' || status == 'rejected') {
      return ElevatedButton(
        onPressed: () => changeStatus(id, 'approved'),
        child: const Text('Reactivate'),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            onPressed: loadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: users.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index];

                    final email =
                        user['email']?.toString() ?? 'No email';

                    final role =
                        user['role']?.toString() ?? 'user';

                    final status =
                        user['account_status']?.toString() ?? '';

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Role: $role',
                                  ),
                                  Text(
                                    'Status: ${readableStatus(status)}',
                                  ),
                                ],
                              ),
                            ),

                            buildActions(user),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

