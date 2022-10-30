import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Future<Position> getUserCurrentLocation() async {
    await Geolocator.requestPermission()
        .then((value) {})
        .onError((error, stackTrace) async {
      await Geolocator.requestPermission();
      print("ERROR" + error.toString());
    });
    return await Geolocator.getCurrentPosition();
  }

  Completer<GoogleMapController> _controller = Completer();

  LatLng initialLocation = LatLng(37.42796133580664, -122.085749655962);
  CameraPosition getCurrentCameraPosition() {
    return CameraPosition(
      target: initialLocation,
      zoom: 14.4746,
    );
  }

  Set<Marker> markers = Set();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.8),
        child: Scaffold(
          floatingActionButton: FloatingActionButton(onPressed: () {
            getUserCurrentLocation().then((value) {
              initialLocation = LatLng(value.latitude, value.longitude);
              goToCurrentLocation();
            });
          }),
          body: GoogleMap(
            onLongPress: (argument) {
              setState(() {
                FirebaseDatabase.instance
                    .ref("users/${FirebaseAuth.instance.currentUser!.uid}")
                    .get()
                    .then((userData) {
                  var fileName = ((userData.value as Map)["avatar"]);

                  FirebaseStorage.instance
                      .ref("avatars/$fileName")
                      .getData()
                      .then((avatarAsBytes) {
                    markers.add(Marker(
                        markerId:
                            MarkerId(FirebaseAuth.instance.currentUser!.email!),
                        position: argument,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure)));
                  });
                });
              });
            },
            markers: markers,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            mapType: MapType.hybrid,
            initialCameraPosition: getCurrentCameraPosition(),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
        ),
      ),
    );
  }

  Future<void> goToCurrentLocation() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
        CameraUpdate.newCameraPosition(getCurrentCameraPosition()));
  }
}
