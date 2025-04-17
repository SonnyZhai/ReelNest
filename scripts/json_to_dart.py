import json

JSON_PATH = "../config/api_sites.json"
DART_PATH = "../lib/config/api_config.dart"


def main():
    with open(JSON_PATH, "r", encoding="utf-8") as f:
        sites = json.load(f)
    with open(DART_PATH, "w", encoding="utf-8") as f:
        f.write("// 自动生成，如要添加站点请在config/api_sites.json中添加，并重新生成\n")
        f.write("import '../models/api_site.dart';\n")

        f.write("final List<ApiSite> apiSites = [\n")
        for key, info in sites.items():
            name = info.get("name", key)
            api = info.get("api", "")
            detail = info.get("detail", None)
            adult = info.get("adult", False)
            f.write(
                f"  ApiSite(key: '{key}', name: '{name}', api: '{api}', detail: {repr(detail) if detail else 'null'}, adult: {str(adult).lower()}),\n"
            )
        f.write("];\n")
    print(f"已生成: {DART_PATH}")


if __name__ == "__main__":
    main()
