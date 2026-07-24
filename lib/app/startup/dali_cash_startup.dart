import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../theme/app_colors.dart';

typedef StartupApiBootstrapper = Future<ApiClient> Function();
typedef StartupPermissionLifecycleStarter = void Function();
typedef ReadyAppBuilder = Widget Function(ApiClient client);

class DaliCashStartup extends StatefulWidget {
  const DaliCashStartup({
    required this.bootstrapApi,
    required this.startPermissionLifecycle,
    required this.readyAppBuilder,
    super.key,
  });

  final StartupApiBootstrapper bootstrapApi;
  final StartupPermissionLifecycleStarter startPermissionLifecycle;
  final ReadyAppBuilder readyAppBuilder;

  @override
  State<DaliCashStartup> createState() => _DaliCashStartupState();
}

class _DaliCashStartupState extends State<DaliCashStartup>
    with WidgetsBindingObserver {
  ApiClient? _apiClient;
  bool _bootstrapping = false;
  bool _failed = false;
  bool _permissionLifecycleStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _failed) {
      _bootstrap();
    }
  }

  Future<void> _bootstrap() async {
    if (_bootstrapping || _apiClient != null) {
      return;
    }
    setState(() {
      _bootstrapping = true;
      _failed = false;
    });

    try {
      final client = await widget.bootstrapApi();
      if (!mounted) {
        return;
      }
      setState(() {
        _apiClient = client;
        _bootstrapping = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _permissionLifecycleStarted) {
          return;
        }
        _permissionLifecycleStarted = true;
        widget.startPermissionLifecycle();
      });
    } catch (error) {
      debugPrint(
        '[DaliNetworkDiag] startup gate blocked: '
        '${error.runtimeType}: $error',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _bootstrapping = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = _apiClient;
    if (client != null) {
      return widget.readyAppBuilder(client);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dali Cash',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 24),
              SizedBox.square(
                dimension: 48,
                child: _failed
                    ? IconButton(
                        key: const Key('startup-network-retry'),
                        tooltip: 'Retry network connection',
                        onPressed: _bootstrapping ? null : _bootstrap,
                        color: AppColors.primary,
                        icon: const Icon(Icons.refresh),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          key: Key('startup-network-loading'),
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
