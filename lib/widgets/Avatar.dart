import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class KullaniciAvatar extends StatelessWidget {
  final String kullaniciUid;
  const KullaniciAvatar({Key? key, required this.kullaniciUid})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
        child: StreamBuilder(
          stream: FirebaseDatabase.instance
              .ref("users/${this.kullaniciUid}")
              .onValue,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var fileName = (snapshot.data!.snapshot.value! as Map)["avatar"];
              return FutureBuilder(
                future: FirebaseStorage.instance
                    .ref("avatars/$fileName")
                    .getDownloadURL(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(45),
                      child: Image.network(
                        snapshot.data!,
                        width: 90,
                        height: 90,
                      ),
                    );
                  } else {
                    return Container();
                  }
                },
              );
            } else {
              return Container();
            }
          },
        ),
        minRadius: 75);
  }
}
