import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/size_config.dart';
import './record_info.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart';

import 'globalCubit/user/user_cubit.dart';
import './record_request.dart';

class AudioRecorder extends StatefulWidget {
  final void Function(String path)? onStop;

  const AudioRecorder({Key? key, this.onStop}) : super(key: key);

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  late String token;
  bool stopped = false;
  String path_copy = '';
  int _recordDuration = 0;
  Timer? _timer;
  final _audioRecorder = Record();
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  String? path = '';
  //StreamSubscription<Amplitude>? _amplitudeSub;
  //Amplitude? _amplitude;
  AudioPlayer audioPlayer = AudioPlayer();

  static const platformChannel = MethodChannel('com.sayit.yoggo/channel');

  Future<void> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token')!;
    });
  }

  // void sendPathToKotlin(path) async {
  //   try {
  //     await platformChannel.invokeMethod('setPath', {'path': path});
  //   } catch (e) {
  //     print('Error sending path to Kotlin: $e');
  //   }
  // }

  // Future<void> stopRecording() async {
  //   try {
  //     await platformChannel.invokeMethod('stopRecording');
  //     print('Recording stopped.'); // 녹음이 정상적으로 중지되었음을 출력합니다.
  //   } catch (e) {
  //     print('Error: $e');
  //   }
  // }

  @override
  void initState() {
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      setState(() => _recordState = recordState);
    });

    // _amplitudeSub = _audioRecorder
    //     .onAmplitudeChanged(const Duration(milliseconds: 300))
    //     .listen((amp) => setState(() => _amplitude = amp));

    getToken();
    super.initState();
  }

  Future<int> getId() async {
    var url = Uri.parse('https://yoggo-server.fly.dev/user/id');
    var response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    var responseData = json.decode(response.body);
    var id = responseData[0];
    return id;
  }

  Future<void> sendRecord(audioUrl, recordName) async {
    final UserCubit userCubit;
    var url = Uri.parse('https://yoggo-server.fly.dev/producer/record');

    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('recordUrl', audioUrl,
          contentType: MediaType('audio', 'x-wav')),
    );
    request.fields['recordName'] = recordName;
    var response = await request.send();
    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      //await prefs.setBool('record', true);
      //  await userCubit.fetchUser();
      print('Record sent successfully');
    } else {
      print('Failed to send record. Status code: ${response.statusCode}');
    }
  }

  Future<void> _start(purchase, record) async {
    try {
      if (await _audioRecorder.hasPermission()) {
        var myAppDir = await getAppDirectory();
        var id = await getId();
        var playerExtension = Platform.isAndroid ? '$id.wav' : '$id.flac';
        await _audioRecorder.start(
          path: '$myAppDir/$playerExtension',
          encoder: Platform.isAndroid
              ? AudioEncoder.wav
              : AudioEncoder.flac, // by default
        );

        if (Platform.isAndroid) ('$myAppDir/$playerExtension');
        _recordState = RecordState.record;
        _recordDuration = 0;

        _startTimer();
        _sendRecStartClickEvent(purchase, record);
      }
    } catch (e) {
      if (kDebugMode) {}
    }
  }

  Future<String> getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> _stop(purchase, record) async {
    setState(() {
      stopped = true;
    });
    _timer?.cancel();
    _recordDuration = 0;
    //  if (Platform.isAndroid) stopRecording();
    path = await _audioRecorder.stop(); //path받기
    _sendRecStopClickEvent(purchase, record);
    //  sendPathToKotlin(path);
    // if (path != null) {
    //   widget.onStop?.call(path);
    //   path_copy = path.split('/').last;
    //   sendRecord(path, path_copy);
    // }
  }

  Future<void> _pause() async {
    playAudio();
    _timer?.cancel();
    await _audioRecorder.pause();
  }

  Future<void> _resume() async {
    _startTimer();
    await _audioRecorder.resume();
  }

  void playAudio() async {
    await audioPlayer.play(DeviceFileSource(path_copy));
  }

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    final userCubit = context.watch<UserCubit>();
    final userState = userCubit.state;
    SizeConfig().init(context);
    _sendRecIngViewEvent(userState.purchase, userState.record);
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('lib/images/bkground.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: SizeConfig.defaultSize!,
                  ),
                  Expanded(
                    flex: SizeConfig.defaultSize!.toInt(),
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'LOVEL',
                              style: TextStyle(
                                fontFamily: 'Modak',
                                fontSize: SizeConfig.defaultSize! * 5,
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          left: SizeConfig.defaultSize! * 2,
                          child: IconButton(
                            icon: Icon(
                              Icons.cancel,
                              size: SizeConfig.defaultSize! * 2.3,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RecordInfo(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: SizeConfig.defaultSize!.toInt() * 2,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    'As she emerges from the sea onto the shore, she realizes that her \n',
                                style: TextStyle(
                                    fontSize: SizeConfig.defaultSize! * 1.6,
                                    color: Colors.black),
                              ),
                              TextSpan(
                                text:
                                    'voice is gone, but she still recognizes its immeasurable beauty and\n',
                                style: TextStyle(
                                    fontSize: SizeConfig.defaultSize! * 1.6,
                                    color: Colors.black),
                              ),
                              TextSpan(
                                text:
                                    'preciousness. She expresses it in the following way:\n ',
                                style: TextStyle(
                                    fontSize: SizeConfig.defaultSize! * 1.6,
                                    color: Colors.black),
                              ),
                              TextSpan(
                                text:
                                    '"Voice is an ineffable beauty. It is the purest and most precious gift.\n',
                                style: TextStyle(
                                    fontSize: SizeConfig.defaultSize! * 1.6,
                                    color: Colors.black),
                              ),
                              TextSpan(
                                text:
                                    'Though I have lost this cherished gift, I will embark on a journey to find\n',
                                style: TextStyle(
                                    fontSize: SizeConfig.defaultSize! * 1.6,
                                    color: Colors.black),
                              ),
                              TextSpan(
                                text:
                                    'true love through other means. Even without my voice, the emotions\n',
                                style: TextStyle(
                                    fontSize: SizeConfig.defaultSize! * 1.6,
                                    color: Colors.black),
                              ),
                              TextSpan(
                                text:
                                    'and passions within me will not easily fade away. Love transcends\n',
                                style: TextStyle(
                                    fontSize: SizeConfig.defaultSize! * 1.6,
                                    color: Colors.black),
                              ),
                              TextSpan(
                                text:
                                    'language. In this quest to reclaim my precious voice, I will discover my\n',
                                style: TextStyle(
                                    fontSize: SizeConfig.defaultSize! * 1.6,
                                    color: Colors.black),
                              ),
                              TextSpan(
                                text:
                                    'true self and learn the ways of love and freedom."',
                                style: TextStyle(
                                    fontSize: SizeConfig.defaultSize! * 1.6,
                                    color: Colors.black),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: SizeConfig.defaultSize!.toInt() * 1,
                    //   mainAxisAlignment: MainAxisAlignment.start,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _buildRecordStopControl(),
                        SizedBox(width: SizeConfig.defaultSize! * 3),
                        // _buildPauseResumeControl(),
                        // const SizedBox(width: 20),
                        _buildText(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Visibility(
                visible: stopped,
                child: AlertDialog(
                  titlePadding: EdgeInsets.only(
                      left: SizeConfig.defaultSize! * 9,
                      right: SizeConfig.defaultSize! * 5,
                      top: SizeConfig.defaultSize! * 3),
                  // buttonPadding: const EdgeInsets.only(left: 30, right: 30),
                  actionsPadding: EdgeInsets.only(
                      left: SizeConfig.defaultSize! * 8,
                      right: SizeConfig.defaultSize! * 8,
                      bottom: SizeConfig.defaultSize! * 3,
                      top: SizeConfig.defaultSize! * 3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        SizeConfig.defaultSize!), // 모든 모서리를 10 픽셀로 둥글게 설정
                  ),
                  backgroundColor: Colors.white.withOpacity(0.9),
                  title: Text(
                    'Would you like to use the voice you just recorded?',
                    style: TextStyle(
                      fontSize: SizeConfig.defaultSize! * 1.7,
                      fontFamily: 'Molengo',
                    ),
                  ),
                  // content: const Text('Your recording has been completed.'),
                  actions: [
                    Container(
                      width: SizeConfig.defaultSize! * 17,
                      // color: Colors.orange,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              SizeConfig.defaultSize!), // 원하는 모서리의 둥글기 설정
                          color: const Color.fromARGB(255, 255, 167, 26)),
                      child: TextButton(
                        onPressed: () {
                          path = ''; // 이 버전을 원하지 않는 경우 path 초기화
                          _sendRecRerecClickEvent(
                              userState.purchase, userState.record);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AudioRecorder()));
                          //  Navigator.pop(context);
                        },
                        child: const Text(
                          'No, Re-make',
                          style: TextStyle(
                              color: Colors.black, fontFamily: 'Molengo,'),
                        ),
                      ),
                    ),
                    Container(
                      width: SizeConfig.defaultSize! * 4,
                    ),
                    Container(
                      width: SizeConfig.defaultSize! * 17,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              SizeConfig.defaultSize!), // 원하는 모서리의 둥글기 설정
                          color: const Color.fromARGB(255, 255, 167, 26)),
                      child: TextButton(
                        onPressed: () async {
                          // 1초 후에 다음 페이지로 이동
                          if (path != null) {
                            // 녹음을 해도 괜찮다고 판단했을 경우 백엔드에 보낸다
                            widget.onStop?.call(path!);
                            path_copy = path!.split('/').last;
                            await sendRecord(path, path_copy);
                            _sendRecKeepClickEvent(
                                userState.purchase, userState.record);
                          }
                          Future.delayed(const Duration(seconds: 1), () async {
                            // await userCubit.fetchUser();
                            // print("fetchuser부름");
                            print(userState.record);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const recordRequest()),
                            );
                          });
                        },
                        child: const Text(
                          'Yes',
                          style: TextStyle(
                              color: Colors.black, fontFamily: 'Molengo,'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    // _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Widget _buildRecordStopControl() {
    final userCubit = context.watch<UserCubit>();
    final userState = userCubit.state;
    late Icon icon;
    late Color color;

    if (_recordState != RecordState.stop) {
      icon = Icon(Icons.stop,
          color: Colors.red, size: SizeConfig.defaultSize! * 3);
      color = Colors.red.withOpacity(0.1);
    } else {
      //   _stopRecording();
      final theme = Theme.of(context);
      icon = Icon(Icons.mic,
          color: theme.primaryColor, size: SizeConfig.defaultSize! * 3);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(
              width: SizeConfig.defaultSize! * 5.6,
              height: SizeConfig.defaultSize! * 5.6,
              child: icon),
          onTap: () {
            (_recordState != RecordState.stop)
                ? _stop(userState.purchase, userState.record)
                : _start(userState.purchase, userState.record);
          },
        ),
      ),
    );
  }

  // Widget _buildPauseResumeControl() {
  //   if (_recordState == RecordState.stop) {
  //     return const SizedBox.shrink();
  //   }

  //   late Icon icon;
  //   late Color color;

  //   if (_recordState == RecordState.record) {
  //     icon = const Icon(Icons.pause, color: Colors.red, size: 30);
  //     color = Colors.red.withOpacity(0.1);
  //   } else {
  //     _stopRecording();
  //     // final theme = Theme.of(context);
  //     // icon = const Icon(Icons.play_arrow, color: Colors.red, size: 30);
  //     // color = theme.primaryColor.withOpacity(0.1);
  //   }

  //   return ClipOval(
  //     child: Material(
  //       color: color,
  //       child: InkWell(
  //         child: SizedBox(width: 56, height: 56, child: icon),
  //         onTap: () {
  //           (_recordState == RecordState.pause) ? _resume() : _pause();
  //         },
  //       ),
  //     ),
  //   );
  // }

  Widget _buildText() {
    if (_recordState != RecordState.stop) {
      return _buildTimer();
    }

    return Text(
      "Waiting to record",
      style: TextStyle(
        fontSize: SizeConfig.defaultSize! * 1.6,
      ),
    );
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: const TextStyle(color: Colors.red),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }

  Future<void> _sendRecStartClickEvent(purchase, record) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_start_click',
        parameters: <String, dynamic>{
          'purchase': purchase ? 'true' : 'false',
          'record': record ? 'true' : 'false',
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendRecStopClickEvent(purchase, record) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_stop_click',
        parameters: <String, dynamic>{
          'purchase': purchase ? 'true' : 'false',
          'record': record ? 'true' : 'false',
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendRecIngViewEvent(purchase, record) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_ing_view',
        parameters: <String, dynamic>{
          'purchase': purchase ? 'true' : 'false',
          'record': record ? 'true' : 'false',
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendRecRerecClickEvent(purchase, record) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_rerec_clic',
        parameters: <String, dynamic>{
          'purchase': purchase ? 'true' : 'false',
          'record': record ? 'true' : 'false',
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력
      print('Failed to log event: $e');
    }
  }

  Future<void> _sendRecKeepClickEvent(purchase, record) async {
    try {
      // 이벤트 로깅
      await analytics.logEvent(
        name: 'rec_keep_click',
        parameters: <String, dynamic>{
          'purchase': purchase ? 'true' : 'false',
          'record': record ? 'true' : 'false',
          //'voiceId': voiceId,
        },
      );
    } catch (e) {
      // 이벤트 로깅 실패 시 에러 출력r
      print('Failed to log event: $e');
    }
  }
}
