import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: MapWithRemovableSheet(),
      ),
    );
  }
}

class MapWithRemovableSheet extends HookWidget {
  const MapWithRemovableSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isSheetVisible = useState(false);
    final googleMapController = useState<GoogleMapController?>(null);
    final currentPage = useState(0);
    final pageController = usePageController(viewportFraction: 0.9);
    final bottomSheetHeightRatio = useState(0.5);

    final List<Map<String, dynamic>> locations = [
      {
        "title": "Tokyo",
        "position": const LatLng(35.6895, 139.6917),
      },
      {
        "title": "Nagoya",
        "position": const LatLng(35.1815, 136.9066),
      },
      {
        "title": "Osaka",
        "position": const LatLng(34.6937, 135.5023),
      },
      {
        "title": "Fukuoka",
        "position": const LatLng(33.5902, 130.4017),
      },
      {
        "title": "Sapporo",
        "position": const LatLng(43.0621, 141.3544),
      },
      {
        "title": "Shinjuku",
        "position": const LatLng(35.6938, 139.7034),
      },
      {
        "title": "Shibuya",
        "position": const LatLng(35.6592, 139.7006),
      },
      {
        "title": "Ikebukuro",
        "position": const LatLng(35.7284, 139.7104),
      },
      {
        "title": "Setagaya",
        "position": const LatLng(35.6467, 139.6539),
      },
      {
        "title": "Kichijoji",
        "position": const LatLng(35.7033, 139.5788),
      },
      {
        "title": "Odaiba",
        "position": const LatLng(35.6292, 139.7745),
      },
      {
        "title": "Chiyoda",
        "position": const LatLng(35.6934, 139.7531),
      },
      {
        "title": "Akihabara",
        "position": const LatLng(35.6984, 139.7730),
      },
      {
        "title": "Kawasaki",
        "position": const LatLng(35.5308, 139.7022),
      },
      {
        "title": "Yokohama",
        "position": const LatLng(35.4437, 139.6380),
      },
      {
        "title": "Chiba",
        "position": const LatLng(35.6072, 140.1062),
      },
      {
        "title": "Saitama",
        "position": const LatLng(35.8617, 139.6455),
      },
      {
        "title": "Okinawa",
        "position": const LatLng(26.2124, 127.6809),
      }
    ];

    final markers = useState<Set<Marker>>({});
    final selectedMarkerId = useState<int>(0);

    final contentsKey = useMemoized(() => GlobalKey());
    final availableHeight = useRef<double?>(null);

    const maxChildSize = 0.6;
    final initialChildSize = useState(0.45);

    final currentMaxChildSize = useState(maxChildSize);

    final draggableController = DraggableScrollableController();

