import 'dart:io';

class PingService {
  static Future<String> ping(String ip) async {
    try {
      // Execute the ping command
      final result = await Process.run('ping', ['-c', '4', ip]);

      if (result.exitCode == 0) {
        // Extract RTT statistics using a regex
        final regex =
            RegExp(r'rtt min/avg/max/mdev = [\d.]+/[\d.]+/[\d.]+/([\d.]+) ms');
        final match = regex.firstMatch(result.stdout.toString());

        if (match != null) {
          // Return the mdev value
          return "${match.group(1)} ms";
        } else {
          return "Error: Unable to extract RTT";
        }
      } else {
        // Return "N/A" instead of "Ping failed: ..."
        return "N/A";
      }
    } catch (e) {
      // Return "N/A" in case of any exception
      return "N/A";
    }
  }
}
