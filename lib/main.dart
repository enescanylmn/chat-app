import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kullanici_profili/haritaSayfasi.dart';
import 'package:kullanici_profili/uygulamaSayfa.dart';
import 'firebase_options.dart';
import 'girisSayfasi.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(UygulamaGiris());
}

class UygulamaGiris extends StatefulWidget {
  const UygulamaGiris({Key? key}) : super(key: key);

  @override
  State<UygulamaGiris> createState() => _UygulamaGirisState();
}

class _UygulamaGirisState extends State<UygulamaGiris> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Kullanıcı Profili",
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) return UygulamaSayfa();
            return GirisSayfasi();
          } else {
            return Scaffold(
              body: Center(
                child: SizedBox(
                  height: 200,
                  width: 200,
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
