# rokwire_plugin

Rokwire services Flutter plugin for Flutter bases client applications. Powered by the [Rokwire Platform](https://rokwire.org/).

## Requirements

### [Flutter](https://flutter.dev/docs/get-started/install) v3.3.2

### [Android Studio](https://developer.android.com/studio) 2021.3.1+

### [xCode](https://apps.apple.com/us/app/xcode/id497799835) 14.2

### [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) 1.11.3+

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

## Tools
This plugin provides several tools that make it easier to use and manage the functionality it provides

### Generating Static Style Types
The `tools/gen_styles.dart` tool can be used to generate classes from the `styles.json` asset which 
expose static references that can be easily accessed programmatically. To use this tool, navigate
to the root directory of your application and ensure that this plugin is cloned as a submodule in 
the `plugin` directory. Ensure that `assets/styles.json` is valid and up to date with your desired
changes. To use the tool, run the following command:

```
dart plugin/tools/gen_styles.dart
```

If successful, you will see a new or updates `gen/styles.dart` file available with the generated classes.
You can then import this file and use the included references throughout the application.

Note that this tool also includes a utility which can find and replace all existing references 
in the codebase with the new static class members. To use this util after generating the classes, 
run the following command:

```
dart plugin/tools/gen_styles.dart -u
```


