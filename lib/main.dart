import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';

void main() {
  runApp(const HairprintApp());
}

class HairprintApp extends StatelessWidget {
  const HairprintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hairprint AI',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HairprintHome(),
    );
  }
}

class HairprintHome extends StatefulWidget {
  const HairprintHome({super.key});

  @override
  State<HairprintHome> createState() => _HairprintHomeState();
}

class _HairprintHomeState extends State<HairprintHome> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthdateController = TextEditingController();
  String? _gender;
  XFile? _selectedImage;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the form and select an image'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisScreen(
          name: _nameController.text,
          birthdate: _birthdateController.text,
          gender: _gender!,
          image: _selectedImage!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hairprint™ AI Diagnostic')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Your Scalp Has a Story. The Hairprint™ AI Tells It.",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Introducing the Hairprint™ AI Diagnostic Session, a breakthrough in personalized hair and scalp care...",
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Client Name"),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _birthdateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Birthdate",
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(1990, 1, 1),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        _birthdateController.text = picked
                            .toIso8601String()
                            .split('T')
                            .first;
                      }
                    },
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    items: const [
                      DropdownMenuItem(value: "Male", child: Text("Male")),
                      DropdownMenuItem(value: "Female", child: Text("Female")),
                      DropdownMenuItem(
                        value: "Non-Binary",
                        child: Text("Non-Binary"),
                      ),
                      DropdownMenuItem(
                        value: "Prefer Not to Say",
                        child: Text("Prefer Not to Say"),
                      ),
                    ],
                    onChanged: (val) => setState(() => _gender = val),
                    decoration: const InputDecoration(labelText: "Gender"),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text(
                      _selectedImage == null
                          ? "Select Scalp Image"
                          : "Change Image",
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text("Upload & Analyze"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Share.share('Test share message from Hairprint app');
                    },
                    child: Text("Test Share"),
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

class AnalysisScreen extends StatefulWidget {
  final String name;
  final String birthdate;
  final String gender;
  final XFile image;

  const AnalysisScreen({
    super.key,
    required this.name,
    required this.birthdate,
    required this.gender,
    required this.image,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String _spinnerMessage = 'Analyzing your image...';
  Timer? _spinnerTimer;
  String _response = '';

  static const List<String> _messages = [
    "Reading your follicles like tea leaves...",
    "Your scalp secrets are safe with us...",
    "Detecting rogue split ends...",
    "Assembling follicle facts...",
    "Is it dandruff or just dry wit?",
    "Running AI on your ROI (Root of Interest)...",
    "Scalp-tingling science in progress...",
  ];

  void _startSpinnerMessages() {
    int i = 0;
    _spinnerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _spinnerMessage = _messages[i++ % _messages.length];
      });
    });
  }

  void _stopSpinnerMessages() {
    _spinnerTimer?.cancel();
    setState(() {
      _spinnerMessage = "Analysis complete.";
    });
  }

  Future<void> _analyzeImage() async {
    _startSpinnerMessages();

    final rawBytes = await widget.image.readAsBytes();
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      _stopSpinnerMessages();
      setState(() => _response = 'Could not decode image.');
      return;
    }

    final jpgBytes = img.encodeJpg(decoded, quality: 85);
    final base64Image = base64Encode(jpgBytes);

    final uri = Uri.parse(
      'https://rpgarner65.app.n8n.cloud/webhook/hairprint-app',
    );

    final multipartFile = http.MultipartFile.fromBytes(
      'image',
      jpgBytes,
      filename: 'upload.jpg',
      contentType: MediaType('image', 'jpeg'),
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['clientName'] = widget.name
      ..fields['birthdate'] = widget.birthdate
      ..fields['gender'] = widget.gender
      ..fields['imageBase64'] = base64Image
      ..files.add(multipartFile);

    try {
      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);
      _stopSpinnerMessages();
      setState(() {
        _response = res.body.replaceAll('\n', '').replaceAll('\r', '');
      });
    } catch (e) {
      _stopSpinnerMessages();
      setState(() => _response = 'Error: ${e.toString()}');
    }
  }

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hairprint™ Analysis")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _response.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(_spinnerMessage, textAlign: TextAlign.center),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Html(
                        data: _response,
                        extensions: [
                          TagExtension(
                            tagsToExtend: {"img"},
                            builder: (context) {
                              final src = context.attributes['src'] ?? '';
                              if (src.startsWith("data:image")) {
                                try {
                                  final base64Str = src.split(',').last;
                                  final Uint8List bytes = base64.decode(
                                    base64Str,
                                  );
                                  return Image.memory(bytes);
                                } catch (_) {
                                  return const Text('[Image decode error]');
                                }
                              }
                              return const Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              );
                            },
                          ),
                        ],
                        style: {
                          "hr": Style(margin: Margins.symmetric(vertical: 4)),
                          "img": Style(margin: Margins.symmetric(vertical: 8)),
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final pdfBytes = await Printing.convertHtml(
                          format: PdfPageFormat.a4,
                          html: _response,
                        );

                        final dir = await getTemporaryDirectory();
                        final file = File('${dir.path}/dummy.pdf');
                        await file.writeAsBytes(
                          List<int>.filled(100, 0),
                        ); // Empty PDF-like blob

                        if (!mounted) return;

                        print("PDF saved to: ${file.path}");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('PDF saved at: ${file.path}')),
                        );

                        await Share.shareXFiles(
                          [
                            XFile(
                              file.path,
                              mimeType: 'application/pdf',
                              name: 'Hairprint_Report.pdf',
                            ),
                          ],
                          text: 'Here’s your Hairprint™ AI Diagnostic Report!',
                        );
                      } catch (e) {
                        print('Error sharing: $e');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error sharing report: $e')),
                        );
                      }
                    },

                    icon: const Icon(Icons.share),
                    label: const Text('Share Report as PDF'),
                  ),
                ],
              ),
      ),
    );
  }
}
