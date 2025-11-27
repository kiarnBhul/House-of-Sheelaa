import 'package:flutter/material.dart';
import 'admin/app_admin.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCSS_KuD5VTmvJ_4JM8gHYf6-XMc0b_rTc',
      authDomain: 'house-of-sheelaa.firebaseapp.com',
      projectId: 'house-of-sheelaa',
      storageBucket: 'house-of-sheelaa.firebasestorage.app',
      messagingSenderId: '853952722810',
      appId: '1:853952722810:web:76b40df4ca85105dbc88c3',
      measurementId: 'G-XXMYSYW414',
    ),
  );
  runApp(const AdminApp());
}