import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:knoq_app/features/auth/domain/user_model.dart';
import 'package:knoq_app/features/session/domain/session_model.dart';
import 'package:knoq_app/core/utils/formatters.dart';
import 'dart:math';

class PdfExportService {
  
  /// Generates the PDF and opens the native share modal immediately.
  Future<void> exportAndSharePlayerReport(
    UserModel player,
    List<SessionModel> sessions, {
    List<Map<String, dynamic>>? coachNotes,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(player),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummaryStats(sessions),
          pw.SizedBox(height: 20),
          _buildZoneDistributionChart(sessions),
          pw.SizedBox(height: 20),
          _buildPowerTrendChart(sessions),
          pw.SizedBox(height: 20),
          _buildSessionHistoryTable(sessions),
          if (coachNotes != null && coachNotes.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildCoachNotesSection(coachNotes),
          ],
        ],
      ),
    );

    final bytes = await pdf.save();
    
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${(player.name ?? 'Player').replaceAll(' ', '_')}_report.pdf',
    );
  }

  pw.Widget _buildHeader(UserModel player) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('KnoQ Player Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
        pw.SizedBox(height: 8),
        pw.Text('Player: ${player.name}', style: const pw.TextStyle(fontSize: 16)),
        pw.Text('Academy: ${player.academyId ?? 'Independent'}', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
        pw.Text('Report Generated: ${Formatters.formatDateTime(DateTime.now())}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount} — Powered by KnoQ Smart Bat',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  pw.Widget _buildSummaryStats(List<SessionModel> sessions) {
    if (sessions.isEmpty) {
      return pw.Text("No sessions available to summarize.");
    }
    
    int totalShots = 0;
    double totalPower = 0;
    double totalSweet = 0;
    int peakPower = 0;
    
    for (var s in sessions) {
      totalShots += s.totalHits;
      totalPower += s.avgPower;
      totalSweet += s.sweetSpotPct;
      if (s.peakPower > peakPower) peakPower = s.peakPower;
    }
    
    final avgPwr = (totalPower / sessions.length).toStringAsFixed(1);
    final avgSweet = (totalSweet / sessions.length).toStringAsFixed(1);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _statBox('Total Sessions', '${sessions.length}'),
          _statBox('Total Shots', '$totalShots'),
          _statBox('Avg Power', avgPwr),
          _statBox('Peak Power', '$peakPower'),
          _statBox('Avg Sweet %', '$avgSweet%'),
        ],
      )
    );
  }
  
  pw.Widget _statBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800)),
      ]
    );
  }

  /// Renders a zone distribution chart as colored bars in the PDF.
  pw.Widget _buildZoneDistributionChart(List<SessionModel> sessions) {
    if (sessions.isEmpty) return pw.SizedBox();

    // Aggregate zone data
    final Map<String, int> zoneTotals = {};
    for (var s in sessions) {
      s.zoneDistribution.forEach((key, value) {
        zoneTotals[key] = (zoneTotals[key] ?? 0) + (value as num).toInt();
      });
    }

    if (zoneTotals.isEmpty) return pw.SizedBox();

    final totalHits = zoneTotals.values.fold(0, (a, b) => a + b);
    if (totalHits == 0) return pw.SizedBox();

    // Zone colors
    final zoneColors = {
      'Sweet': PdfColors.green,
      'Top': PdfColors.blue,
      'Left': PdfColors.orange,
      'Right': PdfColors.purple,
      'Bottom': PdfColors.red,
    };

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Zone Distribution', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        ...zoneTotals.entries.map((entry) {
          final pct = (entry.value / totalHits * 100);
          final barWidth = pct * 3.5; // scale to fit ~350px max
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Row(
              children: [
                pw.SizedBox(width: 60, child: pw.Text(entry.key, style: const pw.TextStyle(fontSize: 12))),
                pw.Container(
                  width: max(barWidth, 2),
                  height: 16,
                  decoration: pw.BoxDecoration(
                    color: zoneColors[entry.key] ?? PdfColors.grey,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text('${pct.toStringAsFixed(1)}% (${entry.value})', style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Renders a power trend chart as a series of connected dots.
  pw.Widget _buildPowerTrendChart(List<SessionModel> sessions) {
    if (sessions.length < 2) return pw.SizedBox();

    final sorted = List<SessionModel>.from(sessions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final maxPower = sorted.map((s) => s.avgPower).reduce(max).toDouble();
    final minPower = sorted.map((s) => s.avgPower).reduce(min).toDouble();
    final range = maxPower - minPower;
    final effectiveRange = range == 0 ? 1.0 : range;

    const chartWidth = 400.0;
    const chartHeight = 120.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Power Trend (Avg Power per Session)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.CustomPaint(
          size: const PdfPoint(chartWidth, chartHeight),
          painter: (PdfGraphics canvas, PdfPoint size) {
            final stepX = chartWidth / (sorted.length - 1);

            // Draw grid lines
            canvas.setColor(PdfColors.grey300);
            for (int i = 0; i <= 4; i++) {
              final y = chartHeight * i / 4;
              canvas.drawLine(0, y, chartWidth, y);
              canvas.strokePath();
            }

            // Draw data line
            canvas.setColor(PdfColors.green800);
            canvas.setLineWidth(2);
            for (int i = 0; i < sorted.length - 1; i++) {
              final x1 = i * stepX;
              final y1 = chartHeight - ((sorted[i].avgPower - minPower) / effectiveRange * chartHeight);
              final x2 = (i + 1) * stepX;
              final y2 = chartHeight - ((sorted[i + 1].avgPower - minPower) / effectiveRange * chartHeight);
              canvas.drawLine(x1, y1, x2, y2);
              canvas.strokePath();
            }

            // Draw dots
            for (int i = 0; i < sorted.length; i++) {
              final x = i * stepX;
              final y = chartHeight - ((sorted[i].avgPower - minPower) / effectiveRange * chartHeight);
              canvas.setColor(PdfColors.green);
              canvas.drawEllipse(x, y, 3, 3);
              canvas.fillPath();
            }
          },
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(Formatters.formatDate(sorted.first.startTime), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            pw.Text(Formatters.formatDate(sorted.last.startTime), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSessionHistoryTable(List<SessionModel> sessions) {
    if (sessions.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Session History', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Shots', 'Avg Power', 'Peak Power', 'SweetSpot %'],
          data: sessions.map((s) {
            return [
              Formatters.formatDateTime(s.startTime),
              '${s.totalHits}',
              '${s.avgPower}',
              '${s.peakPower}',
              '${s.sweetSpotPct}%',
            ];
          }).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellHeight: 28,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
            4: pw.Alignment.center,
          },
        ),
      ],
    );
  }

  /// Renders coach notes section in the PDF.
  pw.Widget _buildCoachNotesSection(List<Map<String, dynamic>> notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Coach Notes', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        ...notes.map((note) {
          final date = note['created_at'] != null 
              ? Formatters.formatDateTime(DateTime.parse(note['created_at']))
              : 'Unknown date';
          final tags = (note['tags'] as List?)?.join(', ') ?? '';
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(date, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    if (tags.isNotEmpty)
                      pw.Text(tags, style: pw.TextStyle(fontSize: 9, color: PdfColors.blue800, fontStyle: pw.FontStyle.italic)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(note['note'] ?? '', style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
