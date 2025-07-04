import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart' as flutter_spinkit;

class SurahDetailPage extends StatefulWidget {
  final Map<String, dynamic> surah;
  const SurahDetailPage({super.key, required this.surah});

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _ayahs = [];

  @override
  void initState() {
    super.initState();
    _fetchSurah();
  }

  Future<void> _fetchSurah() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.alquran.cloud/v1/surah/${widget.surah['number']}',
        ),
      );
      if (response.statusCode == 200) {
        final surahData = json.decode(response.body)['data'];
        setState(() {
          _ayahs = surahData['ayahs'] as List;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'تعذر تحميل السورة (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطأ في تحميل السورة: $e';
        _isLoading = false;
      });
    }
  }

  void _goToNextSurah() {
    final currentNumber = widget.surah['number'] as int;
    if (currentNumber < 114) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => SurahDetailPage(
                surah: {...widget.surah, 'number': currentNumber + 1},
              ),
        ),
      );
    }
  }

  void _goToPreviousSurah() {
    final currentNumber = widget.surah['number'] as int;
    if (currentNumber > 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => SurahDetailPage(
                surah: {...widget.surah, 'number': currentNumber - 1},
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<http.Response>(
          future: http.get(
            Uri.parse(
              'https://api.alquran.cloud/v1/surah/${widget.surah['number']}',
            ),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('...جاري التحميل');
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.statusCode != 200) {
              return Text(
                '${widget.surah['name']} (${widget.surah['englishName']})',
              );
            }
            final surahData = json.decode(snapshot.data!.body)['data'];
            final name = surahData['name'] ?? widget.surah['name'];
            final englishName =
                surahData['englishName'] ?? widget.surah['englishName'];
            return Text('$name ($englishName)');
          },
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading:
            true, // Keep back button for surah navigation
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F5F5), Color(0xFFE8F5E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child:
            _isLoading
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
                : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        itemCount: _ayahs.length,
                        itemBuilder: (context, idx) {
                          final ayah = _ayahs[idx];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                '${ayah['numberInSurah']}. ${ayah['text']}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: 'me_quran',
                                  fontSize: 24,
                                  color: Color(0xFF222222),
                                  height: 1.7,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed:
                                (widget.surah['number'] as int) > 1
                                    ? _goToPreviousSurah
                                    : null,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('السورة السابقة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                (widget.surah['number'] as int) < 114
                                    ? _goToNextSurah
                                    : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('السورة التالية'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
