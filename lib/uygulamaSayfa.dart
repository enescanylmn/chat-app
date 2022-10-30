import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kullanici_profili/girisSayfasi.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kullanici_profili/haritaSayfasi.dart';
import 'package:kullanici_profili/widgets/Avatar.dart';
import 'mesajlasma.dart';

class UygulamaSayfa extends StatefulWidget {
  const UygulamaSayfa({Key? key}) : super(key: key);

  @override
  State<UygulamaSayfa> createState() => _UygulamaSayfaState();
}

class _UygulamaSayfaState extends State<UygulamaSayfa> {
  final friendController = TextEditingController();

  Widget getCurrentPage() {
    switch (currentPage) {
      case 0:
        return AnaSayfa();
      case 1:
        return Mesajlasma();
      case 2:
        return MapSample();
      default:
        return Container();
    }
  }

  int currentPage = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: BottomNavigationBar(
            onTap: ((value) {
              setState(() {
                currentPage = value;
              });
            }),
            currentIndex: currentPage,
            items: [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home), label: "Anasayfa"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.chat), label: "Mesajlaşma"),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: "Harita"),
            ]),
        appBar: AppBar(
          title: Text("Uygulama"),
          actions: [
            IconButton(onPressed: () {}, icon: Icon(Icons.add_box_outlined))
          ],
        ),
        body: getCurrentPage());
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({Key? key}) : super(key: key);

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  final authInstance = FirebaseAuth.instance;
  final dbInstance = FirebaseDatabase.instance;
  final storageInstance = FirebaseStorage.instance;
  final picker = ImagePicker();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            children: [
              KullaniciAvatar(kullaniciUid: authInstance.currentUser!.uid),
              Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    shape: CircleBorder(),
                    color: Colors.white,
                    child: InkWell(
                        customBorder: CircleBorder(),
                        onTap: () {
                          picker
                              .pickImage(source: ImageSource.gallery)
                              .then((file) {
                            if (file != null) {
                              int milis = DateTime.now().millisecondsSinceEpoch;
                              String fileName = authInstance.currentUser!.uid +
                                  "_" +
                                  milis.toString();
                              file.readAsBytes().then((fileAsBytes) {
                                storageInstance
                                    .ref("avatars/${fileName}.jpg")
                                    .putData(fileAsBytes)
                                    .whenComplete(() => {
                                          dbInstance
                                              .ref(
                                                  "/users/${authInstance.currentUser!.uid}")
                                              .get()
                                              .then((userFromDb) {
                                            var user =
                                                (userFromDb.value as Map);
                                            if (user["avatar"] !=
                                                "default_avatar.jpg") {
                                              storageInstance
                                                  .ref(
                                                      "avatars/${user["avatar"]}")
                                                  .delete();
                                            }
                                            user["avatar"] = fileName + ".jpg";
                                            dbInstance
                                                .ref(
                                                    "/users/${authInstance.currentUser!.uid}")
                                                .set(user);
                                          })
                                        });
                              });
                            }
                          });
                        },
                        child: Icon(Icons.camera)),
                  ))
            ],
          ),
        ),
        Center(
          child: ElevatedButton(
            onPressed: () {
              authInstance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => GirisSayfasi(),
                  ),
                  (route) => false);
            },
            child: Text("Çıkış"),
          ),
        ),
      ],
    );
  }
}
