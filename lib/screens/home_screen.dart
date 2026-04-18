import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quest.dart';
import '../providers/game_providers.dart';
import '../services/sound_service.dart';
import '../utils/page_transitions.dart';
import '../widgets/add_quest_dialog.dart';
import 'category_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
        // Show level up animation
        _showRewardAnimated('🎉 LEVEL UP! Level $newLevel!');
        // Play level up sound
        await soundService.playSound(SoundType.levelUp);
      }
    } else {
      _showRewardAnimated('Quest complete +${quest.xpReward} XP!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRoomClean = ref.watch(roomCleanProvider);
    final currentXp = ref.watch(xpProvider);
    final currentLevel = ref.watch(levelProvider);
    final xpProgress = ref.watch(xpProgressProvider);
    final xpToNext = ref.watch(xpToNextLevelProvider);
    final questList = ref.watch(questListProvider);
    final pendingQuestCount = ref.watch(pendingQuestCountProvider);

    Color roomColor = isRoomClean ? Colors.green.shade50 : Colors.orange.shade50;
    if (pendingQuestCount >= 3) {
      roomColor = Colors.red.shade50;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Level $currentLevel • XP: $currentXp • Pending: $pendingQuestCount'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Stack(
        children: [
          Container(
            color: roomColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isRoomClean
                              ? 'The room is sparkling clean ✨'
                              : 'The room still needs attention 🧹',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (!isRoomClean)
                        ElevatedButton(
                          onPressed: () async {
                            final soundService = ref.read(soundServiceProvider);
                            final previousXp = ref.read(xpProvider);
                            final previousLevel = (previousXp ~/ xpPerLevel) + 1;

                            ref.read(roomCleanProvider.notifier).cleanRoom();
                            ref.read(xpProvider.notifier).addXp(10);

                            // Play sound
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
                              _showRewardAnimated('Room cleaned +10 XP!');
                            }
                          },
                          child: const Text('Clean'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text('XP Progress ($xpProgress / $xpPerLevel)', style: Theme.of(context).textTheme.bodyLarge,),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: xpProgress / xpPerLevel,
                      minHeight: 14,
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$xpToNext XP to next level', style: Theme.of(context).textTheme.bodySmall),

                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          showAddQuestDialog(context);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('New Mission!'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recent Quests',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    flex: 5,
                    child: questList.isEmpty
                        ? const Center(child: Text('No quests available'))
                        : ListView.builder(
                            itemCount: questList.length,
                            itemBuilder: (context, index) {
                              final quest = questList[index];
                              if (quest.isCompleted) {
                                return const SizedBox.shrink();
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              quest.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${quest.xpReward} XP • ${quest.category.label}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          _completeQuestWithSound(index, quest, ref);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                        ),
                                        child: Text(
                                          'Complete (+${quest.xpReward})',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quest Categories',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    flex: 4,
                    child: GridView.count(
                      crossAxisCount: 4,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 0.8,
                      children: QuestCategory.values.map((category) {
                        final count = ref.watch(pendingQuestsByCategory(category)).length;
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              SlidePageRoute(
                                page: CategoryScreen(category: category),
                              ),
                            );
                          },
                          child: Card(
                            color: Colors.white,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: count > 0 ? Colors.orange : Colors.grey,
                                  width: count > 0 ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    category.label.split(' ')[0],
                                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  if (count > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
