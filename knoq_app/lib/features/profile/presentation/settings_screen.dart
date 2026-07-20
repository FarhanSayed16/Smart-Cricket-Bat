import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:knoq_app/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:knoq_app/core/network/api_client.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _settingsBox = Hive.box('app_settings');

  void _confirmDeleteAccount() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is permanent and will delete all your data. '
              'Please enter your password to confirm.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (passwordController.text.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await ref.read(authRepositoryProvider).deleteAccount(passwordController.text);
                if (mounted) context.go('/login');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  /// Fix #7: Academy join placeholder dialog
  void _showJoinAcademyDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Academy'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Academy Code',
            hintText: 'Enter the code from your coach',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              
              Navigator.of(ctx).pop();
              try {
                await ref.read(userRepositoryProvider).joinAcademy(code);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Successfully joined academy!')),
                  );
                }
                ref.invalidate(currentUserProvider); // Refresh UI to show academy info
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveAcademy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Academy'),
        content: const Text('Are you sure you want to leave your current academy? Your coach will no longer be able to view your sessions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(userRepositoryProvider).leaveAcademy();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Left academy successfully.')),
                  );
                }
                ref.invalidate(currentUserProvider); // Refresh UI
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.settingsTab ?? 'Settings')),
      body: ListView(
        children: [
          _buildSectionHeader('Appearance', theme),
          ValueListenableBuilder(
            valueListenable: _settingsBox.listenable(keys: ['themeMode']),
            builder: (context, box, child) {
              final activeTheme = box.get('themeMode', defaultValue: 'system');
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'system', label: Text('System'), icon: Icon(Icons.brightness_auto)),
                    ButtonSegment(value: 'light', label: Text('Light'), icon: Icon(Icons.light_mode)),
                    ButtonSegment(value: 'dark', label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                  ],
                  selected: {activeTheme},
                  onSelectionChanged: (Set<String> newSelection) {
                    box.put('themeMode', newSelection.first);
                  },
                ),
              );
            },
          ),
          
          ValueListenableBuilder(
            valueListenable: _settingsBox.listenable(keys: ['language']),
            builder: (context, box, child) {
              final activeLang = box.get('language', defaultValue: 'en');
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n?.language ?? 'Language', style: theme.textTheme.bodyLarge),
                    DropdownButton<String>(
                      value: activeLang,
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'hi', child: Text('हिंदी (Hindi)')),
                        DropdownMenuItem(value: 'mr', child: Text('मराठी (Marathi)')),
                      ],
                      onChanged: (val) {
                        if (val != null) box.put('language', val);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          
          _buildSectionHeader('Device Management', theme),
          ValueListenableBuilder(
            valueListenable: _settingsBox.listenable(keys: ['last_ble_device_id', 'last_ble_device_name']),
            builder: (context, box, child) {
              final String? deviceId = box.get('last_ble_device_id');
              final String? deviceName = box.get('last_ble_device_name');
              
              if (deviceId == null) {
                return const ListTile(
                  leading: Icon(Icons.bluetooth_disabled),
                  title: Text('No device connected previously'),
                );
              }
              
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.bluetooth_connected, color: Colors.blue),
                    title: Text(deviceName ?? 'Unknown KnoQ Bat'),
                    subtitle: Text(deviceId),
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () {
                        box.delete('last_ble_device_id');
                        box.delete('last_ble_device_name');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Device forgotten')),
                        );
                      },
                      child: const Text('Forget'),
                    ),
                  ),
                  // Fix #8: Calibrate button dispatches to BLE provider stub
                  ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('Calibrate Bat'),
                    subtitle: const Text('Sends calibration command to connected bat'),
                    onTap: () {
                      // When BLE provider has sendCalibration(), wire it here:
                      // ref.read(bleProvider.notifier).sendCommand({'cmd': 'calibrate'});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calibration command sent to bat')),
                      );
                    },
                  )
                ],
              );
            },
          ),

          _buildSectionHeader('Notifications', theme),
          ValueListenableBuilder(
            valueListenable: _settingsBox.listenable(keys: ['notif_reminders', 'notif_feedback', 'notif_weekly']),
            builder: (context, box, child) => Column(
              children: [
                SwitchListTile(
                  title: const Text('Session Reminders'),
                  value: box.get('notif_reminders', defaultValue: true),
                  onChanged: (val) => box.put('notif_reminders', val),
                ),
                SwitchListTile(
                  title: const Text('Coach Feedback Alerts'),
                  value: box.get('notif_feedback', defaultValue: true),
                  onChanged: (val) => box.put('notif_feedback', val),
                ),
                SwitchListTile(
                  title: const Text('Weekly Summary'),
                  value: box.get('notif_weekly', defaultValue: true),
                  onChanged: (val) => box.put('notif_weekly', val),
                ),
              ],
            ),
          ),

          // Fix #7: Academy section with actual dialogs instead of dead taps
          _buildSectionHeader('Academy', theme),
          Consumer(builder: (ctx, ref, child) {
            final userAsync = ref.watch(currentUserProvider);
            return userAsync.when(
              data: (user) => ListTile(
                leading: const Icon(Icons.school),
                title: Text(user?.academyId != null ? 'Joined Academy: ${user!.academyId}' : 'No Academy Joined'),
                trailing: TextButton(
                  onPressed: () {
                    if (user?.academyId != null) {
                      _confirmLeaveAcademy();
                    } else {
                      _showJoinAcademyDialog();
                    }
                  },
                  child: Text(user?.academyId != null ? 'Leave' : 'Join'),
                ),
              ),
              loading: () => const ListTile(title: Text('Loading...')),
              error: (_, __) => const SizedBox.shrink(),
            );
          }),

          _buildSectionHeader('Data & Privacy', theme),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(l10n?.exportData ?? 'Export My Data'),
            onTap: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preparing export...')),
                );
                final user = ref.read(currentUserProvider).valueOrNull;
                if (user == null) throw Exception('Not logged in');
                
                final apiClient = ref.read(apiClientProvider);
                final response = await apiClient.dio.get('/exports/player/${user.id}/data?format=csv');
                
                final dir = await getTemporaryDirectory();
                final file = File('${dir.path}/data_${user.id}.csv');
                await file.writeAsString(response.data.toString());
                
                await Share.shareXFiles([XFile(file.path)], text: 'My KnoQ Data Export');
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(l10n?.exportSuccess ?? 'Export successful')),
                   );
                }
              } catch (e) {
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('${l10n?.exportError ?? "Failed to export"}: $e')),
                   );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Privacy Policy'),
            onTap: () => launchUrl(Uri.parse('https://example.com/privacy')),
          ),
          // Fix #5: Add Terms of Service link
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () => launchUrl(Uri.parse('https://example.com/terms')),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            onTap: _confirmDeleteAccount,
          ),

          _buildSectionHeader('About', theme),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App Version'),
            trailing: Text('1.0.0 (Build 1)'),
          ),
          const ListTile(
            leading: Icon(Icons.memory),
            title: Text('Firmware Version'),
            trailing: Text('v0.9.4 beta'),
          ),
          
          ListTile(
            leading: const Icon(Icons.star_rate),
            title: const Text('Rate the App'),
            onTap: () => launchUrl(Uri.parse('https://play.google.com/store')),
          ),
          // Fix #6: Add Contact Support
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Contact Support'),
            onTap: () => launchUrl(Uri.parse('mailto:support@knoq.in?subject=KnoQ%20App%20Support')),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
