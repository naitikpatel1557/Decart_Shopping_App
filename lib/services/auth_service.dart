import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. REGISTER USER
  Future<String?> registerUser({required String name, required String email, required String password}) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // Save details to 'users' collection in Firestore
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'createdAt': DateTime.now(),
        'role': 'customer',
      });
      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // 2. LOGIN USER
  Future<String?> loginUser({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // 3. LOGOUT USER
  Future<void> logoutUser() async {
    await _auth.signOut();
  }
}