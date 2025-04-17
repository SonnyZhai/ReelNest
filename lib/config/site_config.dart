// 预留站点相关配置，后续可扩展
class SiteConfig {
  // 示例：站点名称、LOGO、主题色等
  static const String appName = 'ReelNest';
  static const String logoAsset = 'assets/logo.png';
  static const String defaultThemeColor = '#2196F3';

  // 代理服务配置
  static const String proxyScheme = 'http';
  static const String proxyHost = 'localhost';
  static const int proxyPort = 8080;
  static const String proxyPath = '/api/proxy';
  static const String proxySpecialDetailPath = '/api/special-detail';
  static const String proxySearchPath = 'api.php/provide/vod/';
  static const int proxyTimeoutMs = 8000;
}
