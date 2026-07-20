import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';
import 'package:knoq_app/features/auth/domain/user_model.dart';
import 'package:knoq_app/features/home/presentation/player_home_screen.dart'; // for lifetimeStatsProvider
import 'package:go_router/go_router.dart';
import 'package:knoq_app/services/analytics_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  /// Fix #2: Offer camera/gallery choice via bottom sheet
  Future<void> _updatePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;
    
    setState(() => _isUploadingPhoto = true);
    try {
      // In a real app this would upload `File(image.path)` to Firebase Storage/S3
      // and patch the `profileImageUrl` field via UserRepository.
      // For now we simulate an update delay:
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated (simulated)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showEditProfileDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => EditProfileDialog(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(lifetimeStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/profile/settings'),
          )
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Profile not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _updatePhoto,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: user.profileImageUrl != null 
                          ? NetworkImage(user.profileImageUrl!) 
                          : null,
                        child: _isUploadingPhoto
                          ? const CircularProgressIndicator()
                          : (user.profileImageUrl == null ? const Icon(Icons.person, size: 50) : null),
                      ),
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user.name ?? 'Player',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  user.email,
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  user.academyId != null ? 'Academy: ${user.academyId}' : 'No academy — Join one',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blueGrey),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showEditProfileDialog(user),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                  ),
                ),
                const SizedBox(height: 32),
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'LIFETIME STATS',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                statsAsync.when(
                  data: (stats) => Column(
                    children: [
                      _buildStatTile('Total Sessions Played', '${stats.totalSessions}', theme),
                      _buildStatTile('Total Hits', '${stats.totalHits}', theme),
                      _buildStatTile('Best Sweet Spot %', '${stats.overallSweetPct}%', theme),
                      // Fix #1: Add missing "Best Power" stat from masterplan
                      _buildStatTile('Best Power', '${stats.overallPeakPower}', theme),
                      _buildStatTile('Member Since', user.createdAt != null ? user.createdAt!.toLocal().toString().split(' ')[0] : 'Unknown', theme),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Could not load stats: $e'),
                ),

                if (user.role == 'player') ...[
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'MY COACHES',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final coachesAsync = ref.watch(assignedCoachesProvider);
                      return coachesAsync.when(
                        data: (coaches) {
                          if (coaches.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('No coaches assigned yet.', style: TextStyle(color: Colors.grey)),
                            );
                          }
                          return Column(
                            children: coaches.map((c) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Icon(Icons.sports, color: theme.colorScheme.onPrimaryContainer),
                              ),
                              title: Text(c.name ?? 'Unknown Coach', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(c.email),
                            )).toList(),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Could not load coaches: $e', style: const TextStyle(color: Colors.red)),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 48),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authNotifierProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                )
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class EditProfileDialog extends ConsumerStatefulWidget {
  final UserModel user;
  const EditProfileDialog({super.key, required this.user});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  String _battingHand = 'Right';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _ageController = TextEditingController(text: widget.user.age?.toString() ?? '');
    _battingHand = widget.user.battingHand ?? 'Right';
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    
    final updates = <String, dynamic>{
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()),
      'batting_hand': _battingHand,
    };
    // remove nulls
    updates.removeWhere((key, value) => value == null);

    try {
      await ref.read(userRepositoryProvider).updateProfile(updates);

      // Fix #3: Persist to local Hive cache so offline launch shows fresh data
      final profileCache = Hive.box('app_settings');
      profileCache.put('cached_user_name', updates['name']);
      if (updates['age'] != null) profileCache.put('cached_user_age', updates['age']);
      profileCache.put('cached_user_batting_hand', updates['batting_hand']);

      ref.invalidate(currentUserProvider); // Force profile reload
      ref.read(analyticsServiceProvider).logProfileEdited();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            // Fix #4: Use initialValue instead of deprecated value
            DropdownButtonFormField<String>(
              initialValue: _battingHand,
              decoration: const InputDecoration(labelText: 'Batting Hand', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Right', child: Text('Right-handed')),
                DropdownMenuItem(value: 'Left', child: Text('Left-handed')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _battingHand = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveProfile,
          icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save, size: 18),
          label: const Text('Save'),
        ),
      ],
    );
  }
}
