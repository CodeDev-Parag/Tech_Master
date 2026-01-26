import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';

class NoteExportService {
  final ScreenshotController screenshotController = ScreenshotController();

  Future<void> exportToPdf(Note note) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(note.title,
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Created: ${note.createdAt.toString().split('.')[0]}',
                  style:
                      const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(note.content, style: const pw.TextStyle(fontSize: 14)),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${note.title.replaceAll(' ', '_')}.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)],
        text: 'Check out my note: ${note.title}');
  }

  Future<void> exportToImage(Uint8List imageBytes, String title) async {
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${title.replaceAll(' ', '_')}.png");
    await file.writeAsBytes(imageBytes);

    await Share.shareXFiles([XFile(file.path)],
        text: 'Check out my note: $title');
  }
}
