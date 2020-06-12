import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:getflutter/getflutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_speech/flutter_speech.dart';
import './theme.dart';

void main() {
//  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(MaterialApp(
    theme: ThemeData(
      primaryColor: Colors.teal[800],
      accentColor: Colors.teal,
      textTheme: AppTheme.textTheme,
    ),
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

enum TtsState { playing, stopped }

class MyAppState extends State<MyApp> {
  int totPoints = 0;
  Text pointsText = Text(
    "0",
    style: AppTheme.display1,
  );
  final formatter = new NumberFormat("###,###.###");
  var randomizer = new Random();

  SpeechRecognition _speech;
  bool _speechRecognitionAvailable = false;
  bool _isListening = false;
  //String wordListened ='';
  String _selectedlanguage = 'en-US';
  //String _selectedlanguage = 'it-IT';

  FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;
  //String language = "en_US";
  double _speakVolume = 0.5;
  double _speakPitch = 1.0;
  double _speakRate = 0.5;
  String _speakText;

  Icon iconWord = Icon(Icons.local_library);
  Icon iconType = Icon(Icons.keyboard);
  Icon iconSay = Icon(Icons.mic);
  var wordIndex = 0;
  var imageData = [];

  Text wordText = Text("Read:", style: AppTheme.title);
  Text wordListened = Text("Say:", style: AppTheme.title);
  static var _inputController = TextEditingController();
  TextField wordTyped = TextField(
    controller: _inputController,
    decoration: InputDecoration(
      hintText: "Type:",
      border: OutlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsets.all(3.0),
    ),
    style: AppTheme.title,
    autocorrect: false,
    enableSuggestions: false,
    keyboardType: TextInputType.text,
  );

  @override
  initState() {
    super.initState();
    initTts();
    activateSpeechRecognizer();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void activateSpeechRecognizer() {
    print('_MyAppState.activateSpeechRecognizer... ');
    _speech = new SpeechRecognition();
    _speech.setAvailabilityHandler(onSpeechAvailability);
    _speech.setRecognitionStartedHandler(onRecognitionStarted);
    _speech.setRecognitionResultHandler(onRecognitionResult);
    _speech.setRecognitionCompleteHandler(onRecognitionComplete);
    _speech.setErrorHandler(errorHandler);
    _speech.activate(_selectedlanguage).then((res) {
      setState(() => _speechRecognitionAvailable = res);
    });
  }

  initTts() {
    flutterTts = FlutterTts();

    //_getLanguages();
    flutterTts.setLanguage(_selectedlanguage);
    flutterTts.setStartHandler(() {
      setState(() {
        //print("playing"+ _speakText);
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        //print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        //print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Repeat After Me"),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Container(
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Colors.white, Colors.grey],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black,
                        offset: Offset(3.0, 0.0), //(x,y)
                        blurRadius: 3.0),
                  ]),

              child: Row(
                children: <Widget>[
                  pointsText,
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            // Use future builder and DefaultAssetBundle to load the local JSON file
            children: [
              FutureBuilder(
                  future: DefaultAssetBundle.of(context)
                      .loadString('assets/lessons.json'),
                  builder: (context, snapshot) {
                    // Decode the JSON
                    if (snapshot.hasData) {
                      imageData = json.decode(snapshot.data.toString());
                      //pageChanged(0);
                      //print(imageData.toString());
                      return GFCarousel(
                        autoPlay: false,
                        items: imageData.map((img) {
                          return Container(
                            margin: EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                              child: Image.asset(
                                "assets/" + img['image'].toString() + ".jpg",
                                fit: BoxFit.cover,
                                width: 1000.0,
                              ),
                            ),
                          );
                        }).toList(),
                        onPageChanged: pageChanged,
                      );
                      //pageChanged(0);
                    } else {
                      return new CircularProgressIndicator();
                    }
                  }),
              Row(children: <Widget>[
                Expanded(
                  child: iconWord,
                  flex: 1,
                ),
                Expanded(
                  child: wordText,
                  flex: 5,
                ),
                Expanded(
                  child: IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: () => _speak(),
                  ),
                  flex: 1,
                ),
              ]),
              Row(children: <Widget>[
                Expanded(
                  child: iconSay,
                  flex: 1,
                ),
                Expanded(
                  child: wordListened,
                  flex: 5,
                ),
                Expanded(
                  child: IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: _speechRecognitionAvailable && !_isListening
                        ? () => _listenStart()
                        : null,
                  ),
                  flex: 1,
                ),
                /*
                Expanded(
                  child: IconButton(
                    icon: Icon(Icons.stop),
                    onPressed: _isListening ? () => _listenStop() : null,
                  ),
                  flex: 1,
                ),
                */
              ]),
              Row(children: <Widget>[
                Expanded(
                  child: iconType,
                  flex: 1,
                ),
                Expanded(
                  child: wordTyped,
                  flex: 5,
                ),
                Expanded(
                  child: Text(''),
                  flex: 1,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future _speak() async {
    await flutterTts.setLanguage(_selectedlanguage);

    await flutterTts.setVolume(_speakVolume);
    await flutterTts.setSpeechRate(_speakRate);
    await flutterTts.setPitch(_speakPitch);

    if (_speakText != null) {
      if (_speakText.isNotEmpty) {
        var result = await flutterTts.speak(_speakText);
        if (result == 1) setState(() => ttsState = TtsState.playing);
      }
    }
  }

/*  Future _speakStop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }
*/
  void pageChanged(int index) {
    _listenStop();
    //print("index:" + index.toString());
    setState(() {
      wordText = Text(
        imageData[index]['word'],
        style: AppTheme.title,
      );
      wordListened = Text("");
      _inputController.clear();
    });
    _speakText = imageData[index]['word'];
    _speak();
    //new Future.delayed(const Duration(seconds: 5));
  }

  void onPlayPressed() {
    _speak();
  }

  void onRecognitionResult(String text) {
    print('_MyAppState.onRecognitionResult... $text');
    setState(() {
      wordListened = Text(
        text,
        style: AppTheme.title,
      );
    });
  }

/*
  void _listenCancel() =>
      _speech.cancel().then((_) => setState(() => _isListening = false));
*/
  void _listenStop() => _speech.stop().then((_) {
        setState(() => _isListening = false);
      });
  void _listenStart() => _speech.activate(_selectedlanguage).then((_) {
        return _speech.listen().then((result) {
          print('_MyAppState.start => result $result');
          setState(() {
            _isListening = result;
          });
        });
      });
  void onSpeechAvailability(bool result) =>
      setState(() => _speechRecognitionAvailable = result);
  void onRecognitionStarted() {
    setState(() => _isListening = true);
  }

  void onRecognitionComplete(String text) {
    print('_MyAppState.onRecognitionComplete... $text');
    setState(() => _isListening = false);
    String A = _speakText.trim().toLowerCase();
    String B = text.trim().toLowerCase();
    //print("---Comparing---[" + A + "]=[" + B + "]");

    if (A == B) {
      //print("iguais");
      int i = randomizer.nextInt(10);
      i++;
      String T;
      for (var j = 0; j < i; j++) {
        totPoints++;
        T = formatter.format((totPoints));
        setState(() {
          pointsText = Text(T, style: AppTheme.display1);
        });
      }
    } else {
      print("not equals");
    }
  }

  void errorHandler() => activateSpeechRecognizer();
} //end main class

class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }
}
