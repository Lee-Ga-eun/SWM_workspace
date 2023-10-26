import 'package:amplitude_flutter/amplitude.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/component/bookIntro/viewModel/book_voice_cubit.dart';
import 'package:yoggo/component/bookIntro/viewModel/book_voice_model.dart';
import 'package:yoggo/component/home/viewModel/home_screen_cubit.dart';
import 'package:yoggo/component/point.dart';
import 'package:yoggo/component/rec_info.dart';
import '../../../Repositories/Repository.dart';
import '../../bookPage/view/book_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:yoggo/size_config.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../globalCubit/user/user_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../shop.dart';
import '../viewModel/book_intro_model.dart';
import '../viewModel/book_intro_cubit.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io' show File, Platform;
import 'dart:math';

class BookIntroOnboarding extends StatefulWidget {
  final String title;
  final int id;
  final FirebaseRemoteConfig abTest;
  final bool showOnboarding;

  const BookIntroOnboarding(
      {
      // super.key,
      Key? key,
      required this.title,
      required this.id,
      required this.abTest,
      required this.showOnboarding})
      : super(key: key);

  @override
  _BookIntroOnboardingState createState() => _BookIntroOnboardingState();
}

class _BookIntroOnboardingState extends State<BookIntroOnboarding> {
  bool isSelected = true;
  //static bool isClicked = false;
  //static bool isClicked0 = true;
  // ValueNotifier<bool> isClicked = ValueNotifier<bool>(false);
  // ValueNotifier<bool> isClicked0 = ValueNotifier<bool>(true);
  // ValueNotifier<bool> isClicked1 = ValueNotifier<bool>(false);
  // ValueNotifier<bool> isClicked2 = ValueNotifier<bool>(false);
  ValueNotifier<bool> canChanged = ValueNotifier<bool>(true);
  ValueNotifier<bool> wantInference = ValueNotifier<bool>(false);
  ValueNotifier<bool> wantRecord = ValueNotifier<bool>(false);

  //static bool isClicked1 = false;
  //static bool isClicked2 = false;
  bool isPurchased = false;
  bool isLoading = false;
  bool wantPurchase = false;
  bool wantBuyBook = false;
  bool buyPoints = false;
  bool animation = false;
  String lackingPoint = '';
  // bool wantRecord = false;
  //bool wantInference = false;
  bool completeInference = true;
  //late String voiceIcon = "😃";
  //late String voiceName = "";
  static int inferenceId = 0;
  late String token;
  String text = '';
  //int contentVoiceId = 10;
  //String voices='';
  // List<dynamic> voices = [];
  //int cvi = 21; // 여기를 성우의 디폴트 값을 넣어줘야 함
  //int vi = 0;
  //bool canChanged = true;
  // int lastPage = 0;
  final audioPlayer = AudioPlayer();
  //late BookVoiceModel clickedVoice;

  @override
  void dispose() {
    // isClicked.dispose();
    // isClicked0.dispose();
    // isClicked1.dispose();
    // isClicked2.dispose();
    wantInference.dispose();
    wantRecord.dispose();
    canChanged.dispose();
    super.dispose();
  }

  Future<void> fetchPageData() async {
    await dotenv.load(fileName: ".env");

    final url = '${dotenv.get("API_SERVER")}content/v2/${widget.id}';
    final response = await http.get(Uri.parse(url));
    if (mounted) {
      if (response.statusCode == 200) {
        List<dynamic> responseData = jsonDecode(response.body);
        // print(responseData);
        Map<String, dynamic> data = responseData[0];
        // voices = data['voice'];
        // for (var voice in voices) {
        //   if (voice['voiceId'] == 1) {
        //     cvi = voice['contentVoiceId'];
        //     vi = 1;
        //   }
        // }
        final contentText = data['voice'][0]['voiceName'];
        //  lastPage = data['last'];
        //  contentId = data['contentId'];

        setState(() {
          text = contentText;
          // contentVoiceId = data['voice'][0]['contentVoiceId'];
        });
      } else {}
    }
  }

  BookVoiceModel? clickedVoice;

  late int contentId;
  //late BookVoiceCubit bookVoiceCubit;
  @override
  void initState() {
    super.initState();
    UserCubit().fetchUser();

    //  cvi = 0;
    contentId = widget.id;
    fetchClickedVoice(contentId);
    //bookVoiceCubit.loadBookVoiceData(contentId);
    // contentId = widget.id; // contentId는 init에서
    // fetchPageData();
    getToken();
    _sendBookIntroInOnboardingViewEvent(contentId, widget.title);
  }

