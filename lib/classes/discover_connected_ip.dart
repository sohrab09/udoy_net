import 'dart:async';
import 'package:dart_ping/dart_ping.dart';
import 'package:network_info_plus/network_info_plus.dart';

class IPScanner {
  final int startRange;
  final int endRange;
  final int timeout;

  IPScanner({
    this.startRange = 1,
    this.endRange = 254,
    this.timeout = 20,
  });

  Future<Map<String, bool>> scanNetwork() async {
    Map<String, bool> pingResults = {};
    List<Future<void>> pingTasks = [];
    String baseIp = '';
    final NetworkInfo networkInfo = NetworkInfo();
    final ip = await networkInfo.getWifiIP();

    if (ip != null) {
      baseIp = ip.substring(0, ip.lastIndexOf('.'));
    }

    if (baseIp.isEmpty) {
      throw Exception("Failed to retrieve base IP address");
    }

    for (int i = startRange; i <= endRange; i++) {
      final ip = '$baseIp.$i';
      pingTasks.add(
        _pingIp(ip).then((isReachable) {
          if (isReachable) {
            pingResults[ip] = true;
          }
        }),
      );
    }

    await Future.wait(pingTasks);
    return pingResults;
  }

  Future<bool> _pingIp(String ip) async {
    final ping = Ping(
      ip,
      count: 1,
      timeout: timeout,
      interval: 10,
    );
    try {
      final response = await ping.stream.first;
      return response.response != null;
    } catch (e) {
      return false;
    }
  }
}
