import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

class PanoramaScreen extends StatefulWidget {
  const PanoramaScreen({super.key});

  @override
  State<PanoramaScreen> createState() => _PanoramaScreenState();
}

class _PanoramaScreenState extends State<PanoramaScreen> {
  double _zoom = 0.1; // 👈 Lower value = wider view (very zoomed out now)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PanoramaViewer(
        zoom: _zoom, // 👈 Controls how far/close the image appears
        child: Image.asset('assets/images/image5.jpg'),
      ),
    );
  }
}
