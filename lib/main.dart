import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'dart:async';
import 'package:flutter_face_api_beta/face_api.dart' as Regula;
import 'package:image_picker/image_picker.dart';

void main() => runApp(MaterialApp(home: const MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var image1 = Regula.MatchFacesImage();
  var image2 = Regula.MatchFacesImage();
  var img1 = Image.asset('assets/images/portrait.png');
  var img2 = Image.asset('assets/images/portrait.png');
  String _similarity = "nil";
  String _liveness = "nil";

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {}

  showAlertDialog(BuildContext context, bool first) => showDialog(
      context: context,
      builder: (BuildContext context) =>
          AlertDialog(title: const Text("Select option"), actions: [
            // ignore: deprecated_member_use
            FlatButton(
                child: const Text("Use gallery"),
                onPressed: () {
                  ImagePicker().getImage(source: ImageSource.gallery).then(
                      (value) => setImage(
                          first,
                          io.File(value!.path).readAsBytesSync(),
                          Regula.ImageType.PRINTED));
                  Navigator.pop(context);
                }),
            // ignore: deprecated_member_use
            FlatButton(
                child: const Text("Use camera"),
                onPressed: () {
                  Regula.FaceSDK.presentFaceCaptureActivity().then((result) =>
                      setImage(
                          first,
                          base64Decode(Regula.FaceCaptureResponse.fromJson(
                                  json.decode(result))
                              !.image!
                              .bitmap!
                              .replaceAll("\n", "")),
                          Regula.ImageType.LIVE));
                  Navigator.pop(context);
                })
          ]));

  setImage(bool first, List<int> imageFile, int type) {
    if (imageFile == null) return;
    setState(() => _similarity = "nil");
    if (first) {
      image1.bitmap = base64Encode(imageFile);
      image1.imageType = type;
      setState(() {
        img1 = Image.memory(Uint8List.fromList( imageFile));
        _liveness = "nil";
      });
    } else {
      image2.bitmap = base64Encode(imageFile);
      image2.imageType = type;
      setState(() => img2 = Image.memory(Uint8List.fromList( imageFile)));
    }
  }

  clearResults() {
    setState(() {
      img1 = Image.asset('assets/images/portrait.png');
      img2 = Image.asset('assets/images/portrait.png');
      _similarity = "nil";
      _liveness = "nil";
    });
    image1 = Regula.MatchFacesImage();
    image2 = Regula.MatchFacesImage();
  }

  matchFaces() {
    if (image1.bitmap == null ||
        image1.bitmap == "" ||
        image2.bitmap == null ||
        image2.bitmap == "") return;
    setState(() => _similarity = "Processing...");
    var request =  Regula.MatchFacesRequest();
    request.images = [image1, image2];
    Regula.FaceSDK.matchFaces(jsonEncode(request)).then((value) {
      var response = Regula.MatchFacesResponse.fromJson(json.decode(value));
      Regula.FaceSDK.matchFacesSimilarityThresholdSplit(jsonEncode(response!.results), 0.75).then((str) {
        var split = Regula.MatchFacesSimilarityThresholdSplit.fromJson(json.decode(str));
        setState(() => _similarity = split!.matchedFaces.isNotEmpty ? ("${(split.matchedFaces[0]!.similarity! * 100.0).toStringAsFixed(2)}%") : "error");
      });
    });
  }

  liveness() => Regula.FaceSDK.startLiveness().then((value) {
        var result = Regula.LivenessResponse.fromJson(json.decode(value));
        setImage(true, base64Decode(result!.bitmap!.replaceAll("\n", "")),
            Regula.ImageType.LIVE);
        setState(() => _liveness = result.liveness == 0 ? "passed" : "unknown");
      });

  Widget createButton(String text, VoidCallback onPress) => SizedBox(
        // ignore: deprecated_member_use
        width: 250,
        // ignore: deprecated_member_use
        child: FlatButton(
            color: Color.fromARGB(50, 10, 10, 10),
            onPressed: onPress,
            child: Text(text)),
      );

  Widget createImage(image, VoidCallback onPress) => Material(
          child: InkWell(
        onTap: onPress,
        child: Container(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Image(height: 150, width: 150, image: image),
          ),
        ),
      ));

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
            margin: const EdgeInsets.fromLTRB(0, 0, 0, 100),
            width: double.infinity,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  createImage(img1.image, () => showAlertDialog(context, true)),
                  createImage(
                      img2.image, () => showAlertDialog(context, false)),
                  Container(margin: const EdgeInsets.fromLTRB(0, 0, 0, 15)),
                  createButton("Match", () => matchFaces()),
                  createButton("Liveness", () => liveness()),
                  createButton("Clear", () => clearResults()),
                  Container(
                      margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Similarity: $_similarity",
                              style: const TextStyle(fontSize: 18)),
                          Container(margin: const EdgeInsets.fromLTRB(20, 0, 0, 0)),
                          Text("Liveness: $_liveness",
                              style: const TextStyle(fontSize: 18))
                        ],
                      ))
                ])),
      );
}