    void updateInitialChildSize() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final renderBox =
            contentsKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null && availableHeight.value != null) {
          final contentHeightRatio =
              renderBox.size.height / availableHeight.value!;
          initialChildSize.value = min(maxChildSize, contentHeightRatio);
        }
      });
    }

    useEffect(() {
      updateInitialChildSize();
      return null;
    }, [contentsKey.currentContext?.mounted]);

    double calculateChildSizeRatio() {
      final renderBox =
          contentsKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null || availableHeight.value == null) {
        return maxChildSize;
      }

      return max(initialChildSize.value,
          min(renderBox.size.height / availableHeight.value!, maxChildSize));
    }

    useEffect(
      () {
        // <= 追加
        WidgetsBinding.instance.addPostFrameCallback((_) {
          currentMaxChildSize.value = calculateChildSizeRatio();
        });
        return null;
      },
      [contentsKey.currentContext?.mounted],
    );

    useEffect(() {
      Future.wait(locations.asMap().entries.map((entry) async {
        final index = entry.key + 1;
        final location = entry.value;
        final customIcon = await CustomMarkerCreator.createCustomMarker(
            index, selectedMarkerId.value);

        return Marker(
          markerId: MarkerId('marker_$index'),
          position: location['position'],
          icon: customIcon,
          zIndex: index == selectedMarkerId.value ? 1 : 0,
          onTap: () {
            currentPage.value = index - 1;
            isSheetVisible.value = true;
            selectedMarkerId.value = index;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              pageController.jumpToPage(index - 1);
            });
          },
        );
      })).then((markerList) {
        markers.value = markerList.toSet();
      });
      return null;
    }, [selectedMarkerId.value]);

    void hideSheet() {
      isSheetVisible.value = false;
      selectedMarkerId.value = 0;
      bottomSheetHeightRatio.value = initialChildSize.value;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map with Bottom Sheet'),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Update availableHeight based on the full screen height
          availableHeight.value = constraints.maxHeight;

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: locations[0]['position'],
                  zoom: 10,
                  bearing: 0,
                ),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                padding: EdgeInsets.only(
                  bottom: isSheetVisible.value
                      ? availableHeight.value! * bottomSheetHeightRatio.value
                      : 0,
                ),
                onMapCreated: (controller) {
                  googleMapController.value = controller;
                },
                markers: markers.value,
              ),
              if (isSheetVisible.value)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: DraggableScrollableSheet(
                    controller: draggableController,
                    initialChildSize: initialChildSize.value,
                    minChildSize: 0.3,
                    maxChildSize: currentMaxChildSize.value,
                    snap: true,
                    expand: false,
                    builder: (context, scrollController) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        bottomSheetHeightRatio.value = draggableController.size;
                      });

                      return NotificationListener<
                          DraggableScrollableNotification>(
                        onNotification: (notification) {
                          bottomSheetHeightRatio.value = notification.extent;
                          return true;
                        },
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          child: Container(
                            key: contentsKey,
                            clipBehavior: Clip.hardEdge,
                            decoration: const BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              children: [
                                SheetHeader(hideSheet: hideSheet),
                                LocationPageView(
                                  pageController: pageController,
                                  locations: locations,
                                  currentPage: currentPage,
                                  selectedMarkerId: selectedMarkerId,
                                  googleMapController: googleMapController,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomAppBar(
        height: 56,
        color: Colors.white,
        child: Center(
          child: Text(
            'Bottom Navigation Bar',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class SheetHeader extends StatelessWidget {
  final VoidCallback hideSheet;

  const SheetHeader({required this.hideSheet, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      color: Colors.white,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 28.0, top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sheet Header',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  splashRadius: 24,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close),
                  constraints:
                      const BoxConstraints(minWidth: 30, minHeight: 30),
                  onPressed: hideSheet,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
                width: 28,
                height: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LocationPageView extends StatelessWidget {
  final PageController pageController;
  final List<Map<String, dynamic>> locations;
  final ValueNotifier<int> currentPage;
  final ValueNotifier<int> selectedMarkerId;
  final ValueNotifier<GoogleMapController?> googleMapController;

  const LocationPageView({
    required this.pageController,
    required this.locations,
    required this.currentPage,
    required this.selectedMarkerId,
    required this.googleMapController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: pageController,
        itemCount: locations.length,
        onPageChanged: (index) async {
          currentPage.value = index;
          selectedMarkerId.value = index + 1;
          final position = locations[index]['position'];

          await googleMapController.value?.animateCamera(
            CameraUpdate.newLatLng(position),
          );
        },
        itemBuilder: (context, index) {
          final location = locations[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.all(8),
            color: Colors.primaries[index % Colors.primaries.length],
            child: Center(
              child: Text(
                location['title'],
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CustomMarkerCreator {
  static Future<BitmapDescriptor> createCustomMarker(
      int index, int selectedIndex) async {
    const double scale = 4; // Scale
    const double width = 140 * scale; // Width
    const double height = 60 * scale; // Height
    const double borderRadius = 40 * scale; // Border radius
    const double borderWidth = 4 * scale; // Border width

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Draw border
    final Paint borderPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final RRect borderRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(borderWidth, borderWidth, width - borderWidth * 2,
          height - borderWidth * 2),
      const Radius.circular(borderRadius - borderWidth),
    );
    canvas.drawRRect(borderRect, borderPaint);

    // Draw rounded rectangle
    final Paint paint = Paint()
      ..color = index == selectedIndex ? Colors.orange : Colors.grey[50]!;

    final RRect roundedRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(borderWidth, borderWidth, width - borderWidth * 2,
          height - borderWidth * 2),
      const Radius.circular(borderRadius - borderWidth),
    );
    canvas.drawRRect(roundedRect, paint);

    // Draw text
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: index.toString(),
        style: TextStyle(
          fontSize: 32 * scale,
          color: index == selectedIndex ? Colors.white : Colors.grey[800],
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (height - textPainter.height) / 2,
      ),
    );

    final ui.Image image = await pictureRecorder
        .endRecording()
        .toImage(width.toInt(), height.toInt());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(
      bytes,
      width: width / (scale * 2),
      height: height / (scale * 2),
    );
  }
}
