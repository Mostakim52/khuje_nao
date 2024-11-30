import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'api_service.dart';
import 'localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ReportLostItemScreen extends StatefulWidget {
  const ReportLostItemScreen({Key? key}) : super(key: key);

  @override
  _ReportLostItemScreenState createState() => _ReportLostItemScreenState();
}

class _ReportLostItemScreenState extends State<ReportLostItemScreen> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _language = 'en'; // Default language

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.getString(_language, 'no_img'))),
          //const SnackBar(content: Text('No image selected!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }
  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }
  Future<void> _loadLanguage() async {
    String? storedLanguage = await _storage.read(key: 'language');
    setState(() {
      _language = storedLanguage ?? 'en';
    });
  }

  Future<void> _submitReport() async {
    FocusScope.of(context).unfocus(); // Close the keyboard
    try {
      final description = descriptionController.text;
      final location = locationController.text;

      if (description.isEmpty || location.isEmpty || _image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.getString(_language, 'req_fields'))),
          //const SnackBar(content: Text('All fields are required!')),
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success = await ApiService().reportLostItem(
        description: description,
        location: location,
        imagePath: _image!.path,
      );

      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.getString(_language, 'report_success'))),
          //const SnackBar(content: Text('Report submitted successfully! Awaiting admin approval.')),
        );
        Navigator.pop(context); // Close the form screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.getString(_language, 'report_fail'))),
          //const SnackBar(content: Text('Failed to submit report.')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalization.getString(_language, 'report_lost'))),
      //appBar: AppBar(title: const Text('Report Lost Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: AppLocalization.getString(_language, 'item_desc')),
              //decoration: const InputDecoration(labelText: 'Item Description'),
            ),
            TextField(
              controller: locationController,
              decoration: InputDecoration(labelText: AppLocalization.getString(_language, 'found_loc')),
              //decoration: const InputDecoration(labelText: 'Found Location'),
            ),
            const SizedBox(height: 10),
            _image == null
                ? Text(AppLocalization.getString(_language, 'no_img'))
                //? const Text('No image selected.')
                : Image.file(_image!, height: 150, width: 150, fit: BoxFit.cover),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  child: Text(AppLocalization.getString(_language, 'camera')),
                  //child: const Text('Camera'),
                ),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  child: Text(AppLocalization.getString(_language, 'gallery')),
                  //child: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitReport,
              child: Text(AppLocalization.getString(_language, 'submit_report')),
              //child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }
}
