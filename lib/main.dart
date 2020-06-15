import 'dart:convert';
import 'dart:math' show Random;
import 'package:intl/intl.dart';
import 'dart:async' show Future;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getflutter/getflutter.dart';
import './theme.dart';
import 'package:audiofileplayer/audiofileplayer.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_speech/flutter_speech.dart';
import './screen_iap.dart';

///Sound Play
Audio _soundPoints = Audio.load('assets/sounds/soundPoints.m4a');
Audio _soundReward = Audio.load('assets/sounds/soundReward.m4a');

///Sound Play
///Text To Speak
enum TtsState { playing, stopped }
FlutterTts _myFlutterTts = FlutterTts();
TtsState ttsState = TtsState.stopped;
//String language = "en_US";
double _speakVolume = 0.5;
double _speakPitch = 1.0;
double _speakRate = 0.5;
String _speakText;
String _selectedlanguage = 'en-US';

///Text To Speak
///Speech Recognition
SpeechRecognition _mySpeechRecognition;
bool _speechRecognitionAvailable = false;
bool _isListening = false;
//Speech Recognition

int totPoints = 0;
Text pointsText = Text("0", style: AppTheme.display1);
final formatter = new NumberFormat("###,###.###");
var randomizer = new Random();

Icon iconWord = Icon(Icons.local_library);
Icon iconType = Icon(Icons.keyboard);
Icon iconSay = Icon(Icons.mic);
Text wordText = Text("Read:", style: AppTheme.title);
Text wordListened = Text("Say:", style: AppTheme.title);
final _typedController = TextEditingController();

List _listIndex;
List _listLesson;
String _currentLesson = "lesson_0";
int _currentWord = 0;

Future _loadIndex() async {
  //print("Local Assets:");
  String jsonString = await rootBundle.loadString('assets/lessons/index.json');
  _listIndex = json.decode(jsonString);
  //print("Json" + _listIndex.toString());
}

Future _loadLesson() async {
  //print("Local Assets:");
  String jsonString =
      await rootBundle.loadString('assets/lessons/' + _currentLesson + '.json');
  _listLesson = json.decode(jsonString);
  //print("Json" + _listLesson.toString());
}

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  MyApp();
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isListLoaded = false;
  bool _isLessonLoaded = false;
  @override
  void initState() {
    super.initState();
    initTts();
    activateSpeechRecognizer();
    _loadIndex().then((s) => setState(() {
          _isListLoaded = true;
        }));
    _loadLesson().then((s) => setState(() {
          pageChanged(0);
          _isLessonLoaded = true;
        }));
    //audio points
    _soundReward.setVolume(0.5);
    //_soundReward.play();
    //audio points
  } //initstate

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    _typedController.dispose();
    _soundPoints.dispose();
    _soundReward.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.teal[800],
        accentColor: Colors.teal,
        textTheme: AppTheme.textTheme,
      ),

