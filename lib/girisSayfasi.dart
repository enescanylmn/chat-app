import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kullanici_profili/kayitSayfasi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kullanici_profili/uygulamaSayfa.dart';

class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({Key? key}) : super(key: key);

  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  bool emailKontrol(String ifade) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(ifade);
  }

  void girisYap(String email, String sifre) {
    authInstance
        .signInWithEmailAndPassword(email: email, password: sifre)
        .then((value) {
      if (value.user != null) {
        if (!value.user!.emailVerified) {
          authInstance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Account not verified. Check your mail")));
        } else {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => UygulamaSayfa(),
              ),
              (route) => false);
        }
      }
    });
  }

  final emailUnameController = TextEditingController();
  final passwordController = TextEditingController();
  final authInstance = FirebaseAuth.instance;
  final dbInstance = FirebaseDatabase.instance;
  bool emailMi = false;
  bool gecerliSifre = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Giriş Sayfası"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                child: TextField(
                  controller: emailUnameController,
                  decoration: InputDecoration(
                    hintText: "Email/Kullanıcı adı",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                  ),
                  onChanged: (value) {
                    setState(() {
                      emailMi = emailKontrol(value);
                    });
                  },
                ),
                width: min(500, MediaQuery.of(context).size.width * 2 / 4),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                child: TextField(
                    onChanged: (value) {
                      setState(() {
                        gecerliSifre = (value.length >= 6);
                      });
                    },
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                        hintText: "Şifre",
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))))),
                width: min(500, MediaQuery.of(context).size.width * 2 / 4),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 100, 0, 8),
            child: ElevatedButton(
              onPressed: () {
                String email = emailUnameController.text;
                if (!emailMi) {
                  dbInstance
                      .ref("/users")
                      .orderByChild("username")
                      .equalTo(emailUnameController.text)
                      .once()
                      .then((value) {
                    if (value.snapshot.value != null) {
                      email = ((value.snapshot.value as Map).values.first
                          as Map)["email"];
                      girisYap(email, passwordController.text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              "Can't find the account you're trying to log into")));
                    }
                  });
                } else {
                  girisYap(email, passwordController.text);
                }
              },
              child: Text("Giriş Yap"),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KayitSayfasi(),
                    ));
              },
              child: Text("Hesabınız yok mu? Kayıt olun"),
            ),
          ),
        ],
      ),
    );
  }
}
