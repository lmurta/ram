import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:getflutter/getflutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_speech/flutter_speech.dart';

void main() {
//  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

enum TtsState { playing, stopped }

class MyAppState extends State<MyApp> {
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

  Icon iconWord = Icon(
    Icons.local_library,
    //size: 20.0,
  );
  Icon iconType = Icon(Icons.keyboard);
  Icon iconSay = Icon(Icons.mic);
  var wordIndex = 0;
  var imageData = [];
  TextStyle textStyle = TextStyle(
      //fontSize: 20.0,
      //color: const Color(0xFF108caa),
      //fontWeight: FontWeight.w500,
      fontFamily: "Roboto");
  Text wordText = Text("Repeat after me:");
  Text wordListened = Text(". . . ");

  TextField textFieldType = TextField(
    decoration: InputDecoration(
      border: OutlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsets.all(3.0),
    ),
    autocorrect: false,
    enableSuggestions: false,
    keyboardType: TextInputType.text,
    style: TextStyle(
        // color: Colors.red,
        //  fontWeight: FontWeight.w300,
        ),
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
                  flex: 2,
                ),
                Expanded(
                  child: wordText,
                  flex: 5,
                ),
              ]),
              Row(children: <Widget>[
                Expanded(
                  child: iconSay,
                  flex: 2,
                ),
                Expanded(
                  child: wordListened,
                  flex: 3,
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
                Expanded(
                  child: IconButton(
                    icon: Icon(Icons.stop),
                    onPressed: _isListening ? () => _listenStop() : null,
                  ),
                  flex: 1,
                ),
              ]),
              Row(children: <Widget>[
                Expanded(
                  child: iconType,
                  flex: 2,
                ),
                Expanded(
                  child: textFieldType,
                  flex: 4,
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

  Future _speakStop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  void pageChanged(int index) {
    _listenStop();
    //print("index:" + index.toString());
    setState(() {
      wordText = Text(imageData[index]['word'], style: textStyle);
    });
    _speakText = imageData[index]['word'];
    _speak();
    //new Future.delayed(const Duration(seconds: 5));
  }
  void onRecognitionResult(String text) {
    print('_MyAppState.onRecognitionResult... $text');
    setState(() { 
      wordListened = Text(text, style: textStyle);
      });
  }

  void _listenCancel() =>
      _speech.cancel().then((_) => setState(() => _isListening = false));

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
  }

  void errorHandler() => activateSpeechRecognizer();
} //end main class
