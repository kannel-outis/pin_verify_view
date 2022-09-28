import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:pin_verify_view/src/selection_controls.dart';

class PinVerifyViewRemake extends StatefulWidget {
  final int lenght;
  final double size;
  final TextStyle? textStyle;
  final Function(String)? onCompleted;
  final double rightMargin;
  const PinVerifyViewRemake({
    Key? key,
    required this.lenght,
    this.size = 50,
    this.rightMargin = 20,
    this.textStyle,
    this.onCompleted,
  }) : super(key: key);

  @override
  _PinVerifyViewRemakeState createState() => _PinVerifyViewRemakeState();
}

class _PinVerifyViewRemakeState extends State<PinVerifyViewRemake> {
  final List<_CodeBox> _boxes = [];
  _BoxManager _boxManager = _BoxManager.dummy();
  late final TextEditingController _controller;
  double get textFieldSize {
    return (widget.size * widget.lenght) +
        (widget.rightMargin * (widget.lenght - 1));
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    initBoxes();
  }

  void dropAll() {
    _boxes.clear();
  }

  void initBoxes() {
    for (var i = 0; i < widget.lenght; i++) {
      final box = _CodeBox(
        index: i,
        position: getposition(i),
      );
      _boxes.add(box);
    }
    _boxManager = _BoxManager(boxes: _boxes);
  }

  _BoxPosition getposition(int index) {
    if (index == 0) {
      return _BoxPosition.start;
    } else if (index == (widget.lenght - 1)) {
      return _BoxPosition.end;
    }
    return _BoxPosition.middle;
  }

