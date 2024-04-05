/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:collection';
import 'dart:core';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';

import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'firebase_messaging.dart';

enum GroupsContentType { all, my }
enum ResearchProjectsContentType { open, my }

class Groups with Service implements NotificationsListener {

  static const String notifyUserGroupsUpdated         = "edu.illinois.rokwire.groups.user.updated";
  static const String notifyUserMembershipUpdated     = "edu.illinois.rokwire.groups.membership.updated";
  static const String notifyGroupEventsUpdated        = "edu.illinois.rokwire.groups.events.updated";
  static const String notifyGroupStatsUpdated         = "edu.illinois.rokwire.group.stats.updated";
  static const String notifyGroupCreated              = "edu.illinois.rokwire.group.created";
  static const String notifyGroupUpdated              = "edu.illinois.rokwire.group.updated";
  static const String notifyGroupDeleted              = "edu.illinois.rokwire.group.deleted";
  static const String notifyGroupPostCreated          = "edu.illinois.rokwire.group.post.created";
  static const String notifyGroupPostUpdated          = "edu.illinois.rokwire.group.post.updated";
  static const String notifyGroupPostDeleted          = "edu.illinois.rokwire.group.post.deleted";
  static const String notifyGroupPostsUpdated         = "edu.illinois.rokwire.group.posts.updated";
  static const String notifyGroupPostReactionsUpdated = "edu.illinois.rokwire.group.post.reactions.updated";
  static const String notifyGroupDetail               = "edu.illinois.rokwire.group.detail";

  static const String notifyGroupMembershipRequested      = "edu.illinois.rokwire.group.membership.requested";
  static const String notifyGroupMembershipCanceled       = "edu.illinois.rokwire.group.membership.canceled";
  static const String notifyGroupMembershipQuit           = "edu.illinois.rokwire.group.membership.quit";
  static const String notifyGroupMembershipApproved       = "edu.illinois.rokwire.group.membership.approved";
  static const String notifyGroupMembershipRejected       = "edu.illinois.rokwire.group.membership.rejected";
  static const String notifyGroupMembershipRemoved        = "edu.illinois.rokwire.group.membership.removed";
  static const String notifyGroupMembershipSwitchToAdmin  = "edu.illinois.rokwire.group.membership.switch_to_admin";
  static const String notifyGroupMembershipSwitchToMember = "edu.illinois.rokwire.group.membership.switch_to_member";
  static const String notifyGroupMemberAttended           = "edu.illinois.rokwire.group.member.attended";
  static const String _userLoginVersionSetting            = "edu.illinois.rokwire.settings.groups.user.login.version";

  static const String _userGroupsCacheFileName = "groups.json";
  static const String _attendedMembersCacheFileName = "attended_members.json";

  List<Map<String, dynamic>>? _launchGroupDetailsCache;
  List<Map<String, dynamic>>? get launchGroupDetailsCache => _launchGroupDetailsCache;

  Directory? _appDocDir;

  List<Group>? _userGroups;
  Set<String>? _userGroupNames;
  
  Map<String, List<Member>?>? _attendedMembers; // Map that caches attended members for specific group - the key is group's id
  
  Map<String, GroupStats> _cachedGroupStats = <String, GroupStats>{};

  Set<Completer<bool?>>? _loginCompleters;
  final List<Completer<void>> _userGroupUpdateCompleters = [];

  DateTime?  _pausedDateTime;

  // Singletone Factory

  static Groups? _instance;

  static Groups? get instance => _instance;
  
  @protected
  static set instance(Groups? value) => _instance = value;

  factory Groups() => _instance ?? (_instance = Groups.internal());

