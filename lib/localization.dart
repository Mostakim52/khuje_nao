/// A class that handles the localization of strings in different languages.

class AppLocalization {
    /// A map that stores localized strings for different languages.
    ///
    /// The keys are language codes (e.g., 'en' for English, 'bd' for Bengali),
    /// and the values are maps of key-value pairs where the key is a string
    /// representing a specific item or message, and the value is the localized
    /// string for that item in the corresponding language.
    static final Map<String, Map<String, String>> localized_values = {
        'en': {
            'camera'         : 'Camera',
            'cancel'         : 'Cancel',
            'chat'           : 'Chat',
            'email'          : 'Email',
            'failed_otp'     : 'Failed to send OTP. Please try again.',
            'feed'           : 'Activity Feed',
            'found_items'    : 'Found Items ',
            'found_loc'      : 'Found Location',
            'gallery'        : 'Gallery',
            'go_home'        : 'Go Home',
            'id'             : 'NSU ID (First 7 digits)',
            'invalid_id'     : 'Invalid NSU ID. Must be first 7 digits of NSU ID.',
            'invalid_mail'   : 'Invalid Email',
            'invalid_name'   : 'Invalid Name : Name limit is between 2 and 50 characters',
            'invalid_pass'   : 'Invalid Password: Must be at least 8 characters and have at least 1 uppercase letter and a number',
            'invalid_phone'  : 'Invalid phone number: \nMake sure the number starts with 01, \nthe third digit is 3 through 9 (for valid operators), \nand the total length is exactly 11 digits',
            'item_desc'      : 'Item Description',
            'login'          : 'Login',
            'login_failed'   : 'Login Failed.',
            'lost_items'     : 'Lost Items',
            'mark_found'     : 'Mark as Found',
            'mark_msg'       : 'Item marked as found',
            'name'           : 'Name',
            'no_img'         : 'No image selected',
            'okay'           : 'Okay',
            'otp_invalid'    : 'Invalid OTP. Please try again.',
            'otp_send'       : 'Enter OTP send to your mail: ',
            'otp_verified'   : 'OTP Verified! Redirecting...',
            'password'       : 'Password',
            'phone_no'       : 'Phone Number',
            'report_fail'    : 'Failed to submit report.',
            'report_lost'    : 'Report Lost Item',
            'report_success' : 'Report submitted successfully! Awaiting admin approval.',
            'req_fields'     : 'All fields are required!',
            'remember_me'    : 'Remember Me',
            'search'         : 'Search',
            'search_items'   : 'Search Items',
            'search_lost'    : 'Search Lost Items',
            'search_query'   : 'Search Query',
            'share'          : 'Share',
            'share_msg'      : 'Check out this lost item!',
            'signup'         : 'Signup',
            'signup_fail'    : 'Signup failed',
            'submit_report'  : 'Submit Report',
            'verify'         : 'Verify',
            'welcome'        : 'Welcome',
              },
        'bd': {
            'camera'        : 'ক্যামেরা',
            'cancel'        : 'বাতিল করুন',
            'chat'          : 'চ্যাট',
            'email'         : 'ই-মেইল',
            'failed_otp'    : 'OTP পাঠাতে ব্যর্থ হয়েছে। আবার চেষ্টা করুন.',
            'feed'          : 'কার্যক্রম ফিড',
            'found_items'   : 'খুঁজে পাওয়া বস্তু ',
            'found_loc'     : 'অবস্থান পাওয়া গেছে',
            'gallery'       : 'গ্যালারি',
            'go_home'       : 'মূল পৃষ্ঠায় যান',
            'id'            : 'NSU আইডি (প্রথম 7 সংখ্যা)',
            'invalid_id'    : 'অবৈধ NSU আইডি। প্রথম 7 সংখ্যার NSU আইডি হতে হবে।',
            'invalid_mail'  : 'অবৈধ ই-মেইল',
            'invalid_name'  : 'অবৈধ নাম; নামের সীমা 2 থেকে 50 অক্ষরের মধ্যে',
            'invalid_pass'  : 'অবৈধ পাসওয়ার্ড: কমপক্ষে 8 অক্ষর হতে হবে এবং অন্তত 1টি বড় হাতের অক্ষর এবং একটি সংখ্যা থাকতে হবে',
            'invalid_phone' : 'অবৈধ ফোন নম্বর: নিশ্চিত করুন যে নম্বরটি 01 দিয়ে শুরু হয়েছে, তৃতীয় সংখ্যা 3 থেকে 9 এর মধ্যে এবং মোট সংখ্যা 11টি অক্ষরের সমান।',
            'item_desc'     : 'আইটেম বিবরণ',
            'login'         : 'লগইন',
            'login_failed'  : 'লগইন ব্যর্থ হয়েছে৷',
            'lost_items'    : 'হারানো বস্তু',
            'mark_found'    : 'পাওয়া গিয়েছে চিহ্নিত করুন',
            'mark_msg'      : 'বস্তু খুঁজে পাওয়া হিসাবে চিহ্নিত করা হয়েছে',
            'name'          : 'নাম',
            'no_img'        : 'কোনো ছবি নির্বাচন করা হয়নি',
            'okay'          : 'ঠিক আছে',
            'otp_invalid'   : 'অবৈধ OTP আবার চেষ্টা করুন.',
            'otp_send'      : 'আপনার মেইলে পাঠানো OTP লিখুন: ',
            'otp_verified'  : 'OTP যাচাইকৃত! পুনঃনির্দেশ করা হচ্ছে...',
            'password'      : 'পাসওয়ার্ড',
            'phone_no'      : 'ফোন নম্বর',
            'report_fail'   : 'রিপোর্ট জমা দিতে ব্যর্থ।',
            'report_lost'   : 'হারানো বস্তু রিপোর্ট করুন',
            'report_success': 'রিপোর্ট সফলভাবে জমা দেওয়া হয়েছে! অ্যাডমিন অনুমোদনের অপেক্ষায়।',
            'req_fields'    : 'সমস্ত ক্ষেত্র প্রয়োজনীয়!',
            'remember_me'   : 'আমাকে মনে রেখো',
            'search'        : 'অনুসন্ধান করুন',
            'search_items'  : 'বস্তু খুঁজুন',
            'search_lost'   : 'হারিয়ে যাওয়া বস্তু খুঁজুন',
            'search_query'  : 'বস্তু অনুসন্ধান',
            'share'         : 'শেয়ার করুন',
            'share_msg'     : 'এই হারিয়ে যাওয়া জিনিসটি দেখুন!',
            'signup'        : 'নিবন্ধন',
            'signup_fail'   : 'নিবন্ধন ব্যর্থ হয়েছে',
            'submit_report' : 'রিপোর্ট জমা দিন',
            'verify'        : 'যাচাই করুন',
            'welcome'       : 'স্বাগতম',
            }
    };

/// Method to get the string for the given key and language code
/// Returns the localized string for the given [key] and [language_code].
///
/// If the [key] is not found in the provided [language_code], the method
/// will return the string from the default language ('en'). If the [key]
/// does not exist in the default language, the method will return the [key] itself.
///
/// [language_code] The language code (e.g., 'en', 'bd').
/// [key] The key representing the string to be retrieved.
///
/// Returns the localized string for the [key] in the specified language.
  static String getString(String language_code, String key) {
      return localized_values[language_code]?[key]
          ?? localized_values['en']?[key]            //returns default language en if key is invalid
          ?? key;
      }
  }
