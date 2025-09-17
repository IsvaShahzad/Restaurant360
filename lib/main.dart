import 'package:flutter/material.dart';
import 'PanoramaScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '360 Viewer Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PanoramaScreen(), // Open directly to panorama screen
    );
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_typeahead/flutter_typeahead.dart';
// import 'package:http/http.dart' as http;
//
// void main() {
//   runApp(const MaterialApp(
//     home: RestaurantSearchScreen(),
//     debugShowCheckedModeBanner: false,
//   ));
// }
//
// class RestaurantSearchScreen extends StatefulWidget {
//   const RestaurantSearchScreen({Key? key}) : super(key: key);
//
//   @override
//   State<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
// }
//
// class _RestaurantSearchScreenState extends State<RestaurantSearchScreen> {
//   bool _isLoading = false;
//   List<dynamic> _restaurants = [];
//
//   /// Get city/area suggestions dynamically using Nominatim
//   Future<List<Map<String, dynamic>>> _fetchSuggestions(String query) async {
//     if (query.isEmpty) return [];
//
//     final url =
//         "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5";
//
//     debugPrint("🔎 Autocomplete query: $url");
//
//     final response = await http.get(Uri.parse(url), headers: {
//       "User-Agent": "RestaurantFinderFlutterApp/1.0 (contact: isvashaz2@gmail.com)"
//     });
//
//     if (response.statusCode == 200) {
//       final List<dynamic> data = jsonDecode(response.body);
//       debugPrint("✅ Suggestions received: ${data.length}");
//       return data.map((e) => e as Map<String, dynamic>).toList();
//     } else {
//       debugPrint("❌ Failed to fetch suggestions: ${response.statusCode}");
//       return [];
//     }
//   }
//
//   /// Fetch restaurants using Overpass API
//   Future<void> _fetchRestaurants(String lat, String lon) async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _restaurants = [];
//       });
//
//       final query = """
// [out:json];
// node["amenity"="restaurant"](around:5000,$lat,$lon);
// out;
// """;
//
//       debugPrint("🌍 Fetching restaurants near: $lat,$lon");
//
//       final response = await http.post(
//         Uri.parse("https://overpass-api.de/api/interpreter"),
//         body: query,
//         headers: {
//           "Content-Type": "application/x-www-form-urlencoded",
//           "User-Agent": "RestaurantFinderFlutterApp/1.0 (contact: isvashaz2@gmail.com)",
//         },
//       );
//
//       debugPrint("📡 Restaurant response status: ${response.statusCode}");
//       debugPrint("📡 Restaurant response body: ${response.body.substring(0, 200)}...");
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           _restaurants = data["elements"];
//           _isLoading = false;
//         });
//       } else {
//         throw Exception("Failed to fetch restaurants");
//       }
//     } catch (e) {
//       debugPrint("❌ ERROR: $e");
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         title: const Text("🍽 Find Restaurants"),
//         centerTitle: true,
//         backgroundColor: Colors.deepPurple,
//         elevation: 4,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             /// Modern search bar
//             TypeAheadField<Map<String, dynamic>>(
//               builder: (context, controller, focusNode) {
//                 return TextField(
//                   controller: controller,
//                   focusNode: focusNode,
//                   decoration: InputDecoration(
//                     prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
//                     labelText: 'Search city or area',
//                     filled: true,
//                     fillColor: Colors.white,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(16),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                 );
//               },
//               suggestionsCallback: (pattern) async {
//                 return await _fetchSuggestions(pattern);
//               },
//               itemBuilder: (context, suggestion) {
//                 final displayName = suggestion["display_name"] ?? "Unknown";
//                 return ListTile(
//                   leading: const Icon(Icons.location_on, color: Colors.deepPurple),
//                   title: Text(displayName, style: const TextStyle(fontSize: 14)),
//                 );
//               },
//               onSelected: (suggestion) {
//                 final lat = suggestion["lat"];
//                 final lon = suggestion["lon"];
//                 final name = suggestion["display_name"];
//                 debugPrint("✅ Selected location: $name (lat: $lat, lon: $lon)");
//                 _fetchRestaurants(lat, lon);
//               },
//             ),
//             const SizedBox(height: 16),
//
//             /// Restaurant results
//             Expanded(
//               child: _isLoading
//                   ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
//                   : _restaurants.isEmpty
//                   ? const Center(
//                 child: Text(
//                   "No restaurants found.",
//                   style: TextStyle(fontSize: 16, color: Colors.black54),
//                 ),
//               )
//                   : ListView.builder(
//                 itemCount: _restaurants.length,
//                 itemBuilder: (context, index) {
//                   final restaurant = _restaurants[index];
//                   final name = restaurant["tags"]?["name"] ?? "Unnamed Restaurant";
//
//                   // Use address fields if available
//                   final street = restaurant["tags"]?["addr:street"] ?? "";
//                   final housenumber = restaurant["tags"]?["addr:housenumber"] ?? "";
//                   final city = restaurant["tags"]?["addr:city"] ?? "";
//                   final address = [housenumber, street, city]
//                       .where((element) => element.isNotEmpty)
//                       .join(", ");
//
//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 6),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     elevation: 3,
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.all(16),
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.deepPurple.shade100,
//                         child: const Icon(Icons.restaurant, color: Colors.deepPurple),
//                       ),
//                       title: Text(
//                         name,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       subtitle: Text(
//                         address.isNotEmpty ? address : "📍 Address not available",
//                         style: const TextStyle(color: Colors.black54),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//




