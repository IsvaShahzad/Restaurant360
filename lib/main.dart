import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:panorama_viewer/panorama_viewer.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RestaurantSearchScreen(),
  ));
}

class RestaurantSearchScreen extends StatefulWidget {
  const RestaurantSearchScreen({Key? key}) : super(key: key);

  @override
  State<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends State<RestaurantSearchScreen> {
  bool _isLoading = false;
  List<dynamic> _restaurants = [];

  /// Fetch city/area suggestions using Nominatim API
  Future<List<Map<String, dynamic>>> _fetchSuggestions(String query) async {
    if (query.isEmpty) return [];

    final url =
        "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5";

    debugPrint("🌍 Fetching city suggestions: $url");

    final response = await http.get(Uri.parse(url), headers: {
      "User-Agent": "RestaurantFinderFlutterApp/1.0 (contact: your@email.com)"
    });

    debugPrint("📡 City suggestions status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      debugPrint("❌ Failed to fetch city suggestions");
      return [];
    }
  }

  /// Fetch restaurants near given coordinates using Overpass API
  Future<void> _fetchRestaurants(String lat, String lon) async {
    try {
      setState(() {
        _isLoading = true;
        _restaurants = [];
      });

      debugPrint("🍽 Fetching restaurants near: lat=$lat, lon=$lon");

      final query = """
[out:json];
node["amenity"="restaurant"](around:5000,$lat,$lon);
out;
""";

      final response = await http.post(
        Uri.parse("https://overpass-api.de/api/interpreter"),
        body: query,
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "User-Agent": "RestaurantFinderFlutterApp/1.0",
        },
      );

      debugPrint("📡 Restaurant fetch status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _restaurants = data["elements"];
          _isLoading = false;
        });

        debugPrint("✅ Found ${_restaurants.length} restaurants");
      } else {
        throw Exception("Failed to fetch restaurants");
      }
    } catch (e) {
      debugPrint("❌ Error fetching restaurants: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Fetch restaurant image from Unsplash
  Future<String?> _fetchRestaurantImage(String name, String city) async {
    const clientId = "zi4Ab-SGUqYz0jo82AnERuTiZM-JTSD03HMWR9oBT8I"; // 🔑 Replace with your key
    final query = "$name $city restaurant panorama";

    final url =
        "https://api.unsplash.com/search/photos?query=$query&orientation=landscape&client_id=$clientId&per_page=1";

    debugPrint("📸 Fetching Unsplash image for: $query");

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["results"].isNotEmpty) {
        final img = data["results"][0]["urls"]["regular"];
        debugPrint("✅ Got image: $img");
        return img;
      } else {
        debugPrint("⚠️ No Unsplash image found");
        return null;
      }
    } else {
      debugPrint("❌ Unsplash API failed: ${response.statusCode}");
      return null;
    }
  }

  /// Show full screen image with 360° button
  void _showFullScreenImage(String name, String city) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
      const Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
    );

    final imageUrl = await _fetchRestaurantImage(name, city);
    Navigator.pop(context); // close loading indicator

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImagePage(
          imageUrl: imageUrl,
          restaurantName: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 6,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TypeAheadField<Map<String, dynamic>>(
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    prefixIcon:
                    const Icon(Icons.search, color: Colors.deepPurple),
                    hintText: 'Search city or area',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                );
              },
              suggestionsCallback: (pattern) async {
                return await _fetchSuggestions(pattern);
              },
              itemBuilder: (context, suggestion) {
                final displayName = suggestion["display_name"] ?? "Unknown";
                return ListTile(
                  leading: const Icon(Icons.location_on,
                      color: Colors.deepPurple),
                  title: Text(displayName, style: const TextStyle(fontSize: 14)),
                );
              },
              onSelected: (suggestion) {
                final lat = suggestion["lat"];
                final lon = suggestion["lon"];
                _fetchRestaurants(lat, lon);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                  child:
                  CircularProgressIndicator(color: Colors.deepPurple))
                  : _restaurants.isEmpty
                  ? const Center(
                child: Text(
                  "No restaurants found.",
                  style: TextStyle(
                      fontSize: 16, color: Colors.black54),
                ),
              )
                  : ListView.builder(
                itemCount: _restaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = _restaurants[index];
                  final name = restaurant["tags"]?["name"] ??
                      "Unnamed Restaurant";
                  final street =
                      restaurant["tags"]?["addr:street"] ?? "";
                  final city =
                      restaurant["tags"]?["addr:city"] ?? "";
                  final address = [street, city]
                      .where((e) => e.isNotEmpty)
                      .join(", ");

                  return Card(
                    margin:
                    const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor:
                        Colors.deepPurple.shade100,
                        child: const Icon(Icons.restaurant,
                            color: Colors.deepPurple),
                      ),
                      title: Text(name,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        address.isNotEmpty
                            ? address
                            : "📍 Address not available",
                        style: const TextStyle(
                            color: Colors.black54),
                      ),
                      trailing: InkWell(
                        onTap: () => _showFullScreenImage(name, city),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.deepPurple.shade50,
                          ),
                          child: const Icon(Icons.remove_red_eye,
                              color: Colors.deepPurple),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String? imageUrl;
  final String restaurantName;

  const FullScreenImagePage({
    super.key,
    required this.imageUrl,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackUrl =
        "https://images.unsplash.com/photo-1555396273-367ea4eb4db5";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(restaurantName),
      ),
      body: imageUrl != null
          ? Stack(
        children: [
          InteractiveViewer(
            child: Center(
              child: Image.network(imageUrl!, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              backgroundColor: Colors.deepPurple,
              icon: const Icon(Icons.threed_rotation),
              label: const Text("360° View"),
              onPressed: () {
                debugPrint(
                    "🔄 Opening PanoramaPage with ${imageUrl ?? fallbackUrl}");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PanoramaPage(imageUrl: imageUrl ?? fallbackUrl),
                  ),
                );
              },
            ),
          ),
        ],
      )
          : const Center(
        child: Text(
          "No image available",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class PanoramaPage extends StatelessWidget {
  final String imageUrl;
  const PanoramaPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PanoramaViewer(
        zoom: 0.05,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint("❌ Failed to load panorama: $error");
            return const Center(child: Text("Failed to load image"));
          },
        ),
      ),
    );
  }
}
