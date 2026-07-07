import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─── Configuration API ────────────────────────────────────────────────────────
// Émulateur Android → 10.0.2.2 | Appareil réel → IP locale de votre PC
const String baseUrl = 'http://10.0.2.2:5000';
// const String baseUrl = 'http://127.0.0.1:5000';

void main() {
  runApp(const SongTaabaApp());
}

class SongTaabaApp extends StatelessWidget {
  const SongTaabaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SongTaaba',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0F14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B8BEB),
          surface: Color(0xFF1A1D26),
        ),
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
    );
  }
}

// ─── Modèle Bourse ────────────────────────────────────────────────────────────

class Bourse {
  final String id;
  final String nom;
  final String organisme;
  final String pays;
  final String niveau;
  final String type;
  final String? deadline;
  final String? montant;
  bool isFavori;

  Bourse({
    required this.id,
    required this.nom,
    required this.organisme,
    required this.pays,
    required this.niveau,
    required this.type,
    this.deadline,
    this.montant,
    this.isFavori = false,
  });

  factory Bourse.fromJson(Map<String, dynamic> json) {
    return Bourse(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      organisme: json['organisme'] ?? '',
      pays: json['pays'] ?? '',
      niveau: json['niveau'] ?? '',
      type: json['type'] ?? 'bourse',
      deadline: json['deadline'],
      montant: json['montant']?.toString(),
    );
  }
}

// ─── Service API ──────────────────────────────────────────────────────────────

class ApiService {
  static String? _token;
  static String? _userId;
  static String? _userNom;
  static String? _userEmail;

  // Connexion
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _token = data['access_token'];
        _userId = data['user_id'];

        // ← Ajouter : récupérer le profil pour avoir le nom
        final profil = await http.get(
          Uri.parse('$baseUrl/api/auth/me'),
          headers: {'Authorization': 'Bearer $_token'},
        );
        if (profil.statusCode == 200) {
          final profilData = jsonDecode(profil.body);
          _userNom = '${profilData['prenom']} ${profilData['nom']}';
          _userEmail = profilData['email'];
        }

