import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';

const flagUpdateCode = 'update-code';
const flagSkipPlugin = 'skip-plugin';

Map<String, String> classMap = {
  'color': 'AppColors',
  'text_style': 'AppTextStyles',
  'font_family': 'AppFontFamilies',
  'image': 'AppImages',
  'themes': 'AppThemes',
};

Map<String, String> typesMap = {
  'color': 'Color',
  'text_style': 'TextStyle',
  'font_family': 'String',
  'image': 'UiImage',
  'themes': 'String',
};

Map<String, String> refsMap = {
  'color': 'Styles().colors?.getColor(%key)',
  'text_style': 'Styles().textStyles?.getTextStyle(%key)',
  'font_family': 'Styles().fontFamilies?.fromCode(%key)',
  'image': 'Styles().images?.getImage(%key)',
  'themes': '%key',
};

Map<String, Function(String, MapEntry<String, dynamic>, {Map<String, dynamic>? data})> defaultFuncs = {
  'color': _buildDefaultColor,
  'text_style': (name, entry, {data}) => _buildDefaultClass(name, entry, data: data, classFields: textStyleFields),
  'font_family': _buildDefaultString,
  'image': _buildDefaultImage,
};

Map<String, String> textStyleFields = {
  'color': 'color',
  'decoration_color': 'decorationColor:AppColors',
  'size': 'fontSize',
  'height': 'height',
  'font_family': 'fontFamily',
  'font_style': 'fontStyle:FontStyle',
  'letter_spacing': 'letterSpacing',
  'word_spacing': 'wordSpacing',
  'decoration_thickness': 'decorationThickness',
  'decoration': 'decoration:TextDecoration',
  'overflow': 'overflow:TextOverflow',
  'decoration_style': 'decorationStyle:TextDecorationStyle',
  'weight': 'fontWeight:FontWeight',
};

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

String camelCase(String s, {bool startUpper = false}) {
  List<String> parts = s.split(RegExp(r'[_\-.]'));
  String out = '';
  for (String part in parts) {
    if (out.isEmpty && !startUpper) {
      out += part;
    } else {
      out += capitalize(part);
    }
  }
  return out;
}

Map<String, String> replacements = {};

void main(List<String> arguments) async {
  final parser = ArgParser()..addFlag(flagUpdateCode, negatable: false, abbr: 'u')
    ..addFlag(flagSkipPlugin, negatable: false, abbr: 'p');
  ArgResults argResults = parser.parse(arguments);

  bool updateCode = argResults[flagUpdateCode];
  bool skipPlugin = argResults[flagSkipPlugin];

  String assetFilepath = 'assets/styles.json';
  String pluginAssetFilepath = 'plugin/assets/styles.json';
  String libPath = 'lib/';
  String genFilepath = '${libPath}gen/styles.dart';

  Map<String, dynamic>? asset = await _loadFileJson(assetFilepath);
  if (!skipPlugin) {
    print("merging plugin asset...");
    Map<String, dynamic>? pluginAsset = await _loadFileJson(pluginAssetFilepath);
    if (pluginAsset != null) {
      asset = _mergeJson(pluginAsset, asset);
      File(assetFilepath).writeAsString(_prettyJsonEncode(asset));
      print('saved merged plugin asset to $assetFilepath');
    } else {
      print('plugin asset was not loaded');
    }
  }
  if (asset != null) {
    String fileString = _parseAsset(asset);
    if (fileString.isNotEmpty) {
      File(genFilepath).writeAsString(fileString);
      print("saved generated code to $genFilepath");
      if (updateCode) {
        _updateCodeRefs(libPath, genFilepath);
      }
    }
  } else {
    print('asset was not loaded');
  }
}

String _prettyJsonEncode(Map<String, dynamic> jsonObject, {bool deepFormat = false}){
  String out = '{';
  bool first = true;
  for (MapEntry<String, dynamic> entry in jsonObject.entries) {
    if (!first) {
      out += ',';
    }
    out += '\n';
    out += '  "${entry.key}": {';
    if (entry.value is Map<String, dynamic>) {
      bool firstSub = true;
      for (MapEntry<String, dynamic> subentry in entry.value.entries) {
        if (!firstSub) {
          out += ',';
        }
        Map<String, dynamic> subMap = {};
        subMap.addEntries([subentry]);
        String valJson;
        if (entry.key == 'themes' || deepFormat) {
          valJson = _prettyJsonEncode(subMap, deepFormat: entry.key == 'themes');
          valJson = valJson.substring(1, valJson.length - 2);
          valJson = valJson.replaceAll('\n', '\n  ');
        } else {
          valJson = json.encode(subMap).replaceAll(':', ': ');
          valJson = valJson.substring(1, valJson.length - 1);
          out += '\n';
        }
        out += '    ${valJson}';
        firstSub = false;
      }
    } else {
      out += '    ${json.encode(entry.value)}\n';
    }
    out += '\n';
    out += '  }';
    first = false;
  }
  out += '\n';
  out += '}';
  return out;
}

