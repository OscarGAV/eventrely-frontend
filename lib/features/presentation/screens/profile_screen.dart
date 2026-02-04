import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/configuration/app_config.dart';
import '../../presentation/providers.dart';
import '../../presentation/widgets.dart';
import '../../../core/services/voice_command_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final voiceState = ref.watch(voiceCommandControllerProvider);
    final user = authState.user;
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No user logged in'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Info Card
            CustomCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.username[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user.username,
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    user.email,
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Member Since
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Member since ${_formatMemberSince(user.createdAt)}',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Settings Section
            Text(
              'SETTINGS',
              style: AppTextStyles.bodySecondary.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Voice Commands Toggle
            CustomCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: voiceState.isActive 
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.textSecondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          voiceState.isActive ? Icons.mic : Icons.mic_off,
                          color: voiceState.isActive 
                            ? AppColors.success 
                            : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Voice Commands',
                              style: AppTextStyles.h3,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              voiceState.isActive 
                                ? 'Say "Evento..." to create events'
                                : 'Enable to use voice commands',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: voiceState.isActive,
                        onChanged: (value) async {
                          final controller = ref.read(voiceCommandControllerProvider.notifier);
                          await controller.toggleVoiceService();
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  voiceState.isActive 
                                    ? 'Voice service disabled' 
                                    : 'Voice service enabled'
                                ),
                                backgroundColor: !voiceState.isActive 
                                  ? AppColors.success 
                                  : AppColors.textSecondary,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        activeColor: AppColors.success,
                      ),
                    ],
                  ),
                  
                  // Voice Status
                  if (voiceState.isActive) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.cardLightBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                voiceState.isListening 
                                  ? Icons.mic 
                                  : Icons.mic_none,
                                size: 16,
                                color: voiceState.isListening 
                                  ? AppColors.success 
                                  : AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                voiceState.isListening 
                                  ? 'Listening...' 
                                  : 'Ready',
                                style: AppTextStyles.caption.copyWith(
                                  color: voiceState.isListening 
                                    ? AppColors.success 
                                    : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (voiceState.lastCommand != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Last command: "${voiceState.lastCommand}"',
                              style: AppTextStyles.caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  
                  // Error Display
                  if (voiceState.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              voiceState.error!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Logout Button
            CustomButton(
              text: 'Logout',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.cardBackground,
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true && context.mounted) {
                  // Detener servicio de voz antes de logout
                  final controller = ref.read(voiceCommandControllerProvider.notifier);
                  await controller.stopVoiceService();
                  
                  // Hacer logout
                  await ref.read(authProvider.notifier).signOut();
                }
              },
              color: AppColors.error,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Version Info
            const Center(
              child: Text(
                'EventRELY v0.1.0',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatMemberSince(DateTime date) {
    // Formato: "Jan 29, 2026"
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}