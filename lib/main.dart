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
var _congratulation = [
  'Congratulations!',
  'Very good!',
  'Excelent!',
  'Keep going!',
];

Icon iconWord = Icon(Icons.local_library);
Icon iconType = Icon(Icons.keyboard);
Icon iconSay = Icon(Icons.mic);
Text wordText = Text("Read:", style: AppTheme.title);
Text wordListened = Text("Say:", style: AppTheme.title);
final _typedController = TextEditingController();

List _indexOfLessons;
int _currentIndex = 0;
int _currentCarrouselPage = 0;

List _currentLessonList;
String _currentWord = "";
String _currentLessonFile = "lesson_" + _currentIndex.toString();
//GFCarousel _lessonCarousel = new GFCarousel(items: null);

Future _loadIndex() async {
  //print("Local Assets:");
  String jsonString = await rootBundle.loadString('assets/lessons/index.json');
  _indexOfLessons = json.decode(jsonString);
  //print("Json" + _indexOfLessons.toString());
}

Future _loadLesson() async {
  //print("Local Assets:");
  String jsonString = await rootBundle
      .loadString('assets/lessons/' + _currentLessonFile + '.json');
  _currentLessonList = json.decode(jsonString);
  //print("Json" + _currentLessonList.toString());
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
      home: myScaffold(),
      routes: {
        '/IapScreen': (context) => IapScreen(),
      },
    );
  }

  Builder myBuilder() => Builder(
        builder: (context) => Center(
          ////////////////////////
          //child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                //top
                //color: Colors.green,
                width: double.infinity,
                child: //Text("top"),
                    _isLessonLoaded
                        ? _buildLessonCarousel()
                        : Container(
                            height: 150,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: new Center(
                                child: new CircularProgressIndicator(),
                              ),
                            ),
                          ),
              ), //top
              Container(
                //middle
                width: double.infinity,
                height: 120,
                //color: Colors.red,
                child: _buildInputArea(),
              ), //middle
              Expanded(
                  flex: 1,
                  child: Container(
                    //bot
                    //color: Colors.amber,
                    child: Column(children: <Widget>[
                      _isListLoaded
                          ? _buildListLessons()
                          : new Center(child: new CircularProgressIndicator()),
                    ]),
                  )), //bot
            ],
          ),
          //),//Scroolview
          /////////////////////
        ),
      );
  Scaffold myScaffold() => Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false, //TODO bug do scroolview workaround
        appBar: myAppBar(),
        drawer: myDrawer(),
        body: myBuilder(),
      );
  void _showSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.blue,
      content: Text(
        _congratulation[randomizer.nextInt(_congratulation.length)],
        style: AppTheme.textTheme.headline5,
      ),
    ));
  }

  AppBar myAppBar() => AppBar(
        title: Text("Repeat After Me"),
        backgroundColor: Colors.teal[800],
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
                  DrawerHeader(
                    child: Text(""),
                    decoration: BoxDecoration(
                        color: Colors.teal[900],
                        image: DecorationImage(
                            image: AssetImage("assets/lessons/knowledge.jpg"),
                            fit: BoxFit.cover)),
                  ),
                  ListTile(
                      title: Text("Register"),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.of(context).pop();
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
                      //onPressed: null
                      onPressed: () => _speak(),
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
        ]));
  }

  Widget _buildLessonCarousel() {
    return new Column(children: [
      makeGFCarousel(),
    ]);
  }

  GFCarousel makeGFCarousel() => new GFCarousel(
        autoPlay: false,
        enableInfiniteScroll: false,
        pagination: true,
        initialPage: 0,
        realPage: 0,

        //pageController: _myGFController,
        items: _currentLessonList.map((img) {
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
//        onPageChanged: pageChanged,
        onPageChanged: (index) {
          _currentCarrouselPage = index;
          //_myGFController = this.
          print("Page changed to:" + index.toString());
          pageChanged(index);
        },
      );

  Widget _buildListLessons() {
    return new Expanded(
      child: new ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: _indexOfLessons.length,
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
            "assets/lessons/" + _indexOfLessons[index]['image'] + ".jpg",
            width: 80,
            height: 200,
            fit: BoxFit.cover),
        onTap: () {
          print("Tap on: " + index.toString());
          _changeLessonTo(index);
        },
        title: Text(
          _indexOfLessons[index]['word'],
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
              _indexOfLessons[index]['description'],
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

  Future _changeLessonTo(int index) async {
    print("Changing lesson from :" + _currentLessonFile);
    print("Changing lesson from :" + _currentWord);
    _isLessonLoaded = false;
    _currentLessonFile = "lesson_" + index.toString();
    _currentLessonList.clear();
    String jsonString = await rootBundle
        .loadString('assets/lessons/' + _currentLessonFile + '.json');
    _currentLessonList = json.decode(jsonString);
    _loadLesson().then((s) => setState(() {
          print("page:" +
              _currentCarrouselPage.toString() +
              " : " +
              _currentLessonList.length.toString());
          if (_currentCarrouselPage >= _currentLessonList.length) {
            _currentCarrouselPage = _currentLessonList.length - 1;
          }
          pageChanged(_currentCarrouselPage);
          _isLessonLoaded = true;
          print("Changing lesson to :" + _currentLessonFile);
          print("Changing lesson to :" + _currentWord);
        }));
    //print("Json" + _currentLessonList.toString());
  }

  void pageChanged(int index) {
    _listenStop();
    //print("index:" + index.toString());
    //_currentIndex = index;
    setState(() {
      _currentWord = _currentLessonList[index]['word'];
//      _currentWord = index.toString();
      wordText = Text(
        _currentWord,
        style: AppTheme.title,
      );
      wordListened = Text(
        "Say:",
        style: AppTheme.subtitle,
      );
      _typedController.clear();
      _speak();
    });
    //new Future.delayed(const Duration(seconds: 5));
  }

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

    if (_currentWord != null) {
      if (_currentWord.isNotEmpty) {
        var result = await _myFlutterTts.speak(_currentWord);
        if (result == 1) setState(() => ttsState = TtsState.playing);
      }
    }
  }

  ///TTS

  ///Typed text
  void _typedSubmitted(String text) {
    //print("input submitted:" + _typedController.text);
    _checkPoints(_typedController.text);
  }

  void _checkPoints(String text) {
    String A = _currentWord.trim().toLowerCase();
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
