import 'package:flutter_test/flutter_test.dart';
import 'package:knoq_app/features/ble/data/shot_parser.dart';
import 'package:knoq_app/features/ble/domain/shot_data.dart';

void main() {
  group('ShotParser Constraints & Buffering', () {
    late ShotParser parser;

    setUp(() {
      parser = ShotParser();
    });

    test('Valid complete shot JSON is parsed instantly', () {
      final jsonStr = '{"cmd":"shot","hit":1,"zone":"Sweet","power":85,"swing":120.5,"sweetPct":90,"avgPower":80,"totalHits":10}\n';
      final results = parser.ingest(jsonStr);

      expect(results.length, 1);
      final shot = results.first as ShotData;
      expect(shot.hit, 1);
      expect(shot.zone, 'Sweet');
      expect(shot.power, 85);
      expect(shot.swing, 120.5);
    });
    
    test('Swing parameter edge cases are handled precisely', () {
      // 1. swing=0 -> parsed as null
      final json1 = '{"hit":1,"zone":"Top","power":50,"swing":0}\n';
      expect((parser.ingest(json1).first as ShotData).swing, isNull);
      
      // 2. negative swing -> parsed as null (since rule: doubleVal > 0)
      final json2 = '{"hit":2,"zone":"Left","power":50,"swing":-45.2}\n';
      expect((parser.ingest(json2).first as ShotData).swing, isNull);
      
      // 3. missing swing -> parsed as null
      final json3 = '{"hit":3,"zone":"Right","power":50}\n';
      expect((parser.ingest(json3).first as ShotData).swing, isNull);
      
      // 4. normal swing
      final json4 = '{"hit":4,"zone":"Right","power":50,"swing":55.5}\n';
      expect((parser.ingest(json4).first as ShotData).swing, 55.5);
    });

    test('Fragmented JSON (MTU splits) are reassembled safely', () {
      // Incoming chunks simulating MTU limits (e.g. 23 bytes)
      final chunk1 = '{"cmd":"shot","hit":1,"z';
      final chunk2 = 'one":"Bottom","power":2';
      final chunk3 = '0}\n';
      
      expect(parser.ingest(chunk1).isEmpty, true);
      expect(parser.ingest(chunk2).isEmpty, true);
      
      final results = parser.ingest(chunk3);
      expect(results.length, 1);
      final shot = results.first as ShotData;
      expect(shot.zone, 'Bottom');
      expect(shot.power, 20);
    });
    
    test('JSON payload with missing fields populates hardcoded defaults without crashing', () {
       // Missing totalHits, avgPower, sweetPct
      final jsonStr = '{"hit":5,"zone":"Left","power":30}\n';
      final results = parser.ingest(jsonStr);
      final shot = results.first as ShotData;
      expect(shot.sweetPct, 0); 
    });

    test('Summary JSON parses correctly into SessionSummary', () {
      final jsonStr = '{"cmd":"summary","total":42,"avgPower":75,"zones":{"Sweet":0.6,"Top":0.1,"Left":0.1,"Right":0.1,"Bottom":0.1}}\n';
      final results = parser.ingest(jsonStr);

      expect(results.length, 1);
      final summary = results.first as SessionSummary;
      expect(summary.totalShots, 42);
      expect(summary.avgPower, 75);
      expect(summary.zoneDistribution['Sweet'], 0.6);
    });

    test('Garbage/Malformed JSON string does not crash engine', () {
      final jsonStr = '{"hit":1,zone"Sweet","power":85}\n'; // Syntax Error missing quote
      final results = parser.ingest(jsonStr);

      expect(results.isEmpty, true);
      
      // Should recover and parse next ok stream
      final jsonNext = '{"hit":2,"zone":"Left","power":33}\n';
      final resultsNext = parser.ingest(jsonNext);
      expect(resultsNext.length, 1);
    });
  });
}
