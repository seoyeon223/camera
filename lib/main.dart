import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app.dart';

// 🚨 프로젝트에 맞게 옵션 파일 경로를 확인해 주세요. (보통 lib 폴더 안에 자동 생성됩니다)
import 'firebase_options.dart'; 

// 1. main 함수에 비동기(async)를 추가합니다.
void main() async {
  // Flutter 엔진과 위젯 트리가 연결되기 전에 Firebase 설정을 기다려주기 위한 필수 코드입니다.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. 앱이 켜지자마자 조용히 익명 로그인을 실행합니다.
  await _signInAnonymously();

  // 4. 앱 화면 실행 (기존 코드 그대로 유지)
  runApp(const MyApp()); 
}

// 👤 Firebase 익명 로그인 함수
Future<void> _signInAnonymously() async {
  try {
    // 이미 로그인된 상태인지 확인 (앱을 껐다 켜도 기존 UID를 유지하기 위함)
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      // 로그인된 기록이 없다면 새로 익명 계정을 생성합니다.
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      debugPrint('새로운 익명 유저 생성 완료! UID: ${userCredential.user?.uid}');
    } else {
      // 이미 UID가 있다면 기존 UID를 그대로 사용합니다.
      debugPrint('기존 유저 로그인 완료! UID: ${currentUser.uid}');
    }
  } on FirebaseAuthException catch (e) {
    if (e.code == 'operation-not-allowed') {
      debugPrint('에러: Firebase 콘솔에서 [익명 로그인] 기능이 켜져있지 않습니다!');
    } else {
      debugPrint('로그인 실패: ${e.message}');
    }
  }
}

