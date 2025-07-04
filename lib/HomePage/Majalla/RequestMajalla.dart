import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class RequestMajallaPage extends StatefulWidget {
  @override
  _RequestMajallaPageState createState() => _RequestMajallaPageState();
}

class _RequestMajallaPageState extends State<RequestMajallaPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _majallaNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSubmitting = false;
  String? _submitMessage;

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submitMessage = null;
    });

    try {
      final username = _usernameController.text.trim();
      final phone = _phoneController.text.trim();

      await FirebaseFirestore.instance.collection('RequestMajalla').add({
        'username': username,
        'majallaName': _majallaNameController.text.trim(),
        'phone': phone,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _submitMessage = "تم إرسال طلبك بنجاح!";
        _majallaNameController.clear();
        _usernameController.clear();
        _phoneController.clear();
      });
    } catch (e) {
      setState(() {
        _submitMessage = "حدث خطأ أثناء إرسال الطلب: $e";
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _majallaNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب المجلة'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'يرجى إدخال اسم المستخدم واسم المجلة ورقم الهاتف للتواصل',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'اسم المستخدم',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال اسم المستخدم';
                          }
                          return null;
                        },
                        style: const TextStyle(fontFamily: 'Amiri', fontSize: 18),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _majallaNameController,
                        decoration: InputDecoration(
                          labelText: 'اسم المجلة',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال اسم المجلة';
                          }
                          return null;
                        },
                        style: const TextStyle(fontFamily: 'Amiri', fontSize: 18),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'رقم الهاتف للتواصل',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال رقم الهاتف';
                          }
                          // Optional: Add more validation for phone number format
                          return null;
                        },
                        style: const TextStyle(fontFamily: 'Amiri', fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      _isSubmitting
                          ? CircularProgressIndicator(color: primaryColor)
                          : ElevatedButton.icon(
                              icon: const Icon(Icons.send),
                              label: const Text('إرسال الطلب'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                textStyle: const TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _submitRequest,
                            ),
                      if (_submitMessage != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          _submitMessage!,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 17,
                            color: _submitMessage!.contains("نجاح") ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}