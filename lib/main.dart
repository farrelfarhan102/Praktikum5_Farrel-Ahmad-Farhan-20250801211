import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
    home: const StokPage(),
  );
}

class StokPage extends StatefulWidget {
  const StokPage({super.key});
  @override
  State<StokPage> createState() => _StokPageState();
}

class _StokPageState extends State<StokPage> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _masuk = TextEditingController();
  final _keluar = TextEditingController();
  final _kode = TextEditingController();
  final _stok = TextEditingController();
  bool _loading = false;

  String? _wajib(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('stok_barang').add({
        'nama_barang': _nama.text.trim(),
        'tanggal_masuk': _masuk.text.trim(),
        'tanggal_keluar': _keluar.text.trim(),
        'kode_barang': int.parse(_kode.text.trim()),
        'jumlah_stok': int.parse(_stok.text.trim()),
        'waktu': FieldValue.serverTimestamp(),
      });
      _formKey.currentState!.reset();
      for (final c in [_nama, _masuk, _keluar, _kode, _stok]) {
        c.clear();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil disimpan')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(TextEditingController c, String label,
      {bool angka = false, String? Function(String?)? validator}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: angka ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
          validator: validator ?? _wajib,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pencatatan Stok Barang')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            _field(_nama, 'Nama Barang (awali dengan F, mis. Fkeyboard)',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                  if (!v.trim().toUpperCase().startsWith('F')) {
                    return 'Nama barang harus diawali huruf F';
                  }
                  return null;
                }),
            _field(_masuk, 'Tanggal Masuk Barang (mis. 16-10-2026)'),
            _field(_keluar, 'Tanggal Keluar Barang (mis. 20-10-2026)'),
            _field(_kode, 'Kode Barang (min 6 angka, akhiran 211)',
                angka: true, validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                  if (!RegExp(r'^\d{6,}$').hasMatch(v.trim())) {
                    return 'Minimal 6 angka';
                  }
                  if (!v.trim().endsWith('211')) {
                    return 'Harus berakhiran 211';
                  }
                  return null;
                }),
            _field(_stok, 'Jumlah Stok', angka: true, validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Wajib diisi';
              final n = int.tryParse(v.trim());
              if (n == null) return 'Harus berupa angka bulat';
              if (n < 0) return 'Tidak boleh negatif';
              return null;
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _simpan,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Simpan Barang'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}