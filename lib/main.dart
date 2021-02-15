import 'dart:io';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';




List<CameraDescription> cameras;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Food Tracer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>  {

  CameraController controller;
  FirebaseVisionImage visionImage;

  // Streamcontroller<List<String>> streamController ;

  Future<File> getImageFile(XFile imageXFile)async{
  return File.fromRawPath(await imageXFile.readAsBytes());
  }
  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    // streamController = Streamcontroller();
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();

    //streamController?.dispose();
    super.dispose();
  }




  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
       // onNewCameraSelected(controller.description);
      }
    }
  }
  XFile imageXFile;
  final ImageLabeler labeler = FirebaseVision.instance.imageLabeler();
  List<String> labelList;


  Future<List<String>> getLabelList()async{
    imageXFile = await controller.takePicture();
    visionImage = FirebaseVisionImage.fromFilePath(imageXFile.path);
    final List<ImageLabel> labels = await labeler.processImage(visionImage);
    return  labels.map((e) => e.text).toList();
  }
  bool pictureClicked =false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(widget.title)),
      ),
      body: Center(
        child: Column(
          children: [
            if (!controller.value.isInitialized) Container(),
            if(controller.value.isInitialized)
            Column(
              children: [
                AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: CameraPreview(controller)),
                IconButton(
                  icon: Icon(FontAwesomeIcons.camera),
                  onPressed: ()async{
                    // await getLabelList();
                    pictureClicked=true;
                  },
                ),
                FutureBuilder<List<String>>(
                  future: getLabelList(),
                    builder: (context,snapshot){
                    final list = snapshot.data;
                    pictureClicked=false;
                    if(snapshot.connectionState==ConnectionState.done){
                      if(snapshot.hasError){
                        return Text('${snapshot.error}');
                      }else
                    return Column(
                      children: [
                        ...list.map((e) => Text(e)).toList()
                      ],
                    );}
                    else return Text('No Data Received');
                    },
                    )

              ],
            ),
            //Listener()
          ],
        ),
      ),
    );
  }
}
