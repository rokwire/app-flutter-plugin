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
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';

import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'firebase_messaging.dart';

enum GroupsContentType { all, my }

class Groups with Service implements NotificationsListener {

  static const String notifyUserGroupsUpdated         = "edu.illinois.rokwire.groups.user.updated";
  static const String notifyUserMembershipUpdated     = "edu.illinois.rokwire.groups.membership.updated";
  static const String notifyGroupEventsUpdated        = "edu.illinois.rokwire.groups.events.updated";
  static const String notifyGroupCreated              = "edu.illinois.rokwire.group.created";
  static const String notifyGroupUpdated              = "edu.illinois.rokwire.group.updated";
  static const String notifyGroupDeleted              = "edu.illinois.rokwire.group.deleted";
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

  static const String _userGroupsCacheFileName = "groups.json";
  static const String _attendedMembersCacheFileName = "attended_members.json";

  List<Map<String, dynamic>>? _groupDetailsCache;
  List<Map<String, dynamic>>? get groupDetailsCache => _groupDetailsCache;

  List<Group>? _userGroups;
  Set<String>? _userGroupNames;

  Map<String, List<Member>?>? _attendedMembers; // Map that caches attended members for specific group - the key is group's id

  final List<Completer<void>> _loginCompleters = [];
  final List<Completer<void>> _userGroupUpdateCompleters = [];
  List<Completer<void>> get loginCompleters => _loginCompleters;


  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

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
    _groupDetailsCache = [];
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    await waitForLogin();

    _attendedMembers = await _loadAttendedMembersFromCache();

    _userGroups = await _loadUserGroupsFromCache();
    _userGroupNames = _buildGroupNames(_userGroups);

    if (_userGroups == null) {
      await _initUserGroupsFromNet();
    }
    else {
      _waitForUpdateUserGroupsFromNet();
    }

