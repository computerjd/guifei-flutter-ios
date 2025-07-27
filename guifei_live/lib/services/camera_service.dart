import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isRecording = false;
  
  // 相机状态流
  final StreamController<CameraState> _stateController = StreamController<CameraState>.broadcast();
  Stream<CameraState> get stateStream => _stateController.stream;
  
  // 获取当前相机控制器
  CameraController? get controller => _controller;
  
  // 获取可用相机列表
  List<CameraDescription> get cameras => _cameras;
  
  // 获取当前选中的相机索引
  int get selectedCameraIndex => _selectedCameraIndex;
  
  // 是否已初始化
  bool get isInitialized => _isInitialized;
  
  // 是否正在录制
  bool get isRecording => _isRecording;
  
  // 获取当前相机描述
  CameraDescription? get currentCamera {
    if (_cameras.isEmpty || _selectedCameraIndex >= _cameras.length) {
      return null;
    }
    return _cameras[_selectedCameraIndex];
  }
  
  // 是否为前置摄像头
  bool get isFrontCamera {
    return currentCamera?.lensDirection == CameraLensDirection.front;
  }
  
  // 是否为后置摄像头
  bool get isBackCamera {
    return currentCamera?.lensDirection == CameraLensDirection.back;
  }

  // 初始化相机服务
  Future<bool> initialize() async {
    try {
      _emitState(CameraState.initializing);
      
      // 检查相机权限
      final cameraPermission = await Permission.camera.request();
      final microphonePermission = await Permission.microphone.request();
      
      if (cameraPermission != PermissionStatus.granted || 
          microphonePermission != PermissionStatus.granted) {
        _emitState(CameraState.permissionDenied);
        return false;
      }
      
      // 获取可用相机
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        _emitState(CameraState.noCameraAvailable);
        return false;
      }
      
      // 优先选择前置摄像头
      _selectedCameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      
      if (_selectedCameraIndex == -1) {
        _selectedCameraIndex = 0;
      }
      
      // 初始化相机控制器
      await _initializeController();
      
      _isInitialized = true;
      _emitState(CameraState.ready);
      
      return true;
    } catch (e) {
      debugPrint('相机初始化失败: $e');
      _emitState(CameraState.error, error: e.toString());
      return false;
    }
  }
  
  // 初始化相机控制器
  Future<void> _initializeController() async {
    if (_cameras.isEmpty) return;
    
    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    
    await _controller!.initialize();
  }
  
  // 切换摄像头
  Future<bool> switchCamera() async {
    if (_cameras.length <= 1) return false;
    
    try {
      _emitState(CameraState.switching);
      
      // 停止当前录制（如果正在录制）
      if (_isRecording) {
        await stopRecording();
      }
      
      // 释放当前控制器
      await _controller?.dispose();
      
      // 切换到下一个摄像头
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      
      // 初始化新的控制器
      await _initializeController();
      
      _emitState(CameraState.ready);
      return true;
    } catch (e) {
      debugPrint('切换摄像头失败: $e');
      _emitState(CameraState.error, error: e.toString());
      return false;
    }
  }
  
  // 设置闪光灯模式
  Future<bool> setFlashMode(FlashMode mode) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return false;
    }
    
    try {
      await _controller!.setFlashMode(mode);
      return true;
    } catch (e) {
      debugPrint('设置闪光灯失败: $e');
      return false;
    }
  }
  
  // 开启闪光灯
  Future<bool> enableFlash() async {
    return await setFlashMode(FlashMode.torch);
  }
  
  // 关闭闪光灯
  Future<bool> disableFlash() async {
    return await setFlashMode(FlashMode.off);
  }
  
  // 切换闪光灯
  Future<bool> toggleFlash() async {
    if (_controller == null) return false;
    
    final currentMode = _controller!.value.flashMode;
    if (currentMode == FlashMode.torch) {
      return await disableFlash();
    } else {
      return await enableFlash();
    }
  }
  
  // 设置缩放级别
  Future<bool> setZoomLevel(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return false;
    }
    
    try {
      final maxZoom = await _controller!.getMaxZoomLevel();
      final minZoom = await _controller!.getMinZoomLevel();
      final clampedZoom = zoom.clamp(minZoom, maxZoom);
      
      await _controller!.setZoomLevel(clampedZoom);
      return true;
    } catch (e) {
      debugPrint('设置缩放失败: $e');
      return false;
    }
  }
  
  // 开始录制
  Future<bool> startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) {
      return false;
    }
    
    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      _emitState(CameraState.recording);
      return true;
    } catch (e) {
      debugPrint('开始录制失败: $e');
      _emitState(CameraState.error, error: e.toString());
      return false;
    }
  }
  
  // 停止录制
  Future<XFile?> stopRecording() async {
    if (_controller == null || !_isRecording) {
      return null;
    }
    
    try {
      final file = await _controller!.stopVideoRecording();
      _isRecording = false;
      _emitState(CameraState.ready);
      return file;
    } catch (e) {
      debugPrint('停止录制失败: $e');
      _emitState(CameraState.error, error: e.toString());
      return null;
    }
  }
  
  // 拍照
  Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }
    
    try {
      final file = await _controller!.takePicture();
      return file;
    } catch (e) {
      debugPrint('拍照失败: $e');
      return null;
    }
  }
  
  // 设置对焦点
  Future<bool> setFocusPoint(Offset point) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return false;
    }
    
    try {
      await _controller!.setFocusPoint(point);
      return true;
    } catch (e) {
      debugPrint('设置对焦点失败: $e');
      return false;
    }
  }
  
  // 设置曝光点
  Future<bool> setExposurePoint(Offset point) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return false;
    }
    
    try {
      await _controller!.setExposurePoint(point);
      return true;
    } catch (e) {
      debugPrint('设置曝光点失败: $e');
      return false;
    }
  }
  
  // 获取相机预览尺寸
  Size? getPreviewSize() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }
    return _controller!.value.previewSize;
  }
  
  // 发射状态
  void _emitState(CameraState state, {String? error}) {
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }
  
  // 释放资源
  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
    
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isRecording = false;
    
    if (!_stateController.isClosed) {
      await _stateController.close();
    }
  }
}

// 相机状态枚举
enum CameraState {
  uninitialized,
  initializing,
  ready,
  switching,
  recording,
  error,
  permissionDenied,
  noCameraAvailable,
}

// 相机配置类
class CameraConfig {
  final ResolutionPreset resolution;
  final bool enableAudio;
  final ImageFormatGroup imageFormat;
  final FlashMode flashMode;
  final double zoomLevel;
  
  const CameraConfig({
    this.resolution = ResolutionPreset.high,
    this.enableAudio = true,
    this.imageFormat = ImageFormatGroup.jpeg,
    this.flashMode = FlashMode.off,
    this.zoomLevel = 1.0,
  });
  
  CameraConfig copyWith({
    ResolutionPreset? resolution,
    bool? enableAudio,
    ImageFormatGroup? imageFormat,
    FlashMode? flashMode,
    double? zoomLevel,
  }) {
    return CameraConfig(
      resolution: resolution ?? this.resolution,
      enableAudio: enableAudio ?? this.enableAudio,
      imageFormat: imageFormat ?? this.imageFormat,
      flashMode: flashMode ?? this.flashMode,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }
}