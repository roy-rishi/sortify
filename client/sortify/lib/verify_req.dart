
import 'package:http/http.dart' as http;

Future<String> verifyReq() async {
  final response = await http.get(Uri.parse("http://localhost:3004/verify"));

  if (response.statusCode == 200) {
    return response.body;
  }
  if (response.statusCode == 401 || response.body == "Missing authorization" || response.body == "Poor authentication") {
    return "Password required";
  }
  print(response.body);
  throw Exception(response.body);
}