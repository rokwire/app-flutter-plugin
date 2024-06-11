# rokwire_plugin

Rokwire services Flutter plugin for Flutter bases client applications. Powered by the [Rokwire Platform](https://rokwire.org/).

## Requirements

### [Flutter](https://flutter.dev/docs/get-started/install) v3.22.2

### [Android Studio](https://developer.android.com/studio) 2021.3.1+

### [xCode](https://apps.apple.com/us/app/xcode/id497799835) 14.2

### [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) 1.11.3+

## Sub-modules

### Make sure font_awesome_flutter repo persists
Rokwire font_awesome_flutter directory is used by the Rokwire plugin for custom implementation of font_awesome_flutter plugin. It should be located in the `plugins/font_awesome_flutter` subdirectory of the plugin's root project directory. If it does not exist you need to clone it manually.
```
cd app-flutter-plugin/plugins
git clone https://github.com/rokwire/font_awesome_flutter.git font_awesome_flutter
```

#### Note:
If `font_awesome_flutter` pro repo is not available then use the regular `font_awesome_flutter` plugin in pubspec.yaml:
```
font_awesome_flutter: ^10.6.0

...
# dependency_overrides:
#  font_awesome_flutter:
#    path: plugins/font_awesome_flutter
```

## Integration

### Add this repo as submodule of the main repo
```
git submodule add https://github.com/rokwire/services-flutter-pligin.git <plugin-name>
```

### Add dependency of rokwire_plugin in pubspec.yaml of the main project
```
  rokwire_plugin:
    path: <plugin-name>
```
