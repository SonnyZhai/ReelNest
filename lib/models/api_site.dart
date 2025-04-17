class ApiSite {
  final String key;
  final String name;
  final String api;
  final String? detail;
  final bool adult;

  ApiSite({
    required this.key,
    required this.name,
    required this.api,
    this.detail,
    this.adult = false,
  });
}
