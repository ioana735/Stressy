import 'dart:convert';
import 'dart:html' as html;

/// Descarca un fisier pe web (declanseaza download-ul din browser).
/// Pe iOS Safari, un fisier .ics deschide „Add to Calendar".
Future<bool> downloadText(String filename, String content, String mime) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}
