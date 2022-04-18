# Changelog
All notable changes to this library will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
### Changed
- Group service: linkEventToGroup implements members param [#1487](https://github.com/rokwire/illinois-app/issues/1487).
- GroupPost implements members param [#1450](https://github.com/rokwire/illinois-app/issues/1450).
- Group service: implement loadGroupEventMemberSelection [#1519](https://github.com/rokwire/illinois-app/issues/1519).
- Provide possibility for skipping notification when privacy level is changed [#63](https://github.com/rokwire/app-flutter-plugin/issues/63).
- Do not skip sending notification when changing privacy level [#65](https://github.com/rokwire/app-flutter-plugin/issues/65).
- Update favorite icon availability for privacy level 4+ [#68](https://github.com/rokwire/app-flutter-plugin/issues/68).
### Fixed
- Fixed crash on activity destroy in Android native side (#50).
- Image rotation before upload [#58](https://github.com/rokwire/app-flutter-plugin/issues/58).
### Added
- Get, Create, Update and Delete user's profile picture [#53](https://github.com/rokwire/app-flutter-plugin/issues/53).
- Send notification when user changes profile picture [#61](https://github.com/rokwire/app-flutter-plugin/issues/61).

## [1.0.0] - 2022-03-15
### Changed
- Updated homepage and author details in rokwire_plugin.podspec [#34](https://github.com/rokwire/app-flutter-plugin/issues/34).
### Added
- Added miscelanious controls to UI section [#2](https://github.com/rokwire/app-flutter-plugin/issues/2).
 
## [0.0.3] - 2022-03-17
### Fixed
- Wait for applyLogin in Auth2.processLoginResponse [#46](https://github.com/rokwire/app-flutter-plugin/issues/46).

## [0.0.2] - 2022-03-07
### Added
- OIDC auth result codes [#25](https://github.com/rokwire/app-flutter-plugin/issues/25).
- Add auth requests to new Core BB endpoints [#19](https://github.com/rokwire/app-flutter-plugin/issues/19).
- Group rules in FlexUI [#18](https://github.com/rokwire/app-flutter-plugin/issues/18).
- Fix issues with account linking [#11](https://github.com/rokwire/app-flutter-plugin/issues/11).
- Added capability to filter staled analytics packets before sending them to log service [#4](https://github.com/rokwire/app-flutter-plugin/issues/4).
- Added miscelanious controls to UI section [#2](https://github.com/rokwire/app-flutter-plugin/issues/2).
- Added progress capability to RoundedButton [#29](https://github.com/rokwire/app-flutter-plugin/issues/29).
### Changed
- Allow more functions in services to be overridden [#1](https://github.com/rokwire/app-flutter-plugin/issues/1).
- Content expose method uploadImage() [#1375](https://github.com/rokwire/illinois-app/issues/1375).
### Fixed
- Match Core BB JSON keys in Auth Profile [#22](https://github.com/rokwire/app-flutter-plugin/issues/22).
- Fixed crash in FlexContentWidget when no buttons definition persists.
- Android: plugin initialization [#27](https://github.com/rokwire/app-flutter-plugin/issues/27).
- Do not acknowledge pending membership in FlexUI [#31](https://github.com/rokwire/app-flutter-plugin/issues/31).

## [0.0.1] - 2022-02-07
### Added
- Rokwire plugin moved in own GIT repo [#1203](https://github.com/rokwire/illinois-app/issues/1203).


