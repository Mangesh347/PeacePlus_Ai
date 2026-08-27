import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF06B6D4), // Cyan 500
          secondary: Color(0xFF14B8A6), // Teal 500
          surface: Color(0xFF1E293B),
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// GLASSMORPHIC UTILITY CONTAINER
// ==========================================
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? borderColor;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 15,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 1. SPLASH SCREEN
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Celestial Aurora Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF090D16),
                    Color(0xFF0F172A),
                    Color(0xFF132A3E),
                    Color(0xFF0F2B2B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GlassCard(
                    blur: 25,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 36,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFF10B981)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF06B6D4).withOpacity(0.4),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.spa_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "PeacePlus AI",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Compassionate conflict resolution, spiritual wisdom, and personalized peace guidance.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06B6D4),
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor:
                                  const Color(0xFF06B6D4).withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(),
                                ),
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Begin Journey",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. HOME SCREEN & INPUT FORM
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _conflictController = TextEditingController();
  String _selectedReligion = 'General';
  String _selectedPerspective = 'Aggrieved';
  bool _isLoading = false;
  String _apiUrl = "http://10.0.2.2:8000/forgiveness";
  bool _forceOfflineMode = false;

  final List<Map<String, dynamic>> _traditions = [
    {'name': 'General', 'icon': Icons.public_rounded},
    {'name': 'Christianity', 'icon': Icons.church_rounded},
    {'name': 'Islam', 'icon': Icons.mosque_rounded},
    {'name': 'Hinduism', 'icon': Icons.self_improvement_rounded},
    {'name': 'Buddhism', 'icon': Icons.spa_rounded},
    {'name': 'Judaism', 'icon': Icons.synagogue_rounded},
    {'name': 'Secular', 'icon': Icons.auto_awesome_rounded},
  ];

  final List<String> _perspectives = ['Aggrieved', 'Offender', 'Mediator'];

  final List<String> _presetConflicts = [
    "A close friend broke my trust by sharing a secret.",
    "I had a heated argument with a family member over finances.",
    "A coworker took credit for my project presentation.",
    "I reacted harshly to a loved one and want to make amends.",
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiUrl = prefs.getString('api_url') ?? "http://10.0.2.2:8000/forgiveness";
      _forceOfflineMode = prefs.getBool('offline_mode') ?? false;
    });
  }

  Future<void> _saveSettings(String url, bool offline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_url', url);
    await prefs.setBool('offline_mode', offline);
    setState(() {
      _apiUrl = url;
      _forceOfflineMode = offline;
    });
  }

  void _openSettingsDialog() {
    final urlController = TextEditingController(text: _apiUrl);
    bool offlineVal = _forceOfflineMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.settings_rounded, color: Color(0xFF06B6D4)),
              SizedBox(width: 10),
              Text("PeacePlus AI Settings"),
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
                  hintText: "http://10.0.2.2:8000/forgiveness or Render URL",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("Force Offline AI Mode"),
                subtitle: const Text("Use built-in PeacePlus AI engine"),
                value: offlineVal,
                activeColor: const Color(0xFF06B6D4),
                onChanged: (val) {
                  setDlgState(() => offlineVal = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
              ),
              onPressed: () {
                _saveSettings(urlController.text.trim(), offlineVal);
                Navigator.pop(ctx);
              },
              child: const Text("Save Settings"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAdvice() async {
    final conflictText = _conflictController.text.trim();
    if (conflictText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text("Please describe your conflict situation first."),
            ],
          ),
          backgroundColor: const Color(0xFF334155),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> resultData;

    if (_forceOfflineMode) {
      await Future.delayed(const Duration(milliseconds: 900));
      resultData = _generateOfflineAdvice(
        conflictText,
        _selectedReligion,
        _selectedPerspective,
      );
    } else {
      try {
        final response = await http
            .post(
              Uri.parse(_apiUrl),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "conflict": conflictText,
                "religion": _selectedReligion,
                "perspective": _selectedPerspective,
              }),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          resultData = jsonDecode(response.body);
        } else {
          resultData = _generateOfflineAdvice(
            conflictText,
            _selectedReligion,
            _selectedPerspective,
          );
        }
      } catch (e) {
        // Fallback gracefully on network timeout or unreachable server
        resultData = _generateOfflineAdvice(
          conflictText,
          _selectedReligion,
          _selectedPerspective,
        );
      }
    }

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdviceResultScreen(data: resultData),
        ),
      );
    }
  }

  Map<String, dynamic> _generateOfflineAdvice(
    String conflict,
    String religion,
    String perspective,
  ) {
    final scripturesMap = {
      'Christianity': "Ephesians 4:32 – Be kind and compassionate to one another, forgiving each other, just as in Christ God forgiven you.",
      'Islam': "Surah Ash-Shura 42:40 – The reward of an evil deed is its equivalent, but whoever pardons and makes reconciliation will find their reward with Allah.",
      'Hinduism': "Mahabharata 5.33.48 – Forgiveness is the strength of the virtuous; forgiveness is sacrifice; forgiveness is peace of mind.",
      'Buddhism': "Dhammapada 1.5 – Hatred does not cease by hatred, but only by love; this is the eternal rule.",
      'Judaism': "Proverbs 19:11 – A person's wisdom yields patience; it is to one's glory to overlook an offense.",
      'Secular': "Marcus Aurelius – The best revenge is to be unlike him who performed the injury.",
      'General': "Patience and open conversation build bridges over deep misunderstandings.",
    };

    String reflectionText = "";
    List<String> actions = [];
    String apology = "";

    if (perspective == 'Offender') {
      reflectionText =
          "Recognize the impact of your actions regarding '$conflict'. True healing begins with genuine accountability and empathy for the hurt experienced by the other party.";
      actions = [
        "Acknowledge your exact mistake clearly without defensive rationalizations.",
        "Express sincere remorse directly and ask how you can repair the trust.",
        "Give them time and space to process their emotions at their own pace.",
      ];
      apology =
          "I am truly sorry for my role in $conflict. I value our relationship deeply and want to take full responsibility. Please let me know how we can move forward.";
    } else if (perspective == 'Mediator') {
      reflectionText =
          "As a neutral mediator for '$conflict', your primary goal is creating a psychologically safe space for open dialog, validation, and emotional resolution.";
      actions = [
        "Establish ground rules for respectful, non-accusatory communication.",
        "Help both parties identify their core emotional needs behind the conflict.",
        "Focus on shared long-term goals and mutual respect.",
      ];
      apology =
          "Let's focus on mutual understanding regarding $conflict. Both perspectives are important, and reaching a peaceful resolution is our shared goal.";
    } else {
      reflectionText =
          "Dealing with '$conflict' can bring up deep feelings of pain. Forgiveness is not about minimizing what happened, but freeing yourself from carrying ongoing anger.";
      actions = [
        "Acknowledge your valid hurt without letting bitterness control your future.",
        "Set clear, respectful personal boundaries to safeguard your well-being.",
        "Focus on releasing resentment to regain your personal peace of mind.",
      ];
      apology =
          "I felt deeply hurt regarding $conflict, but I value our connection and peace. When you are ready, I am open to discussing this constructively.";
    }

    return {
      "status": "success",
      "conflict": conflict,
      "religion": religion,
      "perspective": perspective,
      "reflection": reflectionText,
      "action_steps": actions,
      "scripture": scripturesMap[religion] ?? scripturesMap['General']!,
      "apology_draft": apology,
      "source": "OfflineEngine",
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2541), Color(0xFF0F172A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.spa_rounded, color: Color(0xFF06B6D4), size: 30),
                          SizedBox(width: 10),
                          Text(
                            "PeacePlus AI",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _openSettingsDialog,
                        icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                        tooltip: "Settings",
                      ),
                    ],
                  ),
                ),

                // Main Form Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: [
                      // Section Header
                      const Text(
                        "Describe Conflict & Choose Tradition",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Conflict Input Card
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.edit_note_rounded, color: Color(0xFF06B6D4)),
                                SizedBox(width: 8),
                                Text(
                                  "What situation occurred?",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _conflictController,
                              maxLines: 4,
                              maxLength: 300,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              decoration: InputDecoration(
                                hintText:
                                    "Describe the misunderstanding, hurt, or conflict in a few sentences...",
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Quick Templates:",
                              style: TextStyle(fontSize: 12, color: Colors.white60),
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _presetConflicts.map((preset) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ActionChip(
                                      backgroundColor: Colors.white.withOpacity(0.08),
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.15),
                                      ),
                                      label: Text(
                                        preset.length > 25
                                            ? "${preset.substring(0, 25)}..."
                                            : preset,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF38BDF8),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _conflictController.text = preset;
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Perspective Selector
                      const Text(
                        "Your Perspective",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _perspectives.map((p) {
                          final isSelected = _selectedPerspective == p;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                onTap: () => setState(() => _selectedPerspective = p),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF06B6D4).withOpacity(0.25)
                                        : Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF06B6D4)
                                          : Colors.white.withOpacity(0.1),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        p == 'Aggrieved'
                                            ? Icons.favorite_border_rounded
                                            : p == 'Offender'
                                                ? Icons.handshake_rounded
                                                : Icons.balance_rounded,
                                        color: isSelected
                                            ? const Color(0xFF38BDF8)
                                            : Colors.white60,
                                        size: 20,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        p,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Religion / Philosophical Framework Filter
                      const Text(
                        "Wisdom & Spiritual Framework",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _traditions.map((item) {
                          final String name = item['name'];
                          final IconData icon = item['icon'];
                          final isSelected = _selectedReligion == name;

                          return FilterChip(
                            selected: isSelected,
                            avatar: Icon(
                              icon,
                              size: 18,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF06B6D4),
                            ),
                            label: Text(name),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            selectedColor: const Color(0xFF06B6D4),
                            backgroundColor: Colors.white.withOpacity(0.07),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF06B6D4)
                                  : Colors.white.withOpacity(0.12),
                            ),
                            onSelected: (val) {
                              setState(() => _selectedReligion = name);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // Submit Button
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4),
                            shadowColor: const Color(0xFF06B6D4).withOpacity(0.4),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isLoading ? null : _fetchAdvice,
                          child: _isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Generating Peace Guidance...",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome_rounded, size: 22),
                                    SizedBox(width: 10),
                                    Text(
                                      "Get PeacePlus AI Guidance",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. RESULT & ADVICE DISPLAY SCREEN
// ==========================================
class AdviceResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const AdviceResultScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String conflict = data['conflict'] ?? "Conflict Situation";
    final String reflection = data['reflection'] ?? "Take time to reflect.";
    final List<dynamic> rawSteps = data['action_steps'] ?? [];
    final List<String> actionSteps = rawSteps.map((e) => e.toString()).toList();
    final String scripture = data['scripture'] ?? "Peace begins with a clear heart.";
    final String apologyDraft = data['apology_draft'] ?? "";

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF132A3E), Color(0xFF090D16)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "PeacePlus Plan",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Chip(
                        backgroundColor: const Color(0xFF06B6D4).withOpacity(0.2),
                        side: const BorderSide(color: Color(0xFF06B6D4)),
                        label: Text(
                          data['religion'] ?? "General",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Deck
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: [
                      // Situation Highlight Banner
                      GlassCard(
                        backgroundColor: Colors.white.withOpacity(0.05),
                        child: Row(
                          children: [
                            const Icon(Icons.psychology_rounded,
                                color: Color(0xFF38BDF8), size: 30),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Analyzed Situation",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    conflict,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card 1: AI Compassionate Reflection
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.favorite_rounded, color: Color(0xFFF43F5E)),
                                SizedBox(width: 10),
                                Text(
                                  "Compassionate Insight",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              reflection,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card 2: Actionable Reconciliation Steps
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.checklist_rtl_rounded,
                                    color: Color(0xFF10B981)),
                                SizedBox(width: 10),
                                Text(
                                  "Actionable Reconciliation Steps",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ...actionSteps.asMap().entries.map((entry) {
                              final idx = entry.key + 1;
                              final step = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        "$idx",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF34D399),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        step,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.4,
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card 3: Sacred & Philosophical Wisdom
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.auto_stories_rounded,
                                    color: Color(0xFFF59E0B)),
                                SizedBox(width: 10),
                                Text(
                                  "Wisdom & Scripture",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                scripture,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                  color: Color(0xFFFDE68A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card 4: Generated Apology / Message Draft
                      if (apologyDraft.isNotEmpty)
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.mark_chat_read_rounded,
                                          color: Color(0xFF38BDF8)),
                                      SizedBox(width: 10),
                                      Text(
                                        "Suggested Message Draft",
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded,
                                        color: Color(0xFF38BDF8), size: 20),
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: apologyDraft));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.check_circle_rounded,
                                                  color: Colors.greenAccent),
                                              SizedBox(width: 8),
                                              Text("Message copied to clipboard!"),
                                            ],
                                          ),
                                          backgroundColor: const Color(0xFF1E293B),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(14),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "\"$apologyDraft\"",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
