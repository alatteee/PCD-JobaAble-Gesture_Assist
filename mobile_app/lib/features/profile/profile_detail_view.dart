import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'profile_controller.dart';
import 'edit_profile_view.dart';
import 'widgets/skill_chip.dart';
import 'widgets/profile_info_field.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

class ProfileDetailView extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const ProfileDetailView({super.key, required this.currentUser});

  @override
  State<ProfileDetailView> createState() => _ProfileDetailViewState();
}

class _ProfileDetailViewState extends State<ProfileDetailView> {
  Map<String, dynamic>? userDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { isLoading = true; });
    final profile = await ProfileController.getProfileByUserId(widget.currentUser['_id']);
    setState(() {
      userDetails = profile;
      isLoading = false;
    });
  }

  bool _isBase64(String str) {
    try {
      base64Decode(str);
      return str.length % 4 == 0 && !str.contains(' ');
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }

    final namaLengkap = userDetails?['nama_lengkap'] ?? widget.currentUser['username'] ?? 'Belum diisi';
    final email = userDetails?['email'] ?? widget.currentUser['email'] ?? 'Belum diisi';
    final noHp = userDetails?['phone'] ?? widget.currentUser['phone'] ?? 'Belum diisi';
    
    String tanggalLahir = 'Belum diisi';
    if (userDetails?['tanggal_lahir'] != null) {
      final date = userDetails!['tanggal_lahir'];
      if (date is DateTime) {
        tanggalLahir = '${date.day}/${date.month}/${date.year}';
      } else if (date is String) {
        try {
          final parsed = DateTime.parse(date);
          tanggalLahir = '${parsed.day}/${parsed.month}/${parsed.year}';
        } catch (_) {}
      }
    }
    
    final jenisKelamin = userDetails?['jenis_kelamin'] ?? 'Belum diisi';
    final jenisDisabilitas = userDetails?['jenis_disabilitas'] ?? 'Belum diisi';
    final deskripsiDisabilitas = userDetails?['deskripsi_disabilitas'] ?? 'Belum diisi';
    final List<dynamic> skillsData = userDetails?['skills'] ?? [];
    List<String> skills = skillsData.map((e) => e.toString()).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context, true),        ),
        title: Text(
          'Detail Profil',
          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: userDetails?['profile_photo'] != null &&
                      userDetails!['profile_photo'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _isBase64(userDetails!['profile_photo'])
                        ? Image.memory(base64Decode(userDetails!['profile_photo']), fit: BoxFit.cover)
                        : (userDetails!['profile_photo'].toString().startsWith('http')
                            ? Image.network(userDetails!['profile_photo'], fit: BoxFit.cover)
                            : Image.file(File(userDetails!['profile_photo']), fit: BoxFit.cover)),
                    )
                  : Icon(
                      Icons.person,
                      size: 50,
                      color: theme.colorScheme.primary,
                    ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaLengkap,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Info Fields
            ProfileInfoField(label: 'Nama Lengkap', value: namaLengkap),
            ProfileInfoField(label: 'No. Handphone', value: noHp),
            ProfileInfoField(label: 'Email', value: email),
            ProfileInfoField(label: 'Tanggal Lahir', value: tanggalLahir),
            ProfileInfoField(label: 'Jenis Kelamin', value: jenisKelamin),
            ProfileInfoField(label: 'Jenis Disabilitas', value: jenisDisabilitas),
            ProfileInfoField(label: 'Deskripsi Disabilitas', value: deskripsiDisabilitas),

            // Skills
            Text(
              'Kemampuan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color),
            ),
            const SizedBox(height: 8),
            skills.isEmpty 
              ? Text('Belum ada kemampuan ditambahkan', style: TextStyle(color: theme.textTheme.bodyMedium?.color))
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: skills.map((s) => SkillChip(label: s)).toList(),
                ),

            const SizedBox(height: 48),

            // Edit Profile Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => EditProfileView(
                      currentUser: widget.currentUser,
                      userDetails: userDetails,
                    )
                  ));
                  if (result == true) {
                    _loadProfile();
                  }
                },
                icon: Icon(Icons.edit, color: theme.colorScheme.onPrimary, size: 20),
                label: const Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
