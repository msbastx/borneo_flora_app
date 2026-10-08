import 'package:flutter/material.dart';
import 'navbar.dart';
import 'dummy_data.dart';
import 'identification.dart';

class FloraHomeScreen extends StatefulWidget {
  const FloraHomeScreen({super.key});

  @override
  State<FloraHomeScreen> createState() => _FloraHomeScreenState();

  static const Color darkGreen = Color(0xFF1E3F27);
  static const Color neonLime = Color(0xFFE2F84F);
  static const Color mutedGrey = Color(0xFF7D8379);
  static const Color cornerBracketColor = Color(0xFF91C5A0);
  static const Color dividerColor = Color(0xFFE0DDD5);
}

class _FloraHomeScreenState extends State<FloraHomeScreen> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FLORA IDENTIFICATION',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          color: FloraHomeScreen.mutedGrey,
                          fontFamily: 'monospace',
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.menu, color: FloraHomeScreen.darkGreen, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Apa yang\nanda temukan\nhari ini?',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 40,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: FloraHomeScreen.darkGreen,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Container(
                    height: 220,
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: FloraHomeScreen.darkGreen,
                      borderRadius: BorderRadiusGeometry.circular(24),
                    ),
                    child: Stack(
                      children: [
                        _buildCorner(top: 0, left: 0, isTop: true, isLeft: true),
                        _buildCorner(top: 0, right: 0, isTop: true, isLeft: false),
                        _buildCorner(bottom: 0, left: 0, isTop: false, isLeft: true),
                        _buildCorner(bottom: 0, right: 0, isTop: false, isLeft: false),

                        const Positioned(
                          top: 24,
                          left: 2,
                          child: Text(
                            'VIEWFINDER',
                            style: TextStyle(
                              color: Color(0xFF6B8B74),
                              fontFamily: 'monospace',
                              fontSize: 10,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const IdentificationScreen(),
                                    )
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: FloraHomeScreen.neonLime,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.camera_alt_outlined, color: Colors.black, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Potret & Identifikasi',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: (){
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => IdentificationScreen(),),
                                  );
                                },
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha:0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.photo_library_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'INDEKS FLORA',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          color: FloraHomeScreen.mutedGrey,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '75 →',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: FloraHomeScreen.darkGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: FloraHomeScreen.dividerColor, thickness: 1),

                  ...dummyFloraList.map((item) => _buildFloraRow(item)),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Navbar(
        activeIndex: _currentIndex,
        onTap: (index) {
          setState((){
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

Widget _buildFloraRow(FloraItem item) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              item.index,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: FloraHomeScreen.mutedGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.commonName,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: FloraHomeScreen.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.scientificName,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      color: FloraHomeScreen.mutedGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const Divider(color: FloraHomeScreen.dividerColor, thickness: 1, height: 1),
    ],
  );
}

Widget _buildCorner({
  double? top,
  double? bottom,
  double? left,
  double? right,
  required bool isTop,
  required bool isLeft,
}) {
  return Positioned(
    top: top,
    bottom: bottom,
    left: left,
    right: right,
    child: Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: FloraHomeScreen.cornerBracketColor, width: 2)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: FloraHomeScreen.cornerBracketColor, width: 2)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: FloraHomeScreen.cornerBracketColor, width: 2)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: FloraHomeScreen.cornerBracketColor, width: 2)
              : BorderSide.none,
        ),
      ),
    ),
  );
}