  @protected
  Groups.internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this,[
      DeepLink.notifyUri,
      Auth2.notifyLoginChanged,
      AppLivecycle.notifyStateChanged,
      FirebaseMessaging.notifyGroupsNotification,
      Connectivity.notifyStatusChanged
    ]);
    _launchGroupDetailsCache = [];
    super.createService();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Future<void> initService() async {

    await _ensureLogin();

    _appDocDir = await _getAppDocumentsDirectory();

    _attendedMembers = await _loadAttendedMembersFromCache();

    _userGroups = await _loadUserGroupsFromCache();
    _userGroupNames = _buildGroupNames(_userGroups);

    if (_userGroups == null) {
      await _initUserGroupsFromNet();
    }
    else {
      _updateUserGroupsFromNetSync();
    }

    await super.initService();
  }

  @override
  void initServiceUI() {
    processCachedLaunchGroupDetails();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { DeepLink(), Config(), Auth2() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      onDeepLinkUri(param);
    }
    else if (name == Auth2.notifyLoginChanged) {
      _onLoginChanged();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == FirebaseMessaging.notifyGroupsNotification){
      _onFirebaseMessageForGroupUpdate();
    }
    else if (name == Connectivity.notifyStatusChanged) {
      if (Connectivity().isOnline) {
        _submitCachedAttendedMembers();
      }
    }
  }

  void _onLoginChanged() {
    if (Auth2().isLoggedIn) {
      _ensureLogin().then((_){
        _updateUserGroupsFromNetSync();
      });
    }
    else {
      _clearUserGroups();
    }
  }
  
  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateUserGroupsFromNetSync();
        }
      }
    }
  }

  void _onFirebaseMessageForGroupUpdate() {
      _updateUserGroupsFromNetSync();
  }

  // Current User Membership

  Future<bool> isAdminForGroup(String groupId) async {
    Group? group = await loadGroup(groupId);
    return group?.currentUserIsAdmin ?? false;
  }

  // Caching

  Future<Directory?> _getAppDocumentsDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    }
    catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }

  // Content Attributes

  ContentAttributes? get contentAttributes => Content().contentAttributes('groups');


  // Categories APIs
  // TBD: REMOVE

  Future<List<String>?> loadCategories() async {
    List<dynamic>? categoriesJsonArray = await Events().loadEventCategories();
    if (CollectionUtils.isNotEmpty(categoriesJsonArray)) {
      List<String> categoriesList = categoriesJsonArray!.map((e) => e['category'].toString()).toList();
      return categoriesList;
    } else {
      return null;
    }
  }

  // Tags APIs
  // TBD: REMOVE

  Future<List<String>?> loadTags() async {
    return Events().loadEventTags();
  }

  // Login APIs

  Future<bool?> _ensureLogin() async {
    if ((Config().groupsUrl != null) && Auth2().isLoggedIn && _isUserNotLoggedIn) {
      if (_loginCompleters == null) {
        _loginCompleters = <Completer<bool?>>{};
        bool? result = await _login();
        Set<Completer<bool?>> loginCompleters = _loginCompleters!;
        _loginCompleters = null;
        for (Completer<bool?> completer in loginCompleters) {
          completer.complete(result);
        }
        return result;
      }
      else {
        Completer<bool?> completer = Completer<bool?>();
        _loginCompleters!.add(completer);
        return completer.future;
      }
    }
    return null;
  }

  Future<bool?> _login() async {
    if ((Config().groupsUrl != null) && Auth2().isLoggedIn && _isUserNotLoggedIn) {
      try {
        String url = '${Config().groupsUrl}/user/login';
        Response? response = await Network().get(url, auth: Auth2(),);
        if (response != null) {
          if (response.statusCode == 200) {
            _userDidLogin();
            return true;
          }
          else {
            return false;
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  bool get _isUserNotLoggedIn {
    String? appVersion = Config().appMajorVersion;
    String? loginVersion = Auth2().prefs?.getStringSetting(_userLoginVersionSetting);
    return ((loginVersion == null) || (AppVersion.compareVersions(loginVersion, appVersion) < 0));
  }

  void _userDidLogin() {
    Auth2().prefs?.applySetting(_userLoginVersionSetting, Config().appMajorVersion);
  }

  // Groups APIs


  ///
  /// Do not load user groups on portions / pages. We cached and use them for checks in flexUi and checklist
  ///
  /// Note: Do not allow loading on portions (paging) - there is a problem on the backend. Revert when it is fixed. 
  Future<List<Group>?> loadGroups({GroupsContentType? contentType, String? title, Map<String, dynamic>? attributes, int? offset, int? limit}) async {
    if (contentType == GroupsContentType.my) {
      await _updateUserGroupsFromNetSync();
      return userGroups;
    } else {
      return await _loadAllGroups(title: title, attributes: attributes, offset: offset, limit:  limit);
    }
  }

  Future<List<Group>?> loadResearchProjects({ResearchProjectsContentType? contentType, String? title, String? category, Set<String>? tags, GroupPrivacy? privacy, int? offset, int? limit}) async {
    if ((Config().groupsUrl != null) && Auth2().isLoggedIn) {
      String url = (contentType != ResearchProjectsContentType.my) ? '${Config().groupsUrl}/v2/groups' : '${Config().groupsUrl}/v2/user/groups';
      String? post = JsonUtils.encode({
        'title': title,
        'category': category,
        'tags': tags,
        'privacy': groupPrivacyToString(privacy),
        'offset': offset,
        'limit': limit,
        'research_group': true,
        'research_open': (contentType == ResearchProjectsContentType.open) ? true : null,
        'exclude_my_groups': (contentType == ResearchProjectsContentType.open) ? true : null,
        'research_answers': Auth2().profile?.researchQuestionnaireAnswers,
      });
      
      try {
        await _ensureLogin();
        Response? response = await Network().get(url, body: post, auth: Auth2());
        String? responseBody = (response?.statusCode == 200) ? response?.body : null;
        //Log.d('GET $url\n$post\n ${response?.statusCode} $responseBody', lineLength: 512);
        return Group.listFromJson(JsonUtils.decodeList(responseBody), filter: (contentType == ResearchProjectsContentType.open) ? (Group group) => (group.currentMember == null) : null);
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  Future<int?> loadResearchProjectTragetAudienceCount(Map<String, dynamic> researchQuestionnaireAnswers) async {
    if (Config().groupsUrl != null) {
      String url = '${Config().groupsUrl}/research-profile/user-count';
      String? post = JsonUtils.encode(researchQuestionnaireAnswers);
      
      try {
        await _ensureLogin();
        Response? response = await Network().post(url, body: post, auth: Auth2());
        String? responseBody = (response?.statusCode == 200) ? response?.body : null;
        return (responseBody != null) ? int.tryParse(responseBody) : null;
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  Future<List<Group>?> _loadAllGroups({String? title, Map<String, dynamic>? attributes, GroupPrivacy? privacy, List<String>? groupIds, int? offset, int? limit}) async =>
    JsonUtils.listTypedValue<Group>(await _loadAllGroupsEx(
        title: title,
        attributes : attributes,
        privacy: privacy,
        groupIds: groupIds,
        offset: offset,
        limit: limit,
    ));

  Future<dynamic> _loadAllGroupsEx({String? title, Map<String, dynamic>? attributes, GroupPrivacy? privacy, List<String>? groupIds, int? offset, int? limit}) async {
    if (Config().groupsUrl != null) {
      String url = '${Config().groupsUrl}/v2/groups';
      String? post = JsonUtils.encode({
        'title': title,
        'attributes': attributes,
        'privacy': groupPrivacyToString(privacy),
        'ids': groupIds,
        'offset': offset,
        'limit': limit,
        'research_group': false,
      });

      try {
        await _ensureLogin();
        Response? response = await Network().get(url, body: post, auth: Auth2());
        //Log.d('GET $url\n$post\n ${response?.statusCode} $responseBody', lineLength: 512);
        return (response?.statusCode == 200) ? Group.listFromJson(JsonUtils.decodeList(response?.body)) : response?.errorText;
      } catch (e) {
        debugPrint(e.toString());
      }
    }

    return null;
  }

  Future<List<Group>?> searchGroups(String searchText, {bool includeHidden = false, bool researchProjects = false, bool researchOpen = false }) async {
    if ((Config().groupsUrl != null) && (StringUtils.isNotEmpty(searchText))) {
      await _ensureLogin();
      String? post = JsonUtils.encode({
        'title': searchText, // Uri.encodeComponent(searchText)
        'include_hidden': includeHidden,
        'research_group': researchProjects,
        'research_open': researchOpen,
        'research_answers': Auth2().profile?.researchQuestionnaireAnswers,
      });


      String url = '${Config().groupsUrl}/v2/groups';
      Response? response = await Network().get(url, auth: Auth2(), body: post);
      int responseCode = response?.statusCode ?? -1;
      String? responseBody = response?.body;
      if (responseCode == 200) {
        return Group.listFromJson(JsonUtils.decodeList(responseBody));
      } else {
        debugPrint('Failed to search for groups. Reason: ');
        debugPrint(responseBody);
      }
    }
    return null;
  }

  Future<Group?> loadGroup(String? groupId) async {
    if ((Config().groupsUrl != null) && StringUtils.isNotEmpty(groupId)) {
      String url = '${Config().groupsUrl}/v2/groups/$groupId';
      try {
        await _ensureLogin();
        Response? response = await Network().get(url, auth: Auth2(),);
        int responseCode = response?.statusCode ?? -1;
        String? responseBody = response?.body;
        if (responseCode == 200) {
          Map<String, dynamic>? groupsJson = JsonUtils.decodeMap(responseBody);
          return Group.fromJson(groupsJson);
        } else {
          debugPrint('Failed to load group with id {$groupId}. Response: $responseCode $responseBody');
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  Future<GroupError?> createGroup(Group? group) async {
    if((Config().groupsUrl != null) && (group != null)) {
      String url = '${Config().groupsUrl}/groups';
      try {
        await _ensureLogin();
        Map<String, dynamic> json = group.toJson(/*withId: false*/);
        json["creator_email"] = Auth2().account?.profile?.email ?? "";
        json["creator_name"] = Auth2().account?.profile?.fullName ?? "";
        String? body = JsonUtils.encode(json);
        Response? response = await Network().post(url, auth: Auth2(), body: body);
        int responseCode = response?.statusCode ?? -1;
        //Log.d('POST $url\n$body\n$responseCode ${response?.body}', lineLength: 512);
        Map<String, dynamic>? jsonData = JsonUtils.decodeMap(response?.body);
        if (responseCode == 200) {
          String? groupId = (jsonData != null) ? JsonUtils.stringValue(jsonData['inserted_id']) : null;
          if (StringUtils.isNotEmpty(groupId)) {
            NotificationService().notify(notifyGroupCreated, groupId);
            _updateUserGroupsFromNetSync();
            return null; // succeeded
          }
        }
        else {
          Map<String, dynamic>? jsonError = (jsonData != null) ? JsonUtils.mapValue(jsonData['error']) : null;
          if (jsonError != null) {
            return GroupError.fromJson(jsonError); // error description
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return GroupError(); // generic error
  }

  Future<GroupError?> updateGroup(Group? group) async {

    if((Config().groupsUrl != null) && (group != null)) {
      String url = '${Config().groupsUrl}/groups/${group.id}';
      try {
        await _ensureLogin();
        Map<String, dynamic> json = group.toJson();
        String? body = JsonUtils.encode(json);
        Response? response = await Network().put(url, auth: Auth2(), body: body);
        int responseCode = response?.statusCode ?? -1;
        //Log.d('PUT $url\n$body\n$responseCode ${response?.body}', lineLength: 512);
        if(responseCode == 200){
          NotificationService().notify(notifyGroupUpdated, group.id);
          return null;
        }
        else {
          Map<String, dynamic>? jsonData = JsonUtils.decodeMap(response?.body);
          Map<String, dynamic>? jsonError = (jsonData != null) ? JsonUtils.mapValue(jsonData['error']) : null;
          if (jsonError != null) {
            return GroupError.fromJson(jsonError); // error description
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return GroupError(); // generic error
  }

  Future<bool> deleteGroup(String? groupId) async {
    if ((Config().groupsUrl != null) && StringUtils.isEmpty(groupId)) {
      return false;
    }
    await _ensureLogin();
    String url = '${Config().groupsUrl}/group/$groupId';
    Response? response = await Network().delete(url, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      NotificationService().notify(notifyGroupDeleted, null);
      _updateUserGroupsFromNetSync();
      return true;
    } else {
      Log.i('Failed to delete group. Reason:\n${response?.body}');
      return false;
    }
  }

  Future<bool> syncAuthmanGroup({required Group group}) async {

    if(Config().groupsUrl != null) {
      if(group.syncAuthmanAllowed) {
        await _ensureLogin();
        String url = '${Config().groupsUrl}/group/${group.id}/authman/synchronize';
        Response? response = await Network().post(url, auth: Auth2());
        int? responseCode = response?.statusCode;
        if (responseCode == 200) {
          _updateUserGroupsFromNetSync();
          return true;
        } else {
          debugPrint('Failed to synchronize authman group. \nReason: $responseCode, ${response?.body}');
        }
      }
      else {
        debugPrint('Current user is not allowed to sync group "${group.id}" in authman.');
      }
    }
    return false;
  }

  // Group Stats

  Future<GroupStats?> loadGroupStats(String? groupId) async {
    if ((Config().groupsUrl != null) && StringUtils.isNotEmpty(groupId)) {
      String url = '${Config().groupsUrl}/group/$groupId/stats';
      try {
        await _ensureLogin();
        Response? response = await Network().get(url, auth: Auth2());
        int responseCode = response?.statusCode ?? -1;
        String? responseBody = response?.body;
        if (responseCode == 200) {
          return _cacheGroupStats(GroupStats.fromJson(JsonUtils.decodeMap(responseBody)), groupId);
        } else {
          debugPrint('Failed to load group stats for group {$groupId}. Reason: $responseCode, $responseBody');
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }
  
  GroupStats? _cacheGroupStats(GroupStats? groupStats, String? groupId) {
    if ((groupId != null) && (groupStats != null)) {
      GroupStats? cachedGroupStats = _cachedGroupStats[groupId];
      if (cachedGroupStats != groupStats) {
        _cachedGroupStats[groupId] = groupStats;
        NotificationService().notify(notifyGroupStatsUpdated, groupId);
      }
    }
    return groupStats;
  }

  GroupStats? cachedGroupStats(String? groupId) => _cachedGroupStats[groupId];

  // Members APIs

  Future<List<Member>?> loadMembers({String? groupId, List<GroupMemberStatus>? statuses, String? memberId, List<String>? userIds,
    String? externalId, String? netId, String? name, int? offset, int? limit}) async {
    if (StringUtils.isEmpty(groupId)) {
      debugPrint('Failed to load group members - missing groupId.');
      return null;
    }
    if (Config().groupsUrl != null) {
      String url = '${Config().groupsUrl}/group/$groupId/members';
      Map<String, dynamic> params = {};
      if (CollectionUtils.isNotEmpty(statuses)) {
        List<String> statusList = [];
        for (GroupMemberStatus status in statuses!) {
          statusList.add(groupMemberStatusToString(status)!);
        }
        params.addAll({'statuses': statusList});
      }
      if (StringUtils.isNotEmpty(memberId)) {
        params.addAll({'id': memberId});
      }
      if (CollectionUtils.isNotEmpty(userIds)) {
        params.addAll({'user_ids': userIds});
      }
      if (StringUtils.isNotEmpty(externalId)) {
        params.addAll({'external_id': externalId});
      }
      if (StringUtils.isNotEmpty(netId)) {
        params.addAll({'net_id': netId});
      }
      if (StringUtils.isNotEmpty(name)) {
        params.addAll({'name': name});
      }
      if (offset != null) {
        params.addAll({'offset': offset});
      }
      if (limit != null) {
        params.addAll({'limit': limit});
      }
      try {
        await _ensureLogin();
        String? body = JsonUtils.encode(params);
        Response? response = await Network().get(url, auth: Auth2(), body: body);
        int responseCode = response?.statusCode ?? -1;
        String? responseBody = response?.body;
        if (responseCode == 200) {
          List<dynamic>? membersJson = JsonUtils.decodeList(responseBody);
          return Member.listFromJson(membersJson);
        } else {
          debugPrint('Failed to load members for group $groupId with body {$body}. Reason: $responseCode $responseBody');
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  /// Admins and members are allowed to post.
  Future<List<Member>?> loadMembersAllowedToPost({String? groupId}) async {
    return await loadMembers(groupId: groupId, statuses: [GroupMemberStatus.admin, GroupMemberStatus.member]);
  }

  Future<bool> requestMembership(Group? group, List<GroupMembershipAnswer>? answers) async{
    if((Config().groupsUrl != null) && (group != null)) {
      String url = '${Config().groupsUrl}/group/${group.id}/pending-members';
      try {
        await _ensureLogin();
        Map<String, dynamic> json = {};
        json["email"] = Auth2().account?.profile?.email ?? "";
        json["name"] = Auth2().account?.profile?.fullName ?? "";
        json["member_answers"] = CollectionUtils.isNotEmpty(answers) ? answers!.map((e) => e.toJson()).toList() : [];
        String? body = JsonUtils.encode(json);
        Response? response = await Network().post(url, auth: Auth2(), body: body);
        if((response?.statusCode ?? -1) == 200){
          _notifyGroupUpdateWithStats(notifyGroupMembershipRequested, group);
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> cancelRequestMembership(Group? group) async{
    if((Config().groupsUrl != null) && (group?.id != null)) {
      String url = '${Config().groupsUrl}/group/${group!.id}/pending-members';
      try {
        await _ensureLogin();
        Response? response = await Network().delete(url, auth: Auth2(),);
        if((response?.statusCode ?? -1) == 200){
          _notifyGroupUpdateWithStats(notifyGroupMembershipCanceled, group);
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> leaveGroup(Group? group) async {
    if ((Config().groupsUrl != null) && StringUtils.isNotEmpty(group?.id)) {
      await _ensureLogin();
      String url = '${Config().groupsUrl}/group/${group!.id}/members';
      Response? response = await Network().delete(url, auth: Auth2());
      int responseCode = response?.statusCode ?? -1;
      if (responseCode == 200) {
        _notifyGroupUpdateWithStats(notifyGroupMembershipQuit, group);
        _updateUserGroupsFromNetSync();
        return true;
      } else {
        String? responseString = response?.body;
        debugPrint(responseString);
      }
    }
    return false;
  }

  Future<bool> acceptMembership(Group? group, Member? member, bool? decision, String? reason) async{
    if((Config().groupsUrl != null) && StringUtils.isNotEmpty(group?.id) && StringUtils.isNotEmpty(member?.id) && decision != null) {
      Map<String, dynamic> bodyMap = {"approve": decision, "reject_reason": reason};
      String? body = JsonUtils.encode(bodyMap);
      String url = '${Config().groupsUrl}/memberships/${member!.id}/approval';
      try {
        await _ensureLogin();
        Response? response = await Network().put(url, auth: Auth2(), body: body);
        if((response?.statusCode ?? -1) == 200){
          _notifyGroupUpdateWithStats(decision ? notifyGroupMembershipApproved : notifyGroupMembershipRejected, group);
          _updateUserGroupsFromNetSync();
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> updateMemberStatus(Group? group, String? memberId, GroupMemberStatus status) async{
    if((Config().groupsUrl != null) && StringUtils.isNotEmpty(group?.id) && StringUtils.isNotEmpty(memberId)) {
      Map<String, dynamic> bodyMap = {"status":groupMemberStatusToString(status)};
      String? body = JsonUtils.encode(bodyMap);
      String url = '${Config().groupsUrl}/memberships/$memberId';
      try {
        await _ensureLogin();
        Response? response = await Network().put(url, auth: Auth2(), body: body);
        if((response?.statusCode ?? -1) == 200){
          String? notification;
          if (status == GroupMemberStatus.admin) {
            notification = notifyGroupMembershipSwitchToAdmin;
          }
          else if (status == GroupMemberStatus.member) {
            notification = notifyGroupMembershipSwitchToMember;
          }
          _notifyGroupUpdateWithStats(notification, group);
          _updateUserGroupsFromNetSync();
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> deleteMembership(Group? group, String? memberId) async{
    if((Config().groupsUrl != null) && StringUtils.isNotEmpty(group?.id) && StringUtils.isNotEmpty(memberId)) {
      String url = '${Config().groupsUrl}/memberships/$memberId';
      try {
        await _ensureLogin();
        Response? response = await Network().delete(url, auth: Auth2(),);
        if((response?.statusCode ?? -1) == 200){
          _notifyGroupUpdateWithStats(notifyGroupMembershipRemoved, group);
          _updateUserGroupsFromNetSync();
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> memberAttended({required Group group, required Member member}) async {
    if (Config().groupsUrl == null) {
      return false;
    }
    bool isNewMember = (member.id == null);
    if (isNewMember && (group.authManEnabled == true)) {
      debugPrint('It is not allowed to import new members to authman groups.');
      return false;
    }
    member.dateAttendedUtc ??= DateTime.now().toUtc();
    if (Connectivity().isOffline) {
      _addAttendedMemberToCache(group: group, member: member);
      return true;
    }
    String? memberJsonBody = JsonUtils.encode(member.toJson());
    String url = isNewMember ? '${Config().groupsUrl}/group/${group.id}/members' : '${Config().groupsUrl}/memberships/${member.id}';
    try {
      await _ensureLogin();
      Response? response = isNewMember ?
        await Network().post(url, body: memberJsonBody, auth: Auth2()) :
        await Network().put(url, body: memberJsonBody, auth: Auth2());
      int? responseCode = response?.statusCode;
      String? responseString = response?.body;
      if (responseCode == 200) {
        NotificationService().notify(notifyGroupMemberAttended, null);
        NotificationService().notify(notifyGroupUpdated, group.id);
        _updateUserGroupsFromNetSync();
        return true;
      } else {
        debugPrint('Failed to attend a member to group. \nResponse: $responseCode, $responseString');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return false;
  }

  Future<bool> updateMember(Member? member) async{
    if ((Config().groupsUrl != null) && (member != null)) {
      Map<String, dynamic> memberJson = member.toJson();
      String? body = JsonUtils.encode(memberJson);
      String url = '${Config().groupsUrl}/memberships/${member.id}';
      try {
        await _ensureLogin();
        Response? response = await Network().put(url, auth: Auth2(), body: body);
        String? responseString = response?.body;
        int? responseCode = response?.statusCode;
        if (responseCode == 200) {
          debugPrint('Successfully updated group member {${member.id}}');
          return true;
        } else {
          debugPrint('Failed to update group member {${member.id}}. Reason: $responseCode, $responseString');
          return false;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false;
  }

  void _notifyGroupUpdateWithStats(String? name, Group? group) {
    loadGroupStats(group?.id).then((_) {
      if (name != null) {
        NotificationService().notify(name, group);
      }
      NotificationService().notify(notifyGroupUpdated, group?.id);
    });
  }

// Events
  
  /*Future<List<String>?> loadEventIds(String? groupId) async{
    if((Config().groupsUrl != null) && StringUtils.isNotEmpty(groupId)) {
      String url = '${Config().groupsUrl}/group/$groupId/events';
      try {
        await _ensureLogin();
        Response? response = await Network().get(url, auth: Auth2());
        if((response?.statusCode ?? -1) == 200){
          //Successfully loaded ids
          int responseCode = response?.statusCode ?? -1;
          String? responseBody = response?.body;
          List<dynamic>? eventIdsJson = ((responseBody != null) && (responseCode == 200)) ? JsonUtils.decodeList(responseBody) : null;
          return JsonUtils.listStringsValue(eventIdsJson);
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null; // fail
  }*/

  /// 
  /// Loads group events based on the current user membership
  /// 
  /// Returns Map with single element:
  ///
  /// key - all events count ignoring the limit,
  /// 
  /// value - events (limited or not)
  ///
  /*Future<Map<int, List<Event2>>?> loadEvents (Group? group, {int limit = -1}) async {
    if (group != null) {
      List<String>? eventIds = await loadEventIds(group.id);
      List<Event2>? allEvents = CollectionUtils.isNotEmpty(eventIds) ? await Events2().loadEventsByIds(eventIds: eventIds) : null;
      if (CollectionUtils.isNotEmpty(allEvents)) {
        List<Event2> currentUserEvents = [];
        bool isCurrentUserMemberOrAdmin = group.currentUserIsMemberOrAdmin;
        for (Event2 event in allEvents!) {
          bool isPrivate = event.private == true;  //It was: From CreateEventPanel ->  event.isGroupPrivate = _isPrivateEvent; -> _selectedPrivacy == eventPrivacyPrivate;
          if (!isPrivate || isCurrentUserMemberOrAdmin) {
            currentUserEvents.add(event);
          }
        }
        int eventsCount = currentUserEvents.length;
        SortUtils.sort(currentUserEvents);
        //limit the result count // limit available events
        List<Event2> visibleEvents = ((limit > 0) && (eventsCount > limit)) ? currentUserEvents.sublist(0, limit) : currentUserEvents;
        List<Event2> groupEvents = <Event2>[];
        for (Event2 event in visibleEvents) {
          ListUtils.add(groupEvents, Event2.fromJson(event.toJson()));
        }
        return {eventsCount: groupEvents};
      }
    }
    return null;
  }*/

  Future<bool> linkEventToGroup({String? groupId, String? eventId, List<Member>? toMembers}) async {
    if((Config().groupsUrl != null) && StringUtils.isNotEmpty(groupId) && StringUtils.isNotEmpty(eventId)) {
      String url = '${Config().groupsUrl}/group/$groupId/events';
      try {
        await _ensureLogin();
        Map<String, dynamic> bodyMap = {"event_id":eventId};
        if(CollectionUtils.isNotEmpty(toMembers)){
          bodyMap["to_members"] = Member.listToJson(toMembers);
        }
        String? body = JsonUtils.encode(bodyMap);
        Response? response = await Network().post(url, auth: Auth2(),body: body);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupUpdated, groupId);
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> updateLinkedEventMembers({String? groupId, String? eventId, List<Member>? toMembers}) async {
    if((Config().groupsUrl != null) && StringUtils.isNotEmpty(groupId) && StringUtils.isNotEmpty(eventId)) {
      String url = '${Config().groupsUrl}/group/$groupId/events';
      try {
        await _ensureLogin();
        Map<String, dynamic> bodyMap = {"event_id":eventId};
        if(CollectionUtils.isNotEmpty(toMembers)){
          bodyMap["to_members"] = Member.listToJson(toMembers);
        }
        String? body = JsonUtils.encode(bodyMap);
        Response? response = await Network().put(url, auth: Auth2(),body: body);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupUpdated, groupId);
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> _removeEventFromGroup({String? groupId, String? eventId}) async {
    if((Config().groupsUrl != null) && StringUtils.isNotEmpty(groupId) && StringUtils.isNotEmpty(eventId)) {
      String url = '${Config().groupsUrl}/group/$groupId/event/$eventId';
      try {
        await _ensureLogin();
        Response? response = await Network().delete(url, auth: Auth2());
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupUpdated, groupId);
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false;
  }

  Future<List<Member>?> loadGroupEventMemberSelection(groupId, eventId) async{
    if(StringUtils.isNotEmpty(groupId) && StringUtils.isNotEmpty(eventId)) {
      String url = '${Config().groupsUrl}/group/$groupId/events/v2';
      try {
        await _ensureLogin();
        Response? response = await Network().get(url, auth: Auth2());
        int responseCode = response?.statusCode ?? -1;
        String? responseBody = response?.body;
        if (responseCode == 200) {
          List<dynamic>? groupEventLinkSettingsJson = (responseBody != null) ? JsonUtils.decodeList(responseBody) : null; //List of settings for all events //Probbably can pass paramether to backend
          if(groupEventLinkSettingsJson?.isNotEmpty ?? false) { //Find settings for this event
            dynamic eventSettings = groupEventLinkSettingsJson!.firstWhereOrNull((element) {
                if (element is Map<String, dynamic>) {
                  String? id = JsonUtils.stringValue(element["event_id"]);
                  if( id != null && id == eventId){
                    return true;
                  }
                }
                return false;
              });

            if(eventSettings != null && eventSettings is Map<String, dynamic>){
              List<dynamic>? membersData = JsonUtils.listValue(eventSettings["to_members"]);
              List<Member>? members= Member.listFromJson(membersData);
              return members;
            }
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null; // fail
  }

  /*Future<String?> updateGroupEvents(Event2 event) async {
    String? id = await Events2().updateEvent(event);
    if (StringUtils.isNotEmpty(id)) {
      NotificationService().notify(Groups.notifyGroupEventsUpdated);
    }
    return id;
  }*/

  /*Future<bool?> deleteEventFromGroup({String? groupId, required Event2 event}) async {
    bool? deleteResult = false;
    if (await _removeEventFromGroup(groupId: groupId, eventId: event.id) ) {
      // String? creatorGroupId = event.createdByGroupId;
      // if(creatorGroupId!=null){
      if(event.userRole == Event2UserRole.admin){ //event.canUserDelete
        Group? creatorGroup = await loadGroup(groupId);
        if(creatorGroup!=null && creatorGroup.currentUserIsAdmin){
          deleteResult = await Events().deleteEvent(event.id);
        }
      }
      NotificationService().notify(Groups.notifyGroupEventsUpdated);
    }
    return deleteResult;
  }*/

  // Events V3

  Future<Events2ListResult?> loadEventsV3 (String? groupId, {
    Event2TimeFilter timeFilter = Event2TimeFilter.upcoming,
    Event2SortType? sortType = Event2SortType.dateTime,
    Event2SortOrder sortOrder = Event2SortOrder.ascending,
    int offset = 0, int? limit
  }) async {
    if ((Config().groupsUrl != null) && StringUtils.isNotEmpty(groupId)) {
      String url = '${Config().groupsUrl}/group/$groupId/events/v3/load';
      String? body = JsonUtils.encode(Events2Query(
        timeFilter: timeFilter,
        sortType: sortType,
        sortOrder: sortOrder,
        offset: offset,
        limit: limit
      ).toQueryJson());
      try {
        await _ensureLogin();
        Response? response = await Network().post(url, body: body, auth: Auth2());
        return (response?.statusCode  == 200) ? Events2ListResult.fromResponseJson(JsonUtils.decode(response?.body)) : null;
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null; // fail
  }

  /*List<Event2>? _buildEventsV3(List<Event2>? sourceEvents) {
    if (sourceEvents != null) {

      // Filter
      List<Event2> events = <Event2>[];
      DateTime nowUtc = DateTime.now().toUtc();
      for (Event2 event in sourceEvents) {
        DateTime? eventEndTime = event.endTimeUtc ?? event.startTimeUtc;
        if ((eventEndTime != null) && nowUtc.isBefore(eventEndTime)) {
          events.add(event);
        }
      }
      
      // Sort
      events.sort((Event2 event1, Event2 event2) =>
        SortUtils.compare(event1.startTimeUtc, event2.startTimeUtc)
      );
      return events;
    }
    return null;
  }*/

  Future<dynamic> createEventForGroupV3(Event2? event, { String? groupId, List<Member>? toMembers }) async {
    if ((Config().groupsUrl != null) && (groupId != null) && (event != null)) {
      String url = '${Config().groupsUrl}/group/$groupId/events/v3';
      String? body = JsonUtils.encode({
        'event': event.toJson(),
        'to_members': Member.listToJson(toMembers)
      });
      try {
        await _ensureLogin();
        Response? response = await Network().post(url, auth: Auth2(), body: body);
        if (response?.statusCode == 200) {
          NotificationService().notify(notifyGroupUpdated, groupId);
          return Event2.fromJson(JsonUtils.decodeMap(response?.body));
        }
        else {
          return response?.errorText;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }
  Future<dynamic> updateEventForGroupV3(Event2? event, { String? groupId, List<Member>? toMembers }) async {
    if ((Config().groupsUrl != null) && (groupId != null) && (event != null)) {
      String url = '${Config().groupsUrl}/group/$groupId/events/v3';
      String? body = JsonUtils.encode({
        'event': event.toJson(),
        'to_members': Member.listToJson(toMembers)
      });
      try {
        await _ensureLogin();
        Response? response = await Network().put(url, auth: Auth2(), body: body);
        if (response?.statusCode == 200) {
          NotificationService().notify(notifyGroupUpdated, groupId);
          return Event2.fromJson(JsonUtils.decodeMap(response?.body));
        }
        else {
          return response?.errorText;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  Future<bool> deleteEventForGroupV3({String? groupId, String? eventId}) =>
    _removeEventFromGroup(groupId: groupId, eventId: eventId);


  Future<dynamic> createEventForGroupsV3(Event2? event, { Set<String>? groupIds }) async {
    if ((Config().groupsUrl != null) && (groupIds != null) && groupIds.isNotEmpty && (event != null)) {
      String url = '${Config().groupsUrl}/group/events/v3';
      String? body = JsonUtils.encode(CreateEventForGroupsV3Param(event: event, groupIds: groupIds).toJson());
      try {
        await _ensureLogin();
        Response? response = await Network().post(url, auth: Auth2(), body: body);
        CreateEventForGroupsV3Param? responseParam = (response?.statusCode == 200) ? CreateEventForGroupsV3Param.fromJson(JsonUtils.decodeMap(response?.body)) : null;
        if (responseParam?.event != null) {
          responseParam?.groupIds?.forEach((String groupId) => NotificationService().notify(notifyGroupUpdated, groupId));
          return responseParam;
        }
        else {
          return response?.errorText;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  Future<dynamic> loadUserGroupsHavingEvent(String eventId) async {
    String? groupsUrl = Config().groupsUrl;
    if (groupsUrl != null) {
      String url = '$groupsUrl/user/event/$eventId/groups';
      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode  == 200) ? _decodeGroupIds(response?.body) : response?.errorText;
    }
    else {
      return null;
    }
  }

  Future<dynamic> loadUserGroupsHavingEventEx(String eventId) async {
    dynamic result1 = await loadUserGroupsHavingEvent(eventId);
    List<String>? groupIds = JsonUtils.listStringsValue(result1);
    return (groupIds != null) ? await _loadAllGroupsEx(groupIds: groupIds) : result1;
  }

  Future<dynamic> saveUserGroupsHavingEvent(String eventId, { Set<String>? groupIds, Set<String>? previousGroupIds } ) async {
    String? groupsUrl = Config().groupsUrl;
    if ((groupsUrl != null) && (groupIds != null)) {
      String url = '$groupsUrl/user/event/$eventId/groups';
      String? body = JsonUtils.encode({'group_ids': groupIds.toList()});
      Response? response = await Network().put(url, auth: Auth2(), body: body);
      if (response?.statusCode != 200) {
        return response?.errorText;
      }
      else {
        Set<String>? groupIds = (response?.statusCode  == 200) ? _decodeGroupIds(response?.body) : null;
        if (groupIds != null) {
          Set<String> modifiedGroupIds = ((previousGroupIds != null) && previousGroupIds.isNotEmpty) ? groupIds.union(previousGroupIds) : groupIds;
          modifiedGroupIds.forEach((String groupId) => NotificationService().notify(notifyGroupUpdated, groupId));
          return groupIds;
        }
      }
    }
    return null;
  }

  Set<String>? _decodeGroupIds(String? responseText) {
    Map<String, dynamic>? responseMap = JsonUtils.decodeMap(responseText);
    return (responseMap != null) ? JsonUtils.setStringsValue(responseMap['group_ids']) : null;
  }

  // Group Posts and Replies

  Future<bool> createPost(String? groupId, GroupPost? post) async {
    if ((Config().groupsUrl != null) && StringUtils.isNotEmpty(groupId) && (post != null)) {
      await _ensureLogin();
      String? requestBody = JsonUtils.encode(post.toJson(create: true));
      String requestUrl = '${Config().groupsUrl}/group/$groupId/posts';
      Response? response = await Network().post(requestUrl, auth: Auth2(), body: requestBody);
      GroupPost? responsePost = (response?.statusCode == 200) ? GroupPost.fromJson(JsonUtils.decodeMap(response?.body)) : null;
      if (responsePost != null) {
        NotificationService().notify(notifyGroupPostCreated, responsePost);
        NotificationService().notify(notifyGroupPostsUpdated);
        return true;
      } else {
        Log.e('Failed to create group post. Response: ${response?.body}');
      }
    }
    return false;
  }

  Future<bool> updatePost(String? groupId, GroupPost? post) async {
    if ((Config().groupsUrl != null) && StringUtils.isNotEmpty(groupId) && StringUtils.isNotEmpty(post?.id)) {
      await _ensureLogin();
      String? requestBody = JsonUtils.encode(post!.toJson(update: true));
      String requestUrl = '${Config().groupsUrl}/group/$groupId/posts/${post.id}';
      Response? response = await Network().put(requestUrl, auth: Auth2(), body: requestBody);
      GroupPost? responsePost = (response?.statusCode == 200) ? GroupPost.fromJson(JsonUtils.decodeMap(response?.body)) : null;
      if (responsePost != null) {
        NotificationService().notify(notifyGroupPostUpdated, responsePost);
        NotificationService().notify(notifyGroupPostsUpdated);
        return true;
      } else {
        Log.e('Failed to update group post. Response: ${response?.body}');
      }
    }
    return false;
  }

  Future<bool> deletePost(String? groupId, GroupPost? post) async {
    if ((Config().groupsUrl != null) && StringUtils.isNotEmpty(groupId) && StringUtils.isNotEmpty(post?.id)) {
      await _ensureLogin();
      String requestUrl = '${Config().groupsUrl}/group/$groupId/posts/${post!.id}';
      Response? response = await Network().delete(requestUrl, auth: Auth2());
      if (response?.statusCode == 200) {
        NotificationService().notify(notifyGroupPostDeleted, post);
        NotificationService().notify(notifyGroupPostsUpdated);
        return true;
      } else {
        Log.e('Failed to delete group post. Response: ${response?.body}');
      }
    }
    return false;
  }

  Future<List<GroupPost>?> loadGroupPosts(String? groupId, {GroupPostType? type, int? offset, int? limit, GroupSortOrder? order}) async {
    if ((Config().groupsUrl != null) && StringUtils.isNotEmpty(groupId)) {
      String urlParams = "";
      if (type != null) {
        urlParams = urlParams.isEmpty ? "?" : "$urlParams&";
        urlParams += "type=${groupPostTypeToString(type)}";
      }
      if (offset != null) {
        urlParams = urlParams.isEmpty ? "?" : "$urlParams&";
        urlParams += "offset=$offset";
      }
      if (limit != null) {
        urlParams = urlParams.isEmpty ? "?" : "$urlParams&";
        urlParams += "limit=$limit";
      }
      if (order != null) {
        urlParams = urlParams.isEmpty ? "?" : "$urlParams&";
        urlParams += "order=${groupSortOrderToString(order)}";
      }
      
      await _ensureLogin();
      String requestUrl = '${Config().groupsUrl}/group/$groupId/posts$urlParams';
      Response? response = await Network().get(requestUrl, auth: Auth2());
      int responseCode = response?.statusCode ?? -1;
      String? responseString = response?.body;
      if (responseCode == 200) {
        List<GroupPost>? posts = GroupPost.fromJsonList(JsonUtils.decodeList(responseString));
        return posts;
      } else {
        Log.e('Failed to retrieve group posts. Response: ${response?.body}');
      }
    }
    return null;
  }

  Future<GroupPost?> loadGroupPost({required String? groupId, required String? postId}) async {
    if (StringUtils.isEmpty(groupId) || StringUtils.isEmpty(postId)) {
      return null;
    }

    await _ensureLogin();
    String requestUrl = '${Config().groupsUrl}/group/$groupId/posts/$postId';
    Response? response = await Network().get(requestUrl, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String? responseString = response?.body;
    if (responseCode == 200) {
      GroupPost? post = GroupPost.fromJson(JsonUtils.decodeMap(responseString));
      return post;
    } else {
      Log.e('Failed to retrieve group post for id $postId. Response: ${response?.body}');
      return null;
    }
  }

  Future<List<GroupPostNudge>?> loadPostNudges({required String groupName}) async {
    const String templatesCategory = 'gies_post_templates';
    List<GroupPostNudge>? allTemplates = GroupPostNudge.fromJsonList(JsonUtils.listValue(await Content().loadContentItem(templatesCategory)));
    if (CollectionUtils.isNotEmpty(allTemplates)) {
      List<GroupPostNudge> groupNudges = <GroupPostNudge>[];
      for (GroupPostNudge template in allTemplates!) {
        GroupPostNudge? nudge = _getNudgeForGroup(groupName: groupName, template: template);
        if (nudge != null) {
          groupNudges.add(nudge);
        }
      }
      return groupNudges;
    }
    return null;
  }

  Future<bool> togglePostReaction(String? groupId, String? postId, String reaction) async {
    if ((Config().groupsUrl != null) && StringUtils.isNotEmpty(groupId) && StringUtils.isNotEmpty(postId)) {
      await _ensureLogin();
      String? requestBody = JsonUtils.encode({'reaction': reaction});
      String requestUrl = '${Config().groupsUrl}/group/$groupId/posts/$postId/reactions';
      Response? response = await Network().put(requestUrl, auth: Auth2(), body: requestBody);
      int responseCode = response?.statusCode ?? -1;
      if (responseCode == 200) {
        // NotificationService().notify(notifyGroupPostsUpdated);
        return true;
      } else {
        Log.e('Failed to update group post reaction. Response: ${response?.body}');
      }
    }
    return false;
  }

  GroupPostNudge? _getNudgeForGroup({required String groupName, required GroupPostNudge template}) {
    dynamic groupNames = template.groupNames;
    List<String>? groupNamesList = JsonUtils.stringListValue(groupNames);
    String? nudgeGroupName = JsonUtils.stringValue(groupNames);
    if (groupNamesList != null) {
      for (String name in groupNamesList) {
        if (name.toLowerCase() == groupName.toLowerCase()) {
          return template;
        }
      }
    } else if (nudgeGroupName != null) {
      const String wildCardSymbol = '*';
      if (nudgeGroupName.toLowerCase() == groupName.toLowerCase()) {
        return template;
      } else if (nudgeGroupName.endsWith(wildCardSymbol)) {
        String namePrefix = nudgeGroupName.substring(0, nudgeGroupName.indexOf(wildCardSymbol));
        if (groupName.toLowerCase().startsWith(namePrefix.toLowerCase())) {
          return template;
        }
      }
    }
    return null;
  }

  //Delete User
  Future<bool?> deleteUserData() async{
    if ((Config().groupsUrl != null) && Auth2().isLoggedIn) {
      try {
        await _ensureLogin();
        Response? response =  await Network().delete("${Config().groupsUrl}/user", auth: Auth2());
        return (response?.statusCode == 200);
      } catch (e) {
        Log.e(e.toString());
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> loadUserStats() async {
    if ((Config().groupsUrl != null) && Auth2().isLoggedIn) {
      try {
        await _ensureLogin();
        Response? response = await Network().get("${Config().groupsUrl}/user/stats", auth: Auth2());
        if(response?.statusCode == 200) {
          return  JsonUtils.decodeMap(response?.body);
        }
      } catch (e) {
        Log.e(e.toString());
      }
    }

    return null;
  }

  Future<int> getUserPostCount() async{
    Map<String, dynamic>? stats = await loadUserStats();
    return stats != null ? (JsonUtils.intValue(stats["posts_count"]) ?? -1) : -1;
  }

  /////////////////////////
  // DeepLinks

  String get groupDetailUrl => '${DeepLink().appUrl}/group_detail';

  @protected
  void onDeepLinkUri(Uri? uri) {
    if (uri != null) {
      Uri? eventUri = Uri.tryParse(groupDetailUrl);
      if ((eventUri != null) &&
          (eventUri.scheme == uri.scheme) &&
          (eventUri.authority == uri.authority) &&
          (eventUri.path == uri.path))
      {
        try { handleLaunchGroupDetail(uri.queryParameters.cast<String, dynamic>()); }
        catch (e) { debugPrint(e.toString()); }
      }
    }
  }

  @protected
  void handleLaunchGroupDetail(Map<String, dynamic>? params) {
    if ((params != null) && params.isNotEmpty) {
      if (_launchGroupDetailsCache != null) {
        cacheLaunchGroupDetail(params);
      }
      else {
        processLaunchGroupDetail(params);
      }
    }
  }

  @protected
  void processLaunchGroupDetail(Map<String, dynamic> params) {
    NotificationService().notify(notifyGroupDetail, params);
  }

  @protected
  void cacheLaunchGroupDetail(Map<String, dynamic> params) {
    _launchGroupDetailsCache?.add(params);
  }

  @protected
  void processCachedLaunchGroupDetails() {
    if (_launchGroupDetailsCache != null) {
      List<Map<String, dynamic>> groupDetailsCache = _launchGroupDetailsCache!;
      _launchGroupDetailsCache = null;

      for (Map<String, dynamic> groupDetail in groupDetailsCache) {
        processLaunchGroupDetail(groupDetail);
      }
    }
  }

  // User Groups

  List<Group>? get userGroups => _userGroups;

  Set<String>? get userGroupNames => _userGroupNames;

  ///
  /// Returns the groups that current user is admin of without the current group
  ///
  Future<List<Group>?> loadAdminUserGroups({List<String> excludeIds = const []}) async {
    List<Group>? userGroups = await loadGroups(contentType: GroupsContentType.my);
    return userGroups?.where((group) => (group.currentUserIsAdmin && (excludeIds.contains(group.id) == false))).toList();
  }

  File? _getUserGroupsCacheFile()  =>
    (_appDocDir != null) ? File(join(_appDocDir!.path, _userGroupsCacheFileName)) : null;

  Future<String?> _loadUserGroupsStringFromCache() async {
    try {
      File? cacheFile = _getUserGroupsCacheFile();
      return (await cacheFile?.exists() == true) ? await cacheFile?.readAsString() : null;
    }
    catch(e) { 
      debugPrint(e.toString()); 
    }
    return null;
  }

  Future<void> _saveUserGroupsStringToCache(String? value) async {
    try {
      File? cacheFile = _getUserGroupsCacheFile();
      if (cacheFile != null) {
        if (value != null) {
          await cacheFile.writeAsString(value, flush: true);
        }
        else if (await cacheFile.exists()){
          await cacheFile.delete();
        }
      }
    }
    catch(e) { 
      debugPrint(e.toString());
    }
  }

  Future<List<Group>?> _loadUserGroupsFromCache() async {
    return Group.listFromJson(JsonUtils.decodeList(await _loadUserGroupsStringFromCache()));
  }

  Future<String?> _loadUserGroupsStringFromNet() async {
    if (StringUtils.isNotEmpty(Config().groupsUrl) && Auth2().isLoggedIn) {
      await _ensureLogin();
      // Load all user groups because we cache them and use them for various checks on startup like flexUI etc
      String url = '${Config().groupsUrl}/v2/user/groups';
      String? post = JsonUtils.encode({
        'research_group': false,
      });
      Response? response = await Network().get(url, body: post, auth: Auth2());
      if (response?.statusCode == 200) {
        return response?.body;
      }
      else {
        debugPrint('Failed to load user groups. Code: ${response?.statusCode}}.\nResponse: ${response?.body}');
      }
    }
    return null;
  }

  Future<void> _initUserGroupsFromNet() async {
    String? jsonString = await _loadUserGroupsStringFromNet();
    List<Group>? userGroups = Group.listFromJson(JsonUtils.decodeList(jsonString));
    if (userGroups != null) {
      _userGroups = userGroups;
      _userGroupNames = _buildGroupNames(_userGroups);
      await _saveUserGroupsStringToCache(jsonString);
    }
  }

  Future<void> _updateUserGroupsFromNetSync() async{
    try {
      if (_userGroupUpdateCompleters.isEmpty) {
        Completer<void> completer = Completer<void>();
        _userGroupUpdateCompleters.add(completer);
        _updateUserGroupsFromNet().whenComplete(() {
          for (var completer in _userGroupUpdateCompleters) {
            completer.complete();
          }
          _userGroupUpdateCompleters.clear();
        });
        return completer.future;
      } else {
        Completer<void> completer = Completer<void>();
        _userGroupUpdateCompleters.add(completer);
        return completer.future;
      }
    } catch(err){
      Log.e("Failed to invoke Update User Group From Net");
      debugPrint(err.toString());
    }
  }

  Future<void> _updateUserGroupsFromNet() async {
    String? jsonString = await _loadUserGroupsStringFromNet();
    List<Group>? userGroups = Group.listFromJson(JsonUtils.decodeList(jsonString));
    if ((userGroups != null) && !const DeepCollectionEquality().equals(_userGroups, userGroups)) {
      _userGroups = userGroups;
      _userGroupNames = _buildGroupNames(_userGroups);
      await _saveUserGroupsStringToCache(jsonString);
      NotificationService().notify(notifyUserGroupsUpdated);
    }
  }

  Future<void> _clearUserGroups() async {
    if (_userGroups != null) {
      _userGroups = null;
      _userGroupNames = null;
      await _saveUserGroupsStringToCache(null);
      NotificationService().notify(notifyUserGroupsUpdated);
    }
  }

  static Set<String>? _buildGroupNames(List<Group>? groups) {
    Set<String>? groupNames;
    if (groups != null) {
      groupNames = {};
      for (Group group in groups) {
        if (group.currentUserIsMemberOrAdmin && (group.title != null)) {
          groupNames.add(group.title!);
        }
      }
    }
    return groupNames;
  }

  // Attended Members

  File? _getAttendedMembersCacheFile() =>
    (_appDocDir != null) ? File(join(_appDocDir!.path, _attendedMembersCacheFileName)) : null;

  Future<String?> _loadAttendedMembersStringFromCache() async {
    try {
      File? cacheFile = _getAttendedMembersCacheFile();
      return (await cacheFile?.exists() == true) ? await cacheFile?.readAsString() : null;
    }
    catch(e) { 
      debugPrint(e.toString()); 
    }
    return null;
  }

  Future<void> _saveAttendedMembersStringToCache(String? value) async {
    try {
      File? cacheFile = _getAttendedMembersCacheFile();
      if (cacheFile != null) {
        if (value != null) {
          await cacheFile.writeAsString(value, flush: true);
        }
        else if (await cacheFile.exists()){
          await cacheFile.delete();
        }
      }
    }
    catch(e) { 
      debugPrint(e.toString());
    }
  }

  Future<Map<String, List<Member>?>?> _loadAttendedMembersFromCache() async {
    String? membersString = await _loadAttendedMembersStringFromCache();
    Map<String, dynamic>? attendedMembersMap = JsonUtils.decodeMap(membersString);
    if (attendedMembersMap != null) {
      Map<String, List<Member>?> resultMap = HashMap<String, List<Member>>();
      for (String key in attendedMembersMap.keys) {
        dynamic members = attendedMembersMap[key];
        resultMap[key] = Member.listFromJson(members);
      }
      return resultMap;
    }
    return null;
  }

  void _addAttendedMemberToCache({required Group group, required Member member}) {
    String groupId = group.id!;
    _attendedMembers ??= HashMap<String, List<Member>>();
    List<Member>? attendedGroupMembers = _attendedMembers![groupId];
    attendedGroupMembers ??= <Member>[];
    attendedGroupMembers.add(member);
    _attendedMembers![groupId] = attendedGroupMembers;
    String? membersString = JsonUtils.encode(_attendedMembers);
    _saveAttendedMembersStringToCache(membersString);
  }

  Future<void> _submitCachedAttendedMembers() async {
    if (Connectivity().isOnline) {
      if ((_attendedMembers != null) && _attendedMembers!.isNotEmpty) {
        Iterable<String> groupIdKeys = _attendedMembers!.keys.toList();
        Iterator groupIdIterator = groupIdKeys.iterator;
        while (groupIdIterator.moveNext()) {
          String groupId = groupIdIterator.current;
          Group? group = _getUserGroup(groupId: groupId);
          if (group != null) {
            List<Member>? attendedMembers = _attendedMembers![groupId];
            if (CollectionUtils.isNotEmpty(attendedMembers)) {
              List<Member> members = attendedMembers!.toList();
              Iterator membersIterator = members.iterator;
              while (membersIterator.moveNext()) {
                Member member = membersIterator.current;
                bool memberAttendedSuccessfully = await memberAttended(group: group, member: member);
                if (memberAttendedSuccessfully) {
                  attendedMembers.remove(member);
                }
              }
              if (CollectionUtils.isEmpty(attendedMembers)) {
                _attendedMembers!.remove(groupId);
              } else {
                _attendedMembers![groupId] = attendedMembers;
              }
            }
          }
        }
        String? membersString;
        if (_attendedMembers!.isEmpty) {
          membersString = null;
        } else {
          membersString = JsonUtils.encode(_attendedMembers);
        }
        _saveAttendedMembersStringToCache(membersString);
      }
    }
  }

  Group? _getUserGroup({required String groupId}) {
    if (CollectionUtils.isNotEmpty(userGroups) && StringUtils.isNotEmpty(groupId)) {
      for (Group group in userGroups!) {
        if (groupId == group.id) {
          return group;
        }
      }
    }
    return null;
  }

  // Report Abuse

  Future<bool> reportAbuse({String? groupId, String? postId, String? comment, bool reportToDeanOfStudents = false, bool reportToGroupAdmins = false}) async {
    if (Config().groupsUrl != null) {
      String url = '${Config().groupsUrl}/group/$groupId/posts/$postId/report/abuse';
      String? body = JsonUtils.encode({
        'comment': comment,
        'send_to_dean_of_students': reportToDeanOfStudents,
        'send_to_group_admins': reportToGroupAdmins,
        
      });
      _ensureLogin();
      Response? response = await Network().put(url, body: body, auth: Auth2());
      return (response?.statusCode == 200);
    }
    return false;
  }
    
}

enum GroupSortOrder { asc, desc }

GroupSortOrder? groupSortOrderFromString(String? value) {
  if (value == 'asc') {
    return GroupSortOrder.asc;
  }
  else if (value == 'desc') {
    return GroupSortOrder.desc;
  }
  else {
    return null;
  }
}

String? groupSortOrderToString(GroupSortOrder? value) {
  switch(value) {
    case GroupSortOrder.asc:  return 'asc';
    case GroupSortOrder.desc: return 'desc';
    default: return null;
  }
}

enum GroupPostType { post, message }

GroupPostType? groupPostTypeFromString(String? value) {
  switch(value) {
    case 'post': return GroupPostType.post;
    case 'message': return GroupPostType.message;
    default: return null;
  }
}

String groupPostTypeToString(GroupPostType value) {
  switch(value) {
    case GroupPostType.post: return 'post';
    case GroupPostType.message: return 'message';
  }
}

extension _ResponseExt on Response {
  String? get errorText {
    String? responseBody = body;
    Map<String, dynamic>? responseJson = JsonUtils.decodeMap(responseBody);
    String? message = (responseJson != null) ? JsonUtils.stringValue(responseJson['message']) : null;
    if (StringUtils.isNotEmpty(message)) {
      return message;
    }
    else if (StringUtils.isNotEmpty(responseBody)) {
      return responseBody;
    }
    else {
      return StringUtils.isNotEmpty(reasonPhrase) ? "$statusCode $reasonPhrase" : "$statusCode";
    }

  }
}

class CreateEventForGroupsV3Param {
  final Event2? event;
  final Set<String>? groupIds;
  
  CreateEventForGroupsV3Param({this.event, this.groupIds});

  static CreateEventForGroupsV3Param? fromJson(Map<String, dynamic>? json) => (json != null) ?
    CreateEventForGroupsV3Param(
      event: Event2.fromJson(JsonUtils.mapValue(json['event'])),
      groupIds: JsonUtils.setStringsValue(json['group_ids'])
    ) : null;

  Map<String, dynamic> toJson() => {
    'event': event?.toJson(),
    'group_ids': groupIds?.toList(),
  };
}