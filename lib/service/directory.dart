import 'package:http/http.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/directory.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Directory {

  // Singleton Factory

  static final Directory _instance = Directory._internal();
  factory Directory() => _instance;
  Directory._internal();

  Future<List<Auth2PublicAccount>?> loadAccounts({String? search,
    String? userName, String? firstName, String? lastName,
    String? followingId, String? followerId,
    int? offset, int? limit}) async {

    return _sampleAccounts;

    // ignore: dead_code
    if (Config().coreUrl != null) {
      String url = UrlUtils.addQueryParameters("${Config().coreUrl}/services/accounts/public", <String, String>{
        if (search != null)
          'search': search,

        if (userName != null)
          'username': userName,
        if (firstName != null)
          'firstname': firstName,
        if (lastName != null)
          'lastname': lastName,

        if (followingId != null)
          'following-id': followingId,
        if (followerId != null)
          'follower-id': followerId,

        if (offset != null)
          'offset': offset.toString(),
        if (limit != null)
          'limit': limit.toString(),
      });

      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode == 200) ? Auth2PublicAccount.listFromJson(JsonUtils.decodeList(response?.body)) : null;
    }
    return null;
  }

  List<Auth2PublicAccount> get _sampleAccounts {
    List<String> manPhotos = <String>[
      'https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/842980/pexels-photo-842980.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/2379005/pexels-photo-2379005.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/262391/pexels-photo-262391.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/25758/pexels-photo.jpg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
    ];

    List<String> womanPhotos = <String>[
      'https://images.pexels.com/photos/1239288/pexels-photo-1239288.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/1102341/pexels-photo-1102341.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/3541389/pexels-photo-3541389.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/1855582/pexels-photo-1855582.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/2681751/pexels-photo-2681751.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
    ];

    return [
      Auth2PublicAccount(id:  '1', profile: Auth2UserProfile(id:  '1', firstName: 'James',      lastName: 'Smith',     email: 'james@illinois.edu',    photoUrl: manPhotos[0],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Academic Affairs', Auth2UserProfile.departmentDataKey: 'Campus Honors Program',       Auth2UserProfile.websiteDataKey: 'linkedin.com/james',},),),
      Auth2PublicAccount(id:  '2', profile: Auth2UserProfile(id:  '2', firstName: 'Mary',       lastName: 'Johnson',   email: 'mary@illinois.edu',     photoUrl: womanPhotos[0], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Chancellor',       Auth2UserProfile.departmentDataKey: 'Academic Human Resources',    Auth2UserProfile.websiteDataKey: 'linkedin.com/mary',},),),
      Auth2PublicAccount(id:  '3', profile: Auth2UserProfile(id:  '3', firstName: 'Michael',    lastName: 'Williams',  email: 'michael@illinois.edu',  photoUrl: manPhotos[1],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Armed Forces',     Auth2UserProfile.departmentDataKey: 'Air Force Aerospace Studies', Auth2UserProfile.websiteDataKey: 'linkedin.com/michael',},),),
      Auth2PublicAccount(id:  '4', profile: Auth2UserProfile(id:  '4', firstName: 'Patricia',   lastName: 'Brown',     email: 'patricia@illinois.edu', photoUrl: womanPhotos[1], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Education',        Auth2UserProfile.departmentDataKey: 'Curriculum and Instruction',  Auth2UserProfile.websiteDataKey: 'linkedin.com/patricia',},),),
      Auth2PublicAccount(id:  '5', profile: Auth2UserProfile(id:  '5', firstName: 'Robert',     lastName: 'Jones',     email: 'robert@illinois.edu',   photoUrl: manPhotos[2],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Law',              Auth2UserProfile.departmentDataKey: 'Law Library',                 Auth2UserProfile.websiteDataKey: 'linkedin.com/robert',},),),
      Auth2PublicAccount(id:  '6', profile: Auth2UserProfile(id:  '6', firstName: 'Jennifer',   lastName: 'Garcia',    email: 'jennifer@illinois.edu', photoUrl: womanPhotos[2], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Academic Affairs', Auth2UserProfile.departmentDataKey: 'Office of the Registrar',     Auth2UserProfile.websiteDataKey: 'linkedin.com/jennifer',},),),
      Auth2PublicAccount(id:  '7', profile: Auth2UserProfile(id:  '7', firstName: 'John',       lastName: 'Miller',    email: 'john@illinois.edu',     photoUrl: manPhotos[3],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Public Safety',    Auth2UserProfile.departmentDataKey: 'Fire Service Institute',      Auth2UserProfile.websiteDataKey: 'linkedin.com/john',},),),
      Auth2PublicAccount(id:  '8', profile: Auth2UserProfile(id:  '8', firstName: 'Linda',      lastName: 'Davis',     email: 'linda@illinois.edu',    photoUrl: womanPhotos[3], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Chancellor',       Auth2UserProfile.departmentDataKey: 'Illinois Human Resources',    Auth2UserProfile.websiteDataKey: 'linkedin.com/linda',},),),
      Auth2PublicAccount(id:  '9', profile: Auth2UserProfile(id:  '9', firstName: 'David',      lastName: 'Rodriguez', email: 'david@illinois.edu',    photoUrl: manPhotos[4],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Education',        Auth2UserProfile.departmentDataKey: 'Education Administration',    Auth2UserProfile.websiteDataKey: 'linkedin.com/david',},),),
      Auth2PublicAccount(id: '10', profile: Auth2UserProfile(id: '10', firstName: 'Elizabeth',  lastName: 'Martinez',  email: 'lizbeth@illinois.edu',  photoUrl: womanPhotos[4], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Armed Forces',     Auth2UserProfile.departmentDataKey: 'Military Science',            Auth2UserProfile.websiteDataKey: 'linkedin.com/lizbeth',},),),
      Auth2PublicAccount(id: '11', profile: Auth2UserProfile(id: '11', firstName: 'William',    lastName: 'Hernandez', email: 'william@illinois.edu',  photoUrl: manPhotos[0],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Law',              Auth2UserProfile.departmentDataKey: 'Law',                         Auth2UserProfile.websiteDataKey: 'linkedin.com/william',},),),
      Auth2PublicAccount(id: '12', profile: Auth2UserProfile(id: '12', firstName: 'Barbara',    lastName: 'Lopez',     email: 'barbara@illinois.edu',  photoUrl: womanPhotos[0], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Public Safety',    Auth2UserProfile.departmentDataKey: 'Police Training Institute',   Auth2UserProfile.websiteDataKey: 'linkedin.com/barbara',},),),
      Auth2PublicAccount(id: '13', profile: Auth2UserProfile(id: '13', firstName: 'Richard',    lastName: 'Gonzalez',  email: 'richard@illinois.edu',  photoUrl: manPhotos[1],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Academic Affairs', Auth2UserProfile.departmentDataKey: 'Campus Honors Program',       Auth2UserProfile.websiteDataKey: 'linkedin.com/richard',},),),
      Auth2PublicAccount(id: '14', profile: Auth2UserProfile(id: '14', firstName: 'Susan',      lastName: 'Wilson',    email: 'susan@illinois.edu',    photoUrl: womanPhotos[1], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Student Affairs',  Auth2UserProfile.departmentDataKey: 'Counseling Center',           Auth2UserProfile.websiteDataKey: 'linkedin.com/susan',},),),
      Auth2PublicAccount(id: '15', profile: Auth2UserProfile(id: '15', firstName: 'Joseph',     lastName: 'Anderson',  email: 'joseph@illinois.edu',   photoUrl: manPhotos[2],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Chancellor',       Auth2UserProfile.departmentDataKey: 'Academic Human Resources',    Auth2UserProfile.websiteDataKey: 'linkedin.com/joseph',},),),
      Auth2PublicAccount(id: '16', profile: Auth2UserProfile(id: '16', firstName: 'Jessica',    lastName: 'Thomas',    email: 'jessica@illinois.edu',  photoUrl: womanPhotos[2], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Education',        Auth2UserProfile.departmentDataKey: 'Special Education',           Auth2UserProfile.websiteDataKey: 'linkedin.com/jessica',},),),
      Auth2PublicAccount(id: '17', profile: Auth2UserProfile(id: '17', firstName: 'Thomas',     lastName: 'Taylor',    email: 'thomas@illinois.edu',   photoUrl: manPhotos[3],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Armed Forces',     Auth2UserProfile.departmentDataKey: 'Naval Science',               Auth2UserProfile.websiteDataKey: 'linkedin.com/thomas',},),),
      Auth2PublicAccount(id: '18', profile: Auth2UserProfile(id: '18', firstName: 'Karen',      lastName: 'Moore',     email: 'karen@illinois.edu',    photoUrl: womanPhotos[3], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Public Safety',    Auth2UserProfile.departmentDataKey: 'Fire Service Institute',      Auth2UserProfile.websiteDataKey: 'linkedin.com/karen',},),),
      Auth2PublicAccount(id: '19', profile: Auth2UserProfile(id: '19', firstName: 'Christopher',lastName: 'Jackson',   email: 'christ@illinois.edu',   photoUrl: manPhotos[3],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Law',              Auth2UserProfile.departmentDataKey: 'Law Library',                 Auth2UserProfile.websiteDataKey: 'linkedin.com/christ',},),),
      Auth2PublicAccount(id: '20', profile: Auth2UserProfile(id: '20', firstName: 'Sarah',      lastName: 'Martin',    email: 'sarah@illinois.edu',    photoUrl: womanPhotos[4], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Education',        Auth2UserProfile.departmentDataKey: 'Curriculum and Instruction',  Auth2UserProfile.websiteDataKey: 'linkedin.com/sarah',},),),
      Auth2PublicAccount(id: '21', profile: Auth2UserProfile(id: '21', firstName: 'Charles',    lastName: 'Lee',       email: 'charles@illinois.edu',  photoUrl: manPhotos[0],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Academic Affairs', Auth2UserProfile.departmentDataKey: 'Principal\'s Scholars Pgm',   Auth2UserProfile.websiteDataKey: 'linkedin.com/charles',},),),
      Auth2PublicAccount(id: '22', profile: Auth2UserProfile(id: '22', firstName: 'Lisa',       lastName: 'Perez',     email: 'lisa@illinois.edu',     photoUrl: womanPhotos[0], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Chancellor',       Auth2UserProfile.departmentDataKey: 'Illinois Human Resources',    Auth2UserProfile.websiteDataKey: 'linkedin.com/lisa',},),),
      Auth2PublicAccount(id: '23', profile: Auth2UserProfile(id: '23', firstName: 'Daniel',     lastName: 'Thompson',  email: 'daniel@illinois.edu',   photoUrl: manPhotos[1],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Law',              Auth2UserProfile.departmentDataKey: 'Law',                         Auth2UserProfile.websiteDataKey: 'linkedin.com/daniel',},),),
      Auth2PublicAccount(id: '24', profile: Auth2UserProfile(id: '24', firstName: 'Nancy',      lastName: 'White',     email: 'nancy@illinois.edu',    photoUrl: womanPhotos[1], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Armed Forces',     Auth2UserProfile.departmentDataKey: 'Military Science',            Auth2UserProfile.websiteDataKey: 'linkedin.com/nancy',},),),
      Auth2PublicAccount(id: '25', profile: Auth2UserProfile(id: '25', firstName: 'Matthew',    lastName: 'Harris',    email: 'matthew@illinois.edu',  photoUrl: manPhotos[2],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Education',        Auth2UserProfile.departmentDataKey: 'Education Administration',    Auth2UserProfile.websiteDataKey: 'linkedin.com/matthew',},),),
      Auth2PublicAccount(id: '26', profile: Auth2UserProfile(id: '26', firstName: 'Sandra',     lastName: 'Sanchez',   email: 'sandra@illinois.edu',   photoUrl: womanPhotos[2], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Public Safety',    Auth2UserProfile.departmentDataKey: 'Police Training Institute',   Auth2UserProfile.websiteDataKey: 'linkedin.com/sandra',},),),
      Auth2PublicAccount(id: '27', profile: Auth2UserProfile(id: '27', firstName: 'Anthony',    lastName: 'Clark',     email: 'anthony@illinois.edu',  photoUrl: manPhotos[3],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Academic Affairs', Auth2UserProfile.departmentDataKey: 'Office of the Registrar',     Auth2UserProfile.websiteDataKey: 'linkedin.com/anthony',},),),
      Auth2PublicAccount(id: '28', profile: Auth2UserProfile(id: '28', firstName: 'Betty',      lastName: 'Ramirez',   email: 'betty@illinois.edu',    photoUrl: womanPhotos[3], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Student Affairs',  Auth2UserProfile.departmentDataKey: 'Campus Recreation',           Auth2UserProfile.websiteDataKey: 'linkedin.com/betty',},),),
      Auth2PublicAccount(id: '29', profile: Auth2UserProfile(id: '29', firstName: 'Mark',       lastName: 'Lewis',     email: 'mark@illinois.edu',     photoUrl: manPhotos[3],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Chancellor',       Auth2UserProfile.departmentDataKey: 'News Bureau',                 Auth2UserProfile.websiteDataKey: 'linkedin.com/mark',},),),
      Auth2PublicAccount(id: '30', profile: Auth2UserProfile(id: '30', firstName: 'Ashley',     lastName: 'Robinson',  email: 'ashley@illinois.edu',   photoUrl: womanPhotos[4], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Armed Forces',     Auth2UserProfile.departmentDataKey: 'Clinical Sciences',           Auth2UserProfile.websiteDataKey: 'linkedin.com/ashley',},),),
      Auth2PublicAccount(id: '31', profile: Auth2UserProfile(id: '31', firstName: 'Donald',     lastName: 'Walker',    email: 'donald@illinois.edu',   photoUrl: manPhotos[0],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Education',        Auth2UserProfile.departmentDataKey: 'Special Education',           Auth2UserProfile.websiteDataKey: 'linkedin.com/donald',},),),
      Auth2PublicAccount(id: '32', profile: Auth2UserProfile(id: '32', firstName: 'Emily',      lastName: 'Allenb',    email: 'emily@illinois.edu',    photoUrl: womanPhotos[0], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Student Affairs',  Auth2UserProfile.departmentDataKey: 'Counseling Center',           Auth2UserProfile.websiteDataKey: 'linkedin.com/emily',},),),
      Auth2PublicAccount(id: '33', profile: Auth2UserProfile(id: '33', firstName: 'Steven',     lastName: 'King',      email: 'steven@illinois.edu',   photoUrl: manPhotos[1],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Academic Affairs', Auth2UserProfile.departmentDataKey: 'Principal\'s Scholars Pgm',   Auth2UserProfile.websiteDataKey: 'linkedin.com/steven',},),),
      Auth2PublicAccount(id: '34', profile: Auth2UserProfile(id: '34', firstName: 'Kimberly',   lastName: 'Wright',    email: 'kimberly@illinois.edu', photoUrl: womanPhotos[1], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Law',              Auth2UserProfile.departmentDataKey: 'Law',                         Auth2UserProfile.websiteDataKey: 'linkedin.com/kimberly',},),),
      Auth2PublicAccount(id: '35', profile: Auth2UserProfile(id: '35', firstName: 'Andrew',     lastName: 'Scott',     email: 'andrew@illinois.edu',   photoUrl: manPhotos[2],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Public Safety',    Auth2UserProfile.departmentDataKey: 'Police Training Institute',   Auth2UserProfile.websiteDataKey: 'linkedin.com/andrew',},),),
      Auth2PublicAccount(id: '36', profile: Auth2UserProfile(id: '36', firstName: 'Margaret',   lastName: 'Torres',    email: 'margaret@illinois.edu', photoUrl: womanPhotos[2], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Armed Forces',     Auth2UserProfile.departmentDataKey: 'Naval Science',               Auth2UserProfile.websiteDataKey: 'linkedin.com/margaret',},),),
      Auth2PublicAccount(id: '37', profile: Auth2UserProfile(id: '37', firstName: 'Paul',       lastName: 'Nguyen',    email: 'paul@illinois.edu',     photoUrl: manPhotos[3],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Education',        Auth2UserProfile.departmentDataKey: 'Education Administration',    Auth2UserProfile.websiteDataKey: 'linkedin.com/paul',},),),
      Auth2PublicAccount(id: '38', profile: Auth2UserProfile(id: '38', firstName: 'Donna',      lastName: 'Hill',      email: 'dona@illinois.edu',     photoUrl: womanPhotos[3], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Chancellor',       Auth2UserProfile.departmentDataKey: 'News Bureau',                 Auth2UserProfile.websiteDataKey: 'linkedin.com/dona',},),),
      Auth2PublicAccount(id: '39', profile: Auth2UserProfile(id: '39', firstName: 'Joshua',     lastName: 'Flores',    email: 'joshua@illinois.edu',   photoUrl: manPhotos[3],   data: { Auth2UserProfile.pronounDataKey: 'he',  Auth2UserProfile.collegeDataKey: 'Academic Affairs', Auth2UserProfile.departmentDataKey: 'Provost/VCAA Admin',          Auth2UserProfile.websiteDataKey: 'linkedin.com/joshua',},),),
      Auth2PublicAccount(id: '40', profile: Auth2UserProfile(id: '40', firstName: 'Michelle',   lastName: 'Green',     email: 'michelle@illinois.edu', photoUrl: womanPhotos[4], data: { Auth2UserProfile.pronounDataKey: 'she', Auth2UserProfile.collegeDataKey: 'Law',              Auth2UserProfile.departmentDataKey: 'Law Library',                 Auth2UserProfile.websiteDataKey: 'linkedin.com/michelle',},),),
    ];
  }

}