import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khuje_nao/report_lost_item_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:image_picker/image_picker.dart';

// Create a mock class for ImagePicker
class MockImagePicker extends Mock implements ImagePicker {}



void main() {
  testWidgets('Test _pickImage method', (WidgetTester tester) async {
    // Create a mock ImagePicker
    final mockPicker = MockImagePicker();

    // Prepare a fake picked file
    final pickedFile = XFile('fake_path_to_image.jpg');

    // Mock the pickImage method to return a Future<XFile?>, not null
    when(mockPicker.pickImage(source: ImageSource.camera))
        .thenAnswer((_) async => pickedFile); // This ensures the mocked method returns the XFile

    // Create an instance of the widget (ReportLostItemScreen)
    await tester.pumpWidget(
      MaterialApp(home: ReportLostItemScreen()),
    );

    // Ensure the widget is rendered properly before interacting
    expect(find.byType(ReportLostItemScreen), findsOneWidget);

    // Find the camera button and tap it
    final cameraButton = find.widgetWithText(ElevatedButton, 'Camera');
    await tester.tap(cameraButton);
    await tester.pumpAndSettle(); // Wait for the widget to update

    // Verify that the image is picked and the image widget is displayed
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('fake_path_to_image.jpg'), findsNothing); // Path should be in state, but not text
  });
}
