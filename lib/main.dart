import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider; // 이름 충돌 방지
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // kReleaseMode를 사용하기 위해 필요
import 'package:flutter_dotenv/flutter_dotenv.dart'; // dotenv 패키지 import

// 자동으로 생성된 Firebase 설정 파일을 import 합니다.
import 'firebase_options.dart';

void main() async {
  // Flutter 앱이 실행될 준비가 될 때까지 기다립니다.
  WidgetsFlutterBinding.ensureInitialized();

  // 현재 빌드 모드에 맞는 .env 파일 로드
  await dotenv.load(fileName: kReleaseMode ? ".env.release" : ".env.debug");

  // .env 파일에서 카카오 네이티브 앱 키를 불러와 SDK를 초기화합니다.
  kakao.KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']!);

  // Firebase 앱을 초기화합니다.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const QtApp());
}

// --- 앱의 전체 구조와 테마를 정의하는 위젯 ---
class QtApp extends StatelessWidget {
  const QtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 큐티',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // AuthWrapper를 통해 로그인 상태에 따라 다른 화면을 보여줍니다.
      home: const AuthWrapper(),
    );
  }
}

// --- 로그인 상태를 감지하여 화면을 전환하는 핵심 위젯 ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 연결 중일 때는 로딩 화면을 보여줍니다.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // 로그인 상태이면 HomeScreen을 보여줍니다.
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        // 로그아웃 상태이면 LoginScreen을 보여줍니다.
        return const LoginScreen();
      },
    );
  }
}

// --- 로그인 화면 ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isNaverLoading = false;
  bool _isKakaoLoading = false;

  // .env 파일에서 백엔드 URL을 불러옵니다.
  final String backendUrl = dotenv.env['BACKEND_URL']!;

  // --- 소셜 로그인 공통 처리 로직 ---
  Future<void> _signInWithSocial(String socialType, Future<String?> Function() getToken) async {
    if (!mounted) return;
    setState(() {
      if (socialType == 'naver') _isNaverLoading = true;
      if (socialType == 'kakao') _isKakaoLoading = true;
    });

    try {
      final socialToken = await getToken();
      if (socialToken == null) {
        throw Exception('$socialType 토큰을 가져오지 못했습니다.');
      }

      final response = await http.post(
        Uri.parse('$backendUrl/auth/$socialType'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': socialToken}),
      );

      if (response.statusCode == 200) {
        final firebaseToken = json.decode(response.body)['firebase_token'];
        await FirebaseAuth.instance.signInWithCustomToken(firebaseToken);
      } else {
        throw Exception('백엔드 인증 실패: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$socialType 로그인 중 오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (socialType == 'naver') _isNaverLoading = false;
          if (socialType == 'kakao') _isKakaoLoading = false;
        });
      }
    }
  }

  // --- 각 소셜 로그인 호출 함수 ---
  Future<void> _signInWithNaver() => _signInWithSocial('naver', () async {
    final result = await FlutterNaverLogin.logIn();
    return result.status == NaverLoginStatus.loggedIn ? result.accessToken?.accessToken : null;
  });

  Future<void> _signInWithKakao() => _signInWithSocial('kakao', () async {
    final isInstalled = await kakao.isKakaoTalkInstalled();
    final oAuthToken = isInstalled
        ? await kakao.UserApi.instance.loginWithKakaoTalk()
        : await kakao.UserApi.instance.loginWithKakaoAccount();
    return oAuthToken.accessToken;
  });

  @override
  Widget build(BuildContext context) {
    // .env 파일에서 구글 웹 클라이언트 ID를 불러옵니다.
    final googleProvider = GoogleProvider(clientId: dotenv.env['GOOGLE_WEB_CLIENT_ID']!);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.auto_stories, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              const Text('AI 큐티', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const Text('말씀과 함께하는 깊은 묵상의 시간', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              EmailForm(),
              const SizedBox(height: 20),
              const Text("또는", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              OAuthProviderButton(provider: googleProvider),
              const SizedBox(height: 12),
              _isKakaoLoading
                  ? const CircularProgressIndicator()
                  : _buildSocialButton(text: '카카오로 로그인', color: const Color(0xFFFEE500), textColor: const Color(0xFF191919), onPressed: _signInWithKakao),
              const SizedBox(height: 12),
              _isNaverLoading
                  ? const CircularProgressIndicator()
                  : _buildSocialButton(text: '네이버로 로그인', color: const Color(0xFF03C75A), textColor: Colors.white, onPressed: _signInWithNaver),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({required String text, required Color color, required Color textColor, required VoidCallback onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

// --- 메인 화면 (로그인 후) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await kakao.UserApi.instance.logout();
      await FlutterNaverLogin.logOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그아웃 중 오류 발생: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 큐티'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _signOut(context), tooltip: '로그아웃'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${user?.displayName ?? user?.email ?? '성도'}님, 좋은 아침입니다!', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            // ... (메인 화면의 말씀/묵상 카드 위젯들)
          ],
        ),
      ),
    );
  }
}