    await super.initService();
  }

  @override
  void initServiceUI() {
    processCachedGroupDetails();
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
    } else if (name == FirebaseMessaging.notifyGroupsNotification){
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
      _waitForUpdateUserGroupsFromNet();
    }
    else {
      _loggedIn = false;
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
          _waitForUpdateUserGroupsFromNet();
        }
      }
    }
  }

  void _onFirebaseMessageForGroupUpdate() {
      _waitForUpdateUserGroupsFromNet();
  }

  // Current User Membership

  Future<bool> isAdminForGroup(String groupId) async {
    Group? group = await loadGroup(groupId);
    return group?.currentUserIsAdmin ?? false;
  }

  // Categories APIs

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

  Future<List<String>?> loadTags() async {
    return Events().loadEventTags();
  }

  // Groups APIs

  // MD: This method is important for user data migration.
  // This method is supposed to run only once in the app lifecycle with user login due to the  _loggedIn flag
  // Please keep in mind there may be old legacy users that haven't been migrated yet and this method resolves this scenario. 
  @protected
  Future<void> waitForLogin() async{
    if(!_loggedIn && Auth2().isLoggedIn) {
      try {
        if (_loginCompleters.isEmpty) {
          Completer<void> completer = Completer<void>();
          _loginCompleters.add(completer);
          _login().whenComplete(() {
            _loggedIn = true;
            for (var completer in _loginCompleters) {
              completer.complete();
            }
            _loginCompleters.clear();
          });
          return completer.future;
        } else {
          Completer<void> completer = Completer<void>();
          _loginCompleters.add(completer);
          return completer.future;
        }
      } catch(err){
        Log.e("Failed to invoke groups login API");
        debugPrint(err.toString());
      }
    }
  }

  Future<void> _login() async{
      try {
        if ((Config().groupsUrl != null) && Auth2().isLoggedIn) {
          try {
            String url = '${Config().groupsUrl}/user/login';
            await Network().get(url, auth: Auth2(),);

            // we need just to be sure the request is made no matter for the result at this point
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      } catch (err) {
        debugPrint(err.toString());
      }
  }

  ///
  /// Do not load user groups on portions / pages. We cached and use them for checks in flexUi and checklist
  ///
  /// Note: Do not allow loading on portions (paging) - there is a problem on the backend. Revert when it is fixed. 
  Future<List<Group>?> loadGroups({GroupsContentType? contentType, String? category}) async {
    if (contentType == GroupsContentType.my) {
      await _waitForUpdateUserGroupsFromNet();
      return userGroups;
    } else {
      return await _loadAllGroups(category: category);
    }
  }

  Future<List<Group>?> _loadAllGroups({String? category, String? title, GroupPrivacy? privacy}) async {
    await waitForLogin();
    if (Config().groupsUrl != null) {
      Map<String, String> queryParams = {};
      if (StringUtils.isNotEmpty(category)) {
        queryParams.addAll({'category': category!});
      }
      if (StringUtils.isNotEmpty(title)) {
        queryParams.addAll({'title': title!});
      }
      if (privacy != null) {
        queryParams.addAll({'privacy': groupPrivacyToString(privacy)!});
      }
      /*
      // TMP disable paging - there is a problem on the backend
      if (offset != null) {
        queryParams.addAll({'offset': offset.toString()});
      }
      if (limit != null) {
        queryParams.addAll({'limit': limit.toString()});
      }*/
      String url = '${Config().groupsUrl}/v2/groups';
      if (queryParams.isNotEmpty) {
        url = UrlUtils.addQueryParameters(url, queryParams);
      }
      
      try {
        Response? response = await Network().get(url, auth: Auth2());
        int responseCode = response?.statusCode ?? -1;
        String? responseBody = response?.body;
        if (responseCode == 200) {
          List<dynamic>? groupsJson = JsonUtils.decodeList(responseBody);
          return Group.listFromJson(groupsJson);
        } else {
          debugPrint('Failed to load all groups for url {$url}. Response: $responseCode $responseBody');
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }

    return null;
  }

  Future<List<Group>?> searchGroups(String searchText, {bool includeHidden = false}) async {
    await waitForLogin();
    if (StringUtils.isEmpty(searchText)) {
      return null;
    }
    String encodedTExt = Uri.encodeComponent(searchText);
    String url = '${Config().groupsUrl}/v2/groups?title=$encodedTExt${includeHidden? "&include_hidden=true" :""}';
    Response? response = await Network().get(url, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      return Group.listFromJson(JsonUtils.decodeList(responseBody));
    } else {
      debugPrint('Failed to search for groups. Reason: ');
      debugPrint(responseBody);
      return null;
    }
  }

  Future<Group?> loadGroup(String? groupId) async {
    await waitForLogin();
    if (StringUtils.isNotEmpty(groupId)) {
      String url = '${Config().groupsUrl}/v2/groups/$groupId';
      try {
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
    await waitForLogin();
    if(group != null) {
      String url = '${Config().groupsUrl}/groups';
      try {
        Map<String, dynamic> json = group.toJson(withId: false);
        json["creator_email"] = Auth2().account?.profile?.email ?? "";
        json["creator_name"] = Auth2().account?.profile?.fullName ?? "";
        String? body = JsonUtils.encode(json);
        Response? response = await Network().post(url, auth: Auth2(), body: body);
        int responseCode = response?.statusCode ?? -1;
        Map<String, dynamic>? jsonData = JsonUtils.decodeMap(response?.body);
        if (responseCode == 200) {
          String? groupId = (jsonData != null) ? JsonUtils.stringValue(jsonData['inserted_id']) : null;
          if (StringUtils.isNotEmpty(groupId)) {
            NotificationService().notify(notifyGroupCreated, group.id);
            _waitForUpdateUserGroupsFromNet();
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

    await waitForLogin();

    if(group != null) {
      String url = '${Config().groupsUrl}/groups/${group.id}';
      try {
        Map<String, dynamic> json = group.toJson();
        String? body = JsonUtils.encode(json);
        Response? response = await Network().put(url, auth: Auth2(), body: body);
        int responseCode = response?.statusCode ?? -1;
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
    await waitForLogin();
    if (StringUtils.isEmpty(groupId)) {
      return false;
    }
    String url = '${Config().groupsUrl}/group/$groupId';
    Response? response = await Network().delete(url, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      NotificationService().notify(notifyGroupDeleted, null);
      _waitForUpdateUserGroupsFromNet();
      return true;
    } else {
      Log.i('Failed to delete group. Reason:\n${response?.body}');
      return false;
    }
  }

  Future<bool> syncAuthmanGroup({required Group group}) async {
    if (!group.syncAuthmanAllowed) {
      debugPrint('Current user is not allowed to sync group "${group.id}" in authman.');
      return false;
    }
    await waitForLogin();
    String url = '${Config().groupsUrl}/group/${group.id}/authman/synchronize';
    Response? response = await Network().post(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    if (responseCode == 200) {
      _waitForUpdateUserGroupsFromNet();
      return true;
    } else {
      debugPrint('Failed to synchronize authman group. \nReason: $responseCode, ${response?.body}');
      return false;
    }
  }

  // Group Stats

  Future<GroupStats?> loadGroupStats(String? groupId) async {
    if (StringUtils.isEmpty(groupId)) {
      return null;
    }
    await waitForLogin();
    if (StringUtils.isNotEmpty(groupId)) {
      String url = '${Config().groupsUrl}/group/$groupId/stats';
      try {
        Response? response = await Network().get(url, auth: Auth2());
        int responseCode = response?.statusCode ?? -1;
        String? responseBody = response?.body;
        if (responseCode == 200) {
          Map<String, dynamic>? statsJson = JsonUtils.decodeMap(responseBody);
          return GroupStats.fromJson(statsJson);
        } else {
          debugPrint('Failed to load group stats for group {$groupId}. Reason: $responseCode, $responseBody');
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  // Members APIs

  Future<List<Member>?> loadMembers({String? groupId, List<GroupMemberStatus>? statuses, String? memberId, List<String>? userIds,
    String? externalId, String? netId, String? name, int? offset, int? limit}) async {
    if (StringUtils.isEmpty(groupId)) {
      debugPrint('Failed to load group members - missing groupId.');
      return null;
    }
    await waitForLogin();
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
    await waitForLogin();
    if(group != null) {
      String url = '${Config().groupsUrl}/group/${group.id}/pending-members';
      try {
        Map<String, dynamic> json = {};
        json["email"] = Auth2().account?.profile?.email ?? "";
        json["name"] = Auth2().account?.profile?.fullName ?? "";
        json["member_answers"] = CollectionUtils.isNotEmpty(answers) ? answers!.map((e) => e.toJson()).toList() : [];

        String? body = JsonUtils.encode(json);
        Response? response = await Network().post(url, auth: Auth2(), body: body);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupMembershipRequested, group);
          NotificationService().notify(notifyGroupUpdated, group.id);
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> cancelRequestMembership(Group? group) async{
    await waitForLogin();
    if(group?.id != null) {
      String url = '${Config().groupsUrl}/group/${group!.id}/pending-members';
      try {
        Response? response = await Network().delete(url, auth: Auth2(),);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupMembershipCanceled, group);
          NotificationService().notify(notifyGroupUpdated, group.id);
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> leaveGroup(Group? group) async {
    await waitForLogin();
    if (StringUtils.isEmpty(group?.id)) {
      return false;
    }
    String url = '${Config().groupsUrl}/group/${group!.id}/members';
    Response? response = await Network().delete(url, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      NotificationService().notify(notifyGroupMembershipQuit, group);
      NotificationService().notify(notifyGroupUpdated, group.id);
      _waitForUpdateUserGroupsFromNet();
      return true;
    } else {
      String? responseString = response?.body;
      debugPrint(responseString);
      return false;
    }
  }

  Future<bool> acceptMembership(Group? group, Member? member, bool? decision, String? reason) async{
    await waitForLogin();
    if(StringUtils.isNotEmpty(group?.id) && StringUtils.isNotEmpty(member?.id) && decision != null) {
      Map<String, dynamic> bodyMap = {"approve": decision, "reject_reason": reason};
      String? body = JsonUtils.encode(bodyMap);
      String url = '${Config().groupsUrl}/memberships/${member!.id}/approval';
      try {
        Response? response = await Network().put(url, auth: Auth2(), body: body);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(decision ? notifyGroupMembershipApproved : notifyGroupMembershipRejected, group);
          NotificationService().notify(notifyGroupUpdated, group?.id);
          _waitForUpdateUserGroupsFromNet();
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> updateMembership(Group? group, String? memberId, GroupMemberStatus status) async{
    await waitForLogin();
    if(StringUtils.isNotEmpty(group?.id) && StringUtils.isNotEmpty(memberId)) {
      Map<String, dynamic> bodyMap = {"status":groupMemberStatusToString(status)};
      String? body = JsonUtils.encode(bodyMap);
      String url = '${Config().groupsUrl}/memberships/$memberId';
      try {
        Response? response = await Network().put(url, auth: Auth2(), body: body);
        if((response?.statusCode ?? -1) == 200){
          if (status == GroupMemberStatus.admin) {
            NotificationService().notify(notifyGroupMembershipSwitchToAdmin, group);
          }
          else if (status == GroupMemberStatus.member) {
            NotificationService().notify(notifyGroupMembershipSwitchToMember, group);
          }
          NotificationService().notify(notifyGroupUpdated, group!.id);
          _waitForUpdateUserGroupsFromNet();
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> deleteMembership(Group? group, String? memberId) async{
    await waitForLogin();
    if(StringUtils.isNotEmpty(group?.id) && StringUtils.isNotEmpty(memberId)) {
      String url = '${Config().groupsUrl}/memberships/$memberId';
      try {
        Response? response = await Network().delete(url, auth: Auth2(),);
        if((response?.statusCode ?? -1) == 200){
          NotificationService().notify(notifyGroupMembershipRemoved, group);
          NotificationService().notify(notifyGroupUpdated, group?.id);
          _waitForUpdateUserGroupsFromNet();
          return true;
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false; // fail
  }

  Future<bool> memberAttended({required Group group, required Member member}) async {
    await waitForLogin();
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
      Response? response;
      if (isNewMember) {
        response = await Network().post(url, body: memberJsonBody, auth: Auth2());
      } else {
        response = await Network().put(url, body: memberJsonBody, auth: Auth2());
      }
      int? responseCode = response?.statusCode;
      String? responseString = response?.body;
      if (responseCode == 200) {
        NotificationService().notify(notifyGroupMemberAttended, null);
        NotificationService().notify(notifyGroupUpdated, group.id);
        _waitForUpdateUserGroupsFromNet();
        return true;
      } else {
        debugPrint('Failed to attend a member to group. \nResponse: $responseCode, $responseString');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return false;
  }


// Events
  Future<List<String>?> loadEventIds(String? groupId) async{
    await waitForLogin();
    if(StringUtils.isNotEmpty(groupId)) {
      String url = '${Config().groupsUrl}/group/$groupId/events';
      try {
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
  }

  /// 
  /// Loads group events based on the current user membership
  /// 
  /// Returns Map with single element:
  ///
  /// key - all events count ignoring the limit,
  /// 
  /// value - events (limited or not)
  ///
  Future<Map<int, List<Event>>?> loadEvents (Group? group, {int limit = -1}) async {
    await waitForLogin();
    if (group != null) {
      List<String>? eventIds = await loadEventIds(group.id);
      List<Event>? allEvents = CollectionUtils.isNotEmpty(eventIds) ? await Events().loadEventsByIds(eventIds) : null;
      if (CollectionUtils.isNotEmpty(allEvents)) {
        List<Event> currentUserEvents = [];
        bool isCurrentUserMemberOrAdmin = group.currentUserIsMemberOrAdmin;
        for (Event event in allEvents!) {
          bool isPrivate = event.isGroupPrivate!;
          if (!isPrivate || isCurrentUserMemberOrAdmin) {
            currentUserEvents.add(event);
          }
        }
        int eventsCount = currentUserEvents.length;
        SortUtils.sort(currentUserEvents);
        //limit the result count // limit available events
        List<Event> visibleEvents = ((limit > 0) && (eventsCount > limit)) ? currentUserEvents.sublist(0, limit) : currentUserEvents;
        List<Event> groupEvents = <Event>[];
        for (Event event in visibleEvents) {
          ListUtils.add(groupEvents, Event.fromJson(event.toJson()));
        }
        return {eventsCount: groupEvents};
      }
    }
    return null;
  }

  Future<bool> linkEventToGroup({String? groupId, String? eventId, List<Member>? toMembers}) async {
    await waitForLogin();
    if(StringUtils.isNotEmpty(groupId) && StringUtils.isNotEmpty(eventId)) {
      String url = '${Config().groupsUrl}/group/$groupId/events';
      try {
        Map<String, dynamic> bodyMap = {"event_id":eventId};
        if(CollectionUtils.isNotEmpty(toMembers)){
          bodyMap["to_members"] = JsonUtils.encodeList(toMembers ?? []);
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
    await waitForLogin();
    if(StringUtils.isNotEmpty(groupId) && StringUtils.isNotEmpty(eventId)) {
      String url = '${Config().groupsUrl}/group/$groupId/events';
      try {
        Map<String, dynamic> bodyMap = {"event_id":eventId};
        if(CollectionUtils.isNotEmpty(toMembers)){
          bodyMap["to_members"] = JsonUtils.encodeList(toMembers ?? []);
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

  Future<bool> removeEventFromGroup({String? groupId, String? eventId}) async {
    await waitForLogin();
    if(StringUtils.isNotEmpty(groupId) && StringUtils.isNotEmpty(eventId)) {
      String url = '${Config().groupsUrl}/group/$groupId/event/$eventId';
      try {
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
        Response? response = await Network().get(url, auth: Auth2());
        int responseCode = response?.statusCode ?? -1;
        String? responseBody = response?.body;
        if (responseCode == 200) {
          List<dynamic>? groupEventLinkSettingsJson = (responseBody != null) ? JsonUtils.decodeList(responseBody) : null; //List of settings for all events //Probbably can pass paramether to backend
          if(groupEventLinkSettingsJson?.isNotEmpty ?? false) { //Find settings for this event
            dynamic eventSettings = groupEventLinkSettingsJson!.firstWhere((element) {
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

  Future<String?> updateGroupEvents(Event event) async {
    await waitForLogin();
    String? id = await Events().updateEvent(event);
    if (StringUtils.isNotEmpty(id)) {
      NotificationService().notify(Groups.notifyGroupEventsUpdated);
    }
    return id;
  }

  Future<bool?> deleteEventFromGroup({String? groupId, required Event event}) async {
    bool? deleteResult = false;
    await removeEventFromGroup(groupId: groupId, eventId: event.id);
    String? creatorGroupId = event.createdByGroupId;
    if(creatorGroupId!=null){
      Group? creatorGroup = await loadGroup(creatorGroupId);
      if(creatorGroup!=null && creatorGroup.currentUserIsAdmin){
        deleteResult = await Events().deleteEvent(event.id);
      }
    }
    NotificationService().notify(Groups.notifyGroupEventsUpdated);
    return deleteResult;
  }

  // Group Posts and Replies

  Future<bool> createPost(String? groupId, GroupPost? post) async {
    await waitForLogin();
    if (StringUtils.isEmpty(groupId) || (post == null)) {
      return false;
    }
    String? requestBody = JsonUtils.encode(post.toJson(create: true));
    String requestUrl = '${Config().groupsUrl}/group/$groupId/posts';
    Response? response = await Network().post(requestUrl, auth: Auth2(), body: requestBody);
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      NotificationService().notify(notifyGroupPostsUpdated, (post.parentId == null) ? 1 : null);
      return true;
    } else {
      Log.e('Failed to create group post. Response: ${response?.body}');
      return false;
    }
  }

  Future<bool> updatePost(String? groupId, GroupPost? post) async {
    await waitForLogin();
    if (StringUtils.isEmpty(groupId) || StringUtils.isEmpty(post?.id)) {
      return false;
    }
    String? requestBody = JsonUtils.encode(post!.toJson(update: true));
    String requestUrl = '${Config().groupsUrl}/group/$groupId/posts/${post.id}';
    Response? response = await Network().put(requestUrl, auth: Auth2(), body: requestBody);
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      NotificationService().notify(notifyGroupPostsUpdated);
      return true;
    } else {
      Log.e('Failed to update group post. Response: ${response?.body}');
      return false;
    }
  }

  Future<bool> deletePost(String? groupId, GroupPost? post) async {
    await waitForLogin();
    if (StringUtils.isEmpty(groupId) || StringUtils.isEmpty(post?.id)) {
      return false;
    }
    String requestUrl = '${Config().groupsUrl}/group/$groupId/posts/${post!.id}';
    Response? response = await Network().delete(requestUrl, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      NotificationService().notify(notifyGroupPostsUpdated, (post.parentId == null) ? -1 : null);
      return true;
    } else {
      Log.e('Failed to delete group post. Response: ${response?.body}');
      return false;
    }
  }

  Future<List<GroupPost>?> loadGroupPosts(String? groupId, {int? offset, int? limit, GroupSortOrder? order}) async {
    await waitForLogin();
    if (StringUtils.isEmpty(groupId)) {
      return null;
    }
    
    String urlParams = "";
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
    
    String requestUrl = '${Config().groupsUrl}/group/$groupId/posts$urlParams';
    Response? response = await Network().get(requestUrl, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<GroupPost>? posts = GroupPost.fromJsonList(JsonUtils.decodeList(responseString));
      return posts;
    } else {
      Log.e('Failed to retrieve group posts. Response: ${response?.body}');
      return null;
    }
  }

  Future<GroupPost?> loadGroupPost({required String? groupId, required String? postId}) async {
    await waitForLogin();
    if (StringUtils.isEmpty(groupId) || StringUtils.isEmpty(postId)) {
      return null;
    }

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
    List<dynamic>? templatesContentItems = await Content().loadContentItems(categories: ['gies_post_templates']);
    dynamic templatesContentItem = templatesContentItems?.first; // "gies.templates" are placed in a single content item.
    if (templatesContentItem is! Map) {
      return null;
    }
    Map<String, dynamic> templatesItem = templatesContentItem.cast<String, dynamic>();
    dynamic templatesJson = templatesItem['data'];
    if (templatesJson is! List) {
      return null;
    }
    List<dynamic> templatesArray = templatesJson.cast<dynamic>();
    List<GroupPostNudge>? allTemplates = GroupPostNudge.fromJsonList(templatesArray);
    List<GroupPostNudge>? groupNudges;
    if (CollectionUtils.isNotEmpty(allTemplates)) {
      groupNudges = <GroupPostNudge>[];
      for (GroupPostNudge template in allTemplates!) {
        GroupPostNudge? nudge = _getNudgeForGroup(groupName: groupName, template: template);
        if (nudge != null) {
          groupNudges.add(nudge);
        }
      }
    }
    return groupNudges;
  }

  Future<bool> togglePostReaction(String? groupId, String? postId, String reaction) async {
    if ((Config().groupsUrl != null) && StringUtils.isNotEmpty(groupId) && StringUtils.isNotEmpty(postId)) {
      await waitForLogin();
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
  void deleteUserData() async{
    try {
      Response? response = (Auth2().isLoggedIn && Config().notificationsUrl != null) ? await Network().delete("${Config().groupsUrl}/user", auth: Auth2()) : null;
      if(response?.statusCode == 200) {
        Log.d('Successfully deleted groups user data');
      }
    } catch (e) {
      Log.e('Failed to load inbox user info');
      Log.e(e.toString());
    }
  }

  Future<Map<String, dynamic>?> loadUserStats() async {
    try {
      Response? response = (Auth2().isLoggedIn && Config().notificationsUrl != null) ? await Network().get("${Config().groupsUrl}/user/stats", auth: Auth2()) : null;
      if(response?.statusCode == 200) {
        return  JsonUtils.decodeMap(response?.body);
      }
    } catch (e) {
      Log.e('Failed to load user stats');
      Log.e(e.toString());
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
        try { handleGroupDetail(uri.queryParameters.cast<String, dynamic>()); }
        catch (e) { debugPrint(e.toString()); }
      }
    }
  }

  @protected
  void handleGroupDetail(Map<String, dynamic>? params) {
    if ((params != null) && params.isNotEmpty) {
      if (_groupDetailsCache != null) {
        cacheGroupDetail(params);
      }
      else {
        processGroupDetail(params);
      }
    }
  }

  @protected
  void processGroupDetail(Map<String, dynamic> params) {
    NotificationService().notify(notifyGroupDetail, params);
  }

  @protected
  void cacheGroupDetail(Map<String, dynamic> params) {
    _groupDetailsCache?.add(params);
  }

  @protected
  void processCachedGroupDetails() {
    if (_groupDetailsCache != null) {
      List<Map<String, dynamic>> groupDetailsCache = _groupDetailsCache!;
      _groupDetailsCache = null;

      for (Map<String, dynamic> groupDetail in groupDetailsCache) {
        processGroupDetail(groupDetail);
      }
    }
  }

  // User Groups

  List<Group>? get userGroups => _userGroups;

  Set<String>? get userGroupNames => _userGroupNames;

  static Future<File?> _getUserGroupsCacheFile() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String cacheFilePath = join(appDocDir.path, _userGroupsCacheFileName);
      return File(cacheFilePath);
    }
    catch(e) { 
      debugPrint(e.toString()); 
    }
    return null;
  }

  static Future<String?> _loadUserGroupsStringFromCache() async {
    try {
      File? cacheFile = await _getUserGroupsCacheFile();
      return (await cacheFile?.exists() == true) ? await cacheFile?.readAsString() : null;
    }
    catch(e) { 
      debugPrint(e.toString()); 
    }
    return null;
  }

  static Future<void> _saveUserGroupsStringToCache(String? value) async {
    try {
      File? cacheFile = await _getUserGroupsCacheFile();
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

  static Future<List<Group>?> _loadUserGroupsFromCache() async {
    return Group.listFromJson(JsonUtils.decodeList(await _loadUserGroupsStringFromCache()));
  }

  static Future<String?> _loadUserGroupsStringFromNet() async {
    if (StringUtils.isNotEmpty(Config().groupsUrl) && Auth2().isLoggedIn) {
      // Load all user groups because we cache them and use them for various checks on startup like flexUI etc
      Response? response = await Network().get('${Config().groupsUrl}/v2/user/groups', auth: Auth2());
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

  Future<void> _waitForUpdateUserGroupsFromNet() async{
    waitForLogin().then((value){
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
    });
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

  static Future<File?> _getAttendedMembersCacheFile() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String cacheFilePath = join(appDocDir.path, _attendedMembersCacheFileName);
      return File(cacheFilePath);
    }
    catch(e) { 
      debugPrint(e.toString()); 
    }
    return null;
  }

  static Future<String?> _loadAttendedMembersStringFromCache() async {
    try {
      File? cacheFile = await _getAttendedMembersCacheFile();
      return (await cacheFile?.exists() == true) ? await cacheFile?.readAsString() : null;
    }
    catch(e) { 
      debugPrint(e.toString()); 
    }
    return null;
  }

  static Future<void> _saveAttendedMembersStringToCache(String? value) async {
    try {
      File? cacheFile = await _getAttendedMembersCacheFile();
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

  static Future<Map<String, List<Member>?>?> _loadAttendedMembersFromCache() async {
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