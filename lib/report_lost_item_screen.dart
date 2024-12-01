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
  ReportLostItemScreenState createState() => ReportLostItemScreenState();
}

class ReportLostItemScreenState extends State<ReportLostItemScreen> {
  /// Controller for the description text field.
  final TextEditingController description_controller = TextEditingController();

  /// Controller for the location text field.
  final TextEditingController location_controller = TextEditingController();

  /// Holds the selected image file of the lost item.
  File? image;

  /// An instance of [ImagePicker] to pick images from the camera or gallery.
  final ImagePicker picker = ImagePicker();

  /// An instance of [FlutterSecureStorage] to securely store user preferences.
  final FlutterSecureStorage STORAGE = const FlutterSecureStorage();

  /// The language code for localization (default is 'en').
  String language = 'en';

  /// Picks an image from the specified [source] (camera or gallery).
  ///
  /// If an image is successfully picked, it updates the state with the selected
  /// image. If no image is selected, a snack bar will show an error message.
  ///
  /// [source] is the source from which the image is picked. This can be:
  /// - [ImageSource.camera]: to pick an image using the camera.
  /// - [ImageSource.gallery]: to pick an image from the gallery.
  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          image = File(pickedFile.path);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.getString(language, 'no_img'))),
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
    loadLanguage();
  }

  /// Loads the user's preferred language from secure storage.
  ///
  /// If no language is stored, it defaults to `'en'` (English).
  Future<void> loadLanguage() async {
    String? storedLanguage = await STORAGE.read(key: 'language');
    setState(() {
      language = storedLanguage ?? 'en';
    });
  }

  /// Submits the lost item report.
  ///
  /// This function checks if the description, location, and image are provided.
  /// If any of these fields are empty, a snack bar is shown with an error message.
  /// If everything is valid, a loading indicator is shown, and the report is sent
  /// to the server via the [ApiService]. On success, a success message is shown,
  /// and the screen is popped. On failure, an error message is displayed.
  Future<void> submitReport() async {
    FocusScope.of(context).unfocus(); // Close the keyboard
    try {
      final description = description_controller.text;
      final location = location_controller.text;

      // Check if all required fields are provided
      if (description.isEmpty || location.isEmpty || image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.getString(language, 'req_fields'))),
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
        imagePath: image!.path,
      );

      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.getString(language, 'report_success'))),
        );
        Navigator.pop(context); // Close the form screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.getString(language, 'report_fail'))),
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
      appBar: AppBar(title: Text(AppLocalization.getString(language, 'report_lost'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: description_controller,
              decoration: InputDecoration(labelText: AppLocalization.getString(language, 'item_desc')),
            ),
            TextField(
              controller: location_controller,
              decoration: InputDecoration(labelText: AppLocalization.getString(language, 'found_loc')),
            ),
            const SizedBox(height: 10),
            image == null
                ? Text(AppLocalization.getString(language, 'no_img'))
                : Image.file(image!, height: 150, width: 150, fit: BoxFit.cover),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => pickImage(ImageSource.camera),
                  child: Text(AppLocalization.getString(language, 'camera')),
                ),
                ElevatedButton(
                  onPressed: () => pickImage(ImageSource.gallery),
                  child: Text(AppLocalization.getString(language, 'gallery')),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitReport,
              child: Text(AppLocalization.getString(language, 'submit_report')),
            ),
          ],
        ),
      ),
    );
  }
}
