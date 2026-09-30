import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CameraOverlayState {
  final double opacity;
  final bool isLocked;
  final bool isFlipped;
  final bool isFlashOn;
  final Offset position;
  final double scale;
  final double rotation;

  CameraOverlayState({
    this.opacity = 0.5,
    this.isLocked = false,
    this.isFlipped = false,
    this.isFlashOn = false,
    this.position = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  CameraOverlayState copyWith({
    double? opacity,
    bool? isLocked,
    bool? isFlipped,
    bool? isFlashOn,
    Offset? position,
    double? scale,
    double? rotation,
  }) {
    return CameraOverlayState(
      opacity: opacity ?? this.opacity,
      isLocked: isLocked ?? this.isLocked,
      isFlipped: isFlipped ?? this.isFlipped,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}

class CameraOverlayNotifier extends Notifier<CameraOverlayState> {
  @override
  CameraOverlayState build() {
    return CameraOverlayState();
  }

  void setOpacity(double opacity) {
    state = state.copyWith(opacity: opacity);
  }

  void toggleLock() {
    state = state.copyWith(isLocked: !state.isLocked);
  }

  void toggleFlip() {
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  void setFlash(bool value) {
    state = state.copyWith(isFlashOn: value);
  }

  void updatePosition(Offset delta) {
    if (state.isLocked) return;
    state = state.copyWith(position: state.position + delta);
  }

  void updateScale(double factor) {
    if (state.isLocked) return;
    state = state.copyWith(scale: (state.scale * factor).clamp(0.1, 8.0));
  }

  void updateRotation(double angleDelta) {
    if (state.isLocked) return;
    state = state.copyWith(rotation: state.rotation + angleDelta);
  }

  void reset() {
    state = CameraOverlayState();
  }
}

final cameraOverlayProvider =
    NotifierProvider<CameraOverlayNotifier, CameraOverlayState>(() {
  return CameraOverlayNotifier();
});