  @override
  void didUpdateWidget(covariant PinVerifyViewRemake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size != widget.size ||
        oldWidget.textStyle != widget.textStyle ||
        widget.rightMargin != oldWidget.rightMargin) {
      setState(() {});
    }
    if (oldWidget.lenght != widget.lenght) {
      dropAll();
      initBoxes();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _value = "";

  void _deleteBoxValueFromIndex(int index) {
    for (var i = index; i < _boxManager.boxes.length; i++) {
      _boxManager.boxes[i].value = "";
    }
  }

  Timer? _timer;
  void _destroyTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0,
            child: Container(
              color: Colors.yellow,
              height: widget.size + 5,
              width: textFieldSize,
              child: Theme(
                data: ThemeData(
                  textSelectionTheme: TextSelectionThemeData(
                    selectionHandleColor: Colors.red,
                  ),
                ),
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (det) {
                    _timer =
                        Timer.periodic(const Duration(seconds: 1), (timer) {
                      if (timer.tick == 3) {
                        print("long pressed");
                        _destroyTimer();
                      }
                    });
                  },
                  onPointerUp: (e) {
                    _destroyTimer();
                  },
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      // LengthLimitingTextInputFormatter(widget.lenght),
                    ],
                    selectionControls: MyMaterialTextSelectionControls(),
                    onTap: () {},
                    maxLength: widget.lenght,
                    maxLines: 2,
                    onChanged: (value) {
                      /// if there is no change in the text, ithsould stop executing
                      /// this is done to avoid the last if statement from executing
                      if (_value == value) return;

                      ///to support copy and paste
                      ///if the value lenght is increased more than one that means the user pasted something on the textfield
                      if ((value.length - _value.length) > 1) {
                        _value = value;
                        _boxManager
                            .setCurrentBox(_boxManager.boxes[value.length - 1]);
                      }

                      /// keep the the value
                      _value = value;

                      ///no notifyListener is called when for the last box soits importatnt to call setState to rebuild the ui
                      if (value.length == _boxManager.boxes.length ||
                          value.length == (_boxManager.boxes.length - 1)) {
                        _deleteBoxValueFromIndex(value.length);
                        setState(() {});
                      }
                      print(value);

                      ///when the user long presses the backspace button to clear every input, the fields should update accordingly
                      ///this makes sure of that
                      if (value.isEmpty) {
                        print(value);
                        _deleteBoxValueFromIndex(0);
                        _boxManager.setCurrentBox(_boxes[0]);
                        return;
                      }

                      /// everytime a user clears the last input form the textfield
                      if (value.length < _boxManager.currentBox!.index &&
                          _boxManager.hasPrev) {
                        _deleteBoxValueFromIndex(value.length);
                        _boxManager.prevBox;
                        return;
                      }

                      /// everytime a user adds something to the textfield
                      for (var i = 0; i < value.length; i++) {
                        _boxManager.boxes[i].value = value.split("")[i];
                      }

                      if (_controller.text.isNotEmpty && _boxManager.hasNext) {
                        _boxManager.nextBox;
                      }
                      return;
                    },
                    showCursor: false,
                    toolbarOptions: ToolbarOptions(
                      selectAll: false,
                      copy: false,
                      cut: false,
                      paste: true,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(
                          top: (widget.size * 2.5) / (widget.rightMargin / 2)),
                      fillColor: Colors.black,
                      counter: const SizedBox(),
                    ),
                    style: widget.textStyle,
                    autocorrect: false,
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final box in _boxes)
                  BoxTextField(
                    box: box,
                    style: widget.textStyle,
                    boxManager: _boxManager,
                    size: widget.size,
                    onCompleted: widget.onCompleted,
                    rightMargin: widget.rightMargin,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BoxTextField extends StatelessWidget {
  final _CodeBox box;
  final _BoxManager boxManager;
  final double size;
  final TextStyle? style;
  final double rightMargin;
  final Function(String)? onCompleted;
  BoxTextField({
    Key? key,
    this.style,
    this.onCompleted,
    required this.rightMargin,
    required this.boxManager,
    required this.box,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: size,
          width: size,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          margin: box.position == _BoxPosition.end
              ? EdgeInsets.zero
              : EdgeInsets.only(right: rightMargin),
        ),
        IgnorePointer(
          child: _BuildWidget<_BoxManager>(
            notifier: boxManager,
            builder: (context) {
              return Container(
                height: size,
                width: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: box.index == boxManager.currentBox!.index
                      ? Border.all()
                      : null,
                ),
                child: Text(
                  // ignore: prefer_is_empty
                  box.value,
                  style: style,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BuildWidget<T extends ChangeNotifier> extends StatefulWidget {
  final T notifier;
  final WidgetBuilder builder;
  const _BuildWidget({Key? key, required this.builder, required this.notifier})
      : super(key: key);

  @override
  __BuildWidgetState createState() => __BuildWidgetState();
}

class __BuildWidgetState extends State<_BuildWidget> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_listener);
  }

  @override
  void didUpdateWidget(covariant _BuildWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifier != widget.notifier) {
      widget.notifier.removeListener(_listener);
      widget.notifier.addListener(_listener);
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    widget.builder(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

class _CodeBox {
  final int index;
  // final TextEditingController controller;
  // final FocusNode focusNode;
  String value;
  final _BoxPosition position;

  _CodeBox({
    required this.index,
    // required this.controller,
    // required this.focusNode,
    this.value = "",
    required this.position,
  });
}

class _BoxManager extends ChangeNotifier {
  final List<_CodeBox> boxes;

  _BoxManager({required this.boxes}) {
    setCurrentBox(boxes[0]);
  }
  _BoxManager.dummy({this.boxes = const []});

  _CodeBox? _currentBox;
  _CodeBox? get currentBox => _currentBox;

  // ignore: use_setters_to_change_properties
  void setCurrentBox(_CodeBox box) {
    _currentBox = box;
    notifyListeners();
  }

  int _currentBoxesIndex = 0;

  _CodeBox? get nextBox {
    _currentBoxesIndex = boxes
        .map((e) => e.index)
        .toList()
        .indexWhere((element) => element == _currentBox!.index);

    if (_hasNext) {
      final next = boxes[_currentBoxesIndex + 1];
      setCurrentBox(next);
      return next;
    }
    // notifyListeners();
    return null;
  }

  _CodeBox? get prevBox {
    _currentBoxesIndex = boxes
        .map((e) => e.index)
        .toList()
        .indexWhere((element) => element == _currentBox!.index);
    print("$_currentBoxesIndex :::::::::::::::::::::::::::::");
    if (_hasPrev) {
      final prev = boxes[_currentBoxesIndex - 1];
      setCurrentBox(prev);
      return prev;
    }
    // notifyListeners();

    return null;
  }

  bool _hasNext = false;
  bool get hasNext {
    _hasNext = false;
    _currentBoxesIndex = boxes
        .map((e) => e.index)
        .toList()
        .indexWhere((element) => element == _currentBox!.index);

    if (_currentBoxesIndex != (boxes.length - 1)) {
      _hasNext = true;
    }

    return _hasNext;
  }

  bool _hasPrev = false;
  bool get hasPrev {
    _hasPrev = false;
    _currentBoxesIndex = boxes
        .map((e) => e.index)
        .toList()
        .indexWhere((element) => element == _currentBox!.index);
    if (_currentBoxesIndex != 0) {
      _hasPrev = true;
    }
    return _hasPrev;
  }
}

enum _BoxPosition {
  end,
  middle,
  start,
}
