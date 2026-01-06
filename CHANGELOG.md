# Changelog
All notable changes to this library will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
<!-- The next version number should be the version already set in pubspec.yaml -->
### Changed
- Removed existing ListUtils sort utilities as unused, ListUtils.sort updated to sort a list copy [#5577](https://github.com/rokwire/illinois-app/issues/5577).
- Switched to load Groups V3 API [#5353](https://github.com/rokwire/illinois-app/issues/5353).
- Merged eventAdmin and administrative GroupFilterTypes [#5353](https://github.com/rokwire/illinois-app/issues/5353).
- Upgrade to http package 1.4.0 [#5562](https://github.com/rokwire/illinois-app/issues/5562).

## [1.12.1] - 2025-12-01
### Added
- Added Auth2UserPrefs.applyFoodFilters API for more precise filter updating [#5202](https://github.com/rokwire/illinois-app/issues/5202).
- Added Read More semantic label in ExpandableText [#4874](https://github.com/rokwire/illinois-app/issues/4874).
- Add AccessibleImageHolder to ModalPhotoImagePanel [#5439](https://github.com/rokwire/illinois-app/issues/5439).
- Added additional semantics properties to RibbonButton, some cleanup applied as well [#4874](https://github.com/rokwire/illinois-app/issues/4874).
- Improved AccessibleImageHolder and ModalImageHolder [#5548](https://github.com/rokwire/illinois-app/issues/5548).
- Added UrlUtils.stripQueryParameters
### Changed
- Make RibbonButton StatelessWidget, as it should be.
- StringUtils.intValue extended to parse string source values [#5526](https://github.com/rokwire/illinois-app/issues/5526).
### Fixed
- Fixed food filters setters in Auth2UserPrefs [#5202](https://github.com/rokwire/illinois-app/issues/5202).
- Fixed contrast accessibility issue for close button in ModalPhotoImagePanel  [#5429](https://github.com/rokwire/illinois-app/issues/5429).

## [1.12.0] - 2025-10-22
### Fixed
- Android: Fix various compilation warnings [#634](https://github.com/rokwire/app-flutter-plugin/issues/634).
- Fixed text color of ImageUtils.mapMarkerImage, removed "Group" from API name [#5344](https://github.com/rokwire/illinois-app/issues/5344).
- Fixed equality operator of Auth2Account.
### Added
- Added ListUtils.last() helper [#5344](https://github.com/rokwire/illinois-app/issues/5344).
- Added ListUtils.stripNull() helper [#5344](https://github.com/rokwire/illinois-app/issues/5344).
- Added reason parameter to notifyLogout notification [#5411](https://github.com/rokwire/illinois-app/issues/5411).
- Added Auth2UserPrefs.replaceFavorite API [#5344](https://github.com/rokwire/illinois-app/issues/5344).
- Added surfaceAccent2 entry to Style's colors map [#5344](https://github.com/rokwire/illinois-app/issues/5344).
- Аcknowledge content load/upload/delete API [#4836](https://github.com/rokwire/illinois-app/issues/4836).
- Added LinkedHashMapUtils [#5344](https://github.com/rokwire/illinois-app/issues/5344).
- Add file attachments to conversation messages [#639](https://github.com/rokwire/app-flutter-plugin/issues/639).
### Changed
- ImageUtils.mapGroupMarkerImage extended to handle pin and explore markers [#5344](https://github.com/rokwire/illinois-app/issues/5344).
- JsonUtils: If unable to perform a collection cast, try to build the collection manually [#5344](https://github.com/rokwire/illinois-app/issues/5344).
- WebPanel: Added back button to the default header bar, if no custom one provided [#5458](https://github.com/rokwire/illinois-app/issues/5458).

## [1.11.2] - 2025-09-18
### Changed
- Acknowledge Comment innerContext field and pass it when create/delete/load comments [#5356](https://github.com/rokwire/illinois-app/issues/5356).

## [1.11.1] - 2025-09-17
### Fixed
- Survey result rule evaluation issues [#637](https://github.com/rokwire/app-flutter-plugin/issues/637).
### Added
- Acknowledge Reaction innerContext field [#5238](https://github.com/rokwire/illinois-app/issues/5238).

## [1.11.0] - 2025-08-05
### Changed
- Android: upgrade compileSdkVersion and targetSdkVersion to 36 [#626](https://github.com/rokwire/app-flutter-plugin/issues/626).
- Upgrade dart sdk [#628](https://github.com/rokwire/app-flutter-plugin/issues/628).
### Added
- Added helper extensions for GlobalKey and double [#5271](https://github.com/rokwire/illinois-app/issues/5271).
- Added prospective student user role [#5270](https://github.com/rokwire/illinois-app/issues/5270).
- Added dropShadow color in Styles [#5289](https://github.com/rokwire/illinois-app/issues/5289).
- Added Content refreshContentItems public API [#5251](https://github.com/rokwire/illinois-app/issues/5251).
### Fixed
- Showing network images [#5240](https://github.com/rokwire/illinois-app/issues/5240).

## [1.10.3] - 2025-06-23
### Changed
- Event2TypeGroup.access renamed to visibility [#5241](https://github.com/rokwire/illinois-app/issues/5241).

## [1.10.2] - 2025-06-16
### Added
- Added Counts API to Events2 service, updated event filter enums implementations [#4890](https://github.com/rokwire/illinois-app/issues/4890).
- Allow managing events by group members [#610](https://github.com/rokwire/app-flutter-plugin/issues/610).

## [1.10.1] - 2025-05-28
### Added
- Added pollStatuses input paramter of Polls.getGroupPolls API [#5175](https://github.com/rokwire/illinois-app/issues/5175).

## [1.10.0] - 2025-05-27
### Added
- Create event with context, e.g. group event [#602](https://github.com/rokwire/app-flutter-plugin/issues/602).
### Fixed
- Fixed ModalImagePanel image zooming.
### Changed
- Change the way how we load individual recurring events [#4737](https://github.com/rokwire/illinois-app/issues/4737).
- Rename ModalImagePanel to ModalPinchZoomImagePanel, introduce ModalPhotoImagePanel and use it by default [#5165](https://github.com/rokwire/illinois-app/issues/5165).

## [1.9.0] - 2025-04-29
### Fixed
- Make sure to dispose TapGestureRecognizer objects.
- Fixed hexadecimal color utilities.
### Added
- Added user prefs data source in FlexUi [#4840](https://github.com/rokwire/illinois-app/issues/4840).
- Check if Tracking services are enabled [#572](https://github.com/rokwire/app-flutter-plugin/issues/572).
- Launch urls based on if Tracking services are enabled [#4898](https://github.com/rokwire/illinois-app/issues/4898).
- Added self-registration data & APIs to events model and service [#4888](https://github.com/rokwire/illinois-app/issues/4888).
- Added Event2PersonsResult.fromOther factory constructor [#4956](https://github.com/rokwire/illinois-app/issues/4956).
- Added optional mode paramter to UrlUtils.launchExternal [#4950](https://github.com/rokwire/illinois-app/issues/4950).
- Added UrlUtils.stripUrlScheme helper [#4950](https://github.com/rokwire/illinois-app/issues/4950).
- Added ability to override the default onTap processing in SurveyBuilder.surveyResponseCard [#5018](https://github.com/rokwire/illinois-app/issues/5018).
- Additional profile fields needed [#580](https://github.com/rokwire/app-flutter-plugin/issues/580).
- Added colors for library card photo border [#4916](https://github.com/rokwire/illinois-app/issues/4916).
### Changed
- Group content attributes split for groups and research projects [#5014](https://github.com/rokwire/illinois-app/issues/5014).
- Groups.loadGroups API loads user groups as regular groups content, some cleanup applied [#4835](https://github.com/rokwire/illinois-app/issues/4835).
- Upgrade to Flutter 3.29.2, upgraded plugin [#4899](https://github.com/rokwire/illinois-app/issues/4899).
- Updated Events2.eventDetailUrl parameter types.
- Extended NotificationService APIs [#576](https://github.com/rokwire/app-flutter-plugin/issues/576).
- Read deep links redirect url from separate config entry [#4888](https://github.com/rokwire/app-flutter-plugin/issues/4888).
- Set error builder to ImageSlantHeader [#4922](https://github.com/rokwire/app-flutter-plugin/issues/4922).
- Content Attributes cleaned up and extended to handle new Event Filters requirements [#4904](https://github.com/rokwire/illinois-app/issues/4904).
- PlatformUtils moved to plugin, extended with environment retrieval [#4950](https://github.com/rokwire/illinois-app/issues/4950).
- Implemented Event2 duplication API, make satellite classes immutable [#5013](https://github.com/rokwire/illinois-app/issues/5013).
- Events2.loadGroupEvents updated to get time filter parameter, cleaned up sort type setting [#5022](https://github.com/rokwire/illinois-app/issues/5022).
- Make Auth2UserProfile.fromFieldsVisibility a factory constructor [#5026](https://github.com/rokwire/illinois-app/issues/5026).

## [1.8.3] - 2025-03-12
### Added
- Created CompactRoundedButton widget [#4872](https://github.com/rokwire/illinois-app/issues/4872).

## [1.8.2] - 2025-03-06 
### Added
- Acknowledge new reaction API [#4613](https://github.com/rokwire/illinois-app/issues/4613).

## [1.8.1] - 2025-03-05 
### Fixed
- Fixed storage update support in FlexUi [#4830](https://github.com/rokwire/illinois-app/issues/4830).

## [1.8.0] - 2025-02-19
### Changed
- Allow event custom range filters in the past [#4450](https://github.com/rokwire/illinois-app/issues/4450).
- Added UiTextStyles.getTextStyleEx helper [#4402](https://github.com/rokwire/illinois-app/issues/4402).
- Added scheme parameter to UrlUtils.fixUrl [#4402](https://github.com/rokwire/illinois-app/issues/4402).
- Added StringUtils.firstNotEmpty helper [#4402](https://github.com/rokwire/illinois-app/issues/4402).
- Cleaned up Image & Audio Result data dispatch [#4402](https://github.com/rokwire/illinois-app/issues/4402).
- Standartized return type of loadUserPhoto and loadUserNamePronunciation [#4402](https://github.com/rokwire/illinois-app/issues/4402).
- Cleaned up social message deep link support [#4572](https://github.com/rokwire/illinois-app/issues/4572).
- Use the new groupings for events filtering [#543](https://github.com/rokwire/app-flutter-plugin/issues/543)
- Bring Admin functionality to UIUC app in progress [#4478](https://github.com/rokwire/illinois-app/issues/4478).
- Cleaned up delete user APIs [#4766](https://github.com/rokwire/illinois-app/issues/4766).
### Added
- Add last message info to conversation [#553](https://github.com/rokwire/app-flutter-plugin/issues/553)
- Add "Past" event filter [#546](https://github.com/rokwire/app-flutter-plugin/issues/546)
- Add notifications for editing/deleting conversation [#541](https://github.com/rokwire/app-flutter-plugin/issues/541)
- Add delete message support to Social BB [#534](https://github.com/rokwire/app-flutter-plugin/issues/534)
- Add support for editing messages on the social block [#529](https://github.com/rokwire/app-flutter-plugin/issues/529)
- Add deep links for messages [#516](https://github.com/rokwire/app-flutter-plugin/issues/516)
- Use Social BB for Posts, Comments and Reactions (task in progress) [#498](https://github.com/rokwire/app-flutter-plugin/issues/498).
- Acknowledge event.notification_settings field and APIs [#4478](https://github.com/rokwire/illinois-app/issues/4478).
- Prepared for directory content access and privacy edit in Core BB [#4402](https://github.com/rokwire/illinois-app/issues/4402).
- Added directory content access and privacy edit in Auth2 [#4402](https://github.com/rokwire/illinois-app/issues/4402).
- Removed voice recording caching in Auth2, improved user profiles coping and merging [#4402](https://github.com/rokwire/illinois-app/issues/4402).
- Added Messages model and service [#506](https://github.com/rokwire/app-flutter-plugin/issues/506).
- Added Socal.loadConversation API [#4536](https://github.com/rokwire/illinois-app/issues/4536).
- Added urls parameter to Auth2.loadDirectoryAccounts API [#4558](https://github.com/rokwire/illinois-app/issues/4558).
- Added URL caching support in DeepLink service, removed it from other services [#4561](https://github.com/rokwire/illinois-app/issues/4561).
- Acknowledge post replies count [#531](https://github.com/rokwire/app-flutter-plugin/issues/531).
- Added reference to app Storage settings in FlexUI [#4531](https://github.com/rokwire/illinois-app/issues/4531).
- Added DateTimeUtils.localDateTimeFileStampToString [#4605](https://github.com/rokwire/illinois-app/issues/4605).
- Added delimiter paramterer to StringUtils.fullName [#4605](https://github.com/rokwire/illinois-app/issues/4605).
- Added StringUtils.split API [#4695](https://github.com/rokwire/illinois-app/issues/4695).
- Added loadUserDataJson API to number of services, make old Response dispatch APIs private [#4264](https://github.com/rokwire/illinois-app/issues/4264).
- Acknowledge GroupSettings: "content_items": GroupContentItem.listToJson(contentItems) [4697](https://github.com/rokwire/illinois-app/issues/4697).
- Acknowledge Social: pinPost API [4629](https://github.com/rokwire/illinois-app/issues/4629).
### Fixed
- Update Social BB Deeplink to use Conversation instead of Post [#518](https://github.com/rokwire/app-flutter-plugin/issues/518).
- Fix Social service requests for messaging [#514](https://github.com/rokwire/app-flutter-plugin/issues/514).
- Fixed DeepLink.notifyUri API [#4561](https://github.com/rokwire/illinois-app/issues/4561).
- Do not call Content.initService twice [#4756](https://github.com/rokwire/illinois-app/issues/4756).
- Fixed loadResearchProjects for open research projects [#4699](https://github.com/rokwire/illinois-app/issues/4699).
  
## [1.7.4] - 2024-11-07
### Fixed
- Fixed possible unhandled exception when parsing URLs.

## [1.7.3] - 2024-10-23
### Changed
- Upgraded url_launcher plugin to resolve build issue on Xcode 16.
- Survey Card widgets color explicitly set to be white [#4385](https://github.com/rokwire/illinois-app/issues/4385).
### Fixed
- Link / Unlink event to group [#481](https://github.com/rokwire/app-flutter-plugin/issues/481).
### Added
- Added Places model and service [#475](https://github.com/rokwire/app-flutter-plugin/issues/475).
- Create a triangle header image widget [#488](https://github.com/rokwire/app-flutter-plugin/issues/488).
- Added deeplinking support to Places [#491](https://github.com/rokwire/app-flutter-plugin/issues/491).

## [1.7.2] - 2024-09-20
### Fixed
- Show sub-events for group members [#474](https://github.com/rokwire/app-flutter-plugin/issues/474).

### Added
- Added new Survey fields [#4243](https://github.com/rokwire/illinois-app/issues/4243).
- Created SurveysQueryParam class for surveys query model [#4243](https://github.com/rokwire/illinois-app/issues/4243).
- Created notification for deletion of survey response [#4243](https://github.com/rokwire/illinois-app/issues/4243).
- Exposed low level APIs in services for accessing My Stored Data [#4264](https://github.com/rokwire/illinois-app/issues/4264).
### Changed
- Upgraded outdated Flutter plugins [#4302](https://github.com/rokwire/illinois-app/issues/4302).
- Upgraded Flutter to 3.24.0 [#4302](https://github.com/rokwire/illinois-app/issues/4302).
### Fixed
- Android: crash on startup [#4320](https://github.com/rokwire/illinois-app/issues/4320).

## [1.7.1] - 2024-08-15
### Changed
- Upgrade Android app to target API level 34 and upgrade plugin versions to match that requirement [#464](https://github.com/rokwire/app-flutter-plugin/issues/464).
- Use ISO 8601/RFC 3339 strings for survey start & end dates [#4243](https://github.com/rokwire/illinois-app/issues/4243).
### Added
- Introduce Groups.acceptMembershipMulti [#4268](https://github.com/rokwire/illinois-app/issues/4268).

## [1.7.0] - 2024-07-15
### Changed
- Upgrade to Flutter 3.22.2.
- Upgrade to Flutter 3.19.0 [#435](https://github.com/rokwire/app-flutter-plugin/issues/435).
- Require minimal SDK version 2.17.0 [#445](https://github.com/rokwire/app-flutter-plugin/issues/445).
- Init application services in parallel [#408](https://github.com/rokwire/app-flutter-plugin/issues/408).
- SurveyPanel HeaderBar exposed for overriding [#4020](https://github.com/rokwire/illinois-app/issues/4020).
- Support for Group Report Abuse [#4038](https://github.com/rokwire/illinois-app/issues/4038).
- Extend customization of SliverAppBars [#3827](https://github.com/rokwire/illinois-app/issues/3827).
- Always check if RenderBox has size [#4125](https://github.com/rokwire/illinois-app/issues/4125).
- Upgrade to latest Firebase libraries [#4220](https://github.com/rokwire/illinois-app/issues/4220).
### Added
- Added Group post scheduling [#4027](https://github.com/rokwire/illinois-app/issues/4027).
- Added post type paramter to loadGroupPosts API [#441](https://github.com/rokwire/app-flutter-plugin/issues/441).
- Created additional notifications for group post create/update/delete [#441](https://github.com/rokwire/app-flutter-plugin/issues/441).
- Created separate classes for Auth2 permission, role and group, perform more precise permissions detection [#445](https://github.com/rokwire/app-flutter-plugin/issues/445).
- Added isEmpty & isNotEmpty properties to Event2RegistrationDetails [#4043](https://github.com/rokwire/illinois-app/issues/4043).
- Added events2 query deep link [#4041](https://github.com/rokwire/illinois-app/issues/4041).
- Exposed scope in content attributes [#4029](https://github.com/rokwire/illinois-app/issues/4029).
- Implemented conditional content attributes [#4134](https://github.com/rokwire/illinois-app/issues/4134).
- Acknowledge group.topPаrentId field [#4049](https://github.com/rokwire/illinois-app/issues/4049).
- Truncate notification [#4050](https://github.com/rokwire/illinois-app/issues/4050).
- Implement file content cache [#456](https://github.com/rokwire/app-flutter-plugin/issues/456)
- Created StringCompareGit4143 extension for non-standard lexicographic sorting [#4143](https://github.com/rokwire/illinois-app/issues/4143).
- Added clearSafariVC API to RokwirePlugin, do not use it for now.
- Add "prompt":"login" parameter to OIDC login URL in Debug mode only.
### Fixed
- Fixed client paramter in loadEventsEx invocation from loadEvents API.
- Make sure to always return successfully refreshed token in Auth2 service.
- Fixed Content service dependency [#447](https://github.com/rokwire/app-flutter-plugin/issues/447).
- Fixed RegExp definition for Git4143 canonical representation [#4143](https://github.com/rokwire/illinois-app/issues/4143).

## [1.6.3] - 2024-02-19
### Added
- Added group stats caching [#3829](https://github.com/rokwire/illinois-app/issues/3829).

## [1.6.2] - 2024-02-15
### Fixed
- Fixed tappable area of SliverToutHeaderBar back button [#3827](https://github.com/rokwire/illinois-app/issues/3827).

## [1.6.1] - 2024-02-14
### Fixed
- Fix content service storing files [#429](https://github.com/rokwire/app-flutter-plugin/issues/429).

## [1.6.0] - 2024-02-12
### Added
- Content service upload/retrieve/delete profile voice record [#3846](https://github.com/rokwire/illinois-app/issues/3846).
- Import and use Font Awesome Pro icons [#398](https://github.com/rokwire/app-flutter-plugin/issues/398).
- Favorite and admin entrues to Event2TypeFilter enum [#413](https://github.com/rokwire/app-flutter-plugin/issues/413).
- Added deep copy functionality to ContentAttributes [#3828](https://github.com/rokwire/illinois-app/issues/3828).
- Acknowledged new start_time_after_null_end_time and start_time_before_null_end_time event2 time filter paramters [#421](https://github.com/rokwire/app-flutter-plugin/issues/421).
- Added headerBar paramter to SurveyPanel constructor [#3876](https://github.com/rokwire/illinois-app/issues/3876).
- Added APIs for managing event groups on Groups BB [#423](https://github.com/rokwire/app-flutter-plugin/issues/423).
- Add get file content API [#425](https://github.com/rokwire/app-flutter-plugin/issues/425).
- Possibility for loading individual events [#3956](https://github.com/rokwire/illinois-app/issues/3956).
### Fixed
- Fixed image assets resolution [#400](https://github.com/rokwire/app-flutter-plugin/issues/400).
- Replaced textScaleFactor usage with textScaler [#406](https://github.com/rokwire/app-flutter-plugin/issues/406).
- Notify for success of add to calendar API, make sure to return right return value [#3789](https://github.com/rokwire/illinois-app/issues/3789).
- Cleaned up DeviceCalendar service [#415](https://github.com/rokwire/app-flutter-plugin/issues/415).
- Fixed ContentAttributeRequirements clone [#3828](https://github.com/rokwire/illinois-app/issues/3828).
### Changed
- Upgrade to Flutter 3.16.0 [#402](https://github.com/rokwire/app-flutter-plugin/issues/402)
- Extend AppToast functionality [#418](https://github.com/rokwire/app-flutter-plugin/issues/418)
- Allow static access to predefined colors and font styles in Styles [#418](https://github.com/rokwire/app-flutter-plugin/issues/418)
- Updated APIs for managing event groups on Groups BB [#423](https://github.com/rokwire/app-flutter-plugin/issues/423).

## [1.5.4] - 2023-10-06
### Changed
- Set default preferences when user signs in [#393](https://github.com/rokwire/app-flutter-plugin/issues/393).

## [1.5.3] - 2023-09-27
### Changed
- Acknowledged new Groups BB's API person identifier resolving [#387](https://github.com/rokwire/app-flutter-plugin/issues/387).

## [1.5.2] - 2023-09-26
### Changed
- Acknowledged new Groups BB's v3 APIs for events [#384](https://github.com/rokwire/app-flutter-plugin/issues/384).

## [1.5.1] - 2023-09-20
### Changed
- Acknowledge 'time' field for inbox messages [#381](https://github.com/rokwire/app-flutter-plugin/issues/381).

## [1.5.0] - 2023-09-19
### Changed
- Load content attributes JSON from content service [#280](https://github.com/rokwire/app-flutter-plugin/issues/280).
- Load different JSON assets from content service [#280](https://github.com/rokwire/app-flutter-plugin/issues/280).
- Retire Assets service [#280](https://github.com/rokwire/app-flutter-plugin/issues/280).
- Created and acknowledged at different places async versions of JSON encode/decode and collection equality checks [#283](https://github.com/rokwire/app-flutter-plugin/issues/283).
- Move survey and rules logic from models to services [#232](https://github.com/rokwire/app-flutter-plugin/issues/232).
- Cleaned up Explore interface [#289](https://github.com/rokwire/app-flutter-plugin/issues/289).
- Load again content attributes JSON from content service [#359](https://github.com/rokwire/app-flutter-plugin/issues/359).
- Build event time filters in local timezone [#377](https://github.com/rokwire/app-flutter-plugin/issues/377).
- Upgrade to connectivity_plus [#45](https://github.com/rokmetro/vogue-app/issues/45).
### Added
- Survey creation tool [#263](https://github.com/rokwire/app-flutter-plugin/issues/263).
- Added support for material icons to styles images [#292](https://github.com/rokwire/app-flutter-plugin/issues/292).
- Events2 model and service, work in progress [#288](https://github.com/rokwire/app-flutter-plugin/issues/288).
- Added client parameter to Events2.loadEvents and Network.post APIs [#3401](https://github.com/rokwire/illinois-app/issues/3401).
- Defined scopes for profile & prefs for transfer anonymous data to existing user account [#332](https://github.com/rokwire/app-flutter-plugin/issues/332).
- Add query params to load surveys [#340](https://github.com/rokwire/app-flutter-plugin/issues/340).
- More dynamic survey response cards [#344](https://github.com/rokwire/app-flutter-plugin/issues/344).
- Added scope to content attributes global requirements [#349](https://github.com/rokwire/app-flutter-plugin/issues/349).
- Initial handling of super and recurring events [#351](https://github.com/rokwire/app-flutter-plugin/issues/351).
- Added progress to SectionSlantHeader [#351](https://github.com/rokwire/app-flutter-plugin/issues/351).
- Added get all survey responses request [#354](https://github.com/rokwire/app-flutter-plugin/issues/354).
- Added "Multi-person" event type [#356](https://github.com/rokwire/app-flutter-plugin/issues/356).
- Added language selection capability to Localization service [#361](https://github.com/rokwire/app-flutter-plugin/issues/361).
- Acknowledge new event2 model for sport events [#363](https://github.com/rokwire/app-flutter-plugin/issues/363).
- Added HEAD request in Network service [#3580](https://github.com/rokwire/illinois-app/issues/3580).
- Added UrlUtils.fixUriAsync helper [#3580](https://github.com/rokwire/illinois-app/issues/3580).
- Added published flag to event [#369](https://github.com/rokwire/app-flutter-plugin/issues/369).
- Added Pinch Zoom support for ModalImagePanel [#3305](https://github.com/rokwire/illinois-app/issues/3305).
- Override survey action summary [#373](https://github.com/rokwire/app-flutter-plugin/issues/373)
- Added registrationOccupancy to Event2PersonsResult and relevant utility methods [#375](https://github.com/rokwire/app-flutter-plugin/issues/375).
### Fixed
- Upgrade dependencies for Flutter v3.10 [#285](https://github.com/rokwire/app-flutter-plugin/issues/285)
- Survey maximum score JSON encoding error [#294](https://github.com/rokwire/app-flutter-plugin/issues/294)
- Only return null on unsuccessful survey responses request [#349](https://github.com/rokwire/app-flutter-plugin/issues/349)
- Local notifications repeating weekly [#365](https://github.com/rokwire/app-flutter-plugin/issues/365)
- Groups load upcoming events [#3645](https://github.com/rokwire/illinois-app/issues/3645).
- String representation for "Attendance taker" event user role [#3656](https://github.com/rokwire/illinois-app/issues/3656).
- Display raw attribute value as it is if it does not persist as content attribite value [#3743](https://github.com/rokwire/illinois-app/issues/3743).

## [1.4.0] - 2023-05-12
### Fixed
- Handle exceptions that Geolocator.getCurrentPosition could throw. 
- Fixed processing analyticsUrl when sending notifyHttpResponse notification for Analytics [#266](https://github.com/rokwire/app-flutter-plugin/issues/266).
- Fixed taps processing on Read More expandable text [#269](https://github.com/rokwire/app-flutter-plugin/issues/269).
### Changed
- Content attributes prepared for multiple scopes support [#265](https://github.com/rokwire/app-flutter-plugin/issues/265).
- Use Core Url host to test online status in web panel [#271](https://github.com/rokwire/app-flutter-plugin/issues/271).
- UrlUtis.isHostAvailable exposed to public [#3052](https://github.com/rokwire/illinois-app/issues/3052).
- Updated TZDateTimeUtils [#3225](https://github.com/rokwire/illinois-app/issues/3225).
- Always post "research_group" POST paramter in v2/groups and v2/user/groups API calls [#275](https://github.com/rokwire/app-flutter-plugin/issues/275).
### Added
- Added footer widget in ExpandableText [#3055](https://github.com/rokwire/illinois-app/issues/3055).
- Added Uri fix utility [#3112](https://github.com/rokwire/illinois-app/issues/3112).
- Added NotificationService.subscribers getter [#3070](https://github.com/rokwire/illinois-app/issues/3070).
- Added UrlUtils.launchExternal [#3129](https://github.com/rokwire/illinois-app/issues/3129).
- Added UrlUtils.isValidUrl [#3193](https://github.com/rokwire/illinois-app/issues/3193).
- Added DateTimeUtils.min & max [#3206](https://github.com/rokwire/illinois-app/issues/3206).
- Added title parameters to SliverToutHeaderBar [#3149](https://github.com/rokwire/illinois-app/issues/3149).
- Created TZDateTimeUtils [#3215](https://github.com/rokwire/illinois-app/issues/3215).
- Created DateTimeUni extention [#3215](https://github.com/rokwire/illinois-app/issues/3215).
- Exposed DateTimeUni.timezoneUniOrLocal [#3222](https://github.com/rokwire/illinois-app/issues/3222).
- Username authentication [#273](https://github.com/rokwire/app-flutter-plugin/issues/273)

### Deleted
- Removed ExploreJsonHandler definition, not used any more [#3070](https://github.com/rokwire/illinois-app/issues/3070).
- Removed Explore.toJson definition, not used any more [#3070](https://github.com/rokwire/illinois-app/issues/3070).

## [1.3.2] - 2023-02-16
### Changed
- Switch to xCode 14.2.
- Delete poll notification is not a lifecycle notification any more [#2173](https://github.com/rokwire/illinois-app/issues/2173).
- Improve default handling for UIImages [#193](https://github.com/rokwire/app-flutter-plugin/issues/193).
- Added miscellaneous helpers for GoogleMap plugin [#243](https://github.com/rokwire/app-flutter-plugin/issues/243).
- Group filters renamed to attributes [#246](https://github.com/rokwire/app-flutter-plugin/issues/246).
- Group's category and tags replaced by attributes [#246](https://github.com/rokwire/app-flutter-plugin/issues/246).
- Updated Group's attributes logic [#256](https://github.com/rokwire/app-flutter-plugin/issues/256).
- Updated Group's attributes logic [#259](https://github.com/rokwire/app-flutter-plugin/issues/259).
### Fixed
- Clear unread notifications count when logged out.
- Formatting date times when using device local time zone [#240](https://github.com/rokwire/app-flutter-plugin/issues/240).
- Fixed Groups copy constructor [#246](https://github.com/rokwire/app-flutter-plugin/issues/246).
### Added
- Added hint in VerticalTitleValueSection [#2892](https://github.com/rokwire/illinois-app/issues/2892).
- Acknowledge the new group date fields [#244](https://github.com/rokwire/app-flutter-plugin/issues/244).
- Added group filters [#246](https://github.com/rokwire/app-flutter-plugin/issues/246).
- Added filters filter to all groups GET request  [#246](https://github.com/rokwire/app-flutter-plugin/issues/246).
- Load poll by id [#2645](https://github.com/rokwire/illinois-app/issues/2645).
- TextStyle acknowledge extends, override and inherit fields. Supports extending of existing styles [#2932](https://github.com/rokwire/illinois-app/issues/2932).
- Added content attributes support to pluging [#246](https://github.com/rokwire/app-flutter-plugin/issues/246).
- Handle multiple encryption keys for limited secret access [#254](https://github.com/rokwire/app-flutter-plugin/issues/254)

## [1.3.1] - 2023-01-03
### Deleted
- Removed category from inbox message model [#237](https://github.com/rokwire/app-flutter-plugin/issues/237).

## [1.3.0] - 2022-12-22
### Fixed
- Fix launchUrlString LaunchMode [#167](https://github.com/rokwire/app-flutter-plugin/issues/167).
- Move "getContentString" method to Localization service [#136](https://github.com/rokwire/app-flutter-plugin/issues/136).
- Improve SectionSlantHeader [#211](https://github.com/rokwire/app-flutter-plugin/issues/211).
- Crash in header bar widget [#2654](https://github.com/rokwire/illinois-app/issues/2654).
- Crash on tapping image in detail panels [#223](https://github.com/rokwire/app-flutter-plugin/issues/223).
- Survey bug fixes [#219](https://github.com/rokwire/app-flutter-plugin/issues/219)
- Privacy level is not getting saved property [#222](https://github.com/rokwire/app-flutter-plugin/issues/222)
- Missing close button from ModalImagePanel[#227](https://github.com/rokwire/app-flutter-plugin/issues/227).
- Fixed Groups.notifyGroupCreated notification param [#2683](https://github.com/rokwire/illinois-app/issues/2683).
- Hide "Vote" button after user selectes all options in a poll [#2776](https://github.com/rokwire/illinois-app/issues/2776).
- Improve accessibility for surveys [#234](https://github.com/rokwire/app-flutter-plugin/issues/234)
### Added
- Image/icon abstraction [#145](https://github.com/rokwire/app-flutter-plugin/issues/145)
- Added TextStyle capability to pass custom metadata values like color or height [#2311](https://github.com/rokwire/illinois-app/issues/2311).
- Added TextStyle properties to Styles service. Added: decoration and wordSpacing [#2311](https://github.com/rokwire/illinois-app/issues/2311).
- Search group by name support hidden groups [#2403](https://github.com/rokwire/illinois-app/issues/2403).
- Added answers section to Auth2UserProfile [#174](https://github.com/rokwire/app-flutter-plugin/issues/174).
- Intermediate work on "muted" and "unread" notifications [#177](https://github.com/rokwire/app-flutter-plugin/issues/177).
- Add survey UI components [#161](https://github.com/rokwire/app-flutter-plugin/issues/161).
- Introduce ModalImageHolder widget  [#2474](https://github.com/rokwire/illinois-app/issues/2474).
- Introduced research projects [#178](https://github.com/rokwire/app-flutter-plugin/issues/178).
- Survey rules local notifications action [#179](https://github.com/rokwire/app-flutter-plugin/issues/179)
- Acknowledge group member's notification preferences [#198](https://github.com/rokwire/app-flutter-plugin/issues/198)
- Added researchConfirmation flag to Groups [#202](https://github.com/rokwire/app-flutter-plugin/issues/202).
- Survey rules remote notification action [#188](https://github.com/rokwire/app-flutter-plugin/issues/188)
- Added API for loading target audience count in Groups service [#2544](https://github.com/rokwire/illinois-app/issues/2544).
- Implement "Mark all as read" [#2570](https://github.com/rokwire/illinois-app/issues/2570).
- Survey improvements for BESSI [#206](https://github.com/rokwire/app-flutter-plugin/issues/206)
- Add additional group settings [#2619](https://github.com/rokwire/illinois-app/issues/2619).
- Delete survey responses request [#210](https://github.com/rokwire/app-flutter-plugin/issues/210).
- Support font family references in text styles [#213](https://github.com/rokwire/app-flutter-plugin/issues/213).
- Added Explore.exploreLocationDescription interface [#2633](https://github.com/rokwire/illinois-app/issues/2633).
- Support for FlexUI-based access widget [#229](https://github.com/rokwire/app-flutter-plugin/issues/229).
- Fire local notification when message is read [#2833](https://github.com/rokwire/illinois-app/issues/2833).
### Deleted
- Removed Auth2.canFavorite [#2325](https://github.com/rokwire/illinois-app/issues/2325).
- Removed UserRole.resident [#2547](https://github.com/rokwire/illinois-app/issues/2547).
### Changed
- Optimized Groups /user/login API call [#141](https://github.com/rokwire/app-flutter-plugin/issues/141).
- Android: Upgrade compileSdkVersion to 32 [#147](https://github.com/rokwire/app-flutter-plugin/issues/147).
- Upgrade project to build with flutter 3.3.2 [#158](https://github.com/rokwire/app-flutter-plugin/issues/158).
- Applied preliminary work on multiple brands support [#149](https://github.com/rokwire/app-flutter-plugin/issues/149).
- Updated version of firebase_messaging plugin [#2446](https://github.com/rokwire/illinois-app/issues/2446).
- Store research questionnaire answers in account profile [#181](https://github.com/rokwire/app-flutter-plugin/issues/181).
- Cleaned up group model.
- Hook Notifications BB message model changes [#2530](https://github.com/rokwire/illinois-app/issues/2530).
- Researh Project updates in group model [#204](https://github.com/rokwire/app-flutter-plugin/issues/204).
- Filter open resource projects not to include projects where the current user is member, disable paging until this gets resolved on the backend [#2540](https://github.com/rokwire/illinois-app/issues/2540).
- Acknowledged 'exclude_my_groups' parameter for loading open research projects [#2540](https://github.com/rokwire/illinois-app/issues/2540).
- Omit null title/value in VerticalTitleValueSection [#2542](https://github.com/rokwire/illinois-app/issues/2542).
- ExploreLocation updated from ExplorePOI [#220](https://github.com/rokwire/app-flutter-plugin/issues/220).
- Introduce Surveys BB [#230](https://github.com/rokwire/app-flutter-plugin/issues/230)
- Acknowledge the new fields "mute" and "read" for InboxMessage [#2778](https://github.com/rokwire/illinois-app/issues/2778).
- Read messages count from a proper json field [#2833](https://github.com/rokwire/illinois-app/issues/2833).

## [1.2.4] - 2022-09-30
### Added
- Check if user has 'managed_group_admin' permission [#2429](https://github.com/rokwire/illinois-app/issues/2429).

## [1.2.3] - 2022-09-28
### Changed
- Show hidden groups only for admins - hide for all others [#163](https://github.com/rokwire/app-flutter-plugin/issues/163).

## [1.2.2] - 2022-09-16
### Added
- Search group by name support hidden groups [#2403](https://github.com/rokwire/illinois-app/issues/2403).

## [1.2.1] - 2022-09-13
### Added
- Load single group post by id [#2344](https://github.com/rokwire/illinois-app/issues/2344).
- Created AppNotification service [#143](https://github.com/rokwire/app-flutter-plugin/issues/143).
- Add reactions to group posts [#151](https://github.com/rokwire/app-flutter-plugin/issues/151)
### Changed
- Acknowledge "can_poll" in nudges data model [#2365](https://github.com/rokwire/illinois-app/issues/2365).
### Fixed
- Fixed text overflow in TabWidget [#152](https://github.com/rokwire/app-flutter-plugin/issues/152).

## [1.2.0] - 2022-08-15
### Fixed
- Use simple getter for deep link redirect url [#2065](https://github.com/rokwire/illinois-app/issues/2065).
- Properly convert colors that contain adjacent zeros [#122](https://github.com/rokwire/app-flutter-plugin/issues/122).
### Changed
- Allow referring string values from app config in FlexUI service [#118](https://github.com/rokwire/app-flutter-plugin/issues/118).
- Added Auth2UserPres.setFavorite method; use Iterable inetead of List for muliple favorites paramter [#2065](https://github.com/rokwire/illinois-app/issues/2065).
- FlexUI extended with content entry switch and multiple {content, rules} sets in single source  [#121](https://github.com/rokwire/app-flutter-plugin/issues/121).
- Acknowledged new paramters of 'report/abuse' API of Groups BB [#2083](https://github.com/rokwire/illinois-app/issues/2083).
- Refresh Auth2 account object instead of profile and prefs separately [#132](https://github.com/rokwire/app-flutter-plugin/issues/132).
- Updated format of settings APIs in Auth2UserPrefs [#2194](https://github.com/rokwire/illinois-app/issues/2194).
- Do not load all groups on portions (paging) [#125](https://github.com/rokwire/app-flutter-plugin/issues/125).
### Added
- Differ multi events and events that last more than one day [#126](https://github.com/rokwire/app-flutter-plugin/issues/126).
- Added Config().appStoreId getter [#2162](https://github.com/rokwire/illinois-app/issues/2162).
- Added MapUtils.get2 helper [#2169](https://github.com/rokwire/illinois-app/issues/2169).
- Check if event ends in the same year as it starts [#128](https://github.com/rokwire/app-flutter-plugin/issues/128).
- Load groups and members on portions (e.g. paging) [#125](https://github.com/rokwire/app-flutter-plugin/issues/125).
- Added system configs in Auth2Account [#132](https://github.com/rokwire/app-flutter-plugin/issues/132).
- Added int settings getter in Auth2UserPrefs [#2207](https://github.com/rokwire/illinois-app/issues/2207).
- Added config settings refs support for FlexUI enabled rules [#2210](https://github.com/rokwire/illinois-app/issues/2210).


## [1.1.0] - 2022-07-19
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
- Remove check for attendance group for authman sync call [#115](https://github.com/rokwire/app-flutter-plugin/issues/115).
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


