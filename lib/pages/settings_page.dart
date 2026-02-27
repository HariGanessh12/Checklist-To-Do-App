import 'package:flutter/material.dart';
import 'reminders_page.dart';
import '../services/storage_service.dart';
import '../widgets/app_bottom_nav.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _animationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _animationsEnabled = StorageService.getAnimationsEnabled();
  }

  Future<void> _toggleAnimations(bool value) async {
    setState(() => _animationsEnabled = value);
    await StorageService.saveAnimationsEnabled(value);
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _buildSwitchCard(),
              const SizedBox(height: 14),
              _buildReminderCard(context),
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'APP CONTROL',
                  style: TextStyle(
                    letterSpacing: 3.0,
                    color: Color(0xFF6D54A5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFECCFCB),
                    foregroundColor: const Color(0xFFBF2B22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 22),
                  ),
                  onPressed: _factoryReset,
                  child: const Text(
                    'Factory Reset',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'BUILD 2024.12.01 - V1.5.0',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.more),
    );
  }

  Widget _buildSwitchCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4CDDF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smooth Animations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Delightful transitions and movements',
                  style: TextStyle(color: Color(0xFF8C8693)),
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
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const RemindersPage()));
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD4CDDF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 7,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Reminders',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage pending alarms and reminder states',
                    style: TextStyle(color: Color(0xFF8C8693)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Color(0xFF8F8A97)),
          ],
        ),
      ),
    );
  }
}
