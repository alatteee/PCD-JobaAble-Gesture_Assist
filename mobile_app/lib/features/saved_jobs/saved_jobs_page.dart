import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/mongo_service.dart';
import '../job_detail/job_detail_page.dart';

class SavedJobsPage extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const SavedJobsPage({super.key, required this.currentUser});

  @override
  State<SavedJobsPage> createState() => _SavedJobsPageState();
}

class _SavedJobsPageState extends State<SavedJobsPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> savedJobs = [];

  @override
  void initState() {
    super.initState();
    fetchSavedJobs();
  }

  String get currentUserId {
    return widget.currentUser['_id']?.toString() ??
        widget.currentUser['id']?.toString() ??
        widget.currentUser['user_id']?.toString() ??
        widget.currentUser['email']?.toString() ??
        '';
  }

  Future<void> fetchSavedJobs() async {
    setState(() => isLoading = true);

    final data = await MongoService.getSavedJobs(userId: currentUserId);

    if (!mounted) return;
    setState(() {
      savedJobs = data;
      isLoading = false;
    });
  }

  Future<void> removeSavedJob(Map<String, dynamic> job) async {
    final jobId = MongoService.getMongoId(job['_id']);
    final success = await MongoService.unsaveJob(userId: currentUserId, jobId: jobId);

    if (!mounted) return;

    if (success) {
      setState(() {
        savedJobs.removeWhere((item) => MongoService.getMongoId(item['_id']) == jobId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lowongan dihapus dari tersimpan')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus lowongan tersimpan')),
      );
    }
  }

  String formatTime(dynamic value) {
    if (value == null) return 'Tersimpan';

    DateTime? date;
    if (value is DateTime) {
      date = value;
    } else {
      date = DateTime.tryParse(value.toString());
    }

    if (date == null) return 'Tersimpan';

    final now = DateTime.now();
    final diff = now.difference(date.toLocal());

    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'Baru saja';
  }

  IconData jobIcon(String title, String category) {
    final text = '${title.toLowerCase()} ${category.toLowerCase()}';
    if (text.contains('writer') || text.contains('marketing')) return Icons.edit;
    if (text.contains('developer') || text.contains('teknologi')) return Icons.code;
    if (text.contains('admin')) return Icons.computer;
    return Icons.headset_mic;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lowongan Tersimpan',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
            : savedJobs.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada lowongan tersimpan',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: theme.colorScheme.primary,
                    onRefresh: fetchSavedJobs,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: savedJobs.length,
                      itemBuilder: (context, index) {
                        final job = savedJobs[index];
                        final title = job['title']?.toString() ?? '-';
                        final company = job['company_name']?.toString() ?? '-';
                        final location = job['location']?.toString() ?? '-';
                        final jobType = job['job_type']?.toString() ?? '-';
                        final category = job['category']?.toString() ?? '';

                        return _SavedJobCard(
                          title: title,
                          company: company,
                          timeText: formatTime(job['saved_at'] ?? job['created_at']),
                          location: location,
                          jobType: jobType,
                          icon: jobIcon(title, category),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobDetailPage(job: job),
                              ),
                            );
                          },
                          onBookmarkTap: () => removeSavedJob(job),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class _SavedJobCard extends StatelessWidget {
  final String title;
  final String company;
  final String timeText;
  final String location;
  final String jobType;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onBookmarkTap;

  const _SavedJobCard({
    required this.title,
    required this.company,
    required this.timeText,
    required this.location,
    required this.jobType,
    required this.icon,
    required this.onTap,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
        boxShadow: theme.brightness == Brightness.dark ? [] : [
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: theme.textTheme.titleLarge?.color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        company,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        timeText,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppColors.textGray),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              location,
                              style: const TextStyle(color: AppColors.textGray, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.work, size: 14, color: AppColors.textGray),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              jobType,
                              style: const TextStyle(color: AppColors.textGray, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onBookmarkTap,
                  icon: Icon(Icons.bookmark, color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
