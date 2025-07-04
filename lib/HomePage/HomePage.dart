import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:clubquranproject/HomePage/SurahDetail.dart';
import 'Majalla/RequestMajalla.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart' as flutter_spinkit;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MemberHomePage extends StatefulWidget {
  final String username;
  const MemberHomePage({super.key, required this.username});

  @override
  State<MemberHomePage> createState() => _MemberHomePageState();
}

class _MemberHomePageState extends State<MemberHomePage> {
  String? fullName;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _quranSurahs = [];
  int _selectedDrawerIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchMemberData();
    _fetchQuranSurahs();
  }

  Future<void> _fetchMemberData() async {
    try {
      final dbRef = FirebaseDatabase.instance.ref('users/${widget.username}');
      final snapshot = await dbRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          fullName = data['fullname']?.toString() ?? widget.username;
        });
      } else {
        setState(() {
          _error = 'المستخدم غير موجود';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطأ في تحميل البيانات: $e';
      });
    }
  }

  Future<void> _fetchQuranSurahs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/surah'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List surahs = data['data'];
        setState(() {
          _quranSurahs = surahs
              .map<Map<String, dynamic>>(
                (s) => {
                  'number': s['number'],
                  'name': s['name'],
                  'englishName': s['englishName'],
                  'ayahs': s['numberOfAyahs'],
                  'revelationType': s['revelationType'],
                },
              )
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'فشل تحميل السور (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطأ في تحميل السور: $e';
        _isLoading = false;
      });
    }
  }

  void _showSurahPage(Map<String, dynamic> surah) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SurahDetailPage(surah: surah)),
    );
  }

  void _onSelectDrawerItem(int index) {
    setState(() {
      _selectedDrawerIndex = index;
      Navigator.pop(context);
    });
  }

  Widget _buildDrawer(Color primaryColor) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  fullName ?? widget.username,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('الرئيسية'),
            selected: _selectedDrawerIndex == 0,
            onTap: () => _onSelectDrawerItem(0),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_rounded),
            title: const Text('القرآن الكريم'),
            selected: _selectedDrawerIndex == 1,
            onTap: () => _onSelectDrawerItem(1),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList(Color primaryColor) {
    return RefreshIndicator(
      onRefresh: _fetchQuranSurahs,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: primaryColor,
                iconSize: 32,
                tooltip: 'العودة للصفحة الرئيسية',
                onPressed: () {
                  setState(() {
                    _selectedDrawerIndex = 0;
                  });
                },
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'سور القرآن الكريم',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quranSurahs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final surah = _quranSurahs[idx];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.15),
                  child: Text(
                    surah['number'].toString(),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  surah['name'],
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${surah['englishName']} - ${surah['ayahs']} آية',
                  style: const TextStyle(fontSize: 15),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: primaryColor,
                ),
                onTap: () => _showSurahPage(surah),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHomeContent(Color primaryColor) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
              radius: 44,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 54,
                color: primaryColor,
              ),
              ),
              const SizedBox(height: 12),
              Text(
              fullName ?? widget.username,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              ),
              const SizedBox(height: 16),
              Text(
              ':تابعونا واشتركوا في صفحاتنا على مواقع التواصل الاجتماعي',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Column(
                  children: [
                  CircleAvatar(
                    backgroundColor: Colors.purple.withOpacity(0.15),
                    child: Icon(Icons.camera_alt, color: Colors.purple),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@clubquran_ensias',
                    style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14,
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    ),
                  ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.15),
                    child: Icon(Icons.facebook, color: Colors.blue),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Club Quran-ENSIAS',
                    style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    ),
                  ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                  CircleAvatar(
                    backgroundColor: Colors.red.withOpacity(0.15),
                    child: Icon(Icons.ondemand_video, color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Club Quran-ENSIAS',
                    style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    ),
                  ),
                  ],
                ),
                ],
              ),
            const SizedBox(height: 20),
            const Divider(thickness: 1.5),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontFamily: 'Amiri', fontSize: 20, fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('دردشة جماعية'),
                onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                  builder: (context) => GeneralChatPage(username: widget.username),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            const Text(
              'الدردشة الجماعية مخصصة لمشاركة الروابط و المحتوى الديني بين أعضاء النادي',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),
            const Divider(thickness: 1.5),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LireMajallaPage()),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: primaryColor.withOpacity(0.18)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book, color: primaryColor, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'قراءة المجلة',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RequestMajallaPage()),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: primaryColor.withOpacity(0.18)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.request_page, color: primaryColor, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'طلب المجلة',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MajallatsListPage()),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: primaryColor.withOpacity(0.18)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.collections_bookmark, color: primaryColor, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'المجلات',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),



            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
      ),
      drawer: _buildDrawer(primaryColor),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F5F5), Color(0xFFE8F5E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? Center(
                child: flutter_spinkit.SpinKitFadingCircle(
                  color: primaryColor,
                  size: 60,
                ),
              )
            : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  )
                : _selectedDrawerIndex == 1
                    ? _buildSurahList(primaryColor)
                    : _buildHomeContent(primaryColor),
      ),
    );
  }
}





class GeneralChatPage extends StatefulWidget {
  const GeneralChatPage({super.key, required this.username});
  final String username;

