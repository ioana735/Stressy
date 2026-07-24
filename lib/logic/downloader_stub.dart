/// Fallback pentru platforme non-web (VM/mobil). Pe mobil nativ s-ar folosi
/// share_plus; deocamdata exportul e gandit pentru web/PWA.
Future<bool> downloadText(String filename, String content, String mime) async {
  return false;
}
