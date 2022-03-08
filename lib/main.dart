import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Flutter Demo',
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isExecuting = false;

  var _source = "";
  var _destination = "";
  bool _skip_exist = false;
  int _max_skips = 0;
  bool _use_network = false;
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _maxSkipsController = TextEditingController();

  var _bin = "afc_sync";
  List<String> _binArgs = [];
  var _binOutput = "";
  var _binProcess;

  Future<void> _selectSource() async {
    final file = await openFile();
    setState(() {
      _sourceController.text = file?.path ?? _sourceController.text;
    });
  }

  Future<void> _selectDestination() async {
    final file = await openFile();
    setState(() {
      if (file?.path != null) {
        _destinationController.text = file?.path ?? _destinationController.text;
      }
    });
  }

  void composeBinArgs() {
    _binArgs = [];
    _binArgs.add("--src");
    _binArgs.add(_sourceController.text);
    _binArgs.add("--dst");
    _binArgs.add(_destinationController.text);

    if (_skip_exist) {
      _binArgs.add("--skip-exist");
    }
    if (_max_skips != 0) {
      _binArgs.add("--max-skips");
      _binArgs.add(_max_skips.toString());
    }
    if (_use_network) {
      _binArgs.add("--network");
    }
  }

  void executeBin(BuildContext context) async {
    if (_isExecuting) {
      setState(() {
        _isExecuting = false;
      });
      _binProcess.kill();
      return;
    }
    setState(() {
      _isExecuting = true;
    });

    composeBinArgs();
    print(_binArgs);
    try {
      _binProcess = await Process.start(_bin, _binArgs);
    }
    catch (e) {
      print("fatal!");
      print(e.toString());
    }
    _binProcess.stdout.transform(utf8.decoder).forEach((stdout) => setState(
            () => stdout.toString().endsWith("\n")
            ? _binOutput += stdout
            : _binOutput += stdout + "\n"));
    await _binProcess.exitCode;
      setState(() {
        _isExecuting = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text("afc_sync Flutter"),
        ),
        child: SafeArea(
            child: Column(
          children: [
            Row(
              children: [
                CupertinoButton(
                    child: Text("Source:"), onPressed: ()=>{}),
                Expanded(
                  child: CupertinoTextField(
                    controller: _sourceController,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                CupertinoButton(
                    child: Text("Destination:"), onPressed: _selectDestination),
                Expanded(
                  child: CupertinoTextField(
                    controller: _destinationController,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child:
                  Wrap(direction: Axis.horizontal, runSpacing: 10, children: [
                    Text("Skip Exist:"),
                CupertinoSwitch(
                    value: _skip_exist,
                    onChanged: (value) {
                      setState(() {
                        _skip_exist = value;
                      });
                    }),
                SizedBox(width: 10),
                Container(
                  width: 140,
                  child: CupertinoTextField(
                    prefix: Text("Max skips:"),
                    controller: _maxSkipsController,
                  ),
                ),
                    Text("Use Netork:"),
                    SizedBox(width: 10),
                CupertinoSwitch(
                    value: _use_network,
                    onChanged: (value) {
                      setState(() {
                        _use_network = value;
                      });
                    }),
              ]),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                reverse: true,
                children: [
                  Text(
                    _binOutput,
                    style: TextStyle(
                        fontFamily: Platform.isWindows
                            ? "Consolas"
                            : Platform.isMacOS
                                ? "SF Mono"
                                : "Liberation Mono",
                        fontFeatures: [
                          FontFeature.tabularFigures(),
                        ]),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Visibility(
                  visible: _isExecuting,
                  child: Align(
                      alignment: Alignment.bottomLeft,
                      child: CupertinoActivityIndicator()),
                ),
                Expanded(
                    child: Align(
                  alignment: Alignment.bottomCenter,
                  child: CupertinoButton(
                      color: _isExecuting
                          ? Colors.red
                          : CupertinoTheme.of(context).primaryColor,
                      child: _isExecuting ? Text("Terminate") : Text("Execute"),
                      onPressed: () => executeBin(context)),
                )),
              ],
            ),
          ],
        )));
  }
}
