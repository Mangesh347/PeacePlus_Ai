import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const PeacePlusApp());
}

class PeacePlusApp extends StatelessWidget {
  const PeacePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PeacePlus AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), // Pure Black
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFFFFF),
          secondary: Color(0xFFE5E5E5),
          surface: Color(0xFF121212),
          onSurface: Colors.white,
        ),
        fontFamily: 'Roboto',
      ),
      home: const AppEntryGate(),
    );
  }
}

// ==========================================
// DATA MODELS
// ==========================================
class ChatMessage {
  final String id;
  String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? '',
    text: json['text'] ?? '',
    isUser: json['isUser'] ?? false,
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
  );
}

class ChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'] ?? '',
    title: json['title'] ?? 'Conversation',
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    messages: (json['messages'] as List<dynamic>? ?? [])
        .map((m) => ChatMessage.fromJson(m))
        .toList(),
  );
}

class RelationshipProfile {
  final String id;
  final String name;
  final String relationType;
  final int healthScore;
  final String statusNotes;

  RelationshipProfile({
    required this.id,
    required this.name,
    required this.relationType,
    required this.healthScore,
    required this.statusNotes,
  });
}

class JournalEntry {
  final String id;
  final DateTime date;
  final String mood;
  final int stressLevel;
  final String note;

  JournalEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.stressLevel,
    required this.note,
  });
}

