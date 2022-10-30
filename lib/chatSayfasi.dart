import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:kullanici_profili/Models/ChatMessage.dart';

import 'widgets/Avatar.dart';

class ChatSayfasi extends StatefulWidget {
  final String chatId;
  const ChatSayfasi({Key? key, required this.chatId}) : super(key: key);
  @override
  State<ChatSayfasi> createState() => _ChatSayfasiState();
}

class _ChatSayfasiState extends State<ChatSayfasi> {
  final _chatFieldController = TextEditingController();
  final authInstance = FirebaseAuth.instance;
  final dbInstance = FirebaseDatabase.instance;
  final storageInstance = FirebaseStorage.instance;
  var foundUsers = [];
  var receiver;
  var currentUserId = FirebaseAuth.instance.currentUser?.uid;

  void initState() {
    super.initState();
    getUsers();
  }

  Future<void> getUsers() async {
    var usersInChat = await FirebaseFirestore.instance
        .collection("conversations")
        .doc(widget.chatId)
        .get();
    foundUsers = usersInChat.data()!["members"];
    foundUsers.remove(currentUserId);
    var receiverUser = await FirebaseFirestore.instance
        .collection("users")
        .doc(foundUsers.first)
        .get();

    setState(() {
      receiver = receiverUser.data();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                  ),
                ),
                SizedBox(
                  width: 2,
                ),
                KullaniciAvatar(kullaniciUid: authInstance.currentUser!.uid),
                SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        receiver?["username"] ?? "",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        height: 6,
                      ),
                      Text(
                        "Online",
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('conversations')
                .doc(widget.chatId)
                .collection("messages")
                .orderBy("createdAt", descending: false)
                .snapshots(),
            builder: (context, snapshots) {
              return (snapshots.connectionState == ConnectionState.waiting)
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      itemCount: snapshots.data!.docs.length,
                      shrinkWrap: true,
                      padding: EdgeInsets.only(top: 10, bottom: 10),
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        var data = snapshots.data!.docs[index].data()
                            as Map<String, dynamic>;
                        return Container(
                          padding: EdgeInsets.only(
                              left: 14, right: 14, top: 10, bottom: 10),
                          child: Align(
                            alignment: (data["senderId"] != currentUserId
                                ? Alignment.topLeft
                                : Alignment.topRight),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: (data["senderId"] != currentUserId
                                    ? Colors.grey.shade200
                                    : Colors.blue[200]),
                              ),
                              padding: EdgeInsets.all(16),
                              child: Text(
                                data["message"],
                                style: TextStyle(fontSize: 15),
                              ),
                            ),
                          ),
                        );
                      },
                    );
            },
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),
              height: 60,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _chatFieldController,
                      decoration: InputDecoration(
                          hintText: "Bir mesaj yaz",
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none),
                    ),
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      var message = _chatFieldController.text;
                      var senderId = FirebaseAuth.instance.currentUser?.uid;
                      FirebaseFirestore.instance
                          .collection("conversations")
                          .doc(widget.chatId)
                          .collection("messages")
                          .add({
                        "message": message,
                        "senderId": senderId,
                        "createdAt": DateTime.now()
                      });
                      FirebaseFirestore.instance
                          .collection("conversations")
                          .doc(widget.chatId)
                          .update({"displayMessage": message});
                      _chatFieldController.text = "";
                    },
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                    backgroundColor: Colors.blue,
                    elevation: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
