import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/quest.dart';
import '../providers/game_providers.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'pip_mascot.dart';
import 'puffy_button.dart';

void showAddQuestBottomSheet(
  BuildContext context, {
  QuestCategory? initialCategory,
  int? editIndex,
  Quest? questToEdit,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddQuestSheet(
      initialCategory: initialCategory,
      editIndex: editIndex,
      questToEdit: questToEdit,
    ),
  );
}

// Alias so existing call sites still compile
void showAddQuestDialog(BuildContext context) => showAddQuestBottomSheet(context);

class _AddQuestSheet extends ConsumerStatefulWidget {
  final QuestCategory? initialCategory;
  final int? editIndex;
  final Quest? questToEdit;

  const _AddQuestSheet({this.initialCategory, this.editIndex, this.questToEdit});

  @override
  ConsumerState<_AddQuestSheet> createState() => _AddQuestSheetState();
}

class _AddQuestSheetState extends ConsumerState<_AddQuestSheet> {
  final _nameController = TextEditingController();
  final _formKey        = GlobalKey<FormState>();
  late QuestCategory? _category;
  int _xpTier           = 20;

  @override
  void initState() {
    super.initState();
    if (widget.questToEdit != null) {
      final q = widget.questToEdit!;
      _nameController.text = q.name;
      _category = q.category;
      _xpTier = _tiers.reduce((a, b) =>
          (a.xp - q.xpReward).abs() < (b.xp - q.xpReward).abs() ? a : b).xp;
    } else {
      _category = widget.initialCategory;
    }
  }
  bool _isSubmitting    = false;

  static const _tiers = [
    (label: 'Tiny',  xp: 5,  color: AppColors.cyan),
    (label: 'Easy',  xp: 10, color: AppColors.green),
    (label: 'Solid', xp: 20, color: AppColors.violet),
    (label: 'Boss',  xp: 50, color: AppColors.pink),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a category, brave one!'), backgroundColor: AppColors.violet),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      if (widget.editIndex != null) {
        ref.read(questListProvider.notifier).editQuest(
          widget.editIndex!,
          _nameController.text.trim(),
          _xpTier,
          _category!,
        );
        await ref.read(soundServiceProvider).playSound(SoundType.saveConfirm);
      } else {
        ref.read(questListProvider.notifier).addQuest(
          _nameController.text.trim(),
          _xpTier,
          _category!,
        );
        await ref.read(soundServiceProvider).playSound(SoundType.addQuest);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oops! $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;
    final navBarBottom   = MediaQuery.of(context).padding.bottom;
    // Hide the category picker when adding from a category screen — the
    // category is already locked in via initialCategory. Still show it when
    // adding from the quest board (no initialCategory) or when editing.
    final hideCategoryPicker =
        widget.initialCategory != null && widget.editIndex == null;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardBottom),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: EdgeInsets.fromLTRB(22, 0, 22, 14 + navBarBottom),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x669D5CFF), blurRadius: 40, offset: Offset(0, -10)),
            BoxShadow(color: Color(0x80000000), offset: Offset(0, 4)),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withOpacity(.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  const PipWithItems(size: 48),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.questToEdit != null ? 'Edit quest!' : 'New quest!', style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text(widget.questToEdit != null ? 'Tweak it, hero!' : "What're we crushing today?", style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SheetField(
                label: 'Quest',
                hint: 'e.g. Replace the cracked mug',
                controller: _nameController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Every quest needs a name!';
                  if (v.trim().length < 3) return 'At least 3 characters';
                  return null;
                },
              ),
              if (!hideCategoryPicker) ...[
                const SizedBox(height: 12),
                Text('Where in the room?', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
                const SizedBox(height: 6),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 3.4,
                  children: QuestCategory.values.map((cat) {
                    final selected = cat == _category;
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: selected ? LinearGradient(colors: [cat.color1, cat.color2]) : null,
                          color: selected ? null : AppColors.bgDeep,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? Colors.transparent : Colors.white.withOpacity(.06),
                            width: 2,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: cat.color2.withOpacity(.3), offset: const Offset(0, 3))]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Text(cat.glyph, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              cat.label.split(' ').last,
                              style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Text('How hard?', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
              const SizedBox(height: 6),
              Row(
                children: _tiers.map((tier) {
                  final selected = tier.xp == _xpTier;
                  final isLast = tier.xp == 50;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _xpTier = tier.xp),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.only(right: isLast ? 0 : 8),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? tier.color : AppColors.bgDeep,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? Colors.transparent : Colors.white.withOpacity(.06),
                            width: 2,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: tier.color.withOpacity(.3), offset: const Offset(0, 3))]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text('+${tier.xp}', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text(
                              tier.label,
                              style: GoogleFonts.nunito(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: selected ? Colors.white : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              PuffyButton(
                label: _isSubmitting
                    ? (widget.editIndex != null ? 'Saving…' : 'Adding…')
                    : (widget.editIndex != null ? 'SAVE CHANGES' : 'ADD QUEST'),
                color: AppColors.pink,
                onTap: _isSubmitting ? null : _submit,
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const _SheetField({required this.label, required this.hint, required this.controller, this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.nunito(fontSize: 14, color: AppColors.muted.withOpacity(.5)),
            filled: true,
            fillColor: AppColors.bgDeep,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border, width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(.08), width: 2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.violet, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.red, width: 2)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.red, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ],
    );
  }
}