  Future<void> fetchClickedVoice(int id) async {
    final bookVoiceCubit = context.read<BookVoiceCubit>();
    clickedVoice = await bookVoiceCubit.loadBookVoiceData(id) as BookVoiceModel;
    setState(() {
      // clickedVoice를 초기화하고 다시 빌드되도록 setState 호출
    });
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static Amplitude amplitude = Amplitude.getInstance();
  // static Analytics_config.analytics.logEvent("suhwanc");

  Future<void> _sendBookMyVoiceInOnboardingClickEvent(contentId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_my_voice_in_onboarding_click',
        parameters: <String, dynamic>{'contentId': contentId, 'title': title},
      );
      amplitude.logEvent(
        'book_my_voice_in_onboarding_click',
        eventProperties: {'contentId': contentId, 'title': title},
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  // Future<void> _checkHaveRead() async {
  //   // 앱 최초 사용 접속 : 온보딩 화면 보여주기
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   // Set isFirstTime to false after showing overlay
  //   await prefs.setBool('haveRead', true);
  // }

  Future<void> _sendBookVoiceInOnboardingClickEvent(
      contentVoiceId, contentId, title, voiceId) async {
    try {
      // 이벤트 로깅
      print('book voice click: $contentVoiceId, $voiceId');
      await analytics.logEvent(
        name: 'book_voice_in_onboarding_click',
        parameters: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'title': title,
          'voiceId': voiceId,
        },
      );

      await amplitude.logEvent(
        'book_voice_in_onboarding_click',
        eventProperties: {
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'title': title,
          'voiceId': voiceId,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookStartClickEvent(
    contentVoiceId,
    contentId,
    title,
    voiceId,
  ) async {
    print('book start click: $contentVoiceId, $voiceId');

    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_start_click',
        parameters: <String, dynamic>{
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'title': title,
          'voiceId': voiceId,
        },
      );
      await amplitude.logEvent(
        'book_start_click',
        eventProperties: {
          'contentVoiceId': contentVoiceId,
          'contentId': contentId,
          'title': title,
          'voiceId': voiceId,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookIntroInOnboardingViewEvent(
    contentId,
    title,
  ) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_intro_view',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'title': title,
        },
      );
      await amplitude.logEvent(
        'book_intro_view',
        eventProperties: {
          'contentId': contentId,
          'title': title,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookIntroXInOnboardingClickEvent(
    contentId,
    title,
  ) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_intro_x_in_onboarding_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'title': title,
        },
      );
      await amplitude.logEvent(
        'book_intro_x_in_onboarding_click',
        eventProperties: {
          'contentId': contentId,
          'title': title,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  // Future<void> _sendBookLoadingViewEvent(
  //   contentVoiceId,
  // ) async {
  //   try {
  //     // 이벤트 로깅
  //     await analytics.logEvent(
  //       name: 'book_loading_view',
  //       parameters: <String, dynamic>{
  //         'contentId': contentId,
  //         'title': title,
  //       },
  //     );
  //     await amplitude.logEvent(
  //       'book_loading_view',
  //       eventProperties: {
  //         'contentId': contentId,'title': title,
  //       },
  //     );
  //   } catch (e) {
  //     // 이벤트 로깅 실패 시 에러 출력
  //     print('Failed to log event: $e');
  //   }
  // }

  Future<void> _sendBookIntroRegisterLaterClickEvent(contentId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_intro_register_later_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'title': title,
        },
      );
      await amplitude.logEvent(
        'book_intro_register_later_click',
        eventProperties: {
          'contentId': contentId,
          'title': title,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookIntroRegisterOkClickEvent(
    contentId,
    title,
  ) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_intro_register_ok_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'title': title,
        },
      );
      await amplitude.logEvent(
        'book_intro_register_ok_click',
        eventProperties: {
          'contentId': contentId,
          'title': title,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookIntroRecordLaterClickEvent(
    contentId,
    title,
  ) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_intro_record_later_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'title': title,
        },
      );
      await amplitude.logEvent(
        'book_intro_record_later_click',
        eventProperties: {
          'contentId': contentId,
          'title': title,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookIntroRecordOkClickEvent(
    contentId,
    title,
  ) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_intro_record_ok_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'title': title,
        },
      );
      await amplitude.logEvent(
        'book_intro_record_ok_click',
        eventProperties: {
          'contentId': contentId,
          'title': title,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookIntroBuyPointLaterClickEvent(
    lackingPoint,
    contentId,
    title,
    voiceId,
  ) async {
    try {
      // 이벤트 로깅
      print('buy point later click: $voiceId');

      await analytics.logEvent(
        name: 'book_intro_buy_point_later_click',
        parameters: <String, dynamic>{
          'lackingPoint': lackingPoint,
          'contentId': contentId,
          'title': title,
          'voiceId': voiceId
        },
      );
      await amplitude.logEvent(
        'book_intro_buy_point_later_click',
        eventProperties: {
          'lackingPoint': lackingPoint,
          'contentId': contentId,
          'title': title,
          'voiceId': voiceId
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookIntroBuyPointOkClickEvent(
      lackingPoint, contentId, title, voiceId) async {
    try {
      print('buy point ok: $voiceId');

      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_intro_buy_point_ok_click',
        parameters: <String, dynamic>{
          'lackingPoint': lackingPoint,
          'contentId': contentId,
          'title': title,
          'voiceId': voiceId
        },
      );
      await amplitude.logEvent(
        'book_intro_buy_point_ok_click',
        eventProperties: {
          'lackingPoint': lackingPoint,
          'contentId': contentId,
          'title': title,
          'voiceId': voiceId
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookIntroMakeBookLaterClickEvent(contentId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_intro_make_book_later_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'title': title,
        },
      );
      await amplitude.logEvent(
        'book_intro_make_book_later_click',
        eventProperties: {
          'contentId': contentId,
          'title': title,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookIntroMakeBookOkClickEvent(
    contentId,
    title,
  ) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_intro_make_book_ok_click',
        parameters: <String, dynamic>{
          'contentId': contentId,
          'title': title,
        },
      );
      await amplitude.logEvent(
        'book_intro_not_make_book_ok_click',
        eventProperties: {
          'contentId': contentId,
          'title': title,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBook3000ClickEvent(pointNow, contentId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_3000_click',
        parameters: <String, dynamic>{
          'point_now': pointNow,
          'contentId': contentId,
          'title': title,
        },
      );
      amplitude.logEvent(
        'book_3000_click',
        eventProperties: {
          'point_now': pointNow,
          'contentId': contentId,
          'title': title,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookBuyClickEvent(pointNow, contentId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_buy_click',
        parameters: <String, dynamic>{
          'point_now': pointNow,
          'contentId': contentId,
          'title': title,
        },
      );
      amplitude.logEvent(
        'book_buy_click',
        eventProperties: {
          'point_now': pointNow,
          'contentId': contentId,
          'title': title,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookBuyLaterClickEvent(pointNow, contentId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_buy_later_click',
        parameters: <String, dynamic>{
          'point_now': pointNow,
          'contentId': contentId,
          'title': title,
        },
      );
      amplitude.logEvent(
        'book_buy_later_click',
        eventProperties: {
          'point_now': pointNow,
          'contentId': contentId,
          'title': title,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendBookBuySuccessEvent(pointNow, contentId, title) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'book_buy_success',
        parameters: <String, dynamic>{
          'point_now': pointNow,
          'contentId': contentId,
          'title': title,
        },
      );
      amplitude.logEvent(
        'book_buy_success',
        eventProperties: {
          'point_now': pointNow,
          'contentId': contentId,
          'title': title,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token')!;
      purchaseInfo(token);
      checkInference(token);
    });
  }

  Future<String> buyContent() async {
    final url = '${dotenv.get("API_SERVER")}content/buy';
    final response = await http.post(Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'contentId': widget.id.toString()}));
    print(response.statusCode);
    if (response.statusCode == 200) {
      UserCubit().fetchUser();
      final bookIntro = context.read<BookIntroCubit>().state;
      _sendBookBuySuccessEvent(json.decode(response.body)[0]['point'],
          contentId, bookIntro.first.title);
      Amplitude.getInstance()
          .setUserProperties({'point': json.decode(response.body)[0]['point']});
      return response.statusCode.toString();
    } else if (response.statusCode == 400) {
      return json.decode(response.body)[0].toString();
    } else {
      throw Exception('Failed to fetch data');
    }
  }

//구매한 사람인지, 이 책이 인퍼런스되어 있는지 확인
  Future<String> purchaseInfo(String token) async {
    var url =
        Uri.parse('${dotenv.get("API_SERVER")}user/purchaseInfo/${widget.id}');
    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        inferenceId = json.decode(response.body)['inference'];
      });
      return response.body;
    } else {
      throw Exception('Failed to fetch data');
    }
  }

//인퍼런스 안 되어 있다면 시작하도록
  Future<void> startInference(String token) async {
    var url = Uri.parse('${dotenv.get("API_SERVER")}producer/book');
    Map data = {'contentId': widget.id};
    var response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data));
    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          isLoading = true;
          inferenceId = json.decode(response.body)['id'];
          checkInference(token);
        });
      }
    } else {
      throw Exception('Failed to start inference');
    }
  }

//인퍼런스 완료 되었는지 (ContentVoice) 확인
  Future<bool> checkInference(String token) async {
    var url =
        Uri.parse('${dotenv.get("API_SERVER")}content/inference/${widget.id}');
    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> responseData = jsonDecode(response.body);
      // print(responseData);
      bool data = responseData[0];
      if (data == true) {
        setState(() {
          isLoading = false;
          completeInference = true;
        });
        context.read<BookVoiceCubit>().changeBookVoiceData(contentId);
        canChanged.value = true;
        return true;
      } else {
        setState(() {
          isLoading = true;
          //loadData(token);
          Future.delayed(const Duration(seconds: 1), () {
            checkInference(token);
          });
        });
        return false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final sw = (MediaQuery.of(context).size.width -
        MediaQuery.of(context).padding.left -
        MediaQuery.of(context).padding.right);
    final sh = (MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom);
    double thumbSize = min(0.7 * sh, 0.4 * sw);
    final bookIntroCubit = context.watch<BookIntroCubit>();
    final bookVoiceCubit = context.watch<BookVoiceCubit>();
    final dataCubit = context.read<DataCubit>();

    final dataRepository = RepositoryProvider.of<DataRepository>(context);
    bookIntroCubit.loadBookIntroData(widget.id);
    return BlocBuilder<BookIntroCubit, List<BookIntroModel>>(
        builder: (context, bookIntro) {
      final userCubit = context.watch<UserCubit>();
      final userState = userCubit.state;
      SizeConfig().init(context);
      return BlocBuilder<BookVoiceCubit, List<BookVoiceModel>>(
          builder: (context, voiceState) {
        if (bookIntro.isEmpty || voiceState.isEmpty || clickedVoice == null) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  opacity: 0.6,
                  image: AssetImage('lib/images/bkground.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                // 로딩 화면
                child: LoadingAnimationWidget.fourRotatingDots(
                  color: const Color.fromARGB(255, 255, 169, 26),
                  size: SizeConfig.defaultSize! * 10,
                ),
              ),
            ),
          );
        } else {
          final String title = bookIntro.first.title;
          List<dynamic> voices = [];
          voices = bookIntro.first.voice;

          //int cvi = clickedVoice!.contentVoiceId;

          final int lastPage = bookIntro.first.last;
          return Scaffold(
              backgroundColor: const Color(0xFFF1ECC9).withOpacity(1),
              body: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        opacity: 0.6,
                        image: AssetImage('lib/images/bkground.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        // left: 0.5 * SizeConfig.defaultSize!,
                        top: SizeConfig.defaultSize!,
                      ),
                      child: SafeArea(
                        bottom: false,
                        top: false,
                        minimum: EdgeInsets.only(
                            top: SizeConfig.defaultSize!,
                            right: 3 * SizeConfig.defaultSize!,
                            left: 3 * SizeConfig.defaultSize!),
                        child: Column(children: [
                          Expanded(
                              // HEADER
                              flex: 11,
                              child: Row(children: [
                                Expanded(
                                    flex: 1,
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          IconButton(
                                            padding: EdgeInsets.all(
                                                0.2 * SizeConfig.defaultSize!),
                                            icon: Icon(Icons.clear,
                                                color: Colors.grey,
                                                size: 3 *
                                                    SizeConfig.defaultSize!),
                                            onPressed: () {
                                              _sendBookIntroXInOnboardingClickEvent(
                                                  widget.id, title);
                                              audioPlayer.stop();
                                              Navigator.popUntil(context,
                                                  (route) => route.isFirst);
                                              // Navigator.pushReplacement(
                                              //     context,
                                              //     MaterialPageRoute(
                                              //         builder: (context) =>
                                              //             HomeScreen()));
                                            },
                                          )
                                        ])),
                                Expanded(
                                    flex: 11,
                                    child: Container(
                                      alignment: Alignment.center,
                                      //color: Colors.black12,
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize:
                                                3.2 * SizeConfig.defaultSize!,
                                            fontFamily: bookIntro.first.font,
                                            fontWeight: FontWeight.w200),
                                      ),
                                    )),
                                Expanded(flex: 1, child: Container())
                              ])),

                          Expanded(
                              // BODY
                              flex: 70,
                              child: Row(children: [
                                Expanded(
                                  // 썸네일 사진
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: SizeConfig.defaultSize!,
                                      ),
                                      Container(
                                        color: const Color.fromARGB(0, 0, 0, 0),
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween<double>(
                                              begin:
                                                  30 * SizeConfig.defaultSize!,
                                              end:
                                                  30 * SizeConfig.defaultSize!),
                                          duration:
                                              const Duration(milliseconds: 300),
                                          builder: (context, value, child) {
                                            return Stack(children: [
                                              Container(
                                                width: thumbSize,
                                                // height: thumbSize,
                                                clipBehavior: Clip.hardEdge,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: child,
                                              ),
                                              Positioned(
                                                left: SizeConfig.defaultSize!,
                                                top: SizeConfig.defaultSize!,
                                                child: Container(
                                                  width: 6.2 *
                                                      SizeConfig.defaultSize!,
                                                  height: 3.5 *
                                                      SizeConfig.defaultSize!,
                                                  //clipBehavior: Clip.hardEdge,
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromARGB(
                                                        128, 255, 255, 255),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                  ),
                                                  child: Center(
                                                      child: Text('$lastPage p',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                              fontFamily:
                                                                  'GenBkBasR',
                                                              fontSize: 2 *
                                                                  SizeConfig
                                                                      .defaultSize!))),
                                                ),
                                              )
                                            ]);
                                          },
                                          child: Image(
                                              image: FileImage(File(bookIntro
                                                  .first.thumbUrl
                                                  .replaceAll("'", ""))),
                                              colorBlendMode: BlendMode.srcATop,
                                              color: Color.fromARGB(
                                                  153, 255, 255, 255)),

                                          // child: CachedNetworkImage(
                                          //   imageUrl: widget.thumb,
                                          //   fit: BoxFit
                                          //       .cover, // 이미지를 컨테이너에 맞게 조절
                                          // ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: SizeConfig.defaultSize! * 2,
                                ),
                                Expanded(
                                    // 제목, 성우, 요약
                                    flex: 3,
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Text(
                                          //   title,
                                          //   style: TextStyle(
                                          //       fontSize: 3.2 * SizeConfig.defaultSize!,
                                          //       fontFamily: 'BreeSerif'),
                                          // ),
                                          // SizedBox(
                                          //   height: SizeConfig.defaultSize! * 2,
                                          // ),
                                          SizedBox(
                                            height: userState.purchase
                                                ? 1 * SizeConfig.defaultSize!
                                                : 1.5 * SizeConfig.defaultSize!,
                                          ),
                                          Column(
                                            children: [
                                              Container(
                                                  width:
                                                      SizeConfig.defaultSize! *
                                                          34,
                                                  padding: EdgeInsets.only(
                                                      left: SizeConfig
                                                              .defaultSize! *
                                                          1.2,
                                                      top: SizeConfig
                                                          .defaultSize!,
                                                      bottom: SizeConfig
                                                          .defaultSize!),
                                                  // color: Colors.red,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.4),
                                                    borderRadius: BorderRadius
                                                        .circular(SizeConfig
                                                                .defaultSize! *
                                                            3),
                                                  ),
                                                  child: Row(
                                                    //  mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      GestureDetector(
                                                          // purchase & record
                                                          // no start Inference
                                                          onTap: () {
                                                            // bookVoiceCubit
                                                            //     .changeBookVoiceData(contentId);
                                                            _sendBookMyVoiceInOnboardingClickEvent(
                                                              contentId,
                                                              title,
                                                            );
                                                            Navigator
                                                                .pushReplacement(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          RecInfo(
                                                                            contentId:
                                                                                10,
                                                                            abTest:
                                                                                widget.abTest,
                                                                          )),
                                                            );
                                                          },
                                                          child: Column(
                                                              children: [
                                                                Padding(
                                                                    padding: EdgeInsets.only(
                                                                        right: 0 *
                                                                            SizeConfig
                                                                                .defaultSize!),
                                                                    child: Image
                                                                        .asset(
                                                                      'lib/images/icons/grinning-face-c.png',
                                                                      height:
                                                                          SizeConfig.defaultSize! *
                                                                              7,
                                                                    )),
                                                                SizedBox(
                                                                    height: SizeConfig
                                                                            .defaultSize! *
                                                                        0.3),
                                                                Text('My Voice',
                                                                    style: TextStyle(
                                                                        fontFamily: 'GenBkBasR',
                                                                        fontWeight: FontWeight.bold,
                                                                        //     FontWeight.w800,
                                                                        fontSize: 1.8 * SizeConfig.defaultSize!))
                                                              ])),
                                                      SizedBox(
                                                        // color: ,
                                                        width: 1.5 *
                                                            SizeConfig
                                                                .defaultSize!,
                                                      ),
                                                      GestureDetector(
                                                        //Jolly
                                                        onTap: () async {
                                                          _sendBookVoiceInOnboardingClickEvent(
                                                              clickedVoice!
                                                                  .contentVoiceId,
                                                              contentId,
                                                              title,
                                                              clickedVoice!
                                                                  .voiceId);
                                                        },
                                                        child:
                                                            //   ValueListenableBuilder<
                                                            //       bool>(
                                                            // valueListenable:
                                                            //     isClicked0,
                                                            // builder: (context,
                                                            //     value, child) {
                                                            //   return
                                                            Center(
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .only(
                                                                  right: 0 *
                                                                      SizeConfig
                                                                          .defaultSize!,
                                                                ),
                                                                child:
                                                                    Image.asset(
                                                                  'lib/images/jolly.png',
                                                                  height: SizeConfig
                                                                          .defaultSize! *
                                                                      6.5,
                                                                  colorBlendMode:
                                                                      BlendMode
                                                                          .srcATop,
                                                                  color: const Color
                                                                          .fromARGB(
                                                                      150,
                                                                      255,
                                                                      255,
                                                                      255),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: SizeConfig
                                                                        .defaultSize! *
                                                                    0.3,
                                                              ),
                                                              Text(
                                                                voiceState[1]
                                                                    .voiceName,
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .grey,
                                                                    fontFamily:
                                                                        'GenBkBasR',
                                                                    fontSize: 1.8 *
                                                                        SizeConfig
                                                                            .defaultSize!,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal),
                                                              ),
                                                            ],
                                                          ),
                                                          //);
                                                          //},
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 1.5 *
                                                            SizeConfig
                                                                .defaultSize!,
                                                      ),
                                                      // Morgan
                                                      GestureDetector(
                                                        onTap: () async {
                                                          _sendBookVoiceInOnboardingClickEvent(
                                                              clickedVoice!
                                                                  .contentVoiceId,
                                                              contentId,
                                                              title,
                                                              clickedVoice!
                                                                  .voiceId);
                                                        },
                                                        child:
                                                            //   ValueListenableBuilder<
                                                            //       bool>(
                                                            // valueListenable:
                                                            //     isClicked1,
                                                            // builder: (context,
                                                            //     value, child) {
                                                            //return
                                                            Center(
                                                          child: Column(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .only(
                                                                  right: 0 *
                                                                      SizeConfig
                                                                          .defaultSize!,
                                                                ),
                                                                child:
                                                                    Image.asset(
                                                                  'lib/images/morgan.png',
                                                                  height: SizeConfig
                                                                          .defaultSize! *
                                                                      6.5,
                                                                  colorBlendMode:
                                                                      BlendMode
                                                                          .srcATop,
                                                                  color: voiceState[
                                                                              2]
                                                                          .clicked
                                                                      ? null
                                                                      : const Color
                                                                              .fromARGB(
                                                                          150,
                                                                          255,
                                                                          255,
                                                                          255),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: SizeConfig
                                                                        .defaultSize! *
                                                                    0.3,
                                                              ),
                                                              Text(
                                                                voiceState[2]
                                                                    .voiceName,
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontFamily:
                                                                      'GenBkBasR',
                                                                  fontSize: 1.8 *
                                                                      SizeConfig
                                                                          .defaultSize!,
                                                                  fontWeight: voiceState[
                                                                              2]
                                                                          .clicked
                                                                      ? FontWeight
                                                                          .bold
                                                                      : FontWeight
                                                                          .normal,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          //);
                                                          //},
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 1.5 *
                                                            SizeConfig
                                                                .defaultSize!,
                                                      ),
                                                      // Eric
                                                      GestureDetector(
                                                          onTap: () async {
                                                            // _sendBookVoiceInOnboardingClickEvent(
                                                            //     clickedVoice!
                                                            //         .contentVoiceId,
                                                            //     contentId,
                                                            //     title,
                                                            //     clickedVoice!
                                                            //         .voiceId);
                                                          },
                                                          child: Center(
                                                            child: Column(
                                                              children: [
                                                                Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .only(
                                                                    right: 0 *
                                                                        SizeConfig
                                                                            .defaultSize!,
                                                                  ),
                                                                  child: Image
                                                                      .asset(
                                                                    'lib/images/eric.png',
                                                                    height:
                                                                        SizeConfig.defaultSize! *
                                                                            6.5,
                                                                    colorBlendMode:
                                                                        BlendMode
                                                                            .srcATop,
                                                                    color: voiceState[3]
                                                                            .clicked
                                                                        ? null
                                                                        : const Color.fromARGB(
                                                                            150,
                                                                            255,
                                                                            255,
                                                                            255),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: SizeConfig
                                                                          .defaultSize! *
                                                                      0.3,
                                                                ),
                                                                Text(
                                                                  voiceState[3]
                                                                      .voiceName,
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .grey,
                                                                    fontFamily:
                                                                        'GenBkBasR',
                                                                    fontSize: 1.8 *
                                                                        SizeConfig
                                                                            .defaultSize!,
                                                                    fontWeight: voiceState[
                                                                                3]
                                                                            .clicked
                                                                        ? FontWeight
                                                                            .bold
                                                                        : FontWeight
                                                                            .normal,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          )
                                                          //},
                                                          //),
                                                          ),
                                                    ],
                                                  ) //;
                                                  // }),
                                                  ),
                                            ],
                                          ),
                                          SizedBox(
                                              height: 1.5 *
                                                  SizeConfig
                                                      .defaultSize! //userState.purchase
                                              //? 4
                                              //: 4 * SizeConfig.defaultSize!,
                                              ),
                                          Expanded(
                                              flex: 3,
                                              child: Scrollbar(
                                                thumbVisibility: true,
                                                trackVisibility: true,
                                                child: ListView(children: [
                                                  Padding(
                                                    // Summary
                                                    padding: EdgeInsets.only(
                                                      right: 1 *
                                                          SizeConfig
                                                              .defaultSize!,
                                                      top: 0 *
                                                          SizeConfig
                                                              .defaultSize!,
                                                    ),
                                                    child: Text(
                                                      bookIntro.first.summary,
                                                      style: TextStyle(
                                                          color: Colors.grey,
                                                          fontFamily:
                                                              'GenBkBasR',
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: SizeConfig
                                                                  .defaultSize! *
                                                              2.1),
                                                    ),
                                                  ),
                                                ]),
                                              )),
                                          SizedBox(
                                            height:
                                                SizeConfig.defaultSize! * 1.5,
                                          ),
                                          Expanded(
                                              flex: 2,
                                              child: Stack(children: [
                                                // 다른 위젯들...
                                                Align(
                                                    alignment:
                                                        Alignment.topCenter,
                                                    // right: SizeConfig.defaultSize! * 12,
                                                    // top: SizeConfig.defaultSize! * 1.4,
                                                    child: GestureDetector(
                                                        onTap: () async {
                                                          //   // print(clickedVoice!
                                                          //   //     .voiceId);
                                                          //   // // 버튼 클릭 시 동작
                                                          //   // _checkHaveRead();
                                                          //   (clickedVoice!
                                                          //               .contentVoiceId ==
                                                          //           inferenceId) // 원래는 cvi==inferenceId
                                                          //       ? await checkInference(
                                                          //               token)
                                                          //           ? {
                                                          //               _sendBookStartClickEvent(
                                                          //                 clickedVoice!
                                                          //                     .contentVoiceId,
                                                          //                 contentId,
                                                          //                 title,
                                                          //                 clickedVoice!
                                                          //                     .voiceId,
                                                          //               ),
                                                          //               // print(clickedVoice!
                                                          //               //     .voiceName),
                                                          //               Navigator
                                                          //                   .push(
                                                          //                 context,
                                                          //                 MaterialPageRoute(
                                                          //                   builder: (context) => BookPage(
                                                          //                       // 다음 화면으로 contetnVoiceId를 가지고 이동
                                                          //                       contentVoiceId: clickedVoice!.contentVoiceId,
                                                          //                       voiceId: clickedVoice!.voiceId,
                                                          //                       contentId: contentId,
                                                          //                       lastPage: lastPage,
                                                          //                       isSelected: true,
                                                          //                       title: bookIntro.first.title,
                                                          //                       abTest: widget.abTest),
                                                          //                 ),
                                                          //               )
                                                          //             }
                                                          //           : setState(
                                                          //               () {
                                                          //               completeInference =
                                                          //                   false;
                                                          //             })
                                                          //       : canChanged
                                                          //               .value
                                                          //           ? {
                                                          //               _sendBookStartClickEvent(
                                                          //                 clickedVoice!
                                                          //                     .contentVoiceId,
                                                          //                 contentId,
                                                          //                 title,
                                                          //                 clickedVoice!
                                                          //                     .voiceId,
                                                          //               ),
                                                          //               print(clickedVoice!
                                                          //                   .voiceName),
                                                          //               Navigator
                                                          //                   .push(
                                                          //                 context,
                                                          //                 MaterialPageRoute(
                                                          //                   builder: (context) => BookPage(
                                                          //                       // 다음 화면으로 contetnVoiceId를 가지고 이동
                                                          //                       abTest: widget.abTest,
                                                          //                       contentVoiceId: clickedVoice!.contentVoiceId,
                                                          //                       voiceId: clickedVoice!.voiceId,
                                                          //                       contentId: contentId,
                                                          //                       lastPage: lastPage,
                                                          //                       isSelected: true,
                                                          //                       title: bookIntro.first.title),
                                                          //                 ),
                                                          //               ),
                                                          //               audioPlayer
                                                          //                   .stop(),
                                                          //             }
                                                          //           : null;
                                                        },
                                                        child: Container(
                                                            width: 31.1 *
                                                                SizeConfig
                                                                    .defaultSize!,
                                                            height: 4.5 *
                                                                SizeConfig
                                                                    .defaultSize!,
                                                            decoration:
                                                                ShapeDecoration(
                                                              color: const Color
                                                                      .fromARGB(
                                                                  50,
                                                                  255,
                                                                  169,
                                                                  26),
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            30),
                                                              ),
                                                            ),
                                                            child: Stack(
                                                                children: [
                                                                  Positioned(
                                                                      right: 1 *
                                                                          SizeConfig
                                                                              .defaultSize!,
                                                                      top: 0.75 *
                                                                          SizeConfig
                                                                              .defaultSize!,
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .chevron_right,
                                                                        color: Colors
                                                                            .grey,
                                                                        size: SizeConfig.defaultSize! *
                                                                            3,
                                                                      )),
                                                                  Center(
                                                                    child: Text(
                                                                      '책-시작',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .grey,
                                                                          fontSize: 2.3 *
                                                                              SizeConfig.defaultSize! *
                                                                              double.parse('font-ratio'.tr()),
                                                                          fontFamily: 'font-book'.tr()),
                                                                    ).tr(),
                                                                  ),
                                                                ]))))
                                              ]))
                                        ]))
                              ])),

                          // Expanded(
                          //   // FOOTER
                          //   flex: 12,
                          //   child: Row(children: [
                          //     Expanded(
                          //       flex: 1,
                          //       child: Container(
                          //           color: const Color.fromARGB(0, 0, 100, 0)),
                          //     ),
                          //     Expanded(
                          //         flex: 8,
                          //         child: Container(
                          //             color: const Color.fromARGB(0, 0, 0, 0))),
                          //   Expanded(
                          //     flex: 1,
                          //     child: GestureDetector(
                          //         onTap: () async {
                          //           _checkHaveRead();
                          //           (cvi == inferenceId) // 원래는 cvi==inferenceId
                          //               ? await checkInference(token)
                          //                   ? {
                          //                       _sendBookStartClickEvent(
                          //                         cvi,
                          //                         contentId,
                          //                         vi,
                          //                       ),
                          //                       Navigator.push(
                          //                           context,
                          //                           MaterialPageRoute(
                          //                             builder: (context) =>
                          //                                 BookPage(
                          //                               // 다음 화면으로 contetnVoiceId를 가지고 이동
                          //                               contentVoiceId: cvi,
                          //                               voiceId: vi,
                          //                               contentId: contentId,
                          //                               lastPage: lastPage,
                          //                               isSelected: true,
                          //                             ),
                          //                           ))
                          //                     }
                          //                   : setState(() {
                          //                       completeInference = false;
                          //                     })
                          //               : canChanged.value
                          //                   ? {
                          //                       _sendBookStartClickEvent(
                          //                         cvi,
                          //                         contentId,
                          //                         vi,
                          //                       ),
                          //                       Navigator.push(
                          //                         context,
                          //                         MaterialPageRoute(
                          //                           builder: (context) =>
                          //                               BookPage(
                          //                             // 다음 화면으로 contetnVoiceId를 가지고 이동
                          //                             contentVoiceId: cvi,
                          //                             voiceId: vi,
                          //                             contentId: contentId,
                          //                             lastPage: lastPage,
                          //                             isSelected: true,
                          //                           ),
                          //                         ),
                          //                       ),
                          //                       audioPlayer.stop(),
                          //                     }
                          //                   : null;
                          //         },
                          //         // next 화살표 시작

                          //         child: Container(
                          //           // [->]
                          //           child: Row(
                          //             mainAxisAlignment:
                          //                 MainAxisAlignment.end, // 아이콘을 맨 왼쪽으로 정렬
                          //             children: [
                          //               Padding(
                          //                 padding: EdgeInsets.all(
                          //                     0.2 * SizeConfig.defaultSize!),
                          //                 child: Icon(
                          //                   // padding: EdgeInsets.all(
                          //                   //     0.2 * SizeConfig.defaultSize!),
                          //                   Icons.arrow_forward,
                          //                   size: 3 * SizeConfig.defaultSize!,
                          //                   color: Colors.black,
                          //                 ),
                          //               )
                          //             ],
                          //           ),
                          //         )),
                          //     // next 화살표 끝
                          //   )
                          // ]),
                          // ), // --------------------성우 아이콘 배치 완료  ---------
                        ]),
                      ),
                    ),
                  ),
                  // Visibility(
                  //   visible: wantPurchase,
                  //   child: AlertDialog(
                  //     titlePadding: EdgeInsets.only(
                  //       top: SizeConfig.defaultSize! * 7,
                  //       bottom: SizeConfig.defaultSize! * 2,
                  //     ),
                  //     actionsPadding: EdgeInsets.only(
                  //       left: SizeConfig.defaultSize! * 5,
                  //       right: SizeConfig.defaultSize! * 5,
                  //       bottom: SizeConfig.defaultSize! * 5,
                  //       top: SizeConfig.defaultSize! * 3,
                  //     ),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius:
                  //           BorderRadius.circular(SizeConfig.defaultSize! * 3),
                  //     ),
                  //     backgroundColor: Colors.white.withOpacity(0.9),
                  //     title: Center(
                  //       child: Text(
                  //         '인트로-구독',
                  //         style: TextStyle(
                  //           fontSize: SizeConfig.defaultSize! * 2.5,
                  //           fontFamily: 'font-basic'.tr(),
                  //         ),
                  //       ).tr(),
                  //     ),
                  //     actions: <Widget>[
                  //       Row(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           GestureDetector(
                  //             onTap: () {
                  //               _sendBookIntroRegisterLaterClickEvent(
                  //                   contentId, title);
                  //               // 1초 후에 다음 페이지로 이동
                  //               // Future.delayed(const Duration(seconds: 1), () {
                  //               setState(() {
                  //                 wantPurchase = false;
                  //               });
                  //               //});
                  //             },
                  //             child: Container(
                  //               width: SizeConfig.defaultSize! * 24,
                  //               height: SizeConfig.defaultSize! * 4.5,
                  //               decoration: BoxDecoration(
                  //                 borderRadius: BorderRadius.circular(
                  //                     SizeConfig.defaultSize! * 3),
                  //                 color: const Color(0xFFFFA91A),
                  //               ),
                  //               child: Center(
                  //                 child: Text(
                  //                   '답변-부정',
                  //                   style: TextStyle(
                  //                     color: Colors.black,
                  //                     fontFamily: 'font-basic'.tr(),
                  //                     fontSize: 2.2 * SizeConfig.defaultSize!,
                  //                   ),
                  //                 ).tr(),
                  //               ),
                  //             ),
                  //           ),
                  //           SizedBox(width: SizeConfig.defaultSize! * 4), // 간격 조정
                  //           GestureDetector(
                  //             onTap: () {
                  //               _sendBookIntroRegisterOkClickEvent(
                  //                   contentId, title);
                  //               // 1초 후에 다음 페이지로 이동
                  //               ///Future.delayed(const Duration(seconds: 1), () {
                  //               Navigator.push(
                  //                 context,
                  //                 MaterialPageRoute(
                  //                     builder: (context) => Purchase(
                  //                           abTest: widget.abTest,
                  //                         )),
                  //               );
                  //             },
                  //             //},
                  //             child: Container(
                  //               width: SizeConfig.defaultSize! * 24,
                  //               height: SizeConfig.defaultSize! * 4.5,
                  //               decoration: BoxDecoration(
                  //                 borderRadius: BorderRadius.circular(
                  //                     SizeConfig.defaultSize! * 3),
                  //                 color: const Color(0xFFFFA91A),
                  //               ),
                  //               child: Center(
                  //                 child: Text(
                  //                   '답변-긍정',
                  //                   style: TextStyle(
                  //                     color: Colors.black,
                  //                     fontFamily: 'font-basic'.tr(),
                  //                     fontSize: 2.2 * SizeConfig.defaultSize!,
                  //                   ),
                  //                 ).tr(),
                  //               ),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: wantBuyBook,
                  //   child: AlertDialog(
                  //     titlePadding: EdgeInsets.only(
                  //       top: SizeConfig.defaultSize! * 7,
                  //       bottom: SizeConfig.defaultSize! * 2,
                  //     ),
                  //     actionsPadding: EdgeInsets.only(
                  //       left: SizeConfig.defaultSize! * 5,
                  //       right: SizeConfig.defaultSize! * 5,
                  //       bottom: SizeConfig.defaultSize! * 5,
                  //       top: SizeConfig.defaultSize! * 3,
                  //     ),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius:
                  //           BorderRadius.circular(SizeConfig.defaultSize! * 3),
                  //     ),
                  //     backgroundColor: Colors.white.withOpacity(0.9),
                  //     title: Center(
                  //       child: Text(
                  //         '인트로-책구매',
                  //         style: TextStyle(
                  //           fontSize: SizeConfig.defaultSize! * 2.5,
                  //           fontFamily: 'font-basic'.tr(),
                  //         ),
                  //       ).tr(),
                  //     ),
                  //     actions: <Widget>[
                  //       Row(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           GestureDetector(
                  //             onTap: () {
                  //               // 1초 후에 다음 페이지로 이동
                  //               // Future.delayed(const Duration(seconds: 1), () {
                  //               _sendBookBuyLaterClickEvent(
                  //                   userState.point, contentId, title);
                  //               setState(() {
                  //                 wantBuyBook = false;
                  //               });
                  //               //});
                  //             },
                  //             child: Container(
                  //               width: SizeConfig.defaultSize! * 24,
                  //               height: SizeConfig.defaultSize! * 4.5,
                  //               decoration: BoxDecoration(
                  //                 borderRadius: BorderRadius.circular(
                  //                     SizeConfig.defaultSize! * 3),
                  //                 color: const Color(0xFFFFA91A),
                  //               ),
                  //               child: Center(
                  //                 child: Text(
                  //                   '답변-부정',
                  //                   style: TextStyle(
                  //                     color: Colors.black,
                  //                     fontFamily: 'font-basic'.tr(),
                  //                     fontSize: 2.2 * SizeConfig.defaultSize!,
                  //                   ),
                  //                 ).tr(),
                  //               ),
                  //             ),
                  //           ),
                  //           SizedBox(width: SizeConfig.defaultSize! * 4), // 간격 조정
                  //           GestureDetector(
                  //             onTap: () async {
                  //               _sendBookBuyClickEvent(
                  //                   userState.point, contentId, title);

                  //               userCubit.fetchUser();
                  //               setState(() {
                  //                 wantBuyBook = false;
                  //               });
                  //               if (userState.point < 3000) {
                  //                 lackingPoint =
                  //                     (3000 - userState.point).toString();
                  //                 setState(() {
                  //                   buyPoints = true;
                  //                 });
                  //               }
                  //               var result = await buyContent();
                  //               if (result == '200') {
                  //                 setState(() {
                  //                   animation = true;
                  //                 });
                  //                 bookIntroCubit.changeBookIntroData(widget.id);
                  //                 userCubit.fetchUser();
                  //                 dataCubit.changeHomeBookData();
                  //               }
                  //               // 1초 후에 다음 페이지로 이동
                  //               ///Future.delayed(const Duration(seconds: 1), () {
                  //             },
                  //             //},
                  //             child: Container(
                  //               width: SizeConfig.defaultSize! * 24,
                  //               height: SizeConfig.defaultSize! * 4.5,
                  //               decoration: BoxDecoration(
                  //                 borderRadius: BorderRadius.circular(
                  //                     SizeConfig.defaultSize! * 3),
                  //                 color: const Color(0xFFFFA91A),
                  //               ),
                  //               child: Center(
                  //                 child: Text(
                  //                   '답변-긍정',
                  //                   style: TextStyle(
                  //                     color: Colors.black,
                  //                     fontFamily: 'font-basic'.tr(),
                  //                     fontSize: 2.2 * SizeConfig.defaultSize!,
                  //                   ),
                  //                 ).tr(),
                  //               ),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: buyPoints,
                  //   child: AlertDialog(
                  //     titlePadding: EdgeInsets.only(
                  //       top: SizeConfig.defaultSize! * 7,
                  //       bottom: SizeConfig.defaultSize! * 2,
                  //     ),
                  //     actionsPadding: EdgeInsets.only(
                  //       left: SizeConfig.defaultSize! * 5,
                  //       right: SizeConfig.defaultSize! * 5,
                  //       bottom: SizeConfig.defaultSize! * 5,
                  //       top: SizeConfig.defaultSize! * 3,
                  //     ),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius:
                  //           BorderRadius.circular(SizeConfig.defaultSize! * 3),
                  //     ),
                  //     backgroundColor: Colors.white.withOpacity(0.9),
                  //     title: Center(
                  //         child: Column(children: [
                  //       RichText(
                  //           text: TextSpan(children: [
                  //         TextSpan(
                  //             style: TextStyle(
                  //               fontSize: 2.5 * SizeConfig.defaultSize!,
                  //               fontFamily: 'font-basic'.tr(),
                  //               color: Colors.black,
                  //             ),
                  //             text: "$lackingPoint"),
                  //         TextSpan(
                  //             style: TextStyle(
                  //               fontSize: 2.5 * SizeConfig.defaultSize!,
                  //               fontFamily: 'font-basic'.tr(),
                  //               color: Colors.black,
                  //             ),
                  //             text: "인트로-포인트부족".tr()),
                  //       ]))
                  //     ])),
                  //     actions: <Widget>[
                  //       Row(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           GestureDetector(
                  //             onTap: () {
                  //               _sendBookIntroBuyPointLaterClickEvent(
                  //                   lackingPoint,
                  //                   contentId,
                  //                   title,
                  //                   clickedVoice!.voiceId);
                  //               // 1초 후에 다음 페이지로 이동
                  //               //Future.delayed(const Duration(seconds: 1), () {
                  //               setState(() {
                  //                 buyPoints = false;
                  //               });
                  //               //});
                  //             },
                  //             child: Container(
                  //               width: SizeConfig.defaultSize! * 24,
                  //               height: SizeConfig.defaultSize! * 4.5,
                  //               decoration: BoxDecoration(
                  //                 borderRadius: BorderRadius.circular(
                  //                     SizeConfig.defaultSize! * 3),
                  //                 color: const Color(0xFFFFA91A),
                  //               ),
                  //               child: Center(
                  //                 child: Text(
                  //                   '답변-부정',
                  //                   style: TextStyle(
                  //                     color: Colors.black,
                  //                     fontFamily: 'font-basic'.tr(),
                  //                     fontSize: 2.2 * SizeConfig.defaultSize!,
                  //                   ),
                  //                 ).tr(),
                  //               ),
                  //             ),
                  //           ),
                  //           SizedBox(width: SizeConfig.defaultSize! * 4), // 간격 조정
                  //           GestureDetector(
                  //             onTap: () {
                  //               _sendBookIntroBuyPointOkClickEvent(lackingPoint,
                  //                   contentId, title, clickedVoice!.voiceId);
                  //               // 1초 후에 다음 페이지로 이동
                  //               //Future.delayed(const Duration(seconds: 1), () {
                  //               Navigator.push(
                  //                 context,
                  //                 MaterialPageRoute(
                  //                     builder: (context) => Purchase(
                  //                           abTest: widget.abTest,
                  //                         )),
                  //               );
                  //               //});
                  //             },
                  //             child: Container(
                  //               width: SizeConfig.defaultSize! * 24,
                  //               height: SizeConfig.defaultSize! * 4.5,
                  //               decoration: BoxDecoration(
                  //                 borderRadius: BorderRadius.circular(
                  //                     SizeConfig.defaultSize! * 3),
                  //                 color: const Color(0xFFFFA91A),
                  //               ),
                  //               child: Center(
                  //                 child: Text(
                  //                   '답변-긍정',
                  //                   style: TextStyle(
                  //                     color: Colors.black,
                  //                     fontFamily: 'font-basic'.tr(),
                  //                     fontSize: 2.2 * SizeConfig.defaultSize!,
                  //                   ),
                  //                 ).tr(),
                  //               ),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // ValueListenableBuilder<bool>(
                  //   valueListenable: wantRecord,
                  //   builder: (context, value, child) {
                  //     return Visibility(
                  //       visible: value,
                  //       child: AlertDialog(
                  //         titlePadding: EdgeInsets.only(
                  //           top: SizeConfig.defaultSize! * 7,
                  //           bottom: SizeConfig.defaultSize! * 2,
                  //         ),
                  //         actionsPadding: EdgeInsets.only(
                  //           left: SizeConfig.defaultSize! * 5,
                  //           right: SizeConfig.defaultSize! * 5,
                  //           bottom: SizeConfig.defaultSize! * 5,
                  //           top: SizeConfig.defaultSize! * 3,
                  //         ),
                  //         shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(
                  //               SizeConfig.defaultSize! * 3),
                  //         ),
                  //         backgroundColor: Colors.white.withOpacity(0.9),
                  //         title: Center(
                  //             child: Text(
                  //           '인트로-목소리녹음'.tr(),
                  //           style: TextStyle(
                  //             fontSize: 2.5 * SizeConfig.defaultSize!,
                  //             fontFamily: 'font-basic'.tr(),
                  //             color: Colors.black,
                  //           ),
                  //         )),
                  //         actions: <Widget>[
                  //           Row(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               GestureDetector(
                  //                 onTap: () {
                  //                   _sendBookIntroRecordLaterClickEvent(
                  //                       contentId, title);
                  //                   //Future.delayed(const Duration(seconds: 1),
                  //                   //   () {
                  //                   wantRecord.value = false;
                  //                   //});
                  //                 },
                  //                 child: Container(
                  //                   width: SizeConfig.defaultSize! * 24,
                  //                   height: SizeConfig.defaultSize! * 4.5,
                  //                   decoration: BoxDecoration(
                  //                     borderRadius: BorderRadius.circular(
                  //                         SizeConfig.defaultSize! * 3),
                  //                     color: const Color(0xFFFFA91A),
                  //                   ),
                  //                   child: Center(
                  //                     child: Text(
                  //                       '답변-부정',
                  //                       style: TextStyle(
                  //                         color: Colors.black,
                  //                         fontFamily: 'font-basic'.tr(),
                  //                         fontSize: 2.2 * SizeConfig.defaultSize!,
                  //                       ),
                  //                     ).tr(),
                  //                   ),
                  //                 ),
                  //               ),
                  //               SizedBox(
                  //                   width: SizeConfig.defaultSize! * 4), // 간격 조정
                  //               GestureDetector(
                  //                 onTap: () {
                  //                   _sendBookIntroRecordOkClickEvent(
                  //                       contentId, title);
                  //                   //Future.delayed(const Duration(seconds: 1),
                  //                   //   () {
                  //                   Navigator.push(
                  //                     context,
                  //                     MaterialPageRoute(
                  //                         builder: (context) => RecInfo(
                  //                               abTest: widget.abTest,
                  //                             )),
                  //                   );
                  //                   //});
                  //                 },
                  //                 child: Container(
                  //                   width: SizeConfig.defaultSize! * 24,
                  //                   height: SizeConfig.defaultSize! * 4.5,
                  //                   decoration: BoxDecoration(
                  //                     borderRadius: BorderRadius.circular(
                  //                         SizeConfig.defaultSize! * 3),
                  //                     color: const Color(0xFFFFA91A),
                  //                   ),
                  //                   child: Center(
                  //                     child: Text(
                  //                       '답변-긍정',
                  //                       style: TextStyle(
                  //                         color: Colors.black,
                  //                         fontFamily: 'font-basic'.tr(),
                  //                         fontSize: 2.2 * SizeConfig.defaultSize!,
                  //                       ),
                  //                     ).tr(),
                  //                   ),
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ],
                  //       ),
                  //     );
                  //   },
                  // ),
                  // Visibility(
                  //   visible: !completeInference,
                  //   child: AlertDialog(
                  //     titlePadding: EdgeInsets.only(
                  //       top: SizeConfig.defaultSize! * 4,
                  //       bottom: SizeConfig.defaultSize! * 0,
                  //     ),
                  //     actionsPadding: EdgeInsets.only(
                  //       left: SizeConfig.defaultSize! * 5,
                  //       right: SizeConfig.defaultSize! * 5,
                  //       bottom: SizeConfig.defaultSize! * 5,
                  //       top: SizeConfig.defaultSize! * 1,
                  //     ),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius:
                  //           BorderRadius.circular(SizeConfig.defaultSize! * 3),
                  //     ),
                  //     backgroundColor: Colors.white.withOpacity(0.9),
                  //     title: Center(
                  //         child: Text(
                  //       '인퍼런스중'.tr(),
                  //       style: TextStyle(
                  //         color: Colors.black,
                  //         fontFamily: 'font-basic'.tr(),
                  //         fontSize: 2.2 * SizeConfig.defaultSize!,
                  //       ),
                  //     )),
                  //     content: Text(
                  //       '인퍼런스중-내용',
                  //       style: TextStyle(
                  //         color: Colors.black,
                  //         fontFamily: 'font-basic'.tr(),
                  //         fontSize: 2.2 * SizeConfig.defaultSize!,
                  //       ),
                  //     ).tr(),
                  //     // content: Text('책만들어봐-내용').tr(),
                  //     actions: <Widget>[
                  //       Row(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           GestureDetector(
                  //             onTap: () {
                  //               _sendBookIntroMakeBookLaterClickEvent(
                  //                   contentId, title);
                  //               setState(() {
                  //                 completeInference = true;
                  //               });
                  //             },
                  //             child: Container(
                  //               width: SizeConfig.defaultSize! * 24,
                  //               height: SizeConfig.defaultSize! * 4.5,
                  //               decoration: BoxDecoration(
                  //                 borderRadius: BorderRadius.circular(
                  //                     SizeConfig.defaultSize! * 3),
                  //                 color: const Color(0xFFFFA91A),
                  //               ),
                  //               child: Center(
                  //                 child: Text(
                  //                   '답변-부정',
                  //                   style: TextStyle(
                  //                     color: Colors.black,
                  //                     fontFamily: 'font-basic'.tr(),
                  //                     fontSize: 2.2 * SizeConfig.defaultSize!,
                  //                   ),
                  //                 ).tr(),
                  //               ),
                  //             ),
                  //           ),
                  //           SizedBox(width: SizeConfig.defaultSize! * 4), // 간격 조정
                  //           GestureDetector(
                  //             onTap: () {
                  //               _sendBookIntroMakeBookOkClickEvent(
                  //                   contentId, title);
                  //               setState(() {
                  //                 completeInference = true;
                  //               });
                  //               //Future.delayed(const Duration(seconds: 1), () {
                  //               // Navigator.push(
                  //               //   context,
                  //               //   MaterialPageRoute(
                  //               //       builder: (context) => const RecInfo()),
                  //               // );
                  //               //});
                  //             },
                  //             child: Container(
                  //               width: SizeConfig.defaultSize! * 24,
                  //               height: SizeConfig.defaultSize! * 4.5,
                  //               decoration: BoxDecoration(
                  //                 borderRadius: BorderRadius.circular(
                  //                     SizeConfig.defaultSize! * 3),
                  //                 color: const Color(0xFFFFA91A),
                  //               ),
                  //               child: Center(
                  //                 child: Text(
                  //                   '답변-긍정',
                  //                   style: TextStyle(
                  //                     color: Colors.black,
                  //                     fontFamily: 'font-basic'.tr(),
                  //                     fontSize: 2.2 * SizeConfig.defaultSize!,
                  //                   ),
                  //                 ).tr(),
                  //               ),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // ValueListenableBuilder<bool>(
                  //   valueListenable: wantInference,
                  //   builder: (context, value, child) {
                  //     return Visibility(
                  //       visible: value,
                  //       child: AlertDialog(
                  //         titlePadding: EdgeInsets.only(
                  //           top: SizeConfig.defaultSize! * 7,
                  //           bottom: SizeConfig.defaultSize! * 2,
                  //         ),
                  //         actionsPadding: EdgeInsets.only(
                  //           left: SizeConfig.defaultSize! * 5,
                  //           right: SizeConfig.defaultSize! * 5,
                  //           bottom: SizeConfig.defaultSize! * 5,
                  //           top: SizeConfig.defaultSize! * 3,
                  //         ),
                  //         shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(
                  //               SizeConfig.defaultSize! * 3),
                  //         ),
                  //         backgroundColor: Colors.white.withOpacity(0.9),

                  //         title: Center(
                  //             child: Text(
                  //           '책만들어봐'.tr(),
                  //           style: TextStyle(
                  //             color: Colors.black,
                  //             fontFamily: 'font-basic'.tr(),
                  //             fontSize: 2.2 * SizeConfig.defaultSize!,
                  //           ),
                  //         )),
                  //         //content: Text('인퍼런스중-내용').tr(),

                  //         actions: <Widget>[
                  //           Row(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               GestureDetector(
                  //                 onTap: () {
                  //                   //Future.delayed(const Duration(seconds: 1),
                  //                   //   () {
                  //                   wantInference.value = false;
                  //                   //});
                  //                 },
                  //                 child: Container(
                  //                   width: SizeConfig.defaultSize! * 24,
                  //                   height: SizeConfig.defaultSize! * 4.5,
                  //                   decoration: BoxDecoration(
                  //                     borderRadius: BorderRadius.circular(
                  //                         SizeConfig.defaultSize! * 3),
                  //                     color: const Color(0xFFFFA91A),
                  //                   ),
                  //                   child: Center(
                  //                     child: Text(
                  //                       '답변-부정',
                  //                       style: TextStyle(
                  //                         color: Colors.black,
                  //                         fontFamily: 'font-basic'.tr(),
                  //                         fontSize: 2.2 * SizeConfig.defaultSize!,
                  //                       ),
                  //                     ).tr(),
                  //                   ),
                  //                 ),
                  //               ),
                  //               SizedBox(
                  //                   width: SizeConfig.defaultSize! * 4), // 간격 조정
                  //               GestureDetector(
                  //                 onTap: () {
                  //                   // 1초 후에 다음 페이지로 이동
                  //                   startInference(token);

                  //                   //   setState(() {
                  //                   wantInference.value = false;
                  //                   // });
                  //                 },
                  //                 child: Container(
                  //                   width: SizeConfig.defaultSize! * 24,
                  //                   height: SizeConfig.defaultSize! * 4.5,
                  //                   decoration: BoxDecoration(
                  //                     borderRadius: BorderRadius.circular(
                  //                         SizeConfig.defaultSize! * 3),
                  //                     color: const Color(0xFFFFA91A),
                  //                   ),
                  //                   child: Center(
                  //                     child: Text(
                  //                       '답변-긍정',
                  //                       style: TextStyle(
                  //                         color: Colors.black,
                  //                         fontFamily: 'font-basic'.tr(),
                  //                         fontSize: 2.2 * SizeConfig.defaultSize!,
                  //                       ),
                  //                     ).tr(),
                  //                   ),
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ],
                  //       ),
                  //     );
                  //   },
                  // )
                  Positioned(
                    left: SizeConfig.defaultSize! * 52,
                    top: SizeConfig.defaultSize! * 13,
                    child: Image.asset(
                      'lib/images/finger.png',
                      width: SizeConfig.defaultSize! * 10,
                    ),
                  ),
                ],
              ));
        }
      }); //);
    });
  }
}
