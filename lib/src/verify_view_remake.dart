import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinVerifyView extends StatefulWidget {
  final int lenght;
  final double size;
  final TextStyle? textStyle;
  final Function(String)? onCompleted;
  final double rightMargin;
  final TextInputType? inputType;
  final List<TextInputFormatter>? inputFormatters;
  const PinVerifyView({
    Key? key,
    required this.lenght,
    this.size = 50,
    this.rightMargin = 20,
    this.textStyle,
    this.onCompleted,
    this.inputFormatters,
    this.inputType,
  }) : super(key: key);

  @override
  _PinVerifyViewState createState() => _PinVerifyViewState();
}

class _PinVerifyViewState extends State<PinVerifyView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;
  final List<_CodeBox> _boxes = [];
  _BoxManager _boxManager = _BoxManager.dummy();
  final LayerLink _layerLink = LayerLink();
  late final FocusNode _focusNode;
  OverlayEntry? _overlayEntry;

  bool _isOpen = false;

  late final TextEditingController _controller;

  GlobalKey _key = GlobalKey();

  double get textFieldSize {
    return (widget.size * widget.lenght) +
        (widget.rightMargin * (widget.lenght - 1));
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
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
  void didUpdateWidget(covariant PinVerifyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size != widget.size ||
        oldWidget.textStyle != widget.textStyle ||
        widget.rightMargin != oldWidget.rightMargin ||
        widget.inputType != oldWidget.inputType ||
        widget.inputFormatters != oldWidget.inputFormatters) {
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

  String filterString(String value) {
    return value.split(RegExp(r'[\s\/\\]+')).join("");
  }

  void _handleText(String text) {
    /// if there is no change in the text, ithsould stop executing
    /// this is done to avoid the last if statement from executing
    final value = filterString(text);
    if (_value == value) return;

    ///to support copy and paste
    ///if the value lenght is increased more than one that means the user pasted something on the textfield
    if ((value.length - _value.length) > 1) {
      _value = value;
      _boxManager.setCurrentBox(_boxManager.boxes[value.length - 1]);
    }

    /// keep the the value
    _value = value;

    ///no notifyListener is called when for the last box soits importatnt to call setState to rebuild the ui
    if (value.length == _boxManager.boxes.length ||
        value.length == (_boxManager.boxes.length - 1)) {
      _deleteBoxValueFromIndex(value.length);
      setState(() {});
    }

    ///when the user long presses the backspace button to clear every input, the fields should update accordingly
    ///this makes sure of that
    if (value.isEmpty) {
      _deleteBoxValueFromIndex(0);
      _boxManager.setCurrentBox(_boxes[0]);
      return;
    }

    /// everytime a user clears the last input form the textfield
    if (value.length < _boxManager.currentBox!.index && _boxManager.hasPrev) {
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
    if (value.length == widget.lenght) {
      widget.onCompleted?.call(value);
    }

    return;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          CompositedTransformTarget(
            link: _layerLink,
            child: Opacity(
              opacity: 0,
              child: Container(
                color: Colors.yellow,
                height: widget.size + 5,
                width: textFieldSize,
                child: Listener(
                  onPointerDown: (det) {
                    _timer = Timer.periodic(const Duration(milliseconds: 500),
                        (timer) async {
                      final copiedText = await Clipboard.getData("text/plain");
                      if (timer.tick == 1) {
                        if (copiedText?.text != null) {
                          _toggleDropdown(
                            context,
                            position: det.localPosition,
                            copiedText: copiedText?.text,
                          );
                        }
                        _destroyTimer();
                      }
                    });
                  },
                  onPointerUp: (e) {
                    _destroyTimer();
                  },
                  child: TextField(
                    key: _key,
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: widget.inputType,
                    inputFormatters: [
                      if (widget.inputFormatters != null)
                        ...widget.inputFormatters!,
                      FilteringTextInputFormatter.deny(RegExp(r'[\s\/\\]+')),
                      // LengthLimitingTextInputFormatter(widget.lenght),
                    ],
                    onTap: () {},
                    maxLength: widget.lenght,
                    maxLines: 2,
                    onChanged: (value) {
                      _handleText(value);
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
                  BoxWidget(
                    box: box,
                    style: widget.textStyle,
                    boxManager: _boxManager,
                    size: widget.size,
                    rightMargin: widget.rightMargin,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  OverlayEntry _createOverlayEntry(
      BuildContext context, Offset position, String? copiedText) {
    print("overlay exist");
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox!.size;

    final offset = renderBox.localToGlobal(position);
    final topOffset = offset.dy + size.height;
    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () => _toggleDropdown(context, close: true),
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              Positioned(
                left: offset.dx,
                top: topOffset,
                // width: 30,
                child: PasteButton(
                    layerLink: _layerLink,
                    expandAnimation: _expandAnimation,
                    offset: Offset(position.dx / 1.2, size.height + 20),
                    callback: () {
                      _toggleDropdown(context);
                      _controller.text = copiedText!;
                      _controller.selection = TextSelection.collapsed(
                          offset: _controller.text.length);
                      _handleText(copiedText);
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleDropdown(
    BuildContext context, {
    Offset position = Offset.zero,
    bool close = false,
    String? copiedText,
  }) async {
    // widget.onToggle?.call(false);
    if (_isOpen || close) {
      await _animationController.reverse();
      _overlayEntry?.remove();
      print("closed");
      setState(() {
        _isOpen = false;
      });
    } else {
      // widget.onToggle?.call(true);
      _overlayEntry = _createOverlayEntry(context, position, copiedText);
      Overlay.of(context)?.insert(_overlayEntry!);
      setState(() => _isOpen = true);
      await _animationController.forward();
    }
  }
}

class PasteButton extends StatelessWidget {
  final Offset offset;
  final Function() callback;
  final Animation<double> expandAnimation;
  const PasteButton({
    Key? key,
    required this.offset,
    required LayerLink layerLink,
    required this.callback,
    required this.expandAnimation,
  })  : _layerLink = layerLink,
        super(key: key);

  final LayerLink _layerLink;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformFollower(
      offset: offset,
      link: _layerLink,
      showWhenUnlinked: false,
      child: Material(
        child: GestureDetector(
          onTap: callback,
          child: SizeTransition(
            sizeFactor: expandAnimation,
            child: Container(
              height: 40,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  "paste",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BoxWidget extends StatelessWidget {
  final _CodeBox box;
  final _BoxManager boxManager;
  final double size;
  final TextStyle? style;
  final double rightMargin;
  BoxWidget({
    Key? key,
    this.style,
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
