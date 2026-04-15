import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quest.dart';
import '../providers/game_providers.dart';
import '../services/sound_service.dart';

class AddQuestDialog extends ConsumerStatefulWidget {
  const AddQuestDialog({super.key});

  @override
  ConsumerState<AddQuestDialog> createState() => _AddQuestDialogState();
}

class _AddQuestDialogState extends ConsumerState<AddQuestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questNameController = TextEditingController();
  final _xpRewardController = TextEditingController();
  QuestCategory? _selectedCategory;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _questNameController.dispose();
    _xpRewardController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a category, brave one!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final questName = _questNameController.text.trim();
      final xpReward = int.parse(_xpRewardController.text);
      final category = _selectedCategory!;

      ref.read(questListProvider.notifier).addQuest(
        questName,
        xpReward,
        category,
      );

      // Play mission accepted sound
      await ref.read(soundServiceProvider).playSound(SoundType.missionAccepted);

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Mission "$questName" accepted!'),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 1500),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oops! $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.amber.shade50,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tiny House Avatar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.brown.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '🏠',
                  style: TextStyle(fontSize: 48),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'New Mission!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
              ),
              const SizedBox(height: 8),

              // Greeting
              Text(
                'Welcome, Adventurer! Let\'s build something great.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quest Name
                    Text(
                      'What to do, Adventurer?',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.brown.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _questNameController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Organize the pantry',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.assignment),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Every quest needs a name!';
                        }
                        if (value.trim().length < 3) {
                          return 'Make it at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // XP Reward
                    Text(
                      'What treasures await? (XP to earn)',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.brown.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _xpRewardController,
                      decoration: InputDecoration(
                        hintText: 'e.g., 50',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.star),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Every quest has rewards!';
                        }
                        final xp = int.tryParse(value);
                        if (xp == null || xp <= 0) {
                          return 'Must be a positive number';
                        }
                        if (xp > 1000) {
                          return 'That\'s too legendary!';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category
                    Text(
                      'Which realm does this belong?',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.brown.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.brown.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: DropdownButton<QuestCategory>(
                        isExpanded: true,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Pick a realm...'),
                        ),
                        value: _selectedCategory,
                        onChanged: (QuestCategory? value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                        underline: const SizedBox.shrink(),
                        items: QuestCategory.values.map((category) {
                          return DropdownMenuItem<QuestCategory>(
                            value: category,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(category.label),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_circle),
                    label: const Text('Accept Mission'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showAddQuestDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const AddQuestDialog(),
    barrierDismissible: false,
  );
}
