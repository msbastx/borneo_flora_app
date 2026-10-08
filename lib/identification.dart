import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class IdentificationScreen extends StatefulWidget {
  const IdentificationScreen({super.key});

  @override
  State<IdentificationScreen> createState() => _IdentificationScreenState();
}

class _IdentificationScreenState extends State<IdentificationScreen> {
  ClassificationModel? _imageModel;
  File? _image;
  String _result = "Belum ada hasil";
  bool _isPredicting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _imageModel = await PytorchLite.loadClassificationModel(
        "assets/model_flora.ptl",
        224, 224,
        75,
        labelPath: "assets/class_names.txt",
      );
      print("Model berhasil dimuat!");
    } catch (e) {
      print("Gagal memuat model: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = "Memproses...";
        _isPredicting = true;
      });
      _runInference();
    }
  }

  Future<void> _runInference() async {
    if (_imageModel != null && _image != null) {
      try {
        final imageBytes = await _image!.readAsBytes();
        List<dynamic>? predictions = await _imageModel!.getImagePredictionList(imageBytes);

        if (predictions != null && predictions.isNotEmpty) {
          // 1. Ubah hasil mentah menjadi list angka desimal
          List<double> scores = predictions.map((e) => double.parse(e.toString())).toList();

          // 2. Terapkan Softmax untuk mengubah Logit menjadi Persentase murni
          double maxLogit = scores.reduce(max);
          double sumExp = scores.fold(0.0, (sum, score) => sum + exp(score - maxLogit));
          List<double> probabilities = scores.map((score) => exp(score - maxLogit) / sumExp).toList();

          // 3. Gabungkan skor, probabilitas, dan index aslinya agar tidak tertukar
          List<Map<String, dynamic>> results = [];
          for (int i = 0; i < probabilities.length; i++) {
            results.add({"index": i, "prob": probabilities[i], "logit": scores[i]});
          }

          // 4. Urutkan dari persentase terbesar ke terkecil
          results.sort((a, b) => b["prob"].compareTo(a["prob"]));

          // 5. Muat daftar nama kelas dan bersihkan baris kosong agar urutan Index akurat
          final String labelsData = await rootBundle.loadString('assets/class_names.txt');
          List<String> classNames = labelsData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

          // 6. Tampilkan 3 tebakan teratas secara detail
          String debugText = "HASIL DIAGNOSA MODEL:\n\n";
          for (int i = 0; i < 3; i++) {
            int idx = results[i]["index"];
            double prob = results[i]["prob"] * 100;
            double logit = results[i]["logit"];
            String name = idx < classNames.length ? classNames[idx] : "Unknown Class";

            debugText += "${i + 1}. $name\n(Index Teks: $idx | Akurasi: ${prob.toStringAsFixed(2)}% | Logit: ${logit.toStringAsFixed(2)})\n\n";
          }

          setState(() {
            _result = debugText.trim();
            _isPredicting = false;
          });
        } else {
          setState(() {
            _result = "Model gagal memproses output";
            _isPredicting = false;
          });
        }
      } catch (e) {
        setState(() {
          _result = "Gagal memproses gambar";
          _isPredicting = false;
        });
        print("Error saat inferensi: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identifikasi', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E3F27),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: _image == null
                  ? const Icon(Icons.image, size: 100, color: Colors.grey)
                  : ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _result,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isPredicting ? null : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Kamera"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2F84F), foregroundColor: Colors.black),
                ),
                ElevatedButton.icon(
                  onPressed: _isPredicting ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Galeri"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3F27), foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}