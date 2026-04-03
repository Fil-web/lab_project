import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Галерея',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const ImageGalleryScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ImageGalleryScreen extends StatelessWidget {
  const ImageGalleryScreen({super.key});

  final List<String> imageUrls = const [
    'https://sun9-8.userapi.com/s/v1/ig2/GljuQvQvVz1tVb0BlzP5S2WvFfGvptAyfdXud24DkKpfI3REPKNTS1W-4JraaVzyjtlfmL2ElG29ChpbahKOLDtZ.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080,1280x1280,1440x1440,2560x2560&from=bu&cs=2560x0',
    'https://sun9-80.userapi.com/s/v1/ig2/3Rnc3tq9A8AvShtsKfPzUeThjHqcmeE7lT4V3CI2vCyAj4Ca6_ni7WsiAKH0-UJZt92XMnjqwd81iCGc7NtLhIpG.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080,1280x1280,1440x1440,2560x2560&from=bu&cs=2560x0',
    'https://sun9-35.userapi.com/s/v1/ig2/xUSYnCj2klXri4TgAnMAM46SpjebzyJESPIiFNkeXK8b0kTs9MMYfzzMKyd6hNKhVVu0kx0ZXivtN_0DTdrj4GTT.jpg?quality=95&as=32x39,48x58,72x87,108x131,160x194,240x290,360x436,480x581,540x653,640x774,720x871,1080x1307,1280x1549,1440x1742,2116x2560&from=bu&cs=2116x0',
    'https://sun9-29.userapi.com/s/v1/ig2/RxJUM-nXWWMcei5Qgb0y-dtm9Yj7h5BX_65-uU-gTJLvsVJdK9kVp548d-6nL3y2v33usWs7rTnjxMT11NKGehbs.jpg?quality=95&as=32x48,48x72,72x108,108x162,160x240,240x361,360x541,480x721,540x811,640x962,720x1082,1080x1623,1280x1923,1440x2164,1472x2212&from=bu&cs=1472x0',
    'https://sun9-54.userapi.com/s/v1/ig2/UYYQxLH0M_dbXXNBbdwC_fYxd45hBexAv5K7rrvAInUs2fRGnOBxGj_s5e01MilY-vbx_RVptVDrMre4ZPWIujHw.jpg?quality=95&as=32x35,48x52,72x78,108x117,160x174,240x260,360x390,480x521,540x586,640x694,720x781,1080x1172,1280x1388,1440x1562,2360x2560&from=bu&cs=2360x0',
    'https://sun9-67.userapi.com/s/v1/ig2/e-yfLZ6zpNuVv5G_jNaXFaTOUjuTa5PEfIL1QWVYHgA_6C7c2ROFk-06LUHRM3eEBviY1_NkAqAkiPpLxpLRMxpp.jpg?quality=95&as=32x48,48x72,72x108,108x162,160x240,240x360,360x540,480x720,540x810,640x960,720x1080,1080x1620,1280x1920,1440x2160,1472x2208&from=bu&cs=1472x0',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Галерея изображений')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Контейнер 1: простой квадрат
            Container(
              margin: const EdgeInsets.all(16.0),
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrls[0],
                  width: 350,
                  height: 350,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stack) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(child: Text('Ошибка загрузки')),
                    );
                  },
                ),
              ),
            ),
            // Контейнер 2: с тенью и закруглёнными углами
            Container(
              margin: const EdgeInsets.all(16),
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(imageUrls[1], fit: BoxFit.cover),
              ),
            ),
            // Контейнер 3: с рамкой
            Container(
              margin: const EdgeInsets.all(24),
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrls[2], fit: BoxFit.cover),
              ),
            ),
            // Контейнер 4: с градиентным наложением
            Container(
              margin: const EdgeInsets.all(16),
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(color: Colors.grey, blurRadius: 8, offset: Offset(0, 4))
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(imageUrls[3], fit: BoxFit.cover),
                  ),
                  Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Контейнер 5: с внутренним отступом и рамкой
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 350,
                height: 350,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(color: Colors.grey, blurRadius: 15, spreadRadius: 2)
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(imageUrls[4], fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            // Контейнер 6: круглое изображение
            Container(
              margin: const EdgeInsets.all(16),
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 10)],
              ),
              child: ClipOval(
                child: Image.network(imageUrls[5], fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ),
    );
  }
}