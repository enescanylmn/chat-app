import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kullanici_profili/girisSayfasi.dart';
import 'package:kullanici_profili/uygulamaSayfa.dart';

class KayitSayfasi extends StatefulWidget {
  const KayitSayfasi({Key? key}) : super(key: key);

  @override
  State<KayitSayfasi> createState() => _KayitSayfasiState();
}

class _KayitSayfasiState extends State<KayitSayfasi> {
  final authInstance = FirebaseAuth.instance;
  final dbInstance = FirebaseDatabase.instance;

  bool emailKontrol(String ifade) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(ifade);
  }

  bool emailMi = false;
  bool gecerliKadi = false;
  bool gecerliSifre = false;

  final kullaniciAdiController = TextEditingController();
  final emailController = TextEditingController();
  final sifreController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kayıt Sayfası"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                child: TextField(
                  controller: kullaniciAdiController,
                  decoration: InputDecoration(
                    hintText: "Kullanıcı adı",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                  ),
                  onChanged: (value) {
                    setState(() {
                      gecerliKadi = (value.length >= 5);
                    });
                  },
                ),
                width: min(500, MediaQuery.of(context).size.width * 2 / 4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: "Email",
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
                    controller: sifreController,
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
              onPressed: (emailMi && gecerliKadi && gecerliSifre)
                  ? () {
                      authInstance
                          .createUserWithEmailAndPassword(
                              email: emailController.text,
                              password: sifreController.text)
                          .then((value) {
                        if (value.user != null) {
                          dbInstance.ref("/users/${value.user!.uid}").set({
                            "email": emailController.text,
                            "username": kullaniciAdiController.text,
                            "avatar": "default_avatar.jpg"
                          }).then(
                            (dbfinished) {
                              FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(value.user!.uid)
                                  .set({
                                "email": emailController.text,
                                "username": kullaniciAdiController.text,
                                "avatar": "default_avatar.jpg",
                                "uuid": value.user!.uid
                              });
                              value.user!.sendEmailVerification().then((value) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        "Sent verification link. Check your mail")));
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GirisSayfasi(),
                                    ),
                                    (route) => false);
                              });
                            },
                          ).catchError((onError) {
                            authInstance.currentUser!.delete();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  (onError as FirebaseAuthException).message!),
                            ));
                          });
                        }
                      }).catchError((onError) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text((onError as FirebaseAuthException).message!),
                        ));
                      });
                    }
                  : null,
              child: Text("Kayıt ol"),
            ),
          )
        ],
      ),
    );
  }
}
