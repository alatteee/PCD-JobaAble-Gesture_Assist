import 'package:flutter/material.dart';
import '../../services/mongo_service.dart';

class CompanyEditJobPage extends StatefulWidget {
  final Map<String, dynamic> job;

  const CompanyEditJobPage({
    super.key,
    required this.job,
  });

  @override
  State<CompanyEditJobPage> createState() => _CompanyEditJobPageState();
}

class _CompanyEditJobPageState extends State<CompanyEditJobPage> {
  static const Color navy = Color(0xFF0D1B55);
  static const Color textGrey = Color(0xFF4A5870);
  static const Color blueChip = Color(0xFF91B4FF);

  late TextEditingController titleController;
  late TextEditingController locationController;
  late TextEditingController descriptionController;
  late TextEditingController qualificationController;

  String selectedJobType = 'Full Time';
  bool isDisabilityFriendly = true;
  List<String> facilities = [];

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.job['title']?.toString() ?? '',
    );

    locationController = TextEditingController(
      text: widget.job['location']?.toString() ?? '',
    );

    descriptionController = TextEditingController(
      text: widget.job['description']?.toString() ?? '',
    );

    selectedJobType = widget.job['job_type']?.toString() ?? 'Full Time';

    facilities = _toStringList(widget.job['facilities']);

    final qualifications = _toStringList(widget.job['qualification']);
    qualificationController = TextEditingController(
      text: qualifications.map((item) => '• $item').join('\n'),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    qualificationController.dispose();
    super.dispose();
  }

  List<String> _toStringList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return [value];
    }

    return [];
  }

  void _addFacility() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Tambah Fasilitas'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Contoh: Transportasi',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isNotEmpty) {
                  setState(() {
                    facilities.add(value);
                  });
                }

                Navigator.pop(context);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    final jobId = MongoService.getMongoId(widget.job['_id']);

    final qualifications = qualificationController.text
        .split('\n')
        .map((item) => item.replaceAll('•', '').trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final success = await MongoService.updateCompanyJob(
      jobId: jobId,
      data: {
        'title': titleController.text.trim(),
        'location': locationController.text.trim(),
        'job_type': selectedJobType,
        'description': descriptionController.text.trim(),
        'qualification': qualifications,
        'facilities': facilities,
        'is_disability_friendly': isDisabilityFriendly,
      },
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lowongan berhasil diperbarui')),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui lowongan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),

            _label('Nama Pekerjaan'),
            const SizedBox(height: 10),
            _inputField(
              controller: titleController,
              hint: 'Nama pekerjaan',
            ),

            const SizedBox(height: 22),
            _label('Lokasi'),
            const SizedBox(height: 10),
            _inputField(
              controller: locationController,
              hint: 'Lokasi',
            ),

            const SizedBox(height: 22),
            _label('Jenis Pekerjaan'),
            const SizedBox(height: 12),
            _buildJobTypeSelector(),

            const SizedBox(height: 24),
            _label('Deskripsi Pekerjaan'),
            const SizedBox(height: 10),
            _inputField(
              controller: descriptionController,
              hint: 'Deskripsi pekerjaan',
              maxLines: 5,
            ),

            const SizedBox(height: 22),
            _label('Kualifikasi'),
            const SizedBox(height: 10),
            _inputField(
              controller: qualificationController,
              hint: 'Kualifikasi',
              maxLines: 5,
            ),

            const SizedBox(height: 24),
            _facilityTitle(),
            const SizedBox(height: 6),
            const Text(
              'Tambahkan fasilitas atau benefit yang diberikan.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildFacilities(),

            const SizedBox(height: 26),
            _label('Terbuka untuk Disabilitas'),
            const SizedBox(height: 12),
            _buildDisabilityOption(
              value: true,
              text: 'Ya, terbuka untuk semua disabilitas',
            ),
            _buildDisabilityOption(
              value: false,
              text: 'Tidak',
            ),

            const SizedBox(height: 26),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            size: 34,
            color: navy,
          ),
        ),
        const SizedBox(width: 18),
        const Text(
          'Edit Lowongan',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: navy,
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Colors.black87,
      ),
    );
  }

  Widget _facilityTitle() {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'Fasilitas ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          TextSpan(
            text: '(opsional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 16,
          color: textGrey,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: textGrey,
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildJobTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _jobTypeButton('Full Time'),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _jobTypeButton('Part Time'),
        ),
      ],
    );
  }

  Widget _jobTypeButton(String type) {
    final selected = selectedJobType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedJobType = type;
        });
      },
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? navy : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: navy,
            width: 1.4,
          ),
        ),
        child: Text(
          type,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : navy,
          ),
        ),
      ),
    );
  }

  Widget _buildFacilities() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...facilities.map((facility) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: blueChip,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  facility,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      facilities.remove(facility);
                    });
                  },
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: navy,
                  ),
                ),
              ],
            ),
          );
        }),
        GestureDetector(
          onTap: _addFacility,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: navy,
                width: 1.4,
              ),
            ),
            child: const Text(
              '+ Tambah',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: navy,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisabilityOption({
    required bool value,
    required String text,
  }) {
    final selected = isDisabilityFriendly == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          isDisabilityFriendly = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 25,
              color: selected ? navy : Colors.black54,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  color: textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _saveChanges,
        icon: const Icon(
          Icons.save_rounded,
          size: 26,
          color: Colors.white,
        ),
        label: const Text('Simpan Perubahan'),
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}