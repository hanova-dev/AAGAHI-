import 'package:connectivity_plus/connectivity_plus.dart';

import '../../features/risk/data/repositories/risk_repository_impl.dart';

/// Reports the OS's own view of connectivity. Never polls or pings a URL
/// (CI-06) - `checkConnectivity()` reads the radio/interface state the
/// platform already tracks.
final class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}
