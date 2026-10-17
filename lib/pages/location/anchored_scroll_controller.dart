import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Scroll controller that can keep one list item in place while the content
/// above it grows or shrinks, so a tapped row stays under the finger.
///
/// The correction happens during the layout of the next frame, so the list
/// never shows the shifted position, not even for a single frame.
class AnchoredScrollController extends ScrollController {
  RenderObject? _anchor;
  double _anchorScrollOffset = 0;

  /// Keeps the list item that [context] belongs to at its place on screen
  /// when the next frame changes the content above it.
  ///
  /// Like scroll anchoring in browsers, nothing is kept at the very top of
  /// the list: there the new content is meant to push the rest down.
  void keepInPlace(BuildContext context) {
    if (!hasClients) return;
    if (position.pixels <= position.minScrollExtent) return;
    final anchor = context.findRenderObject();
    final scrollOffset = anchor == null ? null : _scrollOffsetOf(anchor);
    if (scrollOffset == null) return;
    _anchor = anchor;
    _anchorScrollOffset = scrollOffset;
    // Only the very next layout may move the list.
    WidgetsBinding.instance.addPostFrameCallback((_) => _anchor = null);
  }

  /// How far the anchor moved since [keepInPlace]; clears the anchor.
  double _takeCorrection() {
    final anchor = _anchor;
    _anchor = null;
    if (anchor == null || !anchor.attached) return 0;
    final scrollOffset = _scrollOffsetOf(anchor);
    return scrollOffset == null ? 0 : scrollOffset - _anchorScrollOffset;
  }

  /// The scroll offset at which the sliver item holding [object] starts.
  ///
  /// Reads only sliver layout data, so it may be called while the viewport
  /// lays out its slivers.
  static double? _scrollOffsetOf(RenderObject object) {
    RenderObject child = object;
    while (child.parent is! RenderSliver) {
      final parent = child.parent;
      if (parent == null) return null;
      child = parent;
    }
    final sliver = child.parent! as RenderSliver;
    final offset = sliver.childScrollOffset(child);
    if (offset == null) return null;
    return sliver.constraints.precedingScrollExtent + offset;
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _AnchoredScrollPosition(
      controller: this,
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class _AnchoredScrollPosition extends ScrollPositionWithSingleContext {
  _AnchoredScrollPosition({
    required this.controller,
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  final AnchoredScrollController controller;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    // Called by the viewport once all slivers are laid out; returning false
    // lays them out again at the corrected offset before anything is painted.
    final correction = controller._takeCorrection();
    if (correction != 0) {
      final corrected = (pixels + correction).clamp(
        minScrollExtent,
        maxScrollExtent,
      );
      if (corrected != pixels) {
        correctBy(corrected - pixels);
        return false;
      }
    }
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }
}
