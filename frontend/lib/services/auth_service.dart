Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('${DiseaseService.getBaseUrl()}/login/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    
    // Rest of the code...
  } catch (e) {
    // Error handling...
  }
}