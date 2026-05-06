import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'cv_controller.dart';

class CvFormView extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  final Map<String, dynamic>? existingCv;

  const CvFormView({super.key, required this.currentUser, this.existingCv});

  @override
  State<CvFormView> createState() => _CvFormViewState();
}

class _CvFormViewState extends State<CvFormView> {
  final _formKey = GlobalKey<FormState>();
  
  final _summaryController = TextEditingController();
  final _portfolioController = TextEditingController();
  
  List<Map<String, String>> education = [];
  List<Map<String, String>> experience = [];
  List<String> skills = [];
  List<String> certifications = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingCv != null) {
      _summaryController.text = widget.existingCv!['summary'] ?? '';
      _portfolioController.text = widget.existingCv!['portfolio_link'] ?? '';
      skills = List<String>.from(widget.existingCv!['skills'] ?? []);
      certifications = List<String>.from(widget.existingCv!['certifications'] ?? []);
      
      final List rawEdu = widget.existingCv!['education'] ?? [];
      education = rawEdu.map((e) => Map<String, String>.from(e)).toList();
      
      final List rawExp = widget.existingCv!['experience'] ?? [];
      experience = rawExp.map((e) => Map<String, String>.from(e)).toList();
    }
  }

  void _addSkill() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Keahlian'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Misal: Flutter, UI Design'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => skills.add(controller.text.trim()));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _addCertification() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Sertifikasi'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nama Sertifikat'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => certifications.add(controller.text.trim()));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _addEducation() {
    final schoolCtrl = TextEditingController();
    final majorCtrl = TextEditingController();
    final yearCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Pendidikan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: schoolCtrl, decoration: const InputDecoration(labelText: 'Sekolah/Kampus')),
            TextField(controller: majorCtrl, decoration: const InputDecoration(labelText: 'Jurusan')),
            TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'Tahun')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (schoolCtrl.text.isNotEmpty) {
                setState(() {
                  education.add({
                    'school': schoolCtrl.text,
                    'major': majorCtrl.text,
                    'year': yearCtrl.text,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _addExperience() {
    final posCtrl = TextEditingController();
    final compCtrl = TextEditingController();
    final durCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Pengalaman'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: posCtrl, decoration: const InputDecoration(labelText: 'Posisi')),
              TextField(controller: compCtrl, decoration: const InputDecoration(labelText: 'Perusahaan')),
              TextField(controller: durCtrl, decoration: const InputDecoration(labelText: 'Durasi (misal: 2021-2023)')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (posCtrl.text.isNotEmpty) {
                setState(() {
                  experience.add({
                    'position': posCtrl.text,
                    'company': compCtrl.text,
                    'duration': durCtrl.text,
                    'description': descCtrl.text,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCv() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 keahlian')),
      );
      return;
    }

    final data = {
      'user_id': widget.currentUser['_id'],
      'summary': _summaryController.text,
      'education': education,
      'experience': experience,
      'skills': skills,
      'certifications': certifications,
      'portfolio_link': _portfolioController.text,
    };

    final success = await CvController.createOrUpdateCv(widget.currentUser['_id'], data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CV Berhasil disimpan!')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.existingCv == null ? 'Buat CV Digital' : 'Edit CV Digital', 
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryNavy),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Ringkasan Diri'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _summaryController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ceritakan singkat tentang dirimu...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: Colors.grey.withOpacity(0.05),
                  filled: true,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Ringkasan tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),

              _buildHeaderWithAction('Pendidikan', _addEducation),
              ...education.asMap().entries.map((e) => _buildListItem(
                title: e.value['school']!,
                subtitle: '${e.value['major']} (${e.value['year']})',
                onDelete: () => setState(() => education.removeAt(e.key)),
              )),
              const SizedBox(height: 24),

              _buildHeaderWithAction('Pengalaman Kerja', _addExperience),
              ...experience.asMap().entries.map((e) => _buildListItem(
                title: e.value['position']!,
                subtitle: '${e.value['company']} | ${e.value['duration']}',
                onDelete: () => setState(() => experience.removeAt(e.key)),
              )),
              const SizedBox(height: 24),

              _buildHeaderWithAction('Keahlian (Skills)', _addSkill),
              Wrap(
                spacing: 8,
                children: skills.asMap().entries.map((e) => Chip(
                  label: Text(e.value),
                  onDeleted: () => setState(() => skills.removeAt(e.key)),
                  backgroundColor: AppColors.primaryNavy.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
                )).toList(),
              ),
              const SizedBox(height: 24),

              _buildHeaderWithAction('Sertifikasi', _addCertification),
              ...certifications.asMap().entries.map((e) => _buildListItem(
                title: e.value,
                onDelete: () => setState(() => certifications.removeAt(e.key)),
              )),
              const SizedBox(height: 24),

              _buildSectionTitle('Link Portofolio'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _portfolioController,
                decoration: InputDecoration(
                  hintText: 'https://...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveCv,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Simpan CV', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy));
  }

  Widget _buildHeaderWithAction(String title, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle(title),
        IconButton(onPressed: onAction, icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryNavy)),
      ],
    );
  }

  Widget _buildListItem({required String title, String? subtitle, required VoidCallback onDelete}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: onDelete),
      ),
    );
  }
}
