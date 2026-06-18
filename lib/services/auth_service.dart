import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // 🔥 KHUSUS WEB: Gunakan signInWithPopup agar lebih stabil
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({
          'prompt': 'select_account',
        });
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // 🔥 KHUSUS MOBILE: Gunakan google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user != null) {
        // 🆔 CEK APAKAH USER SUDAH ADA DI FIRESTORE
        DocumentSnapshot doc = await _firestore.collection('user').doc(user.uid).get();
        
        if (!doc.exists) {
          // 🔥 JIKA USER BARU, BUAT DOKUMENNYA
          String userIdCode = "SP-${(10000 + (DateTime.now().millisecondsSinceEpoch % 90000))}";
          await _firestore.collection('user').doc(user.uid).set({
            "name": user.displayName ?? "User Google",
            "email": user.email,
            "role": "user",
            "userIdCode": userIdCode,
            "phoneNumber": user.phoneNumber ?? "",
            "createdAt": FieldValue.serverTimestamp(),
          });
          print("DEBUG: New user created from Google Login: $userIdCode");
        }
      }

      return userCredential;
    } catch (e) {
      print("Error signing in with Google: $e");
      rethrow;
    }
  }

  // Sign up with Email and Password
  Future<UserCredential?> signUpWithEmail(String email, String password, String name, String phoneNumber) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // 🆔 GENERATE USER ID CODE (Format: SP-XXXXX)
      String userIdCode = "SP-${(10000 + (DateTime.now().millisecondsSinceEpoch % 90000))}";

      // 🔥 SIMPAN KE FIRESTORE (Role default: user)
      await _firestore.collection('user').doc(userCredential.user?.uid).set({
        "name": name,
        "email": email,
        "role": "user",
        "userIdCode": userIdCode,
        "phoneNumber": phoneNumber,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 🔥 KIRIM EMAIL VERIFIKASI
      await userCredential.user?.sendEmailVerification();

      return userCredential;
    } catch (e) {
      print("Error signing up: $e");
      rethrow;
    }
  }

  // Sign in with Email and Password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Error signing in: $e");
      rethrow;
    }
  }

  // Reset Password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Error sending password reset email: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get User Role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      print("DEBUG: Fetching role for UID: $uid");
      DocumentSnapshot doc = await _firestore.collection('user').doc(uid).get();
      if (doc.exists) {
        String? role = doc.get('role') as String?;
        print("DEBUG: Role found in Firestore: $role");
        return role;
      }
      print("DEBUG: Document does not exist in Firestore for UID: $uid");
      return "user"; // Default role
    } catch (e) {
      print("DEBUG: Error getting user role: $e");
      return "user";
    }
  }

  // 🔥 Get Full User Data Stream
  Stream<DocumentSnapshot> getUserData(String uid) {
    return _firestore.collection('user').doc(uid).snapshots();
  }

  // 🔥 Update User Data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('user').doc(uid).update(data);
    } catch (e) {
      print("Error updating user data: $e");
      rethrow;
    }
  }

  // 🔥 Update Password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      print("Error updating password: $e");
      rethrow;
    }
  }

  // 🔥 Update Email
  Future<void> updateEmail(String newEmail) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
      await _firestore.collection('user').doc(_auth.currentUser?.uid).update({"email": newEmail});
    } catch (e) {
      print("Error updating email: $e");
      rethrow;
    }
  }

  // 🔥 Update Display Name
  Future<void> updateDisplayName(String name) async {
    try {
      await _auth.currentUser?.updateDisplayName(name);
      await _firestore.collection('user').doc(_auth.currentUser?.uid).update({"name": name});
    } catch (e) {
      print("Error updating display name: $e");
      rethrow;
    }
  }
  // 🔥 Get User-Friendly Error Message
  static String getErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return "Email atau kata sandi salah. Silakan coba lagi.";
        case 'email-already-in-use':
          return "Email sudah terdaftar. Silakan gunakan email lain.";
        case 'invalid-email':
          return "Format email tidak valid.";
        case 'user-disabled':
          return "Akun ini telah dinonaktifkan.";
        case 'weak-password':
          return "Kata sandi terlalu lemah. Gunakan minimal 6 karakter.";
        case 'network-request-failed':
          return "Koneksi internet bermasalah. Periksa koneksi Anda.";
        case 'too-many-requests':
          return "Terlalu banyak percobaan. Silakan coba lagi nanti.";
        case 'popup-closed-by-user':
          return "Proses login dengan Google dibatalkan oleh pengguna.";
        case 'popup-blocked':
          return "Popup login diblokir oleh browser. Izinkan popup untuk login.";
        default:
          return "Terjadi kesalahan: ${e.message ?? 'Unknown error'}";
      }
    }
    return "Terjadi kesalahan: ${e.toString()}";
  }
}
