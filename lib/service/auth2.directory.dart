import 'dart:math';

import 'package:http/http.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

List<Auth2PublicAccount>? _sampleDirectoryAccounts;

extension Auh2Directory on Auth2 {

  static const String attributesScope = 'app-directory';

  ContentAttributes? get directoryAttributes =>
    Content().contentAttributes(attributesScope);

  Future<List<Auth2PublicAccount>?> loadDirectoryAccounts({String? search,
    String? userName, String? firstName, String? lastName,
    String? followingId, String? followerId,
    int? offset, int? limit}) async {

    //TMP:
    //return _sampleAccounts;

    //TMP:
    //return _loadSampleDirectoryAccounts(offset: offset, limit: limit);

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

  // ignore: unused_element
  Future<List<Auth2PublicAccount>?> _loadSampleDirectoryAccounts({int? offset, int? limit}) async
  {
    if (_sampleDirectoryAccounts == null) {
      _sampleDirectoryAccounts = _buildSampleDirectoryAccounts();
    }

    int sampleAccountsCount = _sampleDirectoryAccounts?.length ?? 0;

    int start = offset ?? 0;
    start = min(start, sampleAccountsCount - 1);
    start = max(start, 0);

    int end = (limit != null) ? (start + limit) : sampleAccountsCount;
    end = min(end, sampleAccountsCount);
    end = max(end, 0);

    await Future.delayed(Duration(milliseconds: 1500));

    return ((0 <= start) && (start < sampleAccountsCount) && (0 <= end) && (end <= sampleAccountsCount) && (start < end)) ?
      _sampleDirectoryAccounts?.sublist(start, end) : [];
  }

  List<Auth2PublicAccount> _buildSampleDirectoryAccounts() {

    List<String> manNames   = <String>['James', 'Michael',  'Robert',   'John',  'David',     'William', 'Richard', 'Joseph', 'Thomas', 'Christopher', 'Charles', 'Daniel', 'Matthew', 'Anthony', 'Mark',   'Donald', 'Steven',   'Andrew',   'Paul', 'Joshua'];

    List<String> manPhotos = <String>[
      'https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/842980/pexels-photo-842980.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/2379005/pexels-photo-2379005.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/262391/pexels-photo-262391.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/25758/pexels-photo.jpg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
    ];

    List<String> womanNames = <String>['Mary',  'Patricia', 'Jennifer', 'Linda', 'Elizabeth', 'Barbara', 'Susan',   'Jessica', 'Karen', 'Sarah',       'Lisa',    'Nancy',  'Sandra',  'Betty',   'Ashley', 'Emily',  'Kimberly', 'Margaret', 'Donna', 'Michelle'];

    List<String> womanPhotos = <String>[
      'https://images.pexels.com/photos/1239288/pexels-photo-1239288.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/1102341/pexels-photo-1102341.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/3541389/pexels-photo-3541389.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/1855582/pexels-photo-1855582.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/2681751/pexels-photo-2681751.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
    ];

    List<String> familyNames = <String>[
      'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Garcia', 'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson',
      'Martin', 'Lee', 'Perez', 'Thompson', 'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson', 'Walker', 'Allen', 'King', 'Wright', 'Scott', 'Torres', 'Nguyen', 'Hill', 'Flores', 'Green'
    ];

    List<String> colleges = <String>[
      "Academic Affairs", "Administration & Operations", "Advancement", "Agricultural, Consumer & Environmental Sciences", "Applied Health Sciences", "Armed Forces",
      "Carle Illinois Medicine", "Center for Innovation in Teaching & Learning", "Chancellor", "College of Media",
      "Division of General Studies", "Division of Intercollegiate Athletics",
      "Education", "Energy Services",
      "Facilities & Services", "Fine & Applied Arts",
      "Gies College of Business", "Graduate College", "Grainger Engineering",
      "Illinois International",
      "Law", "Liberal Arts & Sciences",
      "Medicine at UIUC",
      "Provost Academic Programs", "Public Safety",
      "Research and Innovation",
      "School of Information Sciences", "School of Labor and Employment Relations", "School of Social Work", "Student Affairs", "Technology Services",
      "University Library", "Veterinary Medicine", "Vice Chancellor for Diversity"
    ];

    Map<String, List<String>> departments = <String, List<String>>{
      "Academic Affairs":["Big Ten Academic Alliance","Campus Honors Program","Center for Advanced Study","Div of Management Information","Enrollment Mgmt Shared Svcs","Office of the Registrar","Office of Undergrad Research","Osher Lifelong Learning Inst","Principal's Scholars Pgm","Provost/VCAA Admin","SmartHealthyCommunity(Rokwire)","Student Financial Aid","Student Financial Aid-Admin","Undergraduate Admissions","University Laboratory HS"],
      "Administration & Operations":["Administration & Operations","Allerton Park & Retreat Center","Aviation Lease","Division of Public Safety","Facility Scheduling Logistics","Illini Center","Ofc of Strategic Project Mgmt","Swanlund IT","UIUC Purchasing CMO","Willard Airport Commercial Op"],
      "Advancement":["Office of the Vice Chancellor for Institutional Advancement","UI AlumniAssociation"],
      "Agricultural, Consumer & Environmental Sciences":["ACES Technology Services","ADM Institute for PHL","Ag Ldrshp Educ Comm Program","Agricultural & Consumer Economics","Agricultural, Consumer, & Environmental Sciences Admn","Agricultural, Consumer, & Environmental Sciences Gen","Agricultural, Consumer, & Environmental Sciences","Agricultural & Biological Engr","Agricultural Buildings, O & M","Animal Sciences","Cooperative Extension","Crop Sciences","Food Science & Human Nutrition","Human Dvlpmt & Family Studies","Natural Res & Environmental Sciences","Nutritional Sciences"],
      "Applied Health Sciences":["Applied Health Sciences Courses","Applied Health Sciences Admin","Center on Health, Aging & Disability","Chez Veterans Center","Disability Research Institute","Disability Resources & Educ Svcs","Health & Kinesiology","Health & Wellness Initiative","Interdisciplinary Health Sciences","Recreation, Sport and Tourism","Speech & Hearing Science","Tech for Health & Independence"],
      "Armed Forces":["Air Force Aerospace Studies","Armed Forces Coordinator","Military Science","Naval Science"],
      "Carle Illinois Medicine":["Biomed & Translational Sciences","Carle IL COM Administration","Carle Illinois COM Pgm & Crse","Clinical Sciences"],
      "Center for Innovation in Teaching & Learning":["Academic Outreach","Center for Innovation in Teaching & Learning","Guided and Self-Paced Study","I-STEM Education Initiative","Publications and Promotion"],
      "Chancellor":["Academic Human Resources","Employee Development and Learning","Faculty/Staff Assistance Svcs","Illinois Human Resources","News Bureau","Office of Public Engagement","Office of the Chancellor","Public Affairs","Special Events","Strategic Marketing Branding","Web Services"],
      "College of Media":["Advertising","College of Media Admin","College of Media Gen. Expenses","College of Media Programs","Inst of Communications Rsch","IPM Administration","IPM Content Information","IPM Content Production","IPM Content Programming","IPM Delivery","IPM Development","IPM Outreach & Engagement","Journalism","Media and Cinema Studies"],
      "Division of General Studies":["Center Advising & Acad Svcs","Div General Studies Admin","General Studies Courses"],
      "Division of Intercollegiate Athletics":["Intercollegiate Athletics","State Farm Center"],
      "Education":["Bureau Educational Research","Center for Study of Reading","Council Teacher Ed Admin","Curriculum and Instruction","Educ Policy, Orgzn & Leadrshp","Education Administration","Educational Psychology","Special Education","Strategic Initiative & Sp Prg"],
      "Energy Services":["Energy Services Administration","Utilities - UIUC"],
      "Facilities & Services":["Bldg Maintenance Crafts/Trades","Building Maintenance Functionl","Building Operation","Campus Stores and Receiving","Capital Admin & Development","Capital Planning","Construction Improvements","Construction Projects","Eng & Constr Serv Admin","F&S Document Services","F&S Engineering Services","F&S Fleet Operations","Facilities and Services","Grounds","Heat Light & Power","Maint NAF-Incrementally Funded","Maintenance Asset Management","Safety and Compliance","Waste Management"],
      "Fine & Applied Arts":["Action Research Illinois","Architecture","Art & Design","Dance","Fine & Applied Arts Admin","Fine & Applied Arts Courses","Japan House","Krannert Art Museum","Krannert Center","Landscape Architecture","Music","Theatre","Urban & Regional Planning"],
      "Gies College of Business":["Academy Entrepreneurial Ldrshp","Accountancy","Action Learning","Bureau Economic & Business Res","Business Administration","Business Online Programs","College of Business","Ctr Business & Public Policy","Disruption and Innovation","Diversity, Equity, Inclusion","Executive Development Ctr","Executive MBA Program","Finance","Gies Advancement","Gies Business General","Gies Business Grad Programs","Gies College of Business","Gies Mktg & Communications","Gies Undergraduate Affairs","Illinois Business Consulting","IT Partners Gies Business","MBA Program Administration","Student & Corporate Connection","Teaching and Learning"],
      "Graduate College":["Center for Adv Study Courses","CIC Traveling Scholars","Fellowships","Grad Coll Minority Affairs Ofc","Graduate Admin","Graduate College Programs","Professional Education"],
      "Grainger Engineering":["Aerospace Engineering","Applied Research Institute","Bioengineering","Civil & Environmental Eng","Computational Science & Engr","Computer Science","Coordinated Science Lab","Electrical & Computer Eng","Engineering Administration","Engineering Courses","Engineering Honors","Engineering IT Shared Services","Engr Shared Admin Services","Industrial&Enterprise Sys Eng","Information Trust Institute","Intl Research Relations","Materials Research Lab","Materials Science & Engineerng","Mechanical Sciences & Engineering","Micro and Nanotechnology Lab","Nuclear, Plasma, & Rad Engr","Physics","Siebel Center for Design","Technology Entrepreneur Ctr"],
      "Illinois International":["Global Education & Training","Illinois Abroad","Illinois International","Intensive English Institute","Intl Student and Scholar Svcs"],
      "Law":["Law","Law Library"],
      "Liberal Arts & Sciences":["The ACDIS Program","African American Studies","American Indian Studies Prgrm","Anthropology","Appl Tech Learning Arts & Sciences","Asian American Studies","Astronomy","Atmospheric Sciences","Biochemistry","Biophysics & Quant Biology","Cell & Developmental Biology","Center for African Studies","Center for Global Studies","Center for Writing Studies","Chemical & Biomolecular Engr","Chemistry","Classics","Cline Ctr for Adv Social Rsrch","Communication","Comparative & World Literature","Ctr S. Asian & MidEast Studies","E Asian & Pacific Studies Cntr","E. Asian Languages & Cultures","Earth Sci & Environmental Chng","Economics","English","Entomology","European Union Center","Evolution Ecology Behavior","French and Italian","Gender and Women's Studies","Geography & GIS","Geology","Germanic Languages & Lit","Global Studies Prog & Courses","History","Illinois Global Institute","Int'l Forum for US Studies","LAS Administration","Latin American & Carib Studies","Latina/Latino Studies","Lemann Center","Liberal Arts & Sciences","Liberal Arts & Sciences Courses","Life Sciences","Linguistics","Mathematics","Microbiology","Molecular & Integrative Physl","Neuroscience Program","Philosophy","Plant Biology","Political Science","Prg in Jewish Culture &Society","Program in Medieval Studies","Psychology","Religion","Russian,E European,Eurasn Ctr","Sch Earth Soc Environmental Courses","Sch Earth, Soc, Environmentaliron Admin","Sch Lit, Cultures, Ling Adm","School of Chemical Sciences","School of Integrative Biology","School of Molecular & Cell Bio","Slavic Languages & Literature","SLCL Courses","Sociology","Spanish and Portuguese","Spurlock Museum","Statistics","Translation & Interpreting St","Unit For Criticism","Women & Gender in Global Persp"],
      "Medicine at UIUC":["Internal Medicine","Medicine at UC Admin"],
      "Provost Academic Programs":["Provost Courses"],
      "Public Safety":["Fire Service Institute","Police Training Institute"],
      "Research and Innovation":["Agr Animal Care & Use Program","Beckman Institute","Biotechnology Center","Cancer Center at Illinois","Institute for Genomic Biology","Division of Animal Resources","Division of Research Safety","EnterpriseWorks","Humanities Research Institute","IL Natural History Survey","IL State Archaeological Survey","IL State Geological Survey","IL State Water Survey","IL Sustainable Technology Ctr","Inst Animal Care & Use Cmte","Inst for Sustain, Enrgy, & Environmental","Interdis Health Sciences Institute","OCR Special Projects","Office of Corporate Relations","Office of Proposal Development","OVCRI Admin","OVCRI Support","Prairie Research Institute","Protection of Research Subject","Research Board","Research Park LLC","Sponsored Prgms Adm Post-Award","Sponsored Programs Admin","Supercomputing Applications","UIUC DPI Grant Administration"],
      "School of Information Sciences":["Center for Children's Books","Illinois Informatics Institute","Informatics","Information Sciences"],
      "School of Labor and Employment Relations":["School of Labor and Employment Relations"],
      "School of Social Work":["School of Social Work"],
      "Student Affairs":["The Career Center","Counseling Center","Campus Recreation","Conference Center","Conference Services","Illini Union","Illinois Leadership Center","Minority Student Affairs","McKinley Health Center","New Student & Family Experiences","Office of the Dean of Students","Parking Department","Student Affairs Technology","Student Conflict Resolution","Student Health Insurance","Student Success, Inclusion & Belonging","Testing Center","University Housing","Vice Chancellor for Student Affairs"],
      "Technology Services":["Campus Research IT","Ofc of the Chief Info Officer","Technology Services","TS IT Service Delivery"],
      "University Library":["Library","Library Admin","Library Collections/Support","Library Research & Publication","Mortenson Cntr Int'l Lib Prgms"],
      "Veterinary Medicine":["Center for Zoonoses Research","Comparative Biosciences","Medical District Vet Clinic","Pathobiology","Vet Clinical Medicine","Vet Med College-Wide Programs","Vet Medicine Administration","Veterinary Diagnostic Lab","Veterinary Prog in Agriculture","Veterinary Teaching Hospital"],
      "Vice Chancellor for Diversity":["Business Community Econ Dev","Campus Belonging","Diversity Committee & Advocacy","Illinois Scholars Program","Office for Access and Equity","Title IX Office","Vice Chancellor for Diversity"]
    };

    List<Auth2PublicAccount> sampleAccounts = [];
    sampleAccounts.addAll(_buildSampleAccounts(sampleAccounts.length + 1, firstNames: manNames, familyNames: familyNames, photos: manPhotos, colleges: colleges, departments: departments));
    sampleAccounts.addAll(_buildSampleAccounts(sampleAccounts.length + 1, firstNames: womanNames, familyNames: familyNames, photos: womanPhotos, colleges: colleges, departments: departments));

    sampleAccounts.sort((Auth2PublicAccount account1, Auth2PublicAccount account2) {
      int result = SortUtils.compare(account1.profile?.lastName?.toUpperCase(), account2.profile?.lastName?.toUpperCase());
      if (result == 0) {
        result = SortUtils.compare(account1.profile?.firstName?.toUpperCase(), account2.profile?.firstName?.toUpperCase());
      }
      if (result == 0) {
        result = SortUtils.compare(account1.profile?.middleName?.toUpperCase(), account2.profile?.middleName?.toUpperCase());
      }
      return result;
    });
    return sampleAccounts;
  }

  List<Auth2PublicAccount> _buildSampleAccounts(int id, { required List<String> firstNames, required List<String> familyNames, required List<String> photos, required List<String> colleges, required Map<String, List<String>> departments, })
  {
    int photoIndex = 0;
    int collegeIndex = 0;
    List<Auth2PublicAccount> result = <Auth2PublicAccount>[];
    for (String familyName in familyNames) {
      for (String firstName in firstNames) {
        String lowerFirstName = firstName.toLowerCase();
        String college = colleges[collegeIndex];
        List<String> collegeDepartments = departments[college] ?? [];
        String? department = collegeDepartments.isNotEmpty ? collegeDepartments[Random().nextInt(collegeDepartments.length)] : null;
        result.add(Auth2PublicAccount(
          id:  id.toString(),
          profile: Auth2UserProfile(
            firstName: firstName,
            lastName: familyName,
            pronunciationUrl: 'https://api-dev.rokwire.illinois.edu/content/voice_record/$id',
            pronouns: 'she',
            photoUrl: photos[photoIndex],
            email: '$lowerFirstName@illinois.edu',
            website: 'linkedin.com/$lowerFirstName',
            data: {'college': college, 'department': department}
          )
        ));
        id += 1;
        photoIndex = (photoIndex + 1) % photos.length;
        collegeIndex = (collegeIndex + 1) % colleges.length;
      }
    }
    return result;
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