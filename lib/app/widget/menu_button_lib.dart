/// code from [https://github.com/huextrat/menu_button]
///  modified some functions

library menu_button;

import 'package:flutter/material.dart';

class MenuButtonLib<T> extends StatefulWidget {
  final Widget child;
  final Widget toggledChild;
  final MenuItemBuilder<T> itemBuilder;
  final Widget divider;
  final bool topDivider;
  final List<T> items;
  final MenuItemSelected<T> onItemSelected;
  final BoxDecoration decoration;
  final MenuButtonToggleCallback onMenuButtonToggle;
  final ScrollPhysics scrollPhysics;
  final double popupHeight;
  final Function(int) onItemPressed;

  const MenuButtonLib({
    @required final this.child,
    @required final this.items,
    @required final this.itemBuilder,
    final this.toggledChild,
    final this.divider,
    final this.topDivider = true,
    final this.onItemSelected,
    final this.decoration,
    final this.onMenuButtonToggle,
    final this.scrollPhysics,
    final this.popupHeight,
    final this.onItemPressed,
  })  : assert(child != null),
        assert(items != null),
        assert(itemBuilder != null);

  @override
  State<StatefulWidget> createState() => _MenuButtonLibState<T>();
}

class _MenuButtonLibState<T> extends State<MenuButtonLib<T>> {
  @override
  Widget build(BuildContext context) => GestureDetector(
        child: Container(decoration: widget.decoration, child: widget.child),
        onTap: togglePopup,
      );

  void togglePopup() {
    widget.onMenuButtonToggle(true);

    final List<Widget> items = widget.items
        .asMap()
        .map((index, value) {
          return MapEntry(
            index,
            _MenuItem(
              value: value,
              child: widget.itemBuilder(value),
              onPressed: () {
                if (widget.onItemPressed != null) widget.onItemPressed(index);
              },
            ),
          );
        })
        .values
        .toList();
    final RenderBox button = context.findRenderObject();
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(const Offset(0, 0), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    if (items.isNotEmpty) {
      _togglePopup(
        context: context,
        position: position,
        items: items,
        toggledChild: widget.toggledChild,
        divider: widget.divider,
        topDivider: widget.topDivider,
        decoration: widget.decoration,
        scrollPhysics: widget.scrollPhysics,
        popupHeight: widget.popupHeight,
      ).then<void>((T newValue) {
        widget.onMenuButtonToggle(false);
        if (mounted && newValue != null && widget.onItemSelected != null) {
          widget.onItemSelected(newValue);
        }
      });
    }
  }

  Future<T> _togglePopup({
    @required BuildContext context,
    @required RelativeRect position,
    @required List<Widget> items,
    Widget toggledChild,
    Widget divider,
    bool topDivider,
    BoxDecoration decoration,
    ScrollPhysics scrollPhysics,
    double popupHeight,
  }) =>
      Navigator.push(
        context,
        _MenuRoute<T>(
          position: position,
          items: items,
          toggledChild: toggledChild,
          divider: divider,
          topDivider: topDivider,
          decoration: decoration,
          scrollPhysics: scrollPhysics,
          popupHeight: popupHeight,
        ),
      );
}

class _MenuRoute<T> extends PopupRoute<T> {
  final RelativeRect position;
  final List<Widget> items;
  final Widget toggledChild;
  final Widget divider;
  final bool topDivider;
  final BoxDecoration decoration;
  final ScrollPhysics scrollPhysics;
  final double popupHeight;
  final int index;

  _MenuRoute({
    final this.index,
    final this.position,
    final this.items,
    final this.toggledChild,
    final this.divider,
    final this.topDivider,
    final this.decoration,
    final this.scrollPhysics,
    final this.popupHeight,
  });

  @override
  Color get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Animation<double> createAnimation() => CurvedAnimation(
        parent: super.createAnimation(),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        removeLeft: true,
        removeRight: true,
        child: Builder(
          builder: (BuildContext context) {
            return CustomSingleChildLayout(
              delegate: _MenuRouteLayout(
                position,
              ),
              child: _Menu<T>(
                route: this,
                scrollPhysics: scrollPhysics,
                popupHeight: popupHeight,
              ),
            );
          },
        ),
      );
}

// Positioning of the menu on the screen.
class _MenuRouteLayout extends SingleChildLayoutDelegate {
  _MenuRouteLayout(this.position);

  // Rectangle of underlying button, relative to the overlay's dimensions.
  final RelativeRect position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The menu can be at most the size of the overlay minus 8.0 pixels in each
    // direction.
    return BoxConstraints.loose(constraints.biggest);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      Offset(position.left, position.top);

  @override
  bool shouldRelayout(_MenuRouteLayout oldDelegate) =>
      position != oldDelegate.position;
}

class _Menu<T> extends StatelessWidget {
  const _Menu({
    Key key,
    this.route,
    this.scrollPhysics,
    this.popupHeight,
  }) : super(key: key);

  final _MenuRoute<T> route;
  final ScrollPhysics scrollPhysics;
  final double popupHeight;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];

    if (route.topDivider) {
      children.add(route.divider);
    }

    for (int i = 0; i < route.items.length; i += 1) {
      children.add(route.items[i]);

      if (i < route.items.length - 1) {
        children.add(route.divider);
      }
    }

    final CurveTween opacity =
        CurveTween(curve: const Interval(0.0, 1.0 / 8.0));
    final CurveTween height = CurveTween(curve: const Interval(0.0, .9));
    final CurveTween shadow = CurveTween(curve: const Interval(0.0, 1.0 / 4.0));

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: route.animation,
        builder: (BuildContext context, Widget child) => Opacity(
          opacity: opacity.evaluate(route.animation),
          child: Container(
            height: popupHeight,
            decoration: BoxDecoration(
              border: route.decoration.border,
              borderRadius: route.decoration.borderRadius,
              boxShadow: [
                BoxShadow(
                    color: Color.fromARGB(
                        (20 * shadow.evaluate(route.animation)).toInt(),
                        0,
                        0,
                        0),
                    offset: Offset(0.0, 3.0 * shadow.evaluate(route.animation)),
                    blurRadius: 5.0 * shadow.evaluate(route.animation))
              ],
            ),
            child: ClipRRect(
              borderRadius: route.decoration.borderRadius,
              child: IntrinsicWidth(
                child: SingleChildScrollView(
                  physics: scrollPhysics ?? NeverScrollableScrollPhysics(),
                  child: ListBody(children: [
                    _MenuButtonToggledChild(child: route.toggledChild),
                    Container(
                      color: route.decoration.color,
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        widthFactor: 1.0,
                        heightFactor: height.evaluate(route.animation),
                        child: SingleChildScrollView(
                          child: ListBody(
                            children: children,
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButtonToggledChild extends StatelessWidget {
  final Widget child;

  const _MenuButtonToggledChild({@required final this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: child,
    );
  }
}

class _MenuItem<T> extends StatelessWidget {
  final T value;
  final Widget child;
  final Function onPressed;

  const _MenuItem({this.value, @required final this.child, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onPressed != null) onPressed();
        Navigator.of(context).pop<T>(value);
      },
      child: child,
    );
  }
}

typedef MenuButtonToggleCallback = void Function(bool isToggle);

typedef MenuItemBuilder<T> = Widget Function(T value);

typedef MenuItemSelected<T> = void Function(T value);
