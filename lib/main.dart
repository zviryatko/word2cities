import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'word2cities',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: MyHomePage(title: 'Word to cities converter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _inputController = TextEditingController();
  final _tokenInputController = TextEditingController();
  String _token = "";
  List<String> _letters = [];
  Map<String, List<String>> _words = Map<String, List<String>>();
  Timer _timer;

  Future<http.Response> fetchCity(char) {
    return http.post(
        Uri.https(
            'suggestions.dadata.ru', 'suggestions/api/4_1/rs/suggest/address'),
        headers: <String, String>{
          "Accept": "application/json",
          "Authorization": "Token $_token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(<String, dynamic>{
          "query": char,
          "count": 10,
          "locations": [
            {"country_iso_code": "RU"},
            {"country_iso_code": "UA"}
          ]
        }));
  }

  void _refreshWords() {
    Future.wait(_letters.map((char) {
      return fetchCity(char).then((http.Response response) {
        Map<String, dynamic> json = jsonDecode(response.body);
        List<dynamic> suggestions = json["suggestions"];
        List<String> cities = [];
        for (var i = 0; i < suggestions.length; i++) {
          if (suggestions[i]["data"]["city"] != null) {
            String city = suggestions[i]["data"]["city"];
            if (city.split("").first.toLowerCase() == char.toLowerCase()) {
              cities.add(city);
            }
          }
        }
        if (cities.isEmpty) {
          cities.add("🤷");
        }
        return MapEntry(char, cities);
      });
    })).then((citiesList) {
      setState(() {
        _words = Map<String, List<String>>.fromEntries(citiesList);
      });
    });
  }

  void _fillField(String text) {
    var letters = text.split("");
    setState(() {
      _letters = letters;
      _words = letters.asMap().map((key, value) => MapEntry(value, ["⌛"]));
    });
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1500), _refreshWords);
  }

  void _fillToken(String token) {
    setState(() {
      _token = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: "Type a word...",
                contentPadding: EdgeInsets.only(left: 15.0),
              ),
              onChanged: _fillField,
              enabled: _token.isNotEmpty,
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: _letters.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 48,
                    child: Row(
                      children: [
                        Column(children: [
                          Text("${_letters.elementAt(index)} - ",
                              style: TextStyle(fontSize: 46, height: 1))
                        ]),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                                padding: EdgeInsets.only(left: 0.0),
                                child: Text(
                                    _words[_letters.elementAt(index)][index % _words[_letters.elementAt(index)].length],
                                    style: TextStyle(fontSize: 46, height: 1)
                                )
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(),
              ),
            ),
            RichText(text: TextSpan(
              children: [
                TextSpan(text: "Put the API key from "),
                TextSpan(text: "https://dadata.ru/profile/#info", style: TextStyle(color: Colors.lightBlueAccent)),
                TextSpan(text: " (registration required)."),
              ],
            )),
            TextFormField(
              controller: _tokenInputController,
              decoration: InputDecoration(
                  hintText: "Insert token",
                  contentPadding: EdgeInsets.only(left: 15.0)),
              onChanged: _fillToken,
            ),
          ],
        ),
      ),
    );
  }
}
