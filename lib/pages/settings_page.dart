import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'sign_in_page.dart';
import 'reminders_page.dart';
import 'productivity_stats_page.dart';
import 'recycle_bin_page.dart';
import '../services/import_export_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_surface_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _animationsEnabled = true;
  ThemeMode _themeMode = ThemeMode.system;
  bool _transferInProgress = false;

  @override
  void initState() {
    super.initState();
    _animationsEnabled = StorageService.getAnimationsEnabled();
    _themeMode = StorageService.getThemeMode();
  }

  Future<void> _toggleAnimations(bool value) async {
    setState(() => _animationsEnabled = value);
    await StorageService.saveAnimationsEnabled(value);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    await StorageService.saveThemeMode(mode);
  }

  Future<void> _factoryReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Factory Reset?'),
        content: const Text(
          'This will permanently delete all tasks, groups, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RESET'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await StorageService.clearAllData();
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All data has been cleared')));
    setState(() {
      _animationsEnabled = true;
      _themeMode = ThemeMode.system;
    });
  }

  Future<void> _signOut() async {
    await StorageService.signOutLocal();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (_) => false,
    );
  }

  Future<void> _showImportDialog() async {
    var replaceExisting = false;
    String? selectedFileName;
    PlatformFile? selectedFile;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Import From File'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload a JSON or CSV file and import the tasks into local storage.',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      allowMultiple: false,
                      withData: true,
                      type: FileType.custom,
                      allowedExtensions: const ['json', 'csv'],
                    );
                    if (result == null || result.files.isEmpty) return;
                    setModalState(() {
                      selectedFile = result.files.single;
                      selectedFileName = result.files.single.name;
                    });
                  },
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(
                    selectedFileName == null ? 'Choose File' : 'Change File',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  selectedFileName ?? 'No file selected',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Replace existing data'),
                  subtitle: const Text('Turn on to overwrite local tasks and groups'),
                  value: replaceExisting,
                  onChanged: (value) {
                    setModalState(() => replaceExisting = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('IMPORT'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    if (selectedFile == null || selectedFile?.bytes == null) {
      _showMessage('Choose a valid .json or .csv file to import.');
      return;
    }

    setState(() => _transferInProgress = true);
    try {
      final result = await ImportExportService.importFromFile(
        fileName: selectedFile!.name,
        fileBytes: selectedFile!.bytes!,
        replaceExisting: replaceExisting,
      );
      if (!mounted) return;
      _showMessage(
        'Imported ${result.importedTasks} task${result.importedTasks == 1 ? '' : 's'} and ${result.importedGroups} group${result.importedGroups == 1 ? '' : 's'} from ${result.fileName}.',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _transferInProgress = false);
      }
    }
  }

  Future<void> _exportBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Backup'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will create a backup file with your tasks, groups, recycle bin data, and reminder presets.',
              ),
              const SizedBox(height: 12),
              const Text(
                'No internet is required for this export because the backup is downloaded as a local file.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('EXPORT'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final targetPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save checklist backup',
      fileName: ImportExportService.suggestedBackupFileName(),
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );

    if (targetPath == null || targetPath.trim().isEmpty) {
      _showMessage('Backup export was cancelled.');
      return;
    }

    setState(() => _transferInProgress = true);
    try {
      final result = await ImportExportService.exportBackupToFile(
        targetPath: targetPath,
      );
      if (!mounted) return;
      _showMessage(
        'Backup saved as ${result.fileName} with ${result.exportedTasks} task${result.exportedTasks == 1 ? '' : 's'} and ${result.exportedGroups} group${result.exportedGroups == 1 ? '' : 's'}.',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _transferInProgress = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppPageHeader(
                  title: 'Settings',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                _buildThemeModeCard(),
                const SizedBox(height: 14),
                _buildSwitchCard(),
                const SizedBox(height: 14),
                _buildStatsCard(context),
                const SizedBox(height: 14),
                _buildReminderCard(context),
                const SizedBox(height: 14),
                _buildRecycleBinCard(context),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'APP CONTROL',
                    style: TextStyle(
                      letterSpacing: 3.0,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _buildImportExportCard(),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Sign Out',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onErrorContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 22),
                    ),
                    onPressed: _factoryReset,
                    child: const Text(
                      'Factory Reset',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'BUILD 2024.12.01 - V1.5.0',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.more),
    );
  }

  Widget _buildSwitchCard() {
    final scheme = Theme.of(context).colorScheme;
    return AppSurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smooth Animations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Delightful transitions and movements',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(value: _animationsEnabled, onChanged: _toggleAnimations),
        ],
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSurfaceCard(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const RemindersPage()));
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Reminders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage pending alarms and reminder states',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSurfaceCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProductivityStatsPage()),
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Streaks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your task streak progress',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildRecycleBinCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSurfaceCard(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const RecycleBinPage()));
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recycle Bin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'View manually deleted tasks and task groups',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildThemeModeCard() {
    final scheme = Theme.of(context).colorScheme;
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose app theme mode',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.phone_android_rounded),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_rounded),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_rounded),
              ),
            ],
            selected: <ThemeMode>{_themeMode},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              _setThemeMode(selection.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImportExportCard() {
    final scheme = Theme.of(context).colorScheme;
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Import / Export',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (_transferInProgress)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Import tasks from JSON or CSV files and export a full backup as a local file.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            'Import validates the file format, and export creates a downloadable backup snapshot.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _transferInProgress ? null : _showImportDialog,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Import'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _transferInProgress ? null : _exportBackup,
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: const Text('Export Backup'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
