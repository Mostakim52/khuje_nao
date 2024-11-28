

class AppLocalization {
  // A map to store all strings for different languages
  static final Map<String, Map<String, String>> localizedValues = {
    'en': {
      'welcome': 'Welcome',
      'signup': 'Signup',
      'login' : 'Login',
      'name' : 'Name',
      'email' : 'Email',
      'password' : 'Password',
      'id' : 'NSU ID (First 7 digits)',
      'phone_no' : 'Phone Number',
      'okay' : 'Okay',
      'chat' : 'Chat',
      'invalid_name' : 'Invalid Name : Name limit is between 2 and 50 characters',
      'invalid_pass' : 'Invalid Password: Must be at least 8 characters and have at least 1 uppercase letter and a number',
      'invalid_mail' : 'Invalid Email',
      'invalid_id'   : 'Invalid NSU ID. Must be first 7 digits of NSU ID.',
      'invalid_phone': 'Invalid phone number: \nMake sure the number starts with 01, \nthe third digit is 3 through 9 (for valid operators), \nand the total length is exactly 11 digits',
      'signup_fail'  : 'Signup failed',
      'remember_me'  : 'Remember Me',
      'go_home'      : 'Go Home',
      'login_failed' : 'Login Failed.',
      'failed_otp'   : 'Failed to send OTP. Please try again.',
      'cancel'       : 'Cancel',
      'otp_verified' : 'OTP Verified! Redirecting...',
      'otp_invalid'  : 'Invalid OTP. Please try again.',
      'otp_send'     : 'Enter OTP send to your mail: ',
      'verify'       : 'Verify',

  },
    'bd': {
      'welcome': 'স্বাগতম',
      'signup': 'নিবন্ধন',
      'login' : 'লগইন',
      'name': 'নাম',
      'email': 'ই-মেইল',
      'password': 'পাসওয়ার্ড',
      'id': 'NSU আইডি (প্রথম 7 সংখ্যা)',
      'chat': 'চ্যাট',
      'phone_no': 'ফোন নম্বর',
      'okay': 'ঠিক আছে',
      'invalid_name': 'অবৈধ নাম; নামের সীমা 2 থেকে 50 অক্ষরের মধ্যে',
      'invalid_pass': 'অবৈধ পাসওয়ার্ড: কমপক্ষে 8 অক্ষর হতে হবে এবং অন্তত 1টি বড় হাতের অক্ষর এবং একটি সংখ্যা থাকতে হবে',
      'invalid_mail': 'অবৈধ ই-মেইল',
      'invalid_id': 'অবৈধ NSU আইডি। প্রথম 7 সংখ্যার NSU আইডি হতে হবে।',
      'invalid_phone': 'অবৈধ ফোন নম্বর: নিশ্চিত করুন যে নম্বরটি 01 দিয়ে শুরু হয়েছে, তৃতীয় সংখ্যা 3 থেকে 9 এর মধ্যে এবং মোট সংখ্যা 11টি অক্ষরের সমান।',
      'signup_fail': 'নিবন্ধন ব্যর্থ হয়েছে',
      'remember_me': 'আমাকে মনে রেখো',
      'go_home' : 'মূল পৃষ্ঠায় যান',
      'login_failed' : 'লগইন ব্যর্থ হয়েছে৷',
      'failed_otp'   : 'OTP পাঠাতে ব্যর্থ হয়েছে। আবার চেষ্টা করুন.',
      'cancel' : 'বাতিল করুন',
      'otp_verified' : 'OTP যাচাইকৃত! পুনঃনির্দেশ করা হচ্ছে...',
      'otp_invalid'  : 'অবৈধ OTP আবার চেষ্টা করুন.',
      'otp_send'     : 'আপনার মেইলে পাঠানো OTP লিখুন: ',
      'verify'       : 'যাচাই করুন',
    }
  };

  // Method to get the string for the given key and language code
  static String getString(String languageCode, String key) {
    return localizedValues[languageCode]?[key]
        ?? localizedValues['en']?[key]            //returns default language en if key is invalid
        ?? key;
  }
}