  @override
  State<GeneralChatPage> createState() => _GeneralChatPageState();
}

class _GeneralChatPageState extends State<GeneralChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;
  String? _initError;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      setState(() {
        _isInitialized = false;
        _initError = null;
      });

      // Enable network and test connection
      await FirebaseFirestore.instance.enableNetwork();
      
      // Test connection by attempting to read from Firestore
      await FirebaseFirestore.instance
          .collection('ClubChat')
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));

      setState(() {
        _isInitialized = true;
        _isConnected = true;
      });
    } catch (e) {
      print('Firebase initialization error: $e');
      setState(() {
        _initError = _getErrorMessage(e);
        _isInitialized = false;
        _isConnected = false;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('network')) {
      return 'تحقق من اتصال الإنترنت وحاول مرة أخرى';
    } else if (error.toString().contains('permission')) {
      return 'لا يوجد إذن للوصول إلى قاعدة البيانات';
    } else if (error.toString().contains('timeout')) {
      return 'انتهت مهلة الاتصال، حاول مرة أخرى';
    } else {
      return 'خطأ في الاتصال بالخادم';
    }
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    // Check connection before sending
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد اتصال بالإنترنت'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final time = DateFormat('HH:mm').format(now);

      await FirebaseFirestore.instance
          .collection('ClubChat')
          .add({
            'username': widget.username,
            'message': message,
            'time': time,
            'timestamp': now,
          })
          .timeout(const Duration(seconds: 10));

      _controller.clear();
      
      // Auto-scroll to bottom
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Send message error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إرسال الرسالة: ${_getErrorMessage(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteMessage(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ClubChat')
          .doc(docId)
          .delete()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Delete message error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حذف الرسالة: ${_getErrorMessage(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF2E7D32);
    final Color backgroundColor = const Color(0xFFF8F9FA);
    final Color surfaceColor = Colors.white;
    final Color accentColor = const Color(0xFF81C784);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'الدردشة الجماعية',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.white : Colors.red[300],
            ),
            onPressed: _initializeFirebase,
            tooltip: _isConnected ? 'متصل' : 'غير متصل - اضغط للإعادة المحاولة',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Connection status bar
          if (!_isConnected && _initError == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.orange[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, color: Colors.orange[800], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'جاري إعادة الاتصال...',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      color: Colors.orange[800],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          // Messages area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                ),
              ),
              child: _buildMessagesSection(primaryColor, accentColor, surfaceColor),
            ),
          ),
          // Input area
          _buildInputSection(primaryColor, surfaceColor),
        ],
      ),
    );
  }

  Widget _buildMessagesSection(Color primaryColor, Color accentColor, Color surfaceColor) {
    // Show initialization error
    if (_initError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'خطأ في الاتصال بالخادم',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                color: Colors.red[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _initError!,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeFirebase,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show loading while initializing
    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'جاري الاتصال بالخادم...',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Show messages stream
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ClubChat')
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'خطأ في تحميل الرسائل',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _getErrorMessage(snapshot.error),
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializeFirebase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد رسائل بعد',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ابدأ المحادثة الآن!',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data!.docs;
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          itemCount: messages.length,
          itemBuilder: (context, idx) {
            final msg = messages[idx].data() as Map<String, dynamic>;
            final isMe = msg['username'] == widget.username;
            return _buildMessageBubble(
              msg: msg,
              isMe: isMe,
              primaryColor: primaryColor,
              accentColor: accentColor,
              surfaceColor: surfaceColor,
              docId: messages[idx].id,
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required Map<String, dynamic> msg,
    required bool isMe,
    required Color primaryColor,
    required Color accentColor,
    required Color surfaceColor,
    required String docId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: accentColor.withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 18,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? primaryColor : surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Header with username and time
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMe) ...[
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text(
                                    'حذف الرسالة',
                                    style: TextStyle(fontFamily: 'Amiri'),
                                  ),
                                  content: const Text(
                                    'هل تريد حذف هذه الرسالة للجميع؟',
                                    style: TextStyle(fontFamily: 'Amiri'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text(
                                        'إلغاء',
                                        style: TextStyle(fontFamily: 'Amiri'),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _deleteMessage(docId);
                                      },
                                      child: const Text(
                                        'حذف',
                                        style: TextStyle(
                                          fontFamily: 'Amiri',
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Icon(
                            Icons.delete,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          msg['username'] ?? 'مستخدم',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontWeight: FontWeight.w600,
                            color: isMe ? Colors.white : primaryColor,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        msg['time'] ?? '',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 11,
                          color: isMe ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Message content
                  Text(
                    msg['message'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      color: isMe ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor.withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 18,
                color: primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputSection(Color primaryColor, Color surfaceColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك هنا...',
                    hintStyle: TextStyle(
                      fontFamily: 'Amiri',
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: _isConnected ? _sendMessage : null,
                tooltip: _isConnected ? 'إرسال' : 'غير متصل',
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
















class LireMajallaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قراءة المجلة'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'هذه الصفحة قيد التطوير',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class MajallatsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المجلات'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'هذه الصفحة قيد التطوير',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

