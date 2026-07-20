import 'dart:convert';
import 'dart:developer';

import 'package:knoq_app/features/ble/domain/shot_data.dart';

class ShotParser {
  final StringBuffer _buffer = StringBuffer();
  
  /// Ingests string chunks and yields complete parsed objects.
  /// Handles JSON fragmentation seamlessly.
  List<dynamic> ingest(String chunk) {
    _buffer.write(chunk);
    String data = _buffer.toString();
    List<dynamic> emittedObjects = [];

    // Split stream by newline delimiter
    int newlineIndex;
    while ((newlineIndex = data.indexOf('\n')) != -1) {
      String line = data.substring(0, newlineIndex).trim();
      data = data.substring(newlineIndex + 1); // remove parsed line

      if (line.isNotEmpty) {
        final parsedInfo = _parseLine(line);
        if (parsedInfo != null) {
          emittedObjects.add(parsedInfo);
        }
      }
    }
    
    // Store tail fragment back into buffer
    _buffer.clear();
    _buffer.write(data);

    return emittedObjects;
  }

  dynamic _parseLine(String line) {
    try {
      final jsonMap = json.decode(line);
      
      // Determine what type of packet we received
      if (jsonMap.containsKey('hit') && jsonMap.containsKey('zone')) {
        return ShotData.fromJson(jsonMap);
      } else if (jsonMap.containsKey('cmd') && jsonMap['cmd'] == 'summary') {
        return SessionSummary.fromJson(jsonMap);
      }
      
      return null; // Unknown JSON structure
    } catch (e) {
      log('ShotParser skipped malformed line: $line. Error: $e');
      // Do not crash, graceful swallow
      return null;
    }
  }

  void reset() {
    _buffer.clear();
  }
}
