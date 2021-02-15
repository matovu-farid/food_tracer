import 'dart:async';
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
    streamController.close();

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
  var completer = Completer<List<String>>();
  final streamController = StreamController<List<String>>();
  Future addToStream()async{
    final list = await getLabelList();
    streamController.add(list);
  }
  // List<String> get stream =>streamController.stream;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(widget.title)),
      ),
      body: Center(
        child: ListView(
          children: [
            if (!controller.value.isInitialized) Container(),
            if(controller.value.isInitialized)
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  Flexible(

                    child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: CameraPreview(controller)),
                    flex: 4,
                  ),
                  Flexible(
                    flex: 2,
                    child: IconButton(
                      icon: Icon(FontAwesomeIcons.camera),
                      onPressed: (){

                        addToStream();
                      },
                    ),
                  ),
                  Flexible(
                    flex: 4,
                    child: StreamBuilder<List<String>>(
                      stream: streamController.stream,
                        builder: (context,snapshot){
                        print(snapshot.connectionState);

                        final list = snapshot.data;
                        //pictureClicked=false;
                        if(snapshot.connectionState==ConnectionState.active){
                          if(snapshot.hasError){
                            return Text('${snapshot.error}');
                          }else
                        return Container(
                          child: ListView(
                            physics: ClampingScrollPhysics(),
                            children: [
                              ...list.map((e) => ListTile(
                                  title : Text(e),

                              )).toList()
                            ],
                          ),
                        );}
                        else return Text('No Data Received');
                        },
                        ),
                  )

                ],
              ),
            ),
            //Listener()
          ],
        ),
      ),
    );
  }
}
