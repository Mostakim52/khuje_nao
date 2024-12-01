import 'package:flutter_test/flutter_test.dart';
import 'package:khuje_nao/localization.dart';

void main() {
    group('AppLocalization', () {
        test('Returns correct string for valid key and language code (English)', () {
            String result = AppLocalization.getString('en', 'camera');
            expect(result, 'Camera');
        });

        test('Returns correct string for valid key and language code (Bangla)', () {
            String result = AppLocalization.getString('bd', 'camera');
            expect(result, 'ক্যামেরা');
        });

        test('Returns the key itself if the key is missing in English', () {
            String result = AppLocalization.getString('en', 'non_existent_key');
            expect(result, 'non_existent_key');
        });

        test('Returns the key itself if the key is missing in Bangla', () {
            String result = AppLocalization.getString('bd', 'non_existent_key');
            expect(result, 'non_existent_key');
        });

        test('Falls back to default language (English) if language code is invalid', () {
            String result = AppLocalization.getString('invalid_lang_code', 'camera');
            expect(result, 'Camera');
        });

        test('Returns the key itself if the key and language both are missing', () {
            String result = AppLocalization.getString('invalid_lang_code', 'non_existent_key');
            expect(result, 'non_existent_key');
        });

        test('Returns correct string for key that exists in both languages (Bangla)', () {
            String result = AppLocalization.getString('bd', 'login');
            expect(result, 'লগইন');
        });

        test('Returns correct string for key that exists in both languages (English)', () {
            String result = AppLocalization.getString('en', 'login');
            expect(result, 'Login');
        });
    });
}
