import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinVerifyViewOld extends StatefulWidget {
  final int lenght;
  final double size;
  final TextStyle? textStyle;
  final Function(String)? onCompleted;
  final double rightMargin;
  const PinVerifyViewOld({
    Key? key,
    required this.lenght,
    this.size = 50,
    this.rightMargin = 20,
    this.textStyle,
    this.onCompleted,
  }) : super(key: key);

  @override
  _PinVerifyViewOldState createState() => _PinVerifyViewOldState();
}

class _PinVerifyViewOldState extends State<PinVerifyViewOld> {
  final List<_CodeBox> _boxes = [];
  BoxManager _boxManager = BoxManager.dummy();

  @override
  void initState() {
    super.initState();
    initBoxes();
  }

  void dropAll() {
    _boxes.clear();
  }

  void initBoxes() {
    for (var i = 0; i < widget.lenght; i++) {
      final box = _CodeBox(
        index: i,
        controller: TextEditingController.fromValue(TextEditingValue(
            text: "", selection: TextSelection.collapsed(offset: 0)))
          ..addListener(() {
            //if last item , rebuild
            if (i == widget.lenght - 1) {
              setState(() {});
            }
          }),
        focusNode: FocusNode(),
        position: getposition(i),
      );
      _boxes.add(box);
    }
    _boxManager = BoxManager(boxes: _boxes);
  }

  BoxPosition getposition(int index) {
    if (index == 0) {
      return BoxPosition.start;
    } else if (index == (widget.lenght - 1)) {
      return BoxPosition.end;
    }
    return BoxPosition.middle;
  }

  @override
  void didUpdateWidget(covariant PinVerifyViewOld oldWidget) {
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
    for (final box in _boxes) {
      box.focusNode.dispose();
      box.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final box in _boxes)
            _BoxTextField(
              box: box,
              style: widget.textStyle,
              boxManager: _boxManager,
              size: widget.size,
              onCompleted: widget.onCompleted,
              rightMargin: widget.rightMargin,
            ),
        ],
      ),
    );
  }
}

class _BoxTextField extends StatelessWidget {
  final _CodeBox box;
  final BoxManager boxManager;
  final double size;
  final TextStyle? style;
  final double rightMargin;
  final Function(String)? onCompleted;
  _BoxTextField({
    Key? key,
    this.style,
    this.onCompleted,
    required this.rightMargin,
    required this.boxManager,
    required this.box,
    required this.size,
  }) : super(key: key);

  final _values = <String>[];
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: size,
          width: size,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          margin: box.position == BoxPosition.end
              ? EdgeInsets.zero
              : EdgeInsets.only(right: rightMargin),
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) {
              if (event.logicalKey == LogicalKeyboardKey.backspace) {
                print(_values);
                _values.clear();
                if (box.controller.text.isEmpty && boxManager.hasPrev) {
                  boxManager.prevBox!.focusNode.requestFocus();
                }
                box.controller.text = "";
              }
            },
            child: TextFormField(
              controller: box.controller,
              focusNode: box.focusNode,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.numberWithOptions(signed: true),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onTap: () {
                if (box.index != boxManager.currentBox!.index) {
                  // focusNode.unfocus();
                  boxManager.currentBox!.focusNode.requestFocus();
                }
              },
              maxLength: 1,
              maxLines: 2,
              onChanged: (value) {
                _values.clear();

                if (box.controller.text.isNotEmpty && boxManager.hasNext) {
                  boxManager.nextBox!.focusNode.requestFocus();
                }
                // else if (box.controller.text.isEmpty && boxManager.hasPrev) {
                //   boxManager.prevBox!.focusNode.requestFocus();
                // }
                if (!boxManager.hasNext &&
                    box.index == boxManager._currentBoxesIndex &&
                    box.controller.text.isNotEmpty) {
                  for (final value in boxManager.boxes) {
                    _values.add(value.controller.text);
                  }
                  onCompleted?.call(_values.join());
                }
              },
              showCursor: false,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.only(top: (size * 2.5) / (rightMargin / 2)),
                fillColor: Colors.black,
                counter: const SizedBox(),
              ),
              style: style,
              autocorrect: false,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        IgnorePointer(
          child: BuildWidget<BoxManager>(
            notifier: boxManager,
            builder: (context) {
              return Container(
                height: size,
                width: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: box.index == boxManager.currentBox!.index
                      ? Border.all()
                      : null,
                ),
                child: Text(
                  // ignore: prefer_is_empty
                  box.controller.text,
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

class BuildWidget<T extends ChangeNotifier> extends StatefulWidget {
  final T notifier;
  final WidgetBuilder builder;
  const BuildWidget({Key? key, required this.builder, required this.notifier})
      : super(key: key);

  @override
  _BuildWidgetState createState() => _BuildWidgetState();
}

class _BuildWidgetState extends State<BuildWidget> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_listener);
  }

  @override
  void didUpdateWidget(covariant BuildWidget oldWidget) {
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
  final TextEditingController controller;
  final FocusNode focusNode;
  final BoxPosition position;

  _CodeBox({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.position,
  });
}

class BoxManager extends ChangeNotifier {
  final List<_CodeBox> boxes;

  BoxManager({required this.boxes}) {
    setCurrentBox(boxes[0]);
  }
  BoxManager.dummy({this.boxes = const []});

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

enum BoxPosition {
  end,
  middle,
  start,
}
