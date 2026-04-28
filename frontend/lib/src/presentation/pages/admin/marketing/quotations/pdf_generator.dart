import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class QuoteItem {
  final String code;
  final String description;
  final double unitCost;
  final int quantity;

  QuoteItem({
    required this.code,
    required this.description,
    required this.unitCost,
    required this.quantity,
  });

  double get total => unitCost * quantity;
}

class QuoteData {
  final String companyName;
  final String clientName;
  final String clientDetails;
  final String quoteNumber;
  final String quoteDate;
  final String validUntil;
  final List<QuoteItem> items;
  final double discountPercent;
  final double taxAmount;
  final double paidToDate;
  final String description;
  final String introduction;
  final List<String> prerequisites;
  final String currency;

  QuoteData({
    required this.companyName,
    required this.clientName,
    required this.clientDetails,
    required this.quoteNumber,
    required this.quoteDate,
    required this.validUntil,
    required this.items,
    required this.discountPercent,
    this.taxAmount = 0,
    required this.paidToDate,
    required this.description,
    required this.introduction,
    required this.prerequisites,
    this.currency = '$',
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get discountAmount => subtotal * (discountPercent / 100);
  double get total => subtotal - discountAmount + taxAmount;
}

class QuotePdfGenerator {
  static Future<Uint8List> generate(QuoteData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          /// 1. HEADER
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    data.companyName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text("Hosi Academy Zimbabwe", style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Text(
                "QUOTE",
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          /// 2. META INFO
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _metaRow("Quote Number", data.quoteNumber),
                  _metaRow("Quote Date", data.quoteDate),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _metaRow("Valid Until", data.validUntil),
                  _metaRow("Total", "${data.currency}${data.total.round()}", isHighlight: true),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          /// 3. CLIENT INFO
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "BILL TO:",
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  data.clientName,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
                pw.SizedBox(height: 2),
                pw.Text(data.clientDetails, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),

          pw.SizedBox(height: 30),

          /// 4. LINE ITEMS TABLE
          pw.Table(
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: PdfColors.grey200),
              bottom: pw.BorderSide(color: PdfColors.grey300),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(4),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              /// HEADER
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
                children: _tableHeader(["Item", "Description", "Unit Cost", "Qty", "Total"]),
              ),

              /// DATA ROWS
              ...data.items.map((item) => pw.TableRow(
                children: _tableRow([
                  item.code,
                  item.description,
                  "${data.currency}${item.unitCost.round()}",
                  item.quantity.toString(),
                  "${data.currency}${item.total.round()}",
                ]),
              )),
            ],
          ),

          pw.SizedBox(height: 30),

          /// 5. DESCRIPTION / CONTENT
          if (data.introduction.isNotEmpty) ...[
            pw.Text("Introduction", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 8),
            pw.Text(data.introduction, style: const pw.TextStyle(fontSize: 10, lineHeight: 1.5)),
            pw.SizedBox(height: 20),
          ],

          if (data.prerequisites.isNotEmpty) ...[
            pw.Text("Prerequisites", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 8),
            ...data.prerequisites.map((p) => pw.Bullet(text: p, style: const pw.TextStyle(fontSize: 10))),
            pw.SizedBox(height: 20),
          ],

          /// 6. TOTALS SUMMARY
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 200,
                child: pw.Column(
                  children: [
                    _totalRow("Subtotal", "${data.currency}${data.subtotal.round()}"),
                    _totalRow("Discount (${data.discountPercent}%)", "-${data.currency}${data.discountAmount.round()}"),
                    if (data.taxAmount > 0) _totalRow("Tax", "${data.currency}${data.taxAmount.round()}"),
                    pw.Divider(color: PdfColors.grey400),
                    _totalRow("Total", "${data.currency}${data.total.round()}", bold: true),
                    _totalRow("Paid to Date", "${data.currency}${data.paidToDate.round()}"),
                  ],
                ),
              ),
            ],
          ),

          pw.Spacer(),

          /// FOOTER
          pw.Center(
            child: pw.Text(
              "Thank you for your business. This is a computer generated document.\nHosi Academy © ${DateTime.now().year}",
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _metaRow(String label, String value, {bool isHighlight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text("$label: ", style: const pw.TextStyle(fontSize: 9)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: isHighlight ? PdfColors.orange800 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _tableHeader(List<String> headers) {
    return headers.map((h) => pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        h,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
        textAlign: h == "Total" || h == "Unit Cost" || h == "Qty" ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    )).toList();
  }

  static List<pw.Widget> _tableRow(List<String> data) {
    return data.asMap().entries.map((entry) {
      final idx = entry.key;
      final d = entry.value;
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: pw.Text(
          d,
          style: const pw.TextStyle(fontSize: 9),
          textAlign: idx >= 2 ? pw.TextAlign.right : pw.TextAlign.left,
        ),
      );
    }).toList();
  }

  static pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: bold ? PdfColors.orange800 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
