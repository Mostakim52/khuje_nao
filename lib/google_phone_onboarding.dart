// // lib/google_phone_onboarding.dart
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'api_service.dart';
//
// class GooglePhoneOnboarding extends StatefulWidget {
//   const GooglePhoneOnboarding({super.key});
//
//   @override
//   State<GooglePhoneOnboarding> createState() => _GooglePhoneOnboardingState();
// }
//
// class _GooglePhoneOnboardingState extends State<GooglePhoneOnboarding> {
//   final _nameCtrl = TextEditingController();
//   final _nsuCtrl = TextEditingController();
//   final _phoneCtrl = TextEditingController();    // E.164: +8801XXXXXXXXX
//   final _otpCtrl = TextEditingController();
//
//   final _api = ApiService();
//   bool _loading = false;
//   String? _verificationId;
//   String _status = '';
//   bool _googleDone = false;
//   bool _otpSent = false;
//
//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _nsuCtrl.dispose();
//     _phoneCtrl.dispose();
//     _otpCtrl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _continueWithGoogle() async {
//     setState(() { _loading = true; _status = ''; });
//     try {
//       final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
//       if (gUser == null) {
//         setState(() => _status = 'Google sign-in canceled');
//         return;
//       }
//       final gAuth = await gUser.authentication;
//       final credential = GoogleAuthProvider.credential(
//         accessToken: gAuth.accessToken,
//         idToken: gAuth.idToken,
//       );
//       await FirebaseAuth.instance.signInWithCredential(credential);
//
//       // Optionally prefill name from Google display name.
//       final displayName = FirebaseAuth.instance.currentUser?.displayName ?? '';
//       if (displayName.isNotEmpty && _nameCtrl.text.isEmpty) {
//         _nameCtrl.text = displayName;
//       }
//
//       setState(() { _googleDone = true; _status = 'Google signed in. Now verify phone.'; });
//     } on FirebaseAuthException catch (e) {
//       setState(() => _status = e.message ?? 'Google sign-in failed');
//     } catch (e) {
//       setState(() => _status = 'Google sign-in error: $e');
//     } finally {
//       setState(() => _loading = false);
//     }
//   }
//
//   Future<void> _sendOtp() async {
//     final phone = _phoneCtrl.text.trim();
//     if (!phone.startsWith('+')) {
//       setState(() => _status = 'Enter phone like +8801XXXXXXXXX');
//       return;
//     }
//     setState(() { _loading = true; _status = ''; });
//     await FirebaseAuth.instance.verifyPhoneNumber(
//       phoneNumber: phone,
//       timeout: const Duration(seconds: 60),
//       verificationCompleted: (cred) async {
//         try {
//           // Link phone to the same Firebase user if needed:
//           // await FirebaseAuth.instance.currentUser?.linkWithCredential(cred);
//           // Or sign in with credential (if user wasn’t already signed in)
//           await FirebaseAuth.instance.signInWithCredential(cred);
//           setState(() { _otpSent = true; _status = 'Phone verified automatically'; });
//         } catch (e) {
//           setState(() => _status = 'Auto verification error: $e');
//         }
//       },
//       verificationFailed: (e) {
//         setState(() => _status = e.message ?? 'Verification failed');
//       },
//       codeSent: (id, _) {
//         setState(() { _verificationId = id; _otpSent = true; _status = 'Code sent via SMS'; });
//       },
//       codeAutoRetrievalTimeout: (id) {
//         _verificationId = id;
//       },
//     );
//     setState(() => _loading = false);
//   }
//
//   Future<void> _verifyOtpAndComplete() async {
//     if (_verificationId == null) {
//       setState(() => _status = 'Tap Send OTP first');
//       return;
//     }
//     final sms = _otpCtrl.text.trim();
//     if (sms.length < 4) {
//       setState(() => _status = 'Enter the 6-digit code');
//       return;
//     }
//     final name = _nameCtrl.text.trim();
//     final nsu = int.tryParse(_nsuCtrl.text.trim()) ?? 0;
//     if (name.isEmpty || nsu <= 0) {
//       setState(() => _status = 'Enter a valid name and NSU ID');
//       return;
//     }
//
//     setState(() { _loading = true; _status = ''; });
//     try {
//       final cred = PhoneAuthProvider.credential(
//         verificationId: _verificationId!,
//         smsCode: sms,
//       );
//       // Link phone as a second factor to the already-signed-in Google user
//       try {
//         await FirebaseAuth.instance.currentUser?.linkWithCredential(cred);
//       } on FirebaseAuthException catch (e) {
//         // If already linked or linking not allowed, fall back to re-auth or ignore
//         if (e.code == 'provider-already-linked') {
//           // ignore
//         } else {
//           // As a fallback, sign-in with cred (if Google session dropped)
//           await FirebaseAuth.instance.signInWithCredential(cred);
//         }
//       }
//
//       // Get token and save profile server-side
//       final token = await FirebaseAuth.instance.currentUser?.getIdToken();
//       if (token == null) {
//         setState(() => _status = 'Could not get ID token');
//         return;
//       }
//       final ok = await _api.completeProfileWithToken(
//         token: token,
//         name: name,
//         nsuId: nsu,
//         phone: _phoneCtrl.text.trim(),
//       );
//       if (!ok) {
//         setState(() => _status = 'Server profile save failed');
//         return;
//       }
//
//       if (mounted) Navigator.of(context).pop(true);
//     } on FirebaseAuthException catch (e) {
//       setState(() => _status = e.message ?? 'Invalid code');
//     } catch (e) {
//       setState(() => _status = 'Error: $e');
//     } finally {
//       setState(() => _loading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final canComplete = _googleDone;
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Sign up with Google + Phone OTP')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: ListView(
//           children: [
//             ElevatedButton(
//               onPressed: _loading ? null : _continueWithGoogle,
//               child: const Text('Continue with Google'),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _nameCtrl,
//               decoration: const InputDecoration(labelText: 'Name (required)'),
//             ),
//             TextField(
//               controller: _nsuCtrl,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(labelText: 'NSU ID (required)'),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _phoneCtrl,
//               keyboardType: TextInputType.phone,
//               decoration: const InputDecoration(labelText: 'Phone (+8801XXXXXXXXX)'),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _loading || !canComplete ? null : _sendOtp,
//                     child: const Text('Send OTP'),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _loading || !(_otpSent && canComplete) ? null : _verifyOtpAndComplete,
//                     child: const Text('Verify & Finish'),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             if (_loading) const Center(child: CircularProgressIndicator()),
//             if (_status.isNotEmpty) Text(_status, style: const TextStyle(color: Colors.red)),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class GooglePhoneOnboarding extends StatefulWidget {
  const GooglePhoneOnboarding({super.key});

  @override
  State<GooglePhoneOnboarding> createState() => _GooglePhoneOnboardingState();
}