//      home: new Scaffold(),
      home:
          //myBuilder()
          myScaffold2(),
      routes: {
        '/IapScreen': (context) => IapScreen(),
      },
    );
  }

  Builder myBuilder() => Builder(
        builder: (context) => Center(
          child: RaisedButton(
            child: Text("Foo"),
            onPressed: () => Navigator.pushNamed(context, "/"),
          ),
        ),
      );
  Builder myBuilder2() => Builder(
        builder: (context) => Center(
          child: RaisedButton(
            child: Text("Foo2"),
            onPressed: () => Navigator.pushNamed(context, "/IapScreen"),
          ),
        ),
      );
  Builder myBuilder3() => Builder(
        builder: (context) => Center(
          ////////////////////////
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  //decoration: BoxDecoration(color: Colors.red),
                  width: double.infinity,
                  child: //Text("top"),
                      _isLessonLoaded
                          ? _buildLessonCarousel()
                          : new Center(child: new CircularProgressIndicator()),
                ),
                Container(
                  width: double.infinity,
                  child: _buildInputArea(),
                ),
                Container(
                  height: 200,
                  child: Column(
                      //decoration: BoxDecoration(color: Colors.blue),
                      //width: double.infinity,
                      children: <Widget>[
                        _isListLoaded
                            ? _buildListLessons()
                            : new Center(
                                child: new CircularProgressIndicator()),
                      ]),
                ),
              ],
            ),
          ),

          /////////////////////
        ),
      );
  Scaffold myScaffold2() => Scaffold(
            key: _scaffoldKey,

        appBar: myAppBar(),
        drawer: myDrawer(),
        body: myBuilder3(),
      );
  void _showSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  Scaffold myScaffold() => Scaffold(
        //scaffold
        key: _scaffoldKey,
        appBar: myAppBar(),
        drawer: myDrawer(),
        body: Builder(
          builder: (context) => Container(
            margin: EdgeInsets.all(0.0),
            decoration: BoxDecoration(
//            color: Colors.green,
                ),
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Container(
                    //decoration: BoxDecoration(color: Colors.red),
                    width: double.infinity,
                    child: //Text("top"),
                        _isLessonLoaded
                            ? _buildLessonCarousel()
                            : new Center(
                                child: new CircularProgressIndicator()),
                  ),
                  Container(
                    width: double.infinity,
                    child: _buildInputArea(),
                  ),
                  Container(
                    height: 200,
                    child: Column(
                        //decoration: BoxDecoration(color: Colors.blue),
                        //width: double.infinity,
                        children: <Widget>[
                          _isListLoaded
                              ? _buildListLessons()
                              : new Center(
                                  child: new CircularProgressIndicator()),
                        ]),
                  ),
                ],
              ),
            ),
          ),
        ),

        //scaffold
      );

  AppBar myAppBar() => AppBar(
        title: Text("Repeat After Me"),
        backgroundColor: Colors.teal,
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
      );
  Drawer myDrawer() => Drawer(
      child: Builder(
          builder: (context) => Center(
                child: ListView(padding: EdgeInsets.zero, children: <Widget>[
                  DrawerHeader(child: Text("Header")),
                  ListTile(
                      title: Text("Item1fff"),
                      onTap: () {
                        Navigator.pushNamed(context, "/IapScreen");
                      })
                ]),
              )));

  Widget _buildInputArea() {
    return new Container(
        margin: EdgeInsets.all(0.0),
//        decoration: BoxDecoration(color: Colors.amber),
        child: Column(children: <Widget>[
          Container(
//            decoration: BoxDecoration(color: Colors.green),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(children: <Widget>[
                Expanded(child: iconWord, flex: 1),
                Expanded(child: wordText, flex: 5),
                Expanded(
                  child: new SizedBox(
                    height: 28.0,
                    child: IconButton(
                        padding: new EdgeInsets.all(0.0),
                        icon: Icon(Icons.play_arrow),
                        onPressed: null
                        //onPressed: () => _speak(),
                        ),
                  ),
                  flex: 1,
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(children: <Widget>[
              Expanded(child: iconSay, flex: 1),
              Expanded(child: wordListened, flex: 5),
              Expanded(
                  child: new SizedBox(
                    height: 28.0,
                    child: IconButton(
                      padding: new EdgeInsets.all(0.0),
                      icon: Icon(Icons.play_arrow),
                      onPressed: _speechRecognitionAvailable && !_isListening
                          ? () => _listenStart()
                          : null,
                    ),
                  ),
                  flex: 1),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(children: <Widget>[
              Expanded(child: iconType, flex: 1),
              Expanded(
                  child: TextFormField(
                    controller: _typedController,
                    onFieldSubmitted: _typedSubmitted,
                    decoration: AppTheme.inputText1,
                    style: AppTheme.subtitle,
                  ),
                  flex: 5),
              Expanded(
                child: new SizedBox(
                  height: 28.0,
                  child: IconButton(
                    padding: new EdgeInsets.all(0.0),
                    icon: Icon(Icons.play_arrow),
                    onPressed: () => _typedSubmitted(_typedController.text),
                  ),
                ),
                flex: 1,
              ),
            ]),
          ),
        ]));
  }

  Widget _buildLessonCarousel() {
    return new Column(children: [
      makeGFCarousel(),
    ]);
  }

  GFCarousel makeGFCarousel() => GFCarousel(
        autoPlay: false,
        items: _listLesson.map((img) {
          return Container(
            margin: EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),
              child: Image.asset(
                "assets/lessons/" + img['image'].toString() + ".jpg",
                fit: BoxFit.cover,
                width: 1000.0,
              ),
            ),
          );
        }).toList(),
        onPageChanged: pageChanged,
      );

  Widget _buildListLessons() {
    return new Expanded(
      child: new ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: _listIndex.length,
        itemBuilder: (BuildContext context, int index) {
          return new Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            elevation: 5.0,
            margin: new EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
            child: Container(
//              padding: EdgeInsets.all(0.0),
              decoration: BoxDecoration(color: Color.fromRGBO(64, 75, 96, .9)),
              child: makeListTile(index),
            ),
          );
        },
      ),
    );
  }

  ListTile makeListTile(index) => ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 00.0, vertical: 0.0),
        leading: Image.asset(
            "assets/lessons/" + _listIndex[index]['image'] + ".jpg",
            width: 80,
            height: 200,
            fit: BoxFit.cover),
        onTap: () {
          print("Tap on: " + index.toString());
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => IapScreen()));
          //Navigator.of(context).pushNamed('screen_iap',);
          //Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          //  return IapScreen();
          //}));
        },
        title: Text(
          _listIndex[index]['word'],
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: <Widget>[
            Icon(
              Icons.linear_scale,
              color: Colors.yellowAccent,
//              color: Colors.teal,
            ),
            Text(
              _listIndex[index]['description'],
              style: TextStyle(
                color: Colors.grey[200],
              ),
            )
          ],
        ),
        trailing: Icon(
          Icons.keyboard_arrow_right,
          color: Colors.white,
          size: 30.0,
        ),
      );

  ///SpeechRecognition
  void activateSpeechRecognizer() {
    //print('_MyAppState.activateSpeechRecognizer... ');
    _mySpeechRecognition = new SpeechRecognition();
    _mySpeechRecognition.setAvailabilityHandler(onSpeechAvailability);
    _mySpeechRecognition.setRecognitionStartedHandler(onRecognitionStarted);
    _mySpeechRecognition.setRecognitionResultHandler(onRecognitionResult);
    _mySpeechRecognition.setRecognitionCompleteHandler(onRecognitionComplete);
    _mySpeechRecognition.setErrorHandler(errorHandler);
    _mySpeechRecognition.activate(_selectedlanguage).then((res) {
      setState(() => _speechRecognitionAvailable = res);
    });
  }

  void onSpeechAvailability(bool result) =>
      setState(() => _speechRecognitionAvailable = result);
  void onRecognitionStarted() {
    setState(() => _isListening = true);
  }

  void onRecognitionComplete(String text) {
    print('_MyAppState.onRecognitionComplete... $text');
    setState(() => _isListening = false);
    _checkPoints(text);
  }

  void _listenStop() => _mySpeechRecognition.stop().then((_) {
        setState(() => _isListening = false);
      });
  void _listenStart() =>
      _mySpeechRecognition.activate(_selectedlanguage).then((_) {
        return _mySpeechRecognition.listen().then((result) {
          print('_MyAppState.start => result $result');
          setState(() {
            _isListening = result;
          });
        });
      });
  void onRecognitionResult(String text) {
    print('_MyAppState.onRecognitionResult... $text');
    setState(() {
      wordListened = Text(
        text,
        style: AppTheme.title,
      );
    });
  }

  void errorHandler() => activateSpeechRecognizer();

  ///Speech Recognition
  ///TextToSpeak
  initTts() {
    _myFlutterTts = FlutterTts();
    _myFlutterTts.setLanguage(_selectedlanguage);
    _myFlutterTts.setStartHandler(() {
      setState(() {
        //print("playing"+ _speakText);
        ttsState = TtsState.playing;
      });
    });
    _myFlutterTts.setCompletionHandler(() {
      setState(() {
        //print("Complete");
        ttsState = TtsState.stopped;
      });
    });
    _myFlutterTts.setCancelHandler(() {
      setState(() {
        //print("Cancel");
        ttsState = TtsState.stopped;
      });
    });
    _myFlutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  Future _speak() async {
    await _myFlutterTts.setLanguage(_selectedlanguage);

    await _myFlutterTts.setVolume(_speakVolume);
    await _myFlutterTts.setSpeechRate(_speakRate);
    await _myFlutterTts.setPitch(_speakPitch);

    if (_speakText != null) {
      if (_speakText.isNotEmpty) {
        var result = await _myFlutterTts.speak(_speakText);
        if (result == 1) setState(() => ttsState = TtsState.playing);
      }
    }
  }

  ///TTS

  void pageChanged(int index) {
    _listenStop();
    //print("index:" + index.toString());
    _currentWord = index;
    setState(() {
      wordText = Text(
        _listLesson[_currentWord]['word'],
        style: AppTheme.title,
      );
      wordListened = Text(
        "Say:",
        style: AppTheme.subtitle,
      );
      _typedController.clear();
    });
    _speakText = _listLesson[_currentWord]['word'];
    _speak();
    //new Future.delayed(const Duration(seconds: 5));
  }

  ///Typed text
  void _typedSubmitted(String text) {
    //print("input submitted:" + _typedController.text);
    _checkPoints(_typedController.text);
  }

  void _checkPoints(String text) {
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
      //Play sounds reward
      _soundPoints.play();
      _showSnackBar("Congratulations!");
      //_soundReward.play();
    } else {
      //print("not equals");
      _speak();
    }
  }
//typed text

} //end