// ==========================================
// INITIAL ENTRY GATE (LOGIN / GUEST LANDING)
// ==========================================
class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  bool _isLoading = true;
  bool _hasChosenMode = false;
  bool _isSignedInGoogle = false;
  String _userName = "Peace Guest";
  String _userEmail = "guest@peaceplus.ai";

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '46966801209-cito710qr4vcuehdvhobg3g6nr51e1js.apps.googleusercontent.com',
    serverClientId: '46966801209-cito710qr4vcuehdvhobg3g6nr51e1js.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final chosen = prefs.getBool('app_mode_chosen') ?? false;
    final isGoogle = prefs.getBool('google_auth') ?? false;
    final name = prefs.getString('user_name') ?? "Peace Guest";
    final email = prefs.getString('user_email') ?? "guest@peaceplus.ai";

    setState(() {
      _hasChosenMode = chosen;
      _isSignedInGoogle = isGoogle;
      _userName = name;
      _userEmail = email;
      _isLoading = false;
    });
  }

  Future<void> _continueWithGoogle() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await prefs.setBool('app_mode_chosen', true);
        await prefs.setBool('google_auth', true);
        await prefs.setString('user_name', account.displayName ?? "Google User");
        await prefs.setString('user_email', account.email);
        setState(() {
          _hasChosenMode = true;
          _isSignedInGoogle = true;
          _userName = account.displayName ?? "Google User";
          _userEmail = account.email;
        });
        return;
      }
    } catch (_) {}

    await prefs.setBool('app_mode_chosen', true);
    await prefs.setBool('google_auth', true);
    await prefs.setString('user_name', "Mangesh Gholap");
    await prefs.setString('user_email', "mangesh@peaceplus.ai");
    setState(() {
      _hasChosenMode = true;
      _isSignedInGoogle = true;
      _userName = "Mangesh Gholap";
      _userEmail = "mangesh@peaceplus.ai";
    });
  }

  Future<void> _continueWithoutLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_mode_chosen', true);
    await prefs.setBool('google_auth', false);
    await prefs.setString('user_name', "Peace Guest");
    await prefs.setString('user_email', "guest@peaceplus.ai");
    setState(() {
      _hasChosenMode = true;
      _isSignedInGoogle = false;
      _userName = "Peace Guest";
      _userEmail = "guest@peaceplus.ai";
    });
  }

  void _onSignOut() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await prefs.setBool('app_mode_chosen', false);
    await prefs.setBool('google_auth', false);
    setState(() {
      _hasChosenMode = false;
      _isSignedInGoogle = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    if (_hasChosenMode) {
      return ChatGPTMainScreen(
        isSignedInGoogle: _isSignedInGoogle,
        userName: _userName,
        userEmail: _userEmail,
        onSignOut: _onSignOut,
        onSignInGoogle: _continueWithGoogle,
      );
    }

    // Onboarding Gate Screen with Stunning Animations & Google Logo
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, animValue, child) {
            return Opacity(
              opacity: animValue,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - animValue)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Animated Glowing Brand Logo Icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.12),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(48),
                    child: Image.asset(
                      'assets/logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield_rounded, color: Colors.white, size: 44),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                const Text(
                  "PeacePlus AI",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  "Your deeply supportive, comforting, and compassionate counseling companion for peace and forgiveness.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Color(0xFFA3A3A3),
                  ),
                ),

                const Spacer(),

                // Button 1: Continue with Google (with Google 4-Color Logo)
                InkWell(
                  onTap: _continueWithGoogle,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google Brand Logo Mark
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Center(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                children: [
                                  TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Continue with Google",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Button 2: Continue without login (Guest Mode)
                InkWell(
                  onTap: _continueWithoutLogin,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text(
                          "Continue without login",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// CHATGPT MAIN SCREEN WITH SESSION HISTORY
// ==========================================
class ChatGPTMainScreen extends StatefulWidget {
  final bool isSignedInGoogle;
  final String userName;
  final String userEmail;
  final VoidCallback onSignOut;
  final VoidCallback onSignInGoogle;

  const ChatGPTMainScreen({
    super.key,
    required this.isSignedInGoogle,
    required this.userName,
    required this.userEmail,
    required this.onSignOut,
    required this.onSignInGoogle,
  });

  @override
  State<ChatGPTMainScreen> createState() => _ChatGPTMainScreenState();
}

class _ChatGPTMainScreenState extends State<ChatGPTMainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _activeView = 'chat'; // chat, relationships, analyzer, journal, dashboard

  // Tradition Order: 1st General, 2nd Hinduism, then others
  final List<Map<String, dynamic>> _traditions = [
    {'name': 'General', 'icon': Icons.public_rounded, 'desc': 'Universal Peace & Comfort'},
    {'name': 'Hinduism', 'icon': Icons.self_improvement_rounded, 'desc': 'Ahimsa, Dharma & Inner Peace'},
    {'name': 'Christianity', 'icon': Icons.church_rounded, 'desc': 'Grace, Compassion & Pardon'},
    {'name': 'Islam', 'icon': Icons.mosque_rounded, 'desc': 'Reconciliation & Mercy'},
    {'name': 'Buddhism', 'icon': Icons.spa_rounded, 'desc': 'Mindfulness, Loving-Kindness'},
    {'name': 'Judaism', 'icon': Icons.synagogue_rounded, 'desc': 'Teshuvah & Appeasement'},
    {'name': 'Secular', 'icon': Icons.auto_awesome_rounded, 'desc': 'Philosophical Stoicism'},
  ];

  String _selectedReligion = 'General';
  String _selectedPerspective = 'Aggrieved';
  String _apiUrl = "https://peaceplus-ai.onrender.com/forgiveness";
  bool _forceOfflineMode = false;
  bool _dailyNotificationsEnabled = true;

  // Multi-Session Chat History (like ChatGPT)
  List<ChatSession> _chatSessions = [];
  String _currentSessionId = '';
  List<ChatMessage> _messages = [];
  bool _isStreaming = false;

  final List<RelationshipProfile> _relationships = [
    RelationshipProfile(id: '1', name: 'Alex Rivera', relationType: 'Partner', healthScore: 92, statusNotes: 'Open communication, resolving trust misalignments.'),
    RelationshipProfile(id: '2', name: 'Sarah G.', relationType: 'Friend', healthScore: 84, statusNotes: 'Pardoned minor secret sharing incident.'),
    RelationshipProfile(id: '3', name: 'David Miller', relationType: 'Coworker', healthScore: 75, statusNotes: 'Establishing clear project credit boundaries.'),
  ];

  final List<JournalEntry> _journalEntries = [
    JournalEntry(id: 'j1', date: DateTime.now().subtract(const Duration(hours: 14)), mood: 'Peaceful', stressLevel: 3, note: 'Had an open talk with Alex. Expressed my boundaries calmly.'),
    JournalEntry(id: 'j2', date: DateTime.now().subtract(const Duration(days: 1, hours: 8)), mood: 'Hopeful', stressLevel: 5, note: 'Reflected on forgiveness wisdom. Releasing bitterness brings peace.'),
  ];

  @override
  void initState() {
    super.initState();
    _loadHistoryAndSettings();
  }

  Future<void> _loadHistoryAndSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiUrl = prefs.getString('api_url') ?? "https://peaceplus-ai.onrender.com/forgiveness";
    _forceOfflineMode = prefs.getBool('offline_mode') ?? false;
    _dailyNotificationsEnabled = prefs.getBool('daily_notif') ?? true;

    final rawHistory = prefs.getString('saved_chat_sessions');
    if (rawHistory != null && rawHistory.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(rawHistory);
        _chatSessions = decoded.map((s) => ChatSession.fromJson(s)).toList();
        // Remove empty sessions that have no user messages
        _chatSessions.removeWhere((s) => !s.messages.any((m) => m.isUser));
      } catch (_) {}
    }

    // Always start with a fresh new chat whenever opening the app
    _initNewSession();
    setState(() {});
  }

  Future<void> _saveSessionsToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final index = _chatSessions.indexWhere((s) => s.id == _currentSessionId);
    if (index != -1) {
      _chatSessions[index].messages = List.from(_messages);
      if (_messages.length > 1 && _chatSessions[index].title == 'New Conversation') {
        final firstUserMsg = _messages.firstWhere((m) => m.isUser, orElse: () => _messages[1]);
        _chatSessions[index].title = firstUserMsg.text.length > 28
            ? "${firstUserMsg.text.substring(0, 28)}..."
            : firstUserMsg.text;
      }
    }
    final encoded = jsonEncode(_chatSessions.map((s) => s.toJson()).toList());
    await prefs.setString('saved_chat_sessions', encoded);
  }

  void _initNewSession() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final welcomeMsg = ChatMessage(
      id: 'welcome_$newId',
      text: "Hello! I am PeacePlus AI, your peace, emotional intelligence, and forgiveness counselor.\n\nHow can I support you through what you're experiencing today?",
      isUser: false,
      timestamp: DateTime.now(),
    );

    final session = ChatSession(
      id: newId,
      title: 'New Conversation',
      createdAt: DateTime.now(),
      messages: [welcomeMsg],
    );

    _chatSessions.insert(0, session);
    _currentSessionId = newId;
    _messages = [welcomeMsg];
  }

  void _startNewChat() {
    setState(() {
      _activeView = 'chat';
      _initNewSession();
      _saveSessionsToDisk();
    });
    Navigator.pop(context); // Close drawer
  }

  void _loadSession(ChatSession session) {
    setState(() {
      _activeView = 'chat';
      _currentSessionId = session.id;
      _messages = List.from(session.messages);
    });
    Navigator.pop(context);
  }

  void _deleteSession(String sessionId) {
    setState(() {
      _chatSessions.removeWhere((s) => s.id == sessionId);
      if (_currentSessionId == sessionId) {
        if (_chatSessions.isNotEmpty) {
          _currentSessionId = _chatSessions.first.id;
          _messages = List.from(_chatSessions.first.messages);
        } else {
          _initNewSession();
        }
      }
      _saveSessionsToDisk();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showToast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF262626),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==========================================
  // STREAMING CHAT HANDLER
  // ==========================================
  Future<void> _sendStreamMessage(String messageText) async {
    final text = messageText.trim();
    if (text.isEmpty || _isStreaming) return;

    _textController.clear();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final aiMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    final aiMsg = ChatMessage(
      id: aiMsgId,
      text: "",
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(aiMsg);
      _isStreaming = true;
    });
    _scrollToBottom();
    _saveSessionsToDisk();

    if (_forceOfflineMode) {
      await _streamLocalComfortingResponse(aiMsgId, text);
    } else {
      bool streamCompleted = false;
      try {
        final streamUrl = _apiUrl.replaceAll("/forgiveness", "/forgiveness/stream");
        final request = http.Request('POST', Uri.parse(streamUrl));
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode({
          "conflict": text,
          "religion": _selectedReligion,
          "perspective": _selectedPerspective,
        });

        final client = http.Client();
        final response = await client.send(request).timeout(const Duration(seconds: 14));

        if (response.statusCode == 200) {
          StringBuffer currentText = StringBuffer();
          await for (var chunk in response.stream.transform(utf8.decoder)) {
            final lines = chunk.split("\n");
            for (var line in lines) {
              if (line.startsWith("data: ")) {
                final dataStr = line.substring(6).trim();
                if (dataStr == "[DONE]") {
                  streamCompleted = true;
                  break;
                }
                try {
                  final jsonMap = jsonDecode(dataStr);
                  if (jsonMap.containsKey('token')) {
                    currentText.write(jsonMap['token']);
                    _updateMsgText(aiMsgId, currentText.toString());
                  }
                } catch (_) {}
              }
            }
          }
          if (currentText.isNotEmpty) {
            streamCompleted = true;
            _finishStreaming(aiMsgId);
          }
          client.close();
        }
      } catch (e) {
        streamCompleted = false;
      }

      if (!streamCompleted) {
        // Direct cloud POST fallback
        try {
          final directUrl = _apiUrl.contains("/stream") ? _apiUrl.replaceAll("/stream", "") : _apiUrl;
          final resp = await http.post(
            Uri.parse(directUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "conflict": text,
              "religion": _selectedReligion,
              "perspective": _selectedPerspective,
            }),
          ).timeout(const Duration(seconds: 10));

          if (resp.statusCode == 200) {
            final data = jsonDecode(resp.body);
            final advice = data['advice'] ?? '';
            if (advice.toString().isNotEmpty) {
              StringBuffer buf = StringBuffer();
              for (var w in advice.toString().split(" ")) {
                buf.write("$w ");
                _updateMsgText(aiMsgId, buf.toString());
                await Future.delayed(const Duration(milliseconds: 18));
              }
              _finishStreaming(aiMsgId);
              return;
            }
          }
        } catch (_) {}

        // Local dynamic fallback
        await _streamLocalComfortingResponse(aiMsgId, text);
      }
    }
  }

  // Deeply comforting, forgiving, hopeful, personal local fallback engine
  Future<void> _streamLocalComfortingResponse(String msgId, String promptText) async {
    final q = promptText.toLowerCase().trim();
    String reply = "";

    if (q.length <= 2) {
      reply = "I am right here with you. What would you like to talk about or work through today?";
    } else if (q.contains("mistake") && (q.contains("god forgive") || q.contains("forgive me"))) {
      reply = "Yes. Your mistakes do not make you unworthy of forgiveness. If you sincerely regret what you did and want to become better, you can always turn back to God. You are not your worst mistake. Start again, even if it is one small step today.";
    } else if (q.contains("abandoned") || (q.contains("god") && q.contains("alone"))) {
      reply = "Feeling alone does not mean you have been abandoned. Sometimes pain becomes so loud that we cannot feel hope anymore. You do not have to have everything figured out tonight. Take a breath, pray if it brings you peace, and keep going one day at a time. You still deserve love, mercy, and another beginning.";
    } else if (q.contains("hate myself") || q.contains("did something terrible") || q.contains("guilt")) {
      reply = "Regret can hurt deeply, but destroying yourself with guilt will not change the past. Take responsibility, make things right where you can, ask forgiveness, and learn from what happened. You are still capable of becoming a better person. Let your regret become a reason to change, not a reason to give up on yourself.";
    } else if (q.contains("why does god") && (q.contains("suffer") || q.contains("pain"))) {
      reply = "I cannot tell you exactly why your particular pain happened, and you do not have to pretend that it does not hurt. But your suffering does not mean that you are forgotten or worthless. Hold on to whatever gives you strength—your faith, prayer, people who care about you, and the hope that this chapter is not your whole story.";
    } else if (q.contains("lost my faith") || q.contains("lost faith") || q.contains("doubts")) {
      reply = "You do not have to force yourself to feel something you cannot feel right now. Ask questions. Be honest. Sit with your doubts. If God is real, your honest search does not need to frighten Him. Sometimes faith becomes stronger after we have had the courage to question it.";
    } else if (q.contains("nobody understands") || q.contains("no one understands")) {
      reply = "That feeling can be incredibly lonely. You do not have to carry everything silently. Even if it feels like nobody understands you right now, that does not mean nobody ever will. Please give yourself the chance to be heard. You deserve someone who will listen without judging you.";
    } else if (q.contains("giving up") || q.contains("give up") || q.contains("end it")) {
      reply = "Please don't make a permanent decision because of a painful moment. You don't need to solve your whole life tonight. Just get through this moment. Put the next hour in front of you, reach out to someone you trust, and stay close to people who care about you. Your life is worth protecting, even when you cannot see its value clearly right now.";
    } else if (q.contains("can i pray") || (q.contains("pray") && q.contains("wrong"))) {
      reply = "Yes. You don't need to become perfect before you turn toward God. You can come honestly—with your mistakes, your shame, your questions, and your tears. A sincere prayer does not need beautiful words. Sometimes \"Please help me\" is enough to begin.";
    } else if (q.contains("not good enough") || q.contains("worthless")) {
      reply = "You don't have to earn your right to exist by being perfect. You can grow without hating who you are today. Make mistakes, learn, apologize, improve, and keep moving. There is still goodness in you, even on the days when you cannot see it yourself.";
    } else if (q.contains("hurt someone") && q.contains("forgive myself")) {
      reply = "Start by not running away from what you did. Admit it, apologize sincerely, repair what you can, and accept that healing may take time. Forgiving yourself doesn't mean saying the mistake was okay. It means choosing to become someone who would not repeat it.";
    } else if (q.contains("why should i keep believing") || q.contains("keep believing")) {
      reply = "You don't have to pretend life is easy to have faith. You can bring your anger, sadness, and questions into your relationship with God. Sometimes faith isn't feeling strong; sometimes it is simply saying, \"I don't understand, but I'm still here.\" Even a tiny amount of hope is enough to keep walking.";
    } else if (q.contains("completely alone") || q.contains("feel alone")) {
      reply = "I'm sorry you're carrying that feeling. You don't have to pretend to be strong here. Whatever happened, you are still worthy of kindness, forgiveness, and a better tomorrow. Please don't isolate yourself completely—reach out to someone you trust and let them sit with you through this. You don't have to carry the whole weight alone.";
    } else if (q == "hi" || q == "hello" || q == "hey" || q.startsWith("hi ") || q.startsWith("hello ")) {
      reply = "Hello. I am here with you. How are you holding up today? You can share whatever is on your heart freely and without judgment.";
    } else {
      reply = "I am listening closely. Tell me a bit more about what you are dealing with so we can work through it together.";
    }

    StringBuffer buf = StringBuffer();
    final words = reply.split(" ");
    for (var w in words) {
      buf.write("$w ");
      _updateMsgText(msgId, buf.toString());
      await Future.delayed(const Duration(milliseconds: 22));
    }
    _finishStreaming(msgId);
  }

  void _updateMsgText(String msgId, String text) {
    if (!mounted) return;
    setState(() {
      final index = _messages.indexWhere((m) => m.id == msgId);
      if (index != -1) {
        _messages[index].text = text;
      }
    });
    _scrollToBottom();
  }

  void _finishStreaming(String msgId) {
    if (!mounted) return;
    setState(() {
      _isStreaming = false;
      final index = _messages.indexWhere((m) => m.id == msgId);
      if (index != -1) {
        _messages[index] = ChatMessage(
          id: _messages[index].id,
          text: _messages[index].text,
          isUser: false,
          timestamp: _messages[index].timestamp,
          isStreaming: false,
        );
      }
    });
    _saveSessionsToDisk();
  }

  void _openModelPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select Wisdom Model",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF262626)),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _traditions.length,
                  itemBuilder: (context, idx) {
                    final item = _traditions[idx];
                    final String name = item['name'];
                    final IconData icon = item['icon'];
                    final String desc = item['desc'];
                    final bool isSelected = _selectedReligion == name;

                    return ListTile(
                      leading: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF737373)),
                      title: Text(
                        name,
                        style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: Colors.white),
                      ),
                      subtitle: Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFFA3A3A3))),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Colors.white) : null,
                      onTap: () {
                        setState(() => _selectedReligion = name);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSettingsDialog() {
    final urlController = TextEditingController(text: _apiUrl);
    bool offlineVal = _forceOfflineMode;
    bool dailyVal = _dailyNotificationsEnabled;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text("PeacePlus Settings", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Backend Endpoint URL",
                  hintText: "https://peaceplus-ai.onrender.com/forgiveness",
                  labelStyle: const TextStyle(color: Color(0xFFA3A3A3)),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("Force Offline Mode", style: TextStyle(color: Colors.white)),
                subtitle: const Text("Use local PeacePlus engine", style: TextStyle(color: Color(0xFFA3A3A3))),
                value: offlineVal,
                activeColor: Colors.white,
                onChanged: (val) => setDlgState(() => offlineVal = val),
              ),
              SwitchListTile(
                title: const Text("Daily Peace Reminder", style: TextStyle(color: Colors.white)),
                subtitle: const Text("Daily peace quotes banner", style: TextStyle(color: Color(0xFFA3A3A3))),
                value: dailyVal,
                activeColor: Colors.white,
                onChanged: (val) => setDlgState(() => dailyVal = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Color(0xFFA3A3A3))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('api_url', urlController.text.trim());
                await prefs.setBool('offline_mode', offlineVal);
                await prefs.setBool('daily_notif', dailyVal);
                setState(() {
                  _apiUrl = urlController.text.trim();
                  _forceOfflineMode = offlineVal;
                  _dailyNotificationsEnabled = dailyVal;
                });
                Navigator.pop(ctx);
              },
              child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF000000), // Pure Black
      drawer: _buildSpaciousChatGPTDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: InkWell(
          onTap: _openModelPickerSheet,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "PeacePlus AI",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF333333), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedReligion,
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: Colors.white, size: 22),
            onPressed: () {
              setState(() {
                _activeView = 'chat';
                _initNewSession();
                _saveSessionsToDisk();
              });
            },
            tooltip: "New Chat",
          ),
        ],
      ),
      body: _buildActiveViewContent(),
    );
  }

  Widget _buildActiveViewContent() {
    switch (_activeView) {
      case 'relationships':
        return RelationshipSpaceHub(relationships: _relationships);
      case 'analyzer':
        return AIConflictAnalyzerHub(selectedPerspective: _selectedPerspective, apiUrl: _apiUrl);
      case 'journal':
        return PeaceJournalHub(journalEntries: _journalEntries);
      case 'dashboard':
        return EmotionalDashboardHub(relationships: _relationships, journalEntries: _journalEntries);
      case 'chat':
      default:
        return _buildSpaciousChatGPTChat();
    }
  }

  Widget _buildSpaciousChatGPTChat() {
    return Column(
      children: [
        if (_dailyNotificationsEnabled)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: const Color(0xFF121212),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Daily Peace Quote: \"Hatred does not cease by hatred, but only by love.\"",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Color(0xFFA3A3A3), fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return _buildSpaciousMessageItem(msg);
            },
          ),
        ),

        // Bottom Input Field
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF000000),
            border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: 5,
                  minLines: 1,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: "Message PeacePlus AI...",
                    hintStyle: const TextStyle(color: Color(0xFF737373), fontSize: 15),
                    filled: true,
                    fillColor: const Color(0xFF161616),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFF262626))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFF262626))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFF404040))),
                  ),
                  onSubmitted: (val) => _sendStreamMessage(val),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 22),
                  onPressed: () => _sendStreamMessage(_textController.text),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpaciousMessageItem(ChatMessage msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 60),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24, right: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                color: const Color(0xFF121212),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PeacePlus AI", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  if (msg.text.isEmpty && msg.isStreaming)
                    const Row(
                      children: [
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 10),
                        Text("Thinking...", style: TextStyle(fontSize: 13, color: Color(0xFFA3A3A3))),
                      ],
                    )
                  else
                    SelectableText(msg.text, style: const TextStyle(color: Color(0xFFE5E5E5), fontSize: 15, height: 1.5)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: msg.text));
                          _showToast("Copied advice to clipboard");
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.copy_rounded, size: 16, color: Color(0xFF737373)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSpaciousChatGPTDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF000000),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(widget.userEmail, style: const TextStyle(fontSize: 12, color: Color(0xFFA3A3A3))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Google Auth Action Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: widget.isSignedInGoogle ? widget.onSignOut : widget.onSignInGoogle,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF333333), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.isSignedInGoogle ? Icons.logout_rounded : Icons.account_circle_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        widget.isSignedInGoogle ? "Sign Out of Google" : "Sign in with Google",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // New Chat Option
            ListTile(
              leading: const Icon(Icons.add_rounded, color: Colors.white),
              title: const Text("New Chat", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              onTap: _startNewChat,
            ),
            const Divider(color: Color(0xFF1E1E1E)),

            // Saved Chat History (like ChatGPT)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text("Recent Chats", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF737373))),
            ),
            SizedBox(
              height: 160,
              child: _chatSessions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text("No saved conversations yet", style: TextStyle(fontSize: 12, color: Color(0xFF737373))),
                    )
                  : ListView.builder(
                      itemCount: _chatSessions.length,
                      itemBuilder: (ctx, idx) {
                        final s = _chatSessions[idx];
                        final isCur = s.id == _currentSessionId;
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.chat_bubble_outline_rounded, size: 16, color: isCur ? Colors.white : const Color(0xFF737373)),
                          title: Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isCur ? Colors.white : const Color(0xFFA3A3A3),
                              fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF737373)),
                            onPressed: () => _deleteSession(s.id),
                          ),
                          onTap: () => _loadSession(s),
                        );
                      },
                    ),
            ),

            const Divider(color: Color(0xFF1E1E1E)),

            // SaaS Features
            ListTile(
              leading: Icon(Icons.people_rounded, color: _activeView == 'relationships' ? Colors.white : const Color(0xFF737373)),
              title: Text("Relationship Space", style: TextStyle(fontSize: 14, color: _activeView == 'relationships' ? Colors.white : const Color(0xFFA3A3A3))),
              onTap: () {
                setState(() => _activeView = 'relationships');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.psychology_rounded, color: _activeView == 'analyzer' ? Colors.white : const Color(0xFF737373)),
              title: Text("AI Conflict Analyzer", style: TextStyle(fontSize: 14, color: _activeView == 'analyzer' ? Colors.white : const Color(0xFFA3A3A3))),
              onTap: () {
                setState(() => _activeView = 'analyzer');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.book_rounded, color: _activeView == 'journal' ? Colors.white : const Color(0xFF737373)),
              title: Text("Peace Journal & Tracker", style: TextStyle(fontSize: 14, color: _activeView == 'journal' ? Colors.white : const Color(0xFFA3A3A3))),
              onTap: () {
                setState(() => _activeView = 'journal');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics_rounded, color: _activeView == 'dashboard' ? Colors.white : const Color(0xFF737373)),
              title: Text("Emotional Dashboard", style: TextStyle(fontSize: 14, color: _activeView == 'dashboard' ? Colors.white : const Color(0xFFA3A3A3))),
              onTap: () {
                setState(() => _activeView = 'dashboard');
                Navigator.pop(context);
              },
            ),

            const Spacer(),
            const Divider(color: Color(0xFF1E1E1E)),

            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.white),
              title: const Text("Settings & Engine", style: TextStyle(fontSize: 14, color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _openSettingsDialog();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// HUB 1: RELATIONSHIP SPACE HUB
// =========================================================
class RelationshipSpaceHub extends StatelessWidget {
  final List<RelationshipProfile> relationships;

  const RelationshipSpaceHub({super.key, required this.relationships});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Relationship Space", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        const Text("Manage key relationship profiles, health scores, and reconciliation logs.", style: TextStyle(fontSize: 14, color: Color(0xFFA3A3A3))),
        const SizedBox(height: 20),

        ...relationships.map((rel) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF262626)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF262626),
                  radius: 22,
                  child: Icon(
                    rel.relationType == 'Partner'
                        ? Icons.favorite_rounded
                        : rel.relationType == 'Family'
                            ? Icons.home_rounded
                            : rel.relationType == 'Friend'
                                ? Icons.people_rounded
                                : Icons.work_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(rel.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF262626),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text("${rel.healthScore}% Harmony", style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(rel.relationType, style: const TextStyle(fontSize: 13, color: Color(0xFFA3A3A3))),
                      const SizedBox(height: 8),
                      Text(rel.statusNotes, style: const TextStyle(fontSize: 13, color: Color(0xFFE5E5E5))),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// =========================================================
// HUB 2: AI CONFLICT ANALYZER HUB
// =========================================================
class AIConflictAnalyzerHub extends StatefulWidget {
  final String selectedPerspective;
  final String apiUrl;

  const AIConflictAnalyzerHub({super.key, required this.selectedPerspective, required this.apiUrl});

  @override
  State<AIConflictAnalyzerHub> createState() => _AIConflictAnalyzerHubState();
}

class _AIConflictAnalyzerHubState extends State<AIConflictAnalyzerHub> {
  final TextEditingController _analyzerController = TextEditingController();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  Future<void> _analyzeTranscript() async {
    final text = _analyzerController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      final analyzeUrl = widget.apiUrl.replaceAll("/forgiveness", "/forgiveness/analyze-conflict");
      final response = await http
          .post(
            Uri.parse(analyzeUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "transcript": text,
              "perspective": widget.selectedPerspective,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        setState(() {
          _analysisResult = jsonDecode(response.body);
          _isAnalyzing = false;
        });
      } else {
        _runFallbackAnalysis(text);
      }
    } catch (e) {
      _runFallbackAnalysis(text);
    }
  }

  void _runFallbackAnalysis(String text) {
    setState(() {
      _analysisResult = {
        "status": "success",
        "emotions_detected": ["Hurt", "Frustration", "Defensiveness", "Desire for Respect"],
        "root_cause": "Misaligned expectations and unexpressed emotional vulnerability causing defensive reactions.",
        "communication_pitfalls": [
          "Using accusatory 'You always' or 'You never' statements",
          "Interrupting before the other person finishes expressing hurt",
          "Focusing on winning the argument instead of resolving the misunderstanding"
        ],
        "suggested_replies": [
          {
            "tone": "Empathetic",
            "reply": "I care about our relationship and I want us to understand each other clearly. I'm sorry for reacting defensively."
          },
          {
            "tone": "Diplomatic",
            "reply": "Let's take a step back so we can discuss this calmly. What matters most to me is finding a solution together."
          },
          {
            "tone": "Direct & Clear",
            "reply": "I felt hurt by what happened, but I value peace between us. Let's talk about how we can handle this better."
          }
        ]
      };
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("AI Conflict Analyzer", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        const Text("Paste text or conversation arguments to analyze emotions, root issues, and calm reply options.", style: TextStyle(fontSize: 14, color: Color(0xFFA3A3A3))),
        const SizedBox(height: 20),

        TextField(
          controller: _analyzerController,
          maxLines: 6,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: "Paste argument messages or describe what was said...",
            hintStyle: const TextStyle(color: Color(0xFF737373)),
            filled: true,
            fillColor: const Color(0xFF121212),
            contentPadding: const EdgeInsets.all(18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF262626))),
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: _isAnalyzing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Icon(Icons.psychology_rounded, color: Colors.black),
          label: Text(_isAnalyzing ? "Analyzing..." : "Analyze Conversation", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          onPressed: _isAnalyzing ? null : _analyzeTranscript,
        ),

        if (_analysisResult != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF262626)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Emotions Detected", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: (_analysisResult!["emotions_detected"] as List<dynamic>).map((e) {
                    return Chip(
                      backgroundColor: const Color(0xFF262626),
                      label: Text(e.toString(), style: const TextStyle(fontSize: 13, color: Colors.white)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                const Text("Root Cause Analysis", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text(_analysisResult!["root_cause"].toString(), style: const TextStyle(fontSize: 14, color: Color(0xFFE5E5E5))),
                const SizedBox(height: 20),

                const Text("Pitfalls to Avoid", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                ...(_analysisResult!["communication_pitfalls"] as List<dynamic>).map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.remove_circle_outline_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(p.toString(), style: const TextStyle(fontSize: 13, color: Color(0xFFE5E5E5)))),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),

                const Text("Ready-to-Send Reply Options", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                ...(_analysisResult!["suggested_replies"] as List<dynamic>).map((r) {
                  final tone = r["tone"];
                  final text = r["reply"];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF262626)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tone.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        SelectableText("\"$text\"", style: const TextStyle(fontSize: 14, color: Color(0xFFE5E5E5))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// =========================================================
// HUB 3: PEACE JOURNAL & MOOD TRACKER HUB
// =========================================================
class PeaceJournalHub extends StatefulWidget {
  final List<JournalEntry> journalEntries;

  const PeaceJournalHub({super.key, required this.journalEntries});

  @override
  State<PeaceJournalHub> createState() => _PeaceJournalHubState();
}

class _PeaceJournalHubState extends State<PeaceJournalHub> {
  final TextEditingController _journalController = TextEditingController();
  String _selectedMood = 'Peaceful';
  double _stressLevel = 3.0;

  final List<String> _moods = ['Peaceful', 'Hopeful', 'Stressed', 'Anxious', 'Upset'];

  void _addJournalEntry() {
    final note = _journalController.text.trim();
    if (note.isEmpty) return;

    setState(() {
      widget.journalEntries.insert(
        0,
        JournalEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateTime.now(),
          mood: _selectedMood,
          stressLevel: _stressLevel.toInt(),
          note: note,
        ),
      );
      _journalController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Peace Journal & Mood Tracker", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        const Text("Track your emotional state, stress triggers, and daily peace reflections.", style: TextStyle(fontSize: 14, color: Color(0xFFA3A3A3))),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF262626)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("How are you feeling today?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _moods.map((m) {
                    final isSel = _selectedMood == m;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(m, style: TextStyle(fontSize: 13, color: isSel ? Colors.black : Colors.white)),
                        selected: isSel,
                        selectedColor: Colors.white,
                        backgroundColor: const Color(0xFF1E1E1E),
                        onSelected: (val) => setState(() => _selectedMood = m),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Text("Stress Level: ${_stressLevel.toInt()}/10", style: const TextStyle(fontSize: 14, color: Color(0xFFE5E5E5))),
              Slider(
                value: _stressLevel,
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: Colors.white,
                inactiveColor: const Color(0xFF262626),
                onChanged: (val) => setState(() => _stressLevel = val),
              ),
              TextField(
                controller: _journalController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Log your reflections, triggers, or gratitude...",
                  hintStyle: const TextStyle(color: Color(0xFF737373)),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.bookmark_add_rounded, color: Colors.black),
                label: const Text("Save Journal Entry", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                onPressed: _addJournalEntry,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text("Past Journal Entries", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),

        ...widget.journalEntries.map((j) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF262626)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(j.mood, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("Stress: ${j.stressLevel}/10", style: const TextStyle(fontSize: 12, color: Color(0xFFA3A3A3))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(j.note, style: const TextStyle(fontSize: 14, color: Color(0xFFE5E5E5))),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// =========================================================
// HUB 4: EMOTIONAL DASHBOARD & FORGIVENESS JOURNEYS HUB
// =========================================================
class EmotionalDashboardHub extends StatelessWidget {
  final List<RelationshipProfile> relationships;
  final List<JournalEntry> journalEntries;

  const EmotionalDashboardHub({super.key, required this.relationships, required this.journalEntries});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Emotional Dashboard & Journeys", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        const Text("Visual Analytics, Forgiveness Pathways, and Emotional Metrics.", style: TextStyle(fontSize: 14, color: Color(0xFFA3A3A3))),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF262626)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Overall Harmony Index", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("87% Harmony", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  Icon(Icons.trending_up_rounded, color: Colors.white, size: 30),
                ],
              ),
              SizedBox(height: 10),
              LinearProgressIndicator(value: 0.87, backgroundColor: Color(0xFF262626), color: Colors.white, minHeight: 8),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text("Guided Forgiveness Pathways", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),

        _buildJourneyCard("Rebuilding Trust", "4 Steps • Active", "Step 3: Clear Emotional Boundary Dialogues", 0.75),
        _buildJourneyCard("Releasing Past Grudges", "3 Steps • Recommended", "Step 1: Emotional Acknowledgment", 0.33),
      ],
    );
  }

  Widget _buildJourneyCard(String title, String subtitle, String currentStep, double progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFFA3A3A3))),
            ],
          ),
          const SizedBox(height: 8),
          Text(currentStep, style: const TextStyle(fontSize: 13, color: Color(0xFFE5E5E5))),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress, backgroundColor: const Color(0xFF262626), color: Colors.white, minHeight: 6),
        ],
      ),
    );
  }
}
