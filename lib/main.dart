import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const JamListApp());
}

const Color accent = Color(0xFFB7F34A);
const Color pageColor = Color(0xFF101114);
const Color panelColor = Color(0xFF1B1D22);

class JamListApp extends StatelessWidget {
  const JamListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JamList',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: pageColor,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accent,
          surface: panelColor,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panelColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: accent),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: pageColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

String passwordHash(String password) =>
    sha256.convert(utf8.encode(password)).toString();

class LocalAuth {
  static const _usersKey = 'jamlist_users';

  static Future<Map<String, dynamic>> _readUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<String?> register(String username, String password) async {
    final users = await _readUsers();
    final key = username.trim().toLowerCase();
    if (key.isEmpty || password.isEmpty) return 'Fill in all fields.';
    if (users.containsKey(key)) return 'That username already exists.';
    users[key] = {
      'username': username.trim(),
      'passwordHash': passwordHash(password),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
    return null;
  }

  static Future<String?> login(String username, String password) async {
    final users = await _readUsers();
    final key = username.trim().toLowerCase();
    final user = users[key];
    if (user == null || user['passwordHash'] != passwordHash(password)) {
      return null;
    }
    return user['username'] as String? ?? username.trim();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool hidePassword = true;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    setState(() => busy = true);
    final result = await LocalAuth.login(username.text, password.text);
    if (!mounted) return;
    setState(() => busy = false);
    if (result == null) {
      showMessage('Incorrect username or password.');
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(username: result)),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Your music,\nyour way.',
      subtitle: 'Sign in and get back to your favorite sounds.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: username,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: password,
            obscureText: hidePassword,
            onSubmitted: (_) => signIn(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => hidePassword = !hidePassword),
                icon: Icon(
                    hidePassword ? Icons.visibility : Icons.visibility_off),
              ),
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: busy ? null : signIn,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(busy ? 'PLEASE WAIT...' : 'SIGN IN'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            ),
            child: const Text("New to JamList? Create an account"),
          ),
        ],
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> createAccount() async {
    if (username.text.trim().isEmpty ||
        password.text.isEmpty ||
        confirm.text.isEmpty) {
      message('Please complete every field.');
      return;
    }
    if (password.text.length < 6) {
      message('Password must be at least 6 characters.');
      return;
    }
    if (password.text != confirm.text) {
      message('Passwords do not match.');
      return;
    }
    setState(() => busy = true);
    final error = await LocalAuth.register(username.text, password.text);
    if (!mounted) return;
    setState(() => busy = false);
    if (error != null) {
      message(error);
      return;
    }
    message('Account created! You can now sign in.');
    Navigator.pop(context);
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Join the\nplaylist.',
      subtitle: 'Create your account to start organizing your music.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: username,
            decoration: const InputDecoration(
              labelText: 'Choose a username',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password (at least 6 characters)',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: confirm,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm password',
              prefixIcon: Icon(Icons.lock_reset),
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: busy ? null : createAccount,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(busy ? 'CREATING...' : 'CREATE ACCOUNT'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Already have an account? Sign in'),
          ),
        ],
      ),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 62,
                    width: 62,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.graphic_eq,
                        color: Colors.black, size: 36),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'JAMLIST',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white60, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Song {
  String title;
  String artist;
  bool favorite;

  Song({required this.title, required this.artist, this.favorite = false});

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'favorite': favorite,
      };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        title: json['title'] as String? ?? '',
        artist: json['artist'] as String? ?? '',
        favorite: json['favorite'] as bool? ?? false,
      );
}

class HomePage extends StatefulWidget {
  final String username;

  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Song> songs = [];
  List<String> playlists = ['My Favorites'];
  String selectedPlaylist = 'All Songs';
  bool loading = true;

  String get storageKey => 'jamlist_data_${widget.username.toLowerCase()}';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        songs = (data['songs'] as List? ?? [])
            .map((e) => Song.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        playlists = (data['playlists'] as List? ?? ['My Favorites'])
            .map((e) => e.toString())
            .toList();
      } catch (_) {
        songs = [];
        playlists = ['My Favorites'];
      }
    }
    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode({
        'songs': songs.map((song) => song.toJson()).toList(),
        'playlists': playlists,
      }),
    );
  }

  List<Song> get visibleSongs {
    if (selectedPlaylist == 'Favorites') {
      return songs.where((song) => song.favorite).toList();
    }
    return songs;
  }

  Future<void> addSong() async {
    final title = TextEditingController();
    final artist = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: panelColor,
        title: const Text('Add a song'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Song title')),
            const SizedBox(height: 12),
            TextField(
                controller: artist,
                decoration: const InputDecoration(labelText: 'Artist')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (result == true &&
        title.text.trim().isNotEmpty &&
        artist.text.trim().isNotEmpty) {
      setState(() {
        songs.insert(
            0, Song(title: title.text.trim(), artist: artist.text.trim()));
        selectedPlaylist = 'All Songs';
      });
      await saveData();
    }
    title.dispose();
    artist.dispose();
  }

  Future<void> addPlaylist() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: panelColor,
        title: const Text('New playlist'),
        content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Playlist name')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Create')),
        ],
      ),
    );
    final name = controller.text.trim();
    if (result == true &&
        name.isNotEmpty &&
        !playlists.any((p) => p.toLowerCase() == name.toLowerCase())) {
      setState(() {
        playlists.add(name);
        selectedPlaylist = name;
      });
      await saveData();
    }
    controller.dispose();
  }

  Future<void> toggleFavorite(Song song) async {
    setState(() => song.favorite = !song.favorite);
    await saveData();
  }

  Future<void> deleteSong(Song song) async {
    setState(() => songs.remove(song));
    await saveData();
  }

  @override
  Widget build(BuildContext context) {
    final currentSongs = visibleSongs;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.graphic_eq, color: accent, size: 28),
            SizedBox(width: 10),
            Text('JamList', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            ),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addSong,
        backgroundColor: accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add song'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                Text('HEY, ${widget.username.toUpperCase()}',
                    style: const TextStyle(
                        color: accent,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Your sound. Your collection.',
                    style:
                        TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF303C21), Color(0xFF1B1D22)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('YOUR MUSIC LIBRARY',
                                style: TextStyle(
                                    color: accent,
                                    fontSize: 11,
                                    letterSpacing: 1.5)),
                            SizedBox(height: 8),
                            Text('Keep every\ntrack in tune.',
                                style: TextStyle(
                                    fontSize: 23, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Icon(Icons.album, color: accent, size: 68),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const Text('YOUR COLLECTION',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 1.4)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    collectionChip('All Songs', Icons.library_music),
                    collectionChip('Favorites', Icons.favorite),
                    ...playlists
                        .map((name) => collectionChip(name, Icons.queue_music)),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: const Text('New playlist'),
                      onPressed: addPlaylist,
                      backgroundColor: panelColor,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedPlaylist == 'All Songs'
                            ? 'All songs'
                            : selectedPlaylist,
                        style: const TextStyle(
                            fontSize: 21, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text('${currentSongs.length} tracks',
                        style: const TextStyle(color: Colors.white54)),
                  ],
                ),
                const SizedBox(height: 10),
                if (currentSongs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: BorderRadius.circular(18)),
                    child: const Column(
                      children: [
                        Icon(Icons.music_note, size: 38, color: Colors.white38),
                        SizedBox(height: 10),
                        Text('Nothing playing here yet',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text('Add songs to start building your collection.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  )
                else
                  ...currentSongs.map((song) => Container(
                        margin: const EdgeInsets.only(bottom: 9),
                        decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          leading: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFF303C21),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(Icons.music_note, color: accent),
                          ),
                          title: Text(song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(song.artist,
                              style: const TextStyle(color: Colors.white54)),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'favorite') toggleFavorite(song);
                              if (value == 'delete') deleteSong(song);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'favorite',
                                child: Text(song.favorite
                                    ? 'Remove favorite'
                                    : 'Mark as favorite'),
                              ),
                              const PopupMenuItem(
                                  value: 'delete', child: Text('Delete song')),
                            ],
                            icon: Icon(
                                song.favorite
                                    ? Icons.favorite
                                    : Icons.more_vert,
                                color: song.favorite ? accent : Colors.white70),
                          ),
                        ),
                      )),
              ],
            ),
    );
  }

  Widget collectionChip(String label, IconData icon) {
    final active = selectedPlaylist == label;
    return ChoiceChip(
      selected: active,
      onSelected: (_) => setState(() => selectedPlaylist = label),
      avatar: Icon(icon, size: 17, color: active ? Colors.black : accent),
      label: Text(label),
      selectedColor: accent,
      backgroundColor: panelColor,
      labelStyle: TextStyle(color: active ? Colors.black : Colors.white),
      side: BorderSide.none,
    );
  }
}
