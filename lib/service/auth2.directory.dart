import 'package:http/http.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension Auh2Directory on Auth2 {

  // Singleton Factory

  Future<List<Auth2PublicAccount>?> loadDirectoryAccounts({String? search,
    String? userName, String? firstName, String? lastName,
    String? followingId, String? followerId,
    int? offset, int? limit}) async {

    //TMP: return _sampleAccounts;
    //TMP: // ignore: dead_code

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

  // ignore: unused_element
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

    String pronunciationUrl = 'https://api-dev.rokwire.illinois.edu/content/voice_record';

    return [
      Auth2PublicAccount(id:  '1', profile: Auth2UserProfile(id:  '1', firstName: 'James',      lastName: 'Smith',     pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'james@illinois.edu',    photoUrl: manPhotos[0],   website: 'linkedin.com/james',    data: {'college': 'Academic Affairs', 'department': 'Campus Honors Program'})),
      Auth2PublicAccount(id:  '2', profile: Auth2UserProfile(id:  '2', firstName: 'Mary',       lastName: 'Johnson',   pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'mary@illinois.edu',     photoUrl: womanPhotos[0], website: 'linkedin.com/mary',     data: {'college': 'Chancellor',       'department': 'Academic Human Resources'})),
      Auth2PublicAccount(id:  '3', profile: Auth2UserProfile(id:  '3', firstName: 'Michael',    lastName: 'Williams',  pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'michael@illinois.edu',  photoUrl: manPhotos[1],   website: 'linkedin.com/michael',  data: {'college': 'Armed Forces',     'department': 'Air Force Aerospace Studies'})),
      Auth2PublicAccount(id:  '4', profile: Auth2UserProfile(id:  '4', firstName: 'Patricia',   lastName: 'Brown',     pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'patricia@illinois.edu', photoUrl: womanPhotos[1], website: 'linkedin.com/patricia', data: {'college': 'Education',        'department': 'Curriculum and Instruction'})),
      Auth2PublicAccount(id:  '5', profile: Auth2UserProfile(id:  '5', firstName: 'Robert',     lastName: 'Jones',     pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'robert@illinois.edu',   photoUrl: manPhotos[2],   website: 'linkedin.com/robert',   data: {'college': 'Law',              'department': 'Law Library'})),
      Auth2PublicAccount(id:  '6', profile: Auth2UserProfile(id:  '6', firstName: 'Jennifer',   lastName: 'Garcia',    pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'jennifer@illinois.edu', photoUrl: womanPhotos[2], website: 'linkedin.com/jennifer', data: {'college': 'Academic Affairs', 'department': 'Office of the Registrar'})),
      Auth2PublicAccount(id:  '7', profile: Auth2UserProfile(id:  '7', firstName: 'John',       lastName: 'Miller',    pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'john@illinois.edu',     photoUrl: manPhotos[3],   website: 'linkedin.com/john',     data: {'college': 'Public Safety',    'department': 'Fire Service Institute'})),
      Auth2PublicAccount(id:  '8', profile: Auth2UserProfile(id:  '8', firstName: 'Linda',      lastName: 'Davis',     pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'linda@illinois.edu',    photoUrl: womanPhotos[3], website: 'linkedin.com/linda',    data: {'college': 'Chancellor',       'department': 'Illinois Human Resources'})),
      Auth2PublicAccount(id:  '9', profile: Auth2UserProfile(id:  '9', firstName: 'David',      lastName: 'Rodriguez', pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'david@illinois.edu',    photoUrl: manPhotos[4],   website: 'linkedin.com/david',    data: {'college': 'Education',        'department': 'Education Administration'})),
      Auth2PublicAccount(id: '10', profile: Auth2UserProfile(id: '10', firstName: 'Elizabeth',  lastName: 'Martinez',  pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'lizbeth@illinois.edu',  photoUrl: womanPhotos[4], website: 'linkedin.com/lizbeth',  data: {'college': 'Armed Forces',     'department': 'Military Science'})),
      Auth2PublicAccount(id: '11', profile: Auth2UserProfile(id: '11', firstName: 'William',    lastName: 'Hernandez', pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'william@illinois.edu',  photoUrl: manPhotos[0],   website: 'linkedin.com/william',  data: {'college': 'Law',              'department': 'Law'})),
      Auth2PublicAccount(id: '12', profile: Auth2UserProfile(id: '12', firstName: 'Barbara',    lastName: 'Lopez',     pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'barbara@illinois.edu',  photoUrl: womanPhotos[0], website: 'linkedin.com/barbara',  data: {'college': 'Public Safety',    'department': 'Police Training Institute'})),
      Auth2PublicAccount(id: '13', profile: Auth2UserProfile(id: '13', firstName: 'Richard',    lastName: 'Gonzalez',  pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'richard@illinois.edu',  photoUrl: manPhotos[1],   website: 'linkedin.com/richard',  data: {'college': 'Academic Affairs', 'department': 'Campus Honors Program'})),
      Auth2PublicAccount(id: '14', profile: Auth2UserProfile(id: '14', firstName: 'Susan',      lastName: 'Wilson',    pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'susan@illinois.edu',    photoUrl: womanPhotos[1], website: 'linkedin.com/susan',    data: {'college': 'Student Affairs',  'department': 'Counseling Center'})),
      Auth2PublicAccount(id: '15', profile: Auth2UserProfile(id: '15', firstName: 'Joseph',     lastName: 'Anderson',  pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'joseph@illinois.edu',   photoUrl: manPhotos[2],   website: 'linkedin.com/joseph',   data: {'college': 'Chancellor',       'department': 'Academic Human Resources'})),
      Auth2PublicAccount(id: '16', profile: Auth2UserProfile(id: '16', firstName: 'Jessica',    lastName: 'Thomas',    pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'jessica@illinois.edu',  photoUrl: womanPhotos[2], website: 'linkedin.com/jessica',  data: {'college': 'Education',        'department': 'Special Education'})),
      Auth2PublicAccount(id: '17', profile: Auth2UserProfile(id: '17', firstName: 'Thomas',     lastName: 'Taylor',    pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'thomas@illinois.edu',   photoUrl: manPhotos[3],   website: 'linkedin.com/thomas',   data: {'college': 'Armed Forces',     'department': 'Naval Science'})),
      Auth2PublicAccount(id: '18', profile: Auth2UserProfile(id: '18', firstName: 'Karen',      lastName: 'Moore',     pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'karen@illinois.edu',    photoUrl: womanPhotos[3], website: 'linkedin.com/karen',    data: {'college': 'Public Safety',    'department': 'Fire Service Institute'})),
      Auth2PublicAccount(id: '19', profile: Auth2UserProfile(id: '19', firstName: 'Christopher',lastName: 'Jackson',   pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'christ@illinois.edu',   photoUrl: manPhotos[3],   website: 'linkedin.com/christ',   data: {'college': 'Law',              'department': 'Law Library'})),
      Auth2PublicAccount(id: '20', profile: Auth2UserProfile(id: '20', firstName: 'Sarah',      lastName: 'Martin',    pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'sarah@illinois.edu',    photoUrl: womanPhotos[4], website: 'linkedin.com/sarah',    data: {'college': 'Education',        'department': 'Curriculum and Instruction'})),
      Auth2PublicAccount(id: '21', profile: Auth2UserProfile(id: '21', firstName: 'Charles',    lastName: 'Lee',       pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'charles@illinois.edu',  photoUrl: manPhotos[0],   website: 'linkedin.com/charles',  data: {'college': 'Academic Affairs', 'department': 'Principal\'s Scholars Pgm'})),
      Auth2PublicAccount(id: '22', profile: Auth2UserProfile(id: '22', firstName: 'Lisa',       lastName: 'Perez',     pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'lisa@illinois.edu',     photoUrl: womanPhotos[0], website: 'linkedin.com/lisa',     data: {'college': 'Chancellor',       'department': 'Illinois Human Resources'})),
      Auth2PublicAccount(id: '23', profile: Auth2UserProfile(id: '23', firstName: 'Daniel',     lastName: 'Thompson',  pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'daniel@illinois.edu',   photoUrl: manPhotos[1],   website: 'linkedin.com/daniel',   data: {'college': 'Law',              'department': 'Law'})),
      Auth2PublicAccount(id: '24', profile: Auth2UserProfile(id: '24', firstName: 'Nancy',      lastName: 'White',     pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'nancy@illinois.edu',    photoUrl: womanPhotos[1], website: 'linkedin.com/nancy',    data: {'college': 'Armed Forces',     'department': 'Military Science'})),
      Auth2PublicAccount(id: '25', profile: Auth2UserProfile(id: '25', firstName: 'Matthew',    lastName: 'Harris',    pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'matthew@illinois.edu',  photoUrl: manPhotos[2],   website: 'linkedin.com/matthew',  data: {'college': 'Education',        'department': 'Education Administration'})),
      Auth2PublicAccount(id: '26', profile: Auth2UserProfile(id: '26', firstName: 'Sandra',     lastName: 'Sanchez',   pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'sandra@illinois.edu',   photoUrl: womanPhotos[2], website: 'linkedin.com/sandra',   data: {'college': 'Public Safety',    'department': 'Police Training Institute'})),
      Auth2PublicAccount(id: '27', profile: Auth2UserProfile(id: '27', firstName: 'Anthony',    lastName: 'Clark',     pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'anthony@illinois.edu',  photoUrl: manPhotos[3],   website: 'linkedin.com/anthony',  data: {'college': 'Academic Affairs', 'department': 'Office of the Registrar'})),
      Auth2PublicAccount(id: '28', profile: Auth2UserProfile(id: '28', firstName: 'Betty',      lastName: 'Ramirez',   pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'betty@illinois.edu',    photoUrl: womanPhotos[3], website: 'linkedin.com/betty',    data: {'college': 'Student Affairs',  'department': 'Campus Recreation'})),
      Auth2PublicAccount(id: '29', profile: Auth2UserProfile(id: '29', firstName: 'Mark',       lastName: 'Lewis',     pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'mark@illinois.edu',     photoUrl: manPhotos[3],   website: 'linkedin.com/mark',     data: {'college': 'Chancellor',       'department': 'News Bureau'})),
      Auth2PublicAccount(id: '30', profile: Auth2UserProfile(id: '30', firstName: 'Ashley',     lastName: 'Robinson',  pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'ashley@illinois.edu',   photoUrl: womanPhotos[4], website: 'linkedin.com/ashley',   data: {'college': 'Armed Forces',     'department': 'Clinical Sciences'})),
      Auth2PublicAccount(id: '31', profile: Auth2UserProfile(id: '31', firstName: 'Donald',     lastName: 'Walker',    pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'donald@illinois.edu',   photoUrl: manPhotos[0],   website: 'linkedin.com/donald',   data: {'college': 'Education',        'department': 'Special Education'})),
      Auth2PublicAccount(id: '32', profile: Auth2UserProfile(id: '32', firstName: 'Emily',      lastName: 'Allenb',    pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'emily@illinois.edu',    photoUrl: womanPhotos[0], website: 'linkedin.com/emily',    data: {'college': 'Student Affairs',  'department': 'Counseling Center'})),
      Auth2PublicAccount(id: '33', profile: Auth2UserProfile(id: '33', firstName: 'Steven',     lastName: 'King',      pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'steven@illinois.edu',   photoUrl: manPhotos[1],   website: 'linkedin.com/steven',   data: {'college': 'Academic Affairs', 'department': 'Principal\'s Scholars Pgm'})),
      Auth2PublicAccount(id: '34', profile: Auth2UserProfile(id: '34', firstName: 'Kimberly',   lastName: 'Wright',    pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'kimberly@illinois.edu', photoUrl: womanPhotos[1], website: 'linkedin.com/kimberly', data: {'college': 'Law',              'department': 'Law'})),
      Auth2PublicAccount(id: '35', profile: Auth2UserProfile(id: '35', firstName: 'Andrew',     lastName: 'Scott',     pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'andrew@illinois.edu',   photoUrl: manPhotos[2],   website: 'linkedin.com/andrew',   data: {'college': 'Public Safety',    'department': 'Police Training Institute'})),
      Auth2PublicAccount(id: '36', profile: Auth2UserProfile(id: '36', firstName: 'Margaret',   lastName: 'Torres',    pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'margaret@illinois.edu', photoUrl: womanPhotos[2], website: 'linkedin.com/margaret', data: {'college': 'Armed Forces',     'department': 'Naval Science'})),
      Auth2PublicAccount(id: '37', profile: Auth2UserProfile(id: '37', firstName: 'Paul',       lastName: 'Nguyen',    pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'paul@illinois.edu',     photoUrl: manPhotos[3],    website: 'linkedin.com/paul',    data: {'college': 'Education',        'department': 'Education Administration'})),
      Auth2PublicAccount(id: '38', profile: Auth2UserProfile(id: '38', firstName: 'Donna',      lastName: 'Hill',      pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'dona@illinois.edu',     photoUrl: womanPhotos[3], website: 'linkedin.com/dona',     data: {'college': 'Chancellor',       'department': 'News Bureau'})),
      Auth2PublicAccount(id: '39', profile: Auth2UserProfile(id: '39', firstName: 'Joshua',     lastName: 'Flores',    pronunciationUrl: pronunciationUrl, pronouns: 'he',  email: 'joshua@illinois.edu',   photoUrl: manPhotos[3],   website: 'linkedin.com/joshua',   data: {'college': 'Academic Affairs', 'department': 'Provost/VCAA Admin'})),
      Auth2PublicAccount(id: '40', profile: Auth2UserProfile(id: '40', firstName: 'Michelle',   lastName: 'Green',     pronunciationUrl: pronunciationUrl, pronouns: 'she', email: 'michelle@illinois.edu', photoUrl: womanPhotos[4], website: 'linkedin.com/michelle', data: {'college': 'Law',              'department': 'Law Library'})),
    ];
  }

}