import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kullanici_profili/chatSayfasi.dart';
import 'package:kullanici_profili/widgets/Avatar.dart';
import 'firebase_options.dart';

class Mesajlasma extends StatefulWidget {
  const Mesajlasma({Key? key}) : super(key: key);

  @override
  State<Mesajlasma> createState() => _MesajlasmaState();
}

class _MesajlasmaState extends State<Mesajlasma> {
  String name = "";
  bool isShow = false;
  final authInstance = FirebaseAuth.instance;

  final _textEditingController = TextEditingController();

  void getList(word) {
    setState(() {
      name = word;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void showAlertDialog(BuildContext context, uuid) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("İptal"),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop('dialog');
      },
    );
    Widget continueButton = TextButton(
      child: Text("Devam Et"),
      onPressed: () async {
        var currentUser = FirebaseAuth.instance.currentUser?.uid;
        var targetUser = uuid;
        var searchArray = [currentUser, targetUser];
        searchArray.sort();
        var searchCollection = await FirebaseFirestore.instance
            .collection("conversations")
            .where("members", isEqualTo: searchArray)
            .get();
        if (searchCollection.docs.isNotEmpty) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  ChatSayfasi(chatId: searchCollection.docs.first.id)));
          return;
        }
        // var collection = await FirebaseFirestore.instance
        //     .collection("conversations")
        //     // .where("members", arrayContainsAny: [currentUser]).where("members",
        //     //     arrayContainsAny: [targetUser])
        //     .get();
        // print(collection.docs.first.data().toString());
        // Map<String, dynamic> data =
        //     collection.docs.first as Map<String, dynamic>;
        // if (collection.docs.isNotEmpty) {
        //   print("daha önce mesaj varmış abi");
        // } else {
        Navigator.of(context, rootNavigator: true).pop('dialog');
        progressing(context);
        FirebaseFirestore.instance.collection("conversations").add({
          "displayMessage": "Hello world",
          "members": [currentUser, targetUser]
        }).then((value) => {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ChatSayfasi(chatId: value.id)))
            });
        // }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Mesaj Gönderme İsteği"),
      content: Text("Bu kişiye mesaj göndermek istediğinize emin misiniz?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void progressing(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Container(
            color: Colors.grey,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.grey,
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: Column(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Mesaj gondermek istediğiniz kişiyi yazın',
                contentPadding: EdgeInsets.all(8.0),
              ),
              onChanged: (word) {
                setState(() {
                  isShow = true;
                  if (word.isEmpty) {
                    isShow = false;
                  }
                  name = word;
                });
              },
            ),
            isShow
                ? Container(
                    height: 200,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .snapshots(),
                      builder: (context, snapshots) {
                        return (snapshots.connectionState ==
                                ConnectionState.waiting)
                            ? Center(
                                child: CircularProgressIndicator(),
                              )
                            : ListView.builder(
                                itemCount: snapshots.data!.docs.length,
                                itemBuilder: (context, index) {
                                  var data = snapshots.data!.docs[index].data()
                                      as Map<String, dynamic>;
                                  if (data['username']
                                      .toString()
                                      .toLowerCase()
                                      .startsWith(name.toLowerCase())) {
                                    return ListTile(
                                      title: Text(
                                        data['username'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        data['email'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      leading: SizedBox(
                                        child: KullaniciAvatar(
                                          kullaniciUid: data["uuid"],
                                        ),
                                        height: 40,
                                        width: 40,
                                      ),
                                      onTap: () {
                                        showAlertDialog(context, data["uuid"]);
                                      },
                                    );
                                  }
                                  return Container();
                                });
                      },
                    ),
                  )
                : Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('conversations')
                          .where("members",
                              arrayContains:
                                  FirebaseAuth.instance.currentUser!.uid)
                          .snapshots(),
                      builder: (context, snapshots) {
                        return (snapshots.connectionState ==
                                ConnectionState.waiting)
                            ? Center(
                                child: CircularProgressIndicator(),
                              )
                            : ListView.builder(
                                itemCount: snapshots.data!.docs.length,
                                itemBuilder: (context, index) {
                                  var data = snapshots.data!.docs[index].data()
                                      as Map<String, dynamic>;
                                  var lastMessage = data["displayMessage"];
                                  var otherUserUid;
                                  for (var uid in data["members"]) {
                                    if (uid !=
                                        FirebaseAuth
                                            .instance.currentUser!.uid) {
                                      otherUserUid = uid;
                                    }
                                  }
                                  var otherUser;
                                  var otherUserConnection = FirebaseFirestore
                                      .instance
                                      .collection("users")
                                      .doc(otherUserUid)
                                      .get();
                                  otherUserConnection.then(
                                      (value) => {otherUser = value.data()});
                                  print(lastMessage);
                                  return ListTile(
                                    title: Text(
                                      otherUser?['username'] ?? "",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    leading: SizedBox(
                                      child: KullaniciAvatar(
                                        kullaniciUid: otherUser?["uuid"] ?? "",
                                      ),
                                      height: 40,
                                      width: 40,
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) => ChatSayfasi(
                                                  chatId: snapshots
                                                      .data!.docs[index].id)));
                                    },
                                  );
                                });
                      },
                    ),
                  )
          ],
        ),
      ),
    );
  }
}