class _GooglePhoneOnboardingState extends State<GooglePhoneOnboarding> {
  final _nameCtrl = TextEditingController();
  final _nsuCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final _api = ApiService();

  bool _loading = false;
  bool _googleDone = false;
  // OTP removed
  String _status = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nsuCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _setStatus(String msg) => setState(() => _status = msg);

  Future<void> _continueWithGoogle() async {
    setState(() { _loading = true; _status = ''; });
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) {
        _setStatus('Google sign-in canceled');
        return;
      }
      final gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Prefill display name if available
      final dn = FirebaseAuth.instance.currentUser?.displayName ?? '';
      if (dn.isNotEmpty && _nameCtrl.text.isEmpty) {
        _nameCtrl.text = dn;
      }

      setState(() {
        _googleDone = true;
      });
      _setStatus('Google signed in. Verify your email with OTP.');
    } on FirebaseAuthException catch (e) {
      _setStatus(e.message ?? 'Google sign-in failed');
    } catch (e) {
      _setStatus('Google sign-in error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // OTP removed

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    final nsu = int.tryParse(_nsuCtrl.text.trim()) ?? 0;
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || nsu <= 0 || phone.isEmpty) {
      _setStatus('Enter name, NSU ID and phone.');
      return;
    }
    setState(() { _loading = true; _status = ''; });
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        _setStatus('Could not get ID token.');
        return;
      }
      final saved = await _api.completeProfileWithToken(
        token: token,
        name: name,
        nsuId: nsu,
        phone: phone,
      );
      if (!saved) {
        _setStatus('Server profile save failed.');
        return;
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _setStatus('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _googleDone && !_loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Complete profile (Google)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _continueWithGoogle,
              child: const Text('Continue with Google'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name (required)'),
            ),
            TextField(
              controller: _nsuCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'NSU ID (required)'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (required)'),
            ),
            const SizedBox(height: 12),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: canSave ? _saveProfile : null,
              child: const Text('Save profile'),
            ),

            const SizedBox(height: 12),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_status.isNotEmpty)
              Text(_status, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
