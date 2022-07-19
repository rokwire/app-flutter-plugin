# Changelog
All notable changes to this library will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
<!-- Next build on `develop` should refer to version 1.1.0 -->
### Changed
- Added GeoFence location rules in FlexUI [#62](https://github.com/rokwire/app-flutter-plugin/issues/62).
- GeoFence service updated to load regions from content BB [#91](https://github.com/rokwire/app-flutter-plugin/issues/91).
- Cleaned up Favorites, prepare for UIUC 4 features [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Preserve the order of Favorite items [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- StringUtils.capitalize extended to process sentences [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Removed Group polls hook methods [#1679](https://github.com/rokwire/app-flutter-plugin/issues/1679).
- Do not delete automatically empty favorites sections [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Updated Groups.reportAbuse API [1854](https://github.com/rokwire/illinois-app/issues/1854).
- Update inbox Sent By message [#1958](https://github.com/rokwire/illinois-app/issues/1958).
- Check Post Nudges for list of group names or group with wild card [#113](https://github.com/rokwire/app-flutter-plugin/issues/113).
- Updated format of Favorite.toString [#2052](https://github.com/rokwire/illinois-app/issues/2052).
### Fixed
- Fixed auth2AnonymousId storage key [#79](https://github.com/rokwire/app-flutter-plugin/issues/79).
- Handle "leftToRight" horizontal direction in TrianglePainter widget [#83](https://github.com/rokwire/app-flutter-plugin/issues/83).
- Update UserGroups when group firebase message is fired [#1605](https://github.com/rokwire/illinois-app/issues/1605).
- Fixed FlexUI service dependency [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Fixed equality check in Auth2UserProfile.setFavorites [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Send correct "ids" parameter when loading content items [#106](https://github.com/rokwire/app-flutter-plugin/issues/106).
### Added
- Acknowledge the field for hidden group [#81](https://github.com/rokwire/app-flutter-plugin/issues/81).
- Update Group API to hook polls  [#1617](https://github.com/rokwire/illinois-app/issues/1617).
- Added API call for content items [#1636](https://github.com/rokwire/illinois-app/issues/1636)
- Group Attendance [#94](https://github.com/rokwire/app-flutter-plugin/issues/94).
- Cache attended group members [#94](https://github.com/rokwire/app-flutter-plugin/issues/94).
- Added access to FlexUI content source [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Added methods for updating entire category of favorites [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- StringUtils.capitalize extended with custom delimters [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Added FavoriteItem class [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Expose getter for user's first name [#102](https://github.com/rokwire/app-flutter-plugin/issues/102).
- Added DayPart parser utility to DateTimeUtils [#1822](https://github.com/rokwire/illinois-app/issues/1822).
- Added Groups.reportAbuse API [#1847](https://github.com/rokwire/illinois-app/issues/1847).
- Added DateTimeUtils util methods [#1692](https://github.com/rokwire/illinois-app/issues/1692).
- Added debugDisplayName getter in Service interface [#1869](https://github.com/rokwire/illinois-app/issues/1869).
- Load group post templates from the backend [#108](https://github.com/rokwire/app-flutter-plugin/issues/108).
- Added ListUtils.entry helper.
- Added delete API to Polls [#1954](https://github.com/rokwire/illinois-app/issues/1954).
- Defined equality operators to Event and Poll [#2020](https://github.com/rokwire/illinois-app/issues/2020).

## [1.0.2] - 2022-04-27
### Changed
- Bring back the old Polls BB [#76](https://github.com/rokwire/app-flutter-plugin/issues/76).

## [1.0.1] - 2022-04-20
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
- Integrate new Polls BB [#70](https://github.com/rokwire/app-flutter-plugin/issues/70).

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


