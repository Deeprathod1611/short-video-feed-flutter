import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class NetworkService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isOnline = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<NetworkService> init() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnection(results);
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnection);
    return this;
  }

  void _updateConnection(List<ConnectivityResult> results) {
    final offline = results.isEmpty ||
        results.every((item) => item == ConnectivityResult.none);
    isOnline.value = !offline;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}