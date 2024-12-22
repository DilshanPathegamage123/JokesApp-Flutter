import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'joke_service.dart';

void main() {
  runApp(MyJokesApp());
}

class MyJokesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jokes App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: JokeListPage(),
    );
  }
}

class JokeListPage extends StatefulWidget {
  const JokeListPage({Key? key}) : super(key: key);

  @override
  State<JokeListPage> createState() => _JokeListPageState();
}

class _JokeListPageState extends State<JokeListPage> {
  final JokeService _jokeService = JokeService();
  List<Map<String, dynamic>> _jokes = [];
  List<Map<String, dynamic>> _filteredJokes = [];
  Set<Map<String, dynamic>> _favoriteJokes = {};
  int _currentIndex = 0;
  bool _isLoading = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCachedJokes();
    _loadFavoriteJokes();
  }

  Future<void> _loadCachedJokes() async {
    final cachedJokes = await _jokeService.loadCachedJokes();
    if (cachedJokes.isNotEmpty) {
      setState(() {
        _jokes = cachedJokes.cast<Map<String, dynamic>>();
        _filteredJokes = _jokes;
        _currentIndex = 0;
      });
    }
  }

  Future<void> _loadFavoriteJokes() async {
    final favoriteJokes = await _jokeService.loadFavoriteJokes();
    setState(() {
      _favoriteJokes = favoriteJokes;
    });
  }

  Future<void> _fetchJokes() async {
    setState(() => _isLoading = true);
    try {
      _jokes = (await _jokeService.fetchJokes()).cast<Map<String, dynamic>>();
      _filteredJokes = _jokes;
      _currentIndex = 0;
    } catch (e) {
      print('Error fetching jokes: $e');
      if (_jokes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to fetch jokes and no cached jokes available!"),
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  void _toggleFavorite(Map<String, dynamic> joke) async {
    setState(() {
      if (_favoriteJokes.any((favJoke) => favJoke['id'] == joke['id'])) {
        _favoriteJokes.removeWhere((favJoke) => favJoke['id'] == joke['id']);
      } else {
        _favoriteJokes.add(joke);
      }
    });
    await _jokeService.cacheFavoriteJokes(_favoriteJokes);
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Share Jokes on whatsapp as a message
  Future<void> _shareOnWhatsApp(String jokeText) async {
    final url = 'https://wa.me/?text=${Uri.encodeComponent(jokeText)}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jokes App'),
        backgroundColor: Colors.lightGreen,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green,
              Colors.white,
            ],
          ),
        ),
        child: _selectedIndex == 0 ? _buildJokesTab() : _buildFavoritesTab(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
        selectedItemColor: Colors.green,
      ),
    );
  }

  // Home tab
  Widget _buildJokesTab() {
    return Column(
      children: [
        const Text(
          'Welcome to the Joker!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Click the button to get random jokes!',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _fetchJokes,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black45,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 12,
            ),
          ),
          child: _isLoading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Text(
            'Get Jokes',
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchJokes,
            child: _filteredJokes.isEmpty
                ? const Center(
              child: Text(
                'No jokes received yet.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black45,
                ),
              ),
            )
                : ListView.builder(
              itemCount: _filteredJokes.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final joke = _filteredJokes[index];
                final isFavorite = _favoriteJokes.any((favJoke) => favJoke['id'] == joke['id']);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black54,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      joke['type'] == 'single'
                          ? joke['joke']
                          : '${joke['setup']}\n\n${joke['delivery']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _toggleFavorite(joke),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            final jokeText = joke['type'] == 'single'
                                ? joke['joke']
                                : '${joke['setup']}\n\n${joke['delivery']}';
                            _shareOnWhatsApp(jokeText);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // favourites tab
  Widget _buildFavoritesTab() {
    return _favoriteJokes.isEmpty
        ? const Center(
      child: Text(
        'No favorite jokes yet.',
        style: TextStyle(
          fontSize: 16,
          color: Colors.black45,
        ),
      ),
    )
        : ListView.builder(
      itemCount: _favoriteJokes.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final joke = _favoriteJokes.toList()[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          shadowColor: Colors.black54,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(
              joke['type'] == 'single'
                  ? joke['joke']
                  : '${joke['setup']}\n\n${joke['delivery']}',
              style: const TextStyle(fontSize: 16),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () => _toggleFavorite(joke),
            ),
          ),
        );
      },
    );
  }
}
