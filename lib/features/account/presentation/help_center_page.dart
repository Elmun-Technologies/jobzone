import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  int _catIndex = 0;

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: JzTopBar(title: l.helpCenter),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l.search,
                    hintStyle: context.text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
            ),
            TabBar(
              controller: _tab,
              indicatorColor: colors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: colors.primary,
              unselectedLabelColor: colors.textSecondary,
              labelStyle: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: context.text.titleSmall,
              tabs: [
                Tab(text: l.faq),
                Tab(text: l.contactUs),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _FaqTab(
                    catIndex: _catIndex,
                    onCatChanged: (i) => setState(() => _catIndex = i),
                  ),
                  const _ContactTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FAQ ─────────────────────────────────────────────────────────────────────

class _FaqTab extends StatelessWidget {
  const _FaqTab({required this.catIndex, required this.onCatChanged});
  final int catIndex;
  final ValueChanged<int> onCatChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cats = [
      l.faqCatAll,
      l.faqCatServices,
      l.faqCatGeneral,
      l.faqCatAccount,
    ];
    final faqs = [
      (l.faqQ1, l.faqA1),
      (l.faqQ2, l.faqA2),
      (l.faqQ3, l.faqA3),
      (l.faqQ4, l.faqA4),
      (l.faqQ5, l.faqA5),
      (l.faqQ6, l.faqA6),
      (l.faqQ7, l.faqA7),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cats.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => _CatChip(
              label: cats[i],
              selected: catIndex == i,
              onTap: () => onCatChanged(i),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final (q, a) in faqs) _AccordionCard(question: q, answer: a),
      ],
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Text(
          label,
          style: context.text.labelMedium?.copyWith(
            color: selected ? Colors.white : colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AccordionCard extends StatelessWidget {
  const _AccordionCard({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          title: Text(
            question,
            style: context.text.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          iconColor: colors.textSecondary,
          collapsedIconColor: colors.textSecondary,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  answer,
                  style: context.text.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Contact Us ───────────────────────────────────────────────────────────────

class _ContactTab extends StatelessWidget {
  const _ContactTab();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Real channels only — the old list carried a US phone number and fake
    // social handles. Extend as official accounts are registered.
    final items = [
      (Icons.headset_mic_rounded, l.customerService, 'support@yollla.uz'),
      (Icons.language_rounded, l.websiteLabel, 'https://www.yollla.uz'),
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      children: [
        for (final (icon, label, detail) in items)
          _ContactCard(icon: icon, label: label, detail: detail),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.detail,
  });
  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: CircleAvatar(
            backgroundColor: colors.primary,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          title: Text(label, style: context.text.bodyLarge),
          iconColor: colors.textSecondary,
          collapsedIconColor: colors.textSecondary,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                72,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(detail, style: context.text.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