        return {'success': true};
      }
      // APRÈS
      return {'success': false, 'message': 'Identifiants incorrects.'};
    } catch (e) {
      return {'success': false, 'message': 'Impossible de joindre le serveur'};
    }
  }

  // Inscription
  static Future<Map<String, dynamic>> register(
    String nom, String prenom, String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nom': nom, 'prenom': prenom, 'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      _userNom = '${data['prenom']} ${data['nom']}';
      _userEmail = data['email'];
      return {'success': true};
    }
    return {'success': false, 'message': 'Identifiants incorrects.'};
  } catch (e) {
    return {'success': false, 'message': 'Impossible de joindre le serveur'};
  }
}

  // Liste des bourses
  static Future<List<Bourse>> getBourses({String? type, String? pays}) async {
    try {
      final params = <String, String>{};
      if (type != null && type != 'tous') params['type'] = type;
      if (pays != null) params['pays'] = pays;

      final uri = Uri.parse(
        '$baseUrl/api/bourses/',
      ).replace(queryParameters: params);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((j) => Bourse.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Marquer un intérêt
  static Future<bool> marquerInteret(String bourseId) async {
    if (_token == null || _userId == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users-bourses/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'user_id': _userId,
          'bourse_id': bourseId,
          'statut': 'interessé',
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Retirer un intérêt
  static Future<bool> retirerInteret(String bourseId) async {
    if (_token == null || _userId == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/users-bourses/$_userId/$bourseId'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Bourses favorites de l'utilisateur
  static Future<List<String>> getMesBourseIds() async {
    if (_token == null || _userId == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users-bourses/user/$_userId'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map<String>((e) => e['bourse_id'].toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static void logout() {
    _token = null;
    _userId = null;
    _userNom = null;
    _userEmail = null;
  }

  static bool get isLoggedIn => _token != null;
  static String get userName => _userNom ?? 'Utilisateur';
  static String get userEmail => _userEmail ?? '';
}

// ─── Auth Gate ────────────────────────────────────────────────────────────────

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}

// ─── Page Login ───────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _showRegister = false;

  // Champs inscription
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
    setState(() => _loading = false);
    if (result['success']) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      setState(() => _error = result['message']);
    }
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService.register(
      _nomCtrl.text.trim(),
      _prenomCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
    setState(() => _loading = false);
    if (result['success']) {
      setState(() {
        _showRegister = false;
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte créé ! Connectez-vous.'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
    } else {
      setState(() => _error = result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  // Logo / titre
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B8BEB).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF3B8BEB).withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Color(0xFF3B8BEB),
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'SongTaaba',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Cherchons ensemble',
                          style: TextStyle(
                            color: Color(0xFF6B7080),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Tabs Login / Inscription
                  Row(
                    children: [
                      _tabBtn(
                        'Connexion',
                        !_showRegister,
                        () => setState(() {
                          _showRegister = false;
                          _error = null;
                        }),
                      ),
                      const SizedBox(width: 12),
                      _tabBtn(
                        'Inscription',
                        _showRegister,
                        () => setState(() {
                          _showRegister = true;
                          _error = null;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Champs inscription uniquement
                  if (_showRegister) ...[
                    _inputField('Nom', _nomCtrl, Icons.badge_rounded),
                    const SizedBox(height: 14),
                    _inputField('Prénom', _prenomCtrl, Icons.person_rounded),
                    const SizedBox(height: 14),
                  ],

                  _inputField(
                    'Email',
                    _emailCtrl,
                    Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _inputField(
                    'Mot de passe',
                    _passCtrl,
                    Icons.lock_rounded,
                    obscure: true,
                  ),
                  const SizedBox(height: 8),

                  // Erreur
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE74C3C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE74C3C).withOpacity(0.3)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Bouton
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : (_showRegister ? _register : _login),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B8BEB),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _showRegister
                                  ? 'Créer mon compte'
                                  : 'Se connecter',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF6B7080),
              fontSize: 16,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 80,
            color: active ? const Color(0xFF3B8BEB) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _inputField(
    String hint,
    TextEditingController ctrl,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2D3A)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF6B7080)),
          prefixIcon: Icon(icon, color: const Color(0xFF6B7080), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ─── Page Accueil ─────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'tous';

  List<Bourse> _bourses = [];
  List<String> _favorisIds = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final bourses = await ApiService.getBourses();
    final favorisIds = await ApiService.getMesBourseIds();
    if (!mounted) return;
    setState(() {
      _bourses = bourses;
      _favorisIds = favorisIds;
      for (var b in _bourses) {
        b.isFavori = _favorisIds.contains(b.id);
      }
      _loading = false;
      if (bourses.isEmpty) _error = 'Aucune bourse disponible';
    });
  }

  List<Bourse> get _filteredBourses {
    return _bourses.where((b) {
      final matchSearch =
          b.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.organisme.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.pays.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchType = _filterType == 'tous' || b.type == _filterType;
      return matchSearch && matchType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_buildAccueil(), _buildFavoris(), _buildNotifications()];
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D26),
        border: Border(top: BorderSide(color: Color(0xFF2A2D3A), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF3B8BEB),
        unselectedItemColor: const Color(0xFF6B7080),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_rounded),
            label: 'Favoris',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_rounded),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }

  Widget _buildAccueil() {
    return Column(
      children: [
        _buildTopBar(),
        _buildFilterChips(),
        Expanded(child: _buildListeOuEtat()),
      ],
    );
  }

  Widget _buildListeOuEtat() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B8BEB)),
      );
    }
    if (_error != null && _bourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _chargerDonnees,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B8BEB),
              ),
            ),
          ],
        ),
      );
    }
    if (_filteredBourses.isEmpty) return _buildEmptyState();
    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      color: const Color(0xFF3B8BEB),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredBourses.length,
        itemBuilder: (context, i) => _buildBourseCard(_filteredBourses[i]),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D26),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2D3A), width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showProfil(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF3B8BEB).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF3B8BEB).withOpacity(0.4),
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF3B8BEB),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0F14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2D3A)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Chercher une bourse...',
                  hintStyle: TextStyle(color: Color(0xFF6B7080), fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Color(0xFF6B7080),
                    size: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0F14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2D3A)),
            ),
            child: const Icon(
              Icons.mail_rounded,
              color: Color(0xFF6B7080),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('tous', 'Toutes'),
      ('bourse', 'Bourses'),
      ('stage', 'Stages'),
    ];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((f) {
          final selected = _filterType == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8, top: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filterType = f.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF3B8BEB)
                      : const Color(0xFF1A1D26),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF3B8BEB)
                        : const Color(0xFF2A2D3A),
                  ),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF6B7080),
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBourseCard(Bourse bourse) {
    final isBourse = bourse.type == 'bourse';
    final accentColor = isBourse
        ? const Color(0xFF3B8BEB)
        : const Color(0xFF2ECC71);

    return GestureDetector(
      onTap: () => _showDetail(context, bourse),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2D3A)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 80,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isBourse ? 'Bourse' : 'Stage',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '🌍 ${bourse.pays}',
                          style: const TextStyle(
                            color: Color(0xFF6B7080),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bourse.nom,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bourse.organisme,
                      style: const TextStyle(
                        color: Color(0xFF6B7080),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ok = await ApiService.marquerInteret(bourse.id);
                      if (ok) setState(() => bourse.isFavori = true);
                    },
                    child: Icon(
                      bourse.isFavori
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: bourse.isFavori
                          ? const Color(0xFF3B8BEB)
                          : const Color(0xFF6B7080),
                      size: 20,
                    ),
                  ),
                  if (bourse.deadline != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE74C3C).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bourse.deadline!,
                        style: const TextStyle(
                          color: Color(0xFFE74C3C),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune opportunité trouvée',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoris() {
    final favoris = _bourses.where((b) => b.isFavori).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader('Mes favoris', Icons.bookmark_rounded),
        Expanded(
          child: favoris.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 64,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun favori enregistré',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: favoris.length,
                  itemBuilder: (context, i) => _buildBourseCard(favoris[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildNotifications() {
    final notifications = [
      (
        'Nouvelle bourse disponible',
        'Consultez les dernières opportunités',
        '10:30',
      ),
      ('Rappel deadline', 'Vérifiez vos bourses en cours', 'Hier'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader('Notifications', Icons.notifications_rounded),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, i) {
              final n = notifications[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2D3A)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B8BEB).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_rounded,
                        color: Color(0xFF3B8BEB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.$1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            n.$2,
                            style: const TextStyle(
                              color: Color(0xFF6B7080),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      n.$3,
                      style: const TextStyle(
                        color: Color(0xFF6B7080),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D26),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2D3A), width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3B8BEB), size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, Bourse bourse) {
    final isBourse = bourse.type == 'bourse';
    final accentColor = isBourse
        ? const Color(0xFF3B8BEB)
        : const Color(0xFF2ECC71);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1D26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2D3A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isBourse ? 'Bourse' : 'Stage',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              bourse.nom,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              bourse.organisme,
              style: const TextStyle(color: Color(0xFF6B7080), fontSize: 14),
            ),
            const SizedBox(height: 20),
            _infoRow(Icons.public_rounded, 'Pays', bourse.pays),
            _infoRow(Icons.school_rounded, 'Niveau', bourse.niveau),
            if (bourse.deadline != null)
              _infoRow(
                Icons.calendar_today_rounded,
                'Deadline',
                bourse.deadline!,
              ),
            if (bourse.montant != null)
              _infoRow(Icons.attach_money_rounded, 'Montant', bourse.montant!),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  bool ok;
                  String message;
                  if (bourse.isFavori) {
                    ok = await ApiService.retirerInteret(bourse.id);
                    message = ok ? 'Intérêt retiré' : 'Erreur lors du retrait';
                    if (ok) setState(() => bourse.isFavori = false);
                  } else {
                    ok = await ApiService.marquerInteret(bourse.id);
                    message = ok ? 'Intérêt enregistré !' : 'Déjà enregistré ou erreur';
                    if (ok) setState(() => bourse.isFavori = true);
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(message),
                    backgroundColor: ok ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: bourse.isFavori
                      ? const Color(0xFFE74C3C)
                      : const Color(0xFF3B8BEB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  bourse.isFavori ? 'Retirer mon intérêt' : 'Marquer mon intérêt',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3B8BEB), size: 18),
          const SizedBox(width: 10),
          Text(
            '$label : ',
            style: const TextStyle(color: Color(0xFF6B7080), fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfil(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1D26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2D3A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 36,
              backgroundColor: Color(0xFF3B8BEB),
              child: Icon(Icons.person_rounded, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              ApiService.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ApiService.userEmail,
              style: const TextStyle(color: Color(0xFF6B7080), fontSize: 13),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFE74C3C),
              ),
              title: const Text(
                'Se déconnecter',
                style: TextStyle(color: Color(0xFFE74C3C)),
              ),
              onTap: () {
                ApiService.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
