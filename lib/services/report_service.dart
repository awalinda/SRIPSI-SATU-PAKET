import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart' show Colors;

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 GENERATE REPORT
  Future<void> generateReport({
    required String type, // "Barang Masuk" atau "Barang Keluar"
    required String filter, // "Mingguan", "Bulanan", "Semua"
    required String format, // "PDF", "Excel"
  }) async {
    try {
      // 1. Ambil Data
      List<Map<String, dynamic>> data = await _fetchData(type, filter);

      // 2. Simpan Log ke Database
      await _logReport(type, filter, format, data.length);

      // 3. Generate File
      if (format == "PDF") {
        await _generatePdf(type, filter, data);
      } else {
        await _generateExcel(type, filter, data);
      }
    } catch (e) {
      print("Error generating report: $e");
      rethrow;
    }
  }

  // 🔥 FETCH DATA DENGAN FILTER
  Future<List<Map<String, dynamic>>> _fetchData(String type, String filter) async {
    Query query;
    if (type == "Barang Masuk") {
      query = _firestore.collection('packages_admin').orderBy('createdAt', descending: true);
    } else {
      query = _firestore.collection('pengiriman').orderBy('createdAt', descending: true);
    }

    DateTime now = DateTime.now();
    if (filter == "Mingguan") {
      DateTime weekAgo = now.subtract(const Duration(days: 7));
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo));
    } else if (filter == "Bulanan") {
      DateTime monthAgo = DateTime(now.year, now.month - 1, now.day);
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo));
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      var d = doc.data() as Map<String, dynamic>;
      d['id'] = doc.id;
      return d;
    }).toList();
  }

  // 🔥 LOG REPORT TO DATABASE
  Future<void> _logReport(String type, String filter, String format, int totalData) async {
    await _firestore.collection('reports').add({
      "type": type,
      "filter": filter,
      "format": format,
      "totalData": totalData,
      "generatedAt": FieldValue.serverTimestamp(),
    });
  }

  // 🔥 GENERATE PDF
  Future<void> _generatePdf(String type, String filter, List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(type, filter),
          pw.SizedBox(height: 20),
          _buildTable(type, data),
          pw.SizedBox(height: 20),
          pw.Text("Total Data: ${data.length}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text("Dicetak pada: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}"),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: "Laporan_${type}_$filter.pdf",
    );
  }

  pw.Widget _buildHeader(String type, String filter) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("SATUPAKET", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.Text("Laporan $type ($filter)", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildTable(String type, List<Map<String, dynamic>> data) {
    final headers = type == "Barang Masuk" 
      ? ["No", "Resi", "Nama Barang", "Berat", "Kategori", "Tanggal"]
      : ["No", "Resi", "Penerima", "Total Item", "Total Biaya", "Tanggal"];

    final rows = data.asMap().entries.map((entry) {
      int idx = entry.key + 1;
      var d = entry.value;
      if (type == "Barang Masuk") {
        return [
          idx.toString(),
          d["resi"] ?? "-",
          d["nama"] ?? "-",
          "${d["berat"] ?? 0} kg",
          d["kategori"] ?? "-",
          d["tanggal"] ?? "-",
        ];
      } else {
        return [
          idx.toString(),
          d["resi"] ?? "-",
          d["user"] ?? d["nama"] ?? "-",
          "${(d["items"] as List?)?.length ?? 0}",
          "Rp${d["totalBiaya"] ?? 0}",
          d["tanggal"] ?? "-",
        ];
      }
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  // 🔥 GENERATE EXCEL
  Future<void> _generateExcel(String type, String filter, List<Map<String, dynamic>> data) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Laporan $type'];

    // Header
    List<String> headers = type == "Barang Masuk"
      ? ["No", "Resi", "Nama Barang", "Berat (kg)", "Kategori", "Tanggal"]
      : ["No", "Resi", "Penerima", "Total Item", "Total Biaya", "Tanggal"];
    
    sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

    // Data
    for (var i = 0; i < data.length; i++) {
      var d = data[i];
      if (type == "Barang Masuk") {
        sheetObject.appendRow([
          IntCellValue(i + 1),
          TextCellValue(d["resi"] ?? "-"),
          TextCellValue(d["nama"] ?? "-"),
          DoubleCellValue(double.tryParse(d["berat"].toString()) ?? 0),
          TextCellValue(d["kategori"] ?? "-"),
          TextCellValue(d["tanggal"] ?? "-"),
        ]);
      } else {
        sheetObject.appendRow([
          IntCellValue(i + 1),
          TextCellValue(d["resi"] ?? "-"),
          TextCellValue(d["user"] ?? d["nama"] ?? "-"),
          IntCellValue((d["items"] as List?)?.length ?? 0),
          IntCellValue(int.tryParse(d["totalBiaya"].toString()) ?? 0),
          TextCellValue(d["tanggal"] ?? "-"),
        ]);
      }
    }

    // Save & Download (Web handles bytes via Printing or custom)
    final bytes = excel.encode();
    if (bytes != null) {
      await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: "Laporan_${type}_$filter.xlsx");
    }
  }
}
