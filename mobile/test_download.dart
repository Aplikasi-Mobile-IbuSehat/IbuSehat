import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  const fileId = '1Dk-CL3eSqoRT2wwMHdz-4pn0oF4purg7';
  final url = 'https://drive.google.com/uc?export=download&id=$fileId';

  try {
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      if (response.body.contains("Google Drive can't scan this file for viruses")) {
        // ignore: avoid_print
        print('Requires confirmation token.');
        final RegExp regExp = RegExp(r'confirm=([0-9A-Za-z_\-]+)');
        final match = regExp.firstMatch(response.body);
        if (match != null) {
          final token = match.group(1)!;
          // ignore: avoid_print
          print('Found token: $token');
          final res2 = await http.get(Uri.parse('$url&confirm=$token'));
          // ignore: avoid_print
          print('Second status: ${res2.statusCode}, length: ${res2.bodyBytes.length}');
          File('assets/videos/pemanasan.mp4').createSync(recursive: true);
          File('assets/videos/pemanasan.mp4').writeAsBytesSync(res2.bodyBytes);
          // ignore: avoid_print
          print('Success downloaded with token!');
        } else {
          // ignore: avoid_print
          print('No token found in HTML body.');
        }
      } else {
        File('assets/videos/pemanasan.mp4').createSync(recursive: true);
        File('assets/videos/pemanasan.mp4').writeAsBytesSync(response.bodyBytes);
        // ignore: avoid_print
        print('Success downloaded directly! Length: ${response.bodyBytes.length}');
      }
    } else {
      // ignore: avoid_print
      print('Failed: ${response.statusCode}');
    }
  } catch (e) {
    // ignore: avoid_print
    print('Error: $e');
  }
}
