import 'package:flutter/material.dart';

class IapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("IAP scrreen"),
        ),
        body:Center(
          child:
            Card(child: Title(child: Text("Card1"), color: Colors.amber))
        )
    );
  }
}