Map<String, dynamic> _mergeJson(Map<String, dynamic>? from, Map<String, dynamic>? to) {
  to ??= {};
  Map<String, dynamic> out = {};
  out.addAll(to);
  for (MapEntry<String, dynamic> section in from?.entries ?? {}) {
    if (!out.containsKey(section.key)) {
      out[section.key] = {};
    }

    if (section.value is Map<String, dynamic>) {
      for (MapEntry<String, dynamic> entry in section.value.entries ?? {}) {
        dynamic outSection = out[section.key];
        if (!outSection.containsKey(entry.key)) {
          print("added ${section.key}: ${entry.key} = ${entry.value}");
          out[section.key][entry.key] = entry.value;
        }
      }
    } else {
      print("unexpected section type: ${section.value}");
    }
  }

  return out;
}

String _parseAsset(Map<String, dynamic> asset) {
  List<String> classStrings = [];
  for (MapEntry<String, dynamic> entry in asset.entries) {
    if (entry.value is Map<String, dynamic>) {
      String? classString = _buildClass(entry.key, entry.value);
      if (classString != null) {
        classStrings.add(classString);
      }
    } else {
      print("unexpected structure type: ${entry.value}");
    }
  }
  return _buildFile(classStrings);
}

String? _buildClass(String name, Map<String, dynamic> json) {
  String? className = classMap[name];
  String? type = typesMap[name];
  String? ref = refsMap[name];
  if (className == null || type == null || ref == null) {
    return null;
  }

  String classString = "class $className {\n";
  for (MapEntry<String, dynamic> entry in json.entries) {
    String varName = camelCase(entry.key);
    String varRef = ref.replaceAll("%key", "'${entry.key}'");
    String? defaultObj = defaultFuncs[name]?.call(name, entry, data: json);
    String defaultObjString = defaultObj != null ? ' ?? $defaultObj' : '';
    classString += "    static $type get $varName => $varRef$defaultObjString;\n";
    replacements[varRef] = '$className.$varName';
  }
  classString += "}\n";
  return classString;
}

String? _buildDefaultClass(String name, MapEntry<String, dynamic> entry, {Map<String, String>? classFields, Map<String, dynamic>? data}) {
  String? type = typesMap[name];
  if (type == null) {
    return null;
  }

  dynamic value = entry.value;
  if (value is Map<String, dynamic>) {
    String? extendsKey = value['extends'];
    if (extendsKey != null) {
      dynamic extendsMap = data?[extendsKey];
      if (extendsMap is Map<String, dynamic>) {
        _mergeMaps(extendsMap, value);
        value = extendsMap;
      }
    }
    String params = '';
    for (MapEntry<String, dynamic> entry in value.entries) {
      String enumType = '';
      if (classFields != null) {
        String? field = classFields[entry.key];
        if (field != null) {
          if (params.isNotEmpty) {
            params += ', ';
          }
          List<String> fields = field.split(':');
          if (fields.length == 2) {
            params += fields[0];
            enumType = '${fields[1]}.';
          } else {
            params += field;
          }
        } else {
          continue;
        }
      } else {
        params += camelCase(entry.key);
      }
      String? styleClass = classMap[entry.key];
      if (styleClass != null) {
        params += ': $styleClass.${camelCase(entry.value)}';
      } else {
        params += ': $enumType${entry.value}';
      }
    }
    return "$type($params)";
  }
  return null;
}

String? _buildDefaultColor(String name, MapEntry<String, dynamic> entry, {Map<String, dynamic>? data}) {
  dynamic value = entry.value;
  if (value is String ) {
    value = value.replaceFirst('#', '');
    if (value.length == 6) {
      value = 'FF' + value;
    }
    return 'const Color(0x$value)';
  }
  return null;
}

String? _buildDefaultString(String name, MapEntry<String, dynamic> entry, {Map<String, dynamic>? data}) {
  if (entry.value is String) {
    return "'${entry.value}'";
  }
  return null;
}

String? _buildDefaultImage(String name, MapEntry<String, dynamic> entry, {Map<String, dynamic>? data}) {
  return 'UiImage(spec: ImageSpec.fromJson(${json.encode(entry.value)}))';
}

String _buildFile(List<String> classStrings) {
  String fileString = "// Code generated by plugin/utils/gen_styles.dart DO NOT EDIT.\n\n";
  fileString += "import 'package:rokwire_plugin/service/styles.dart';\n";
  fileString += "import 'package:rokwire_plugin/ui/widgets/ui_image.dart';\n";
  fileString += "import 'package:flutter/material.dart';\n";
  fileString += "\n";
  fileString += classStrings.join("\n");
  return fileString;
}

Future<Map<String, dynamic>?> _loadFileJson(String filepath) async {
  try {
    String content = File(filepath).readAsStringSync();
    return json.decode(content);
  } catch (e) {
    print(e);
  }
  return null;
}

void _updateCodeRefs(String libPath, String genFilepath) async {
  print('updating code references...');
  final dir = Directory(libPath);
  List allContents = dir.listSync(recursive: true);
  for (FileSystemEntity entity in allContents) {
    if (entity is File && entity.path != genFilepath) {
      print('processing file ${entity.path}');
      String data = entity.readAsStringSync();
      for (MapEntry<String, String> replacement in replacements.entries) {
        data = data.replaceAll(replacement.key, replacement.value);
      }
      entity.writeAsStringSync(data);
    }
  }
}

void _mergeMaps(Map<String, dynamic> dest, Map<String, dynamic>? src) {
  src?.forEach((String key, dynamic val) {
    dest[key] = val;
  });
}