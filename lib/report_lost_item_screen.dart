import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'api_service.dart';
import 'localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A screen for reporting a lost item. It allows users to input a description,
/// location, and an image of the lost item, which is then submitted to the backend.
///
/// The screen includes:
/// - Fields for item description and location.
/// - An option to select or capture an image of the lost item.
/// - A submit button to send the report to the server.
///
/// The UI supports dynamic localization and language selection.
class ReportLostItemScreen extends StatefulWidget {
  /// Creates a new instance of the [ReportLostItemScreen].
  const ReportLostItemScreen({Key? key}) : super(key: key);

  @override
  _ReportLostItemScreenState createState() => _ReportLostItemScreenState();
}

class _ReportLostItemScreenState extends State<ReportLostItemScreen> {
  /// Controller for the description text field.
  final TextEditingController descriptionController = TextEditingController();

  /// Controller for the location text field.
  final TextEditingController locationController = TextEditingController();

  /// Holds the selected image file of the lost item.
  File? _image;

  /// An instance of [ImagePicker] to pick images from the camera or gallery.
  final ImagePicker _picker = ImagePicker();

  /// An instance of [FlutterSecureStorage] to securely store user preferences.
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// The language code for localization (default is 'en').
  String _language = 'en';

  /// Picks an image from the specified [source] (camera or gallery).
  ///
  /// If an image is successfully picked, it updates the state with the selected
  /// image. If no image is selected, a snack bar will show an error message.
  ///
  /// [source] is the source from which the image is picked. This can be:
  /// - [ImageSource.camera]: to pick an image using the camera.
  /// - [ImageSource.gallery]: to pick an image from the gallery.
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

  /// Loads the user's preferred language from secure storage.
  ///
  /// If no language is stored, it defaults to `'en'` (English).
  Future<void> _loadLanguage() async {
    String? storedLanguage = await _storage.read(key: 'language');
    setState(() {
      _language = storedLanguage ?? 'en';
    });
  }

  /// Submits the lost item report.
  ///
  /// This function checks if the description, location, and image are provided.
  /// If any of these fields are empty, a snack bar is shown with an error message.
  /// If everything is valid, a loading indicator is shown, and the report is sent
  /// to the server via the [ApiService]. On success, a success message is shown,
  /// and the screen is popped. On failure, an error message is displayed.
  Future<void> _submitReport() async {
    FocusScope.of(context).unfocus(); // Close the keyboard
    try {
      final description = descriptionController.text;
      final location = locationController.text;

      // Check if all required fields are provided
      if (description.isEmpty || location.isEmpty || _image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.getString(_language, 'req_fields'))),
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

      // Submit the report to the server
      final success = await ApiService().reportLostItem(
        description: description,
        location: location,
        imagePath: _image!.path,
      );

      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.getString(_language, 'report_success'))),
        );
        Navigator.pop(context); // Close the form screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.getString(_language, 'report_fail'))),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: AppLocalization.getString(_language, 'item_desc')),
            ),
            TextField(
              controller: locationController,
              decoration: InputDecoration(labelText: AppLocalization.getString(_language, 'found_loc')),
            ),
            const SizedBox(height: 10),
            _image == null
                ? Text(AppLocalization.getString(_language, 'no_img'))
                : Image.file(_image!, height: 150, width: 150, fit: BoxFit.cover),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  child: Text(AppLocalization.getString(_language, 'camera')),
                ),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  child: Text(AppLocalization.getString(_language, 'gallery')),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitReport,
              child: Text(AppLocalization.getString(_language, 'submit_report')),
            ),
          ],
        ),
      ),
    );
  }
}
