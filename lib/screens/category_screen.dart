import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quest.dart';
import '../providers/game_providers.dart';
import '../services/sound_service.dart';
import '../widgets/animated_list_item.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  final QuestCategory category;

  const CategoryScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  bool _showReward = false;
  String _rewardMessage = '';

  void _showRewardAnimated(String message) {
    setState(() {
      _rewardMessage = message;
      _showReward = true;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _showReward = false;
      });
    });
  }

  void _completeQuestWithSound(int questIndex, Quest quest, WidgetRef ref) async {
    final soundService = ref.read(soundServiceProvider);
    final previousXp = ref.read(xpProvider);
    final previousLevel = (previousXp ~/ xpPerLevel) + 1;

    // Complete quest and add XP
    ref.read(questListProvider.notifier).completeQuest(questIndex);
    ref.read(xpProvider.notifier).addXp(quest.xpReward);

    // Play quest complete sound
    await soundService.playSound(SoundType.questComplete);

    // Check for level up
    final newXp = ref.read(xpProvider);
    final newLevel = (newXp ~/ xpPerLevel) + 1;

    if (newLevel > previousLevel) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        _showRewardAnimated('🎉 LEVEL UP! Level $newLevel!');
        await soundService.playSound(SoundType.levelUp);
      }
    } else {
      _showRewardAnimated('Quest complete +${quest.xpReward} XP!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final questList = ref.watch(questsByCategory(widget.category));
    final pendingCount = ref.watch(pendingQuestsByCategory(widget.category));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.label),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.category.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Text('Pending: ${pendingCount.length}'),
                  const SizedBox(height: 24),
                  Text(
                    '${widget.category.label} Quests',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: questList.isEmpty
                        ? Center(
                            child: Text(
                              'No quests in ${widget.category.label}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : ListView.builder(
                            itemCount: questList.length,
                            itemBuilder: (context, index) {
                              final quest = questList[index];

                              return AnimatedListItem(
                                index: index,
                                child: Card(
                                  color: quest.isCompleted
                                      ? Colors.grey.shade200
                                      : Colors.white,
                                  child: ListTile(
                                    leading: quest.isCompleted
                                        ? const Icon(Icons.check_circle,
                                            color: Colors.green)
                                        : const Icon(Icons.circle_outlined),
                                    title: Text(
                                      quest.name,
                                      style: TextStyle(
                                        decoration: quest.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    subtitle: Text('${quest.xpReward} XP reward'),
                                    trailing: quest.isCompleted
                                        ? const Icon(Icons.done)
                                        : ElevatedButton(
                                            onPressed: () {
                                              final questIndex = ref
                                                  .read(questListProvider)
                                                  .indexOf(quest);
                                              if (questIndex != -1) {
                                                _completeQuestWithSound(questIndex, quest, ref);
                                              }
                                            },
                                            child: const Text('Complete'),
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _showReward ? 30 : -120,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showReward ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.yellowAccent),
                    const SizedBox(width: 8),
                    Text(
                      _rewardMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
