import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/layout/screen_adapter.dart';
import '../../app/resources/app_assets.dart';
import '../../app/theme/app_colors.dart';
import 'recredit_polling_coordinator.dart';

class RecreditPage extends StatefulWidget {
  const RecreditPage({
    super.key,
    this.progressDelayGenerator,
    this.progressIncrementGenerator,
    this.onStartRecredit,
  });

  final Duration Function()? progressDelayGenerator;
  final int Function(int currentProgress)? progressIncrementGenerator;
  final void Function(String productId)? onStartRecredit;

  @override
  State<RecreditPage> createState() => _RecreditPageState();
}

class _RecreditPageState extends State<RecreditPage> {
  static final Random _random = Random();

  Timer? _progressTimer;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _scheduleProgressUpdate();
    _startRecreditIfPossible();
  }

  void _startRecreditIfPossible() {
    final productId = _extractProductId(Get.arguments);
    if (productId.isEmpty) {
      return;
    }
    final callback = widget.onStartRecredit;
    if (callback != null) {
      callback(productId);
      return;
    }
    final coordinator = Get.isRegistered<RecreditPollingCoordinator>()
        ? Get.find<RecreditPollingCoordinator>()
        : Get.put(RecreditPollingCoordinator(), permanent: true);
    coordinator.start(productId);
  }

  String _extractProductId(Object? arguments) {
    if (arguments is! Map) {
      return '';
    }
    final nested = arguments['payload'];
    final nestedMap = nested is Map ? nested : null;
    for (final key in const ['highlands', 'productId']) {
      for (final source in [arguments, nestedMap]) {
        final value = source?[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return '';
  }

  void _scheduleProgressUpdate() {
    if (_progress >= 99) {
      return;
    }
    final delay =
        widget.progressDelayGenerator?.call() ??
        Duration(seconds: _random.nextInt(3) + 1);
    _progressTimer = Timer(delay, _advanceProgress);
  }

  void _advanceProgress() {
    if (!mounted) {
      return;
    }
    final increment =
        widget.progressIncrementGenerator?.call(_progress) ??
        _random.nextInt(11) + 5;
    setState(() {
      _progress = (_progress + increment).clamp(0, 99);
    });
    _scheduleProgressUpdate();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenAdapter.init(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  SizedBox(height: ScreenAdapter.height(290)),
                  Image.asset(
                    AppAssets.recreditIllustration,
                    key: const Key('recredit-illustration'),
                    width: ScreenAdapter.width(120),
                    height: ScreenAdapter.height(102),
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: ScreenAdapter.height(18)),
                  const _RecreditMessage(),
                  SizedBox(height: ScreenAdapter.height(11)),
                  _RecreditProgress(progress: _progress),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecreditMessage extends StatelessWidget {
  const _RecreditMessage();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: AppColors.recreditText,
      fontFamily: 'Helvetica',
      fontSize: ScreenAdapter.font(14),
      fontWeight: FontWeight.w400,
      height: 18 / 14,
      letterSpacing: 0,
    );
    return SizedBox(
      width: ScreenAdapter.width(279),
      height: ScreenAdapter.height(36),
      child: Column(
        children: [
          RichText(
            maxLines: 1,
            textAlign: TextAlign.center,
            text: TextSpan(
              style: style,
              children: [
                const TextSpan(text: 'Calculating your credit limit, just '),
                TextSpan(
                  text: '30 seconds',
                  style: style.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          Text('Please wait patiently', maxLines: 1, style: style),
        ],
      ),
    );
  }
}

class _RecreditProgress extends StatelessWidget {
  const _RecreditProgress({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final width = ScreenAdapter.width(287);
    return SizedBox(
      key: const Key('recredit-progress-section'),
      width: width,
      height: ScreenAdapter.height(42),
      child: Column(
        children: [
          SizedBox(
            key: const Key('recredit-progress-bar'),
            width: width,
            height: ScreenAdapter.height(12),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    AppAssets.recreditProgressTrack,
                    fit: BoxFit.fill,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenAdapter.width(2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ScreenAdapter.width(4)),
                    child: SizedBox(
                      width: max(
                        0,
                        (width - ScreenAdapter.width(4)) * progress / 100,
                      ),
                      height: ScreenAdapter.height(8),
                      child: const ColoredBox(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ScreenAdapter.height(10)),
          Text(
            '$progress%',
            key: const Key('recredit-progress-label'),
            style: TextStyle(
              color: AppColors.primary,
              fontSize: ScreenAdapter.font(14),
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
