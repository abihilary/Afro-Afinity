import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../core/widgets/app_toast.dart';
import 'forms/about_form.dart';
import 'forms/basics_form.dart';
import 'forms/prompts_form.dart';
import 'widgets/photo_grid.dart';

/// Every field `PATCH /me` accepts, in the same forms onboarding uses.
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void saved(_) => showToast(context, 'Saved');
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          foregroundColor: Colors.white,
          title: const Text('Edit profile'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: Colors.white60,
            dividerColor: Colors.transparent,
            tabs: [Tab(text: 'Photos'), Tab(text: 'Basics'), Tab(text: 'About'), Tab(text: 'Prompts')],
          ),
        ),
        body: TabBarView(children: [
          ListView(padding: const EdgeInsets.all(20), children: const [
            PhotoGrid(),
            SizedBox(height: 12),
            Text('Changes save as you make them. Tap a photo to make it your main picture or remove it.',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ]),
          ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 30), children: [BasicsForm(submitLabel: 'Save', onSaved: saved)]),
          ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 30), children: [AboutForm(submitLabel: 'Save', onSaved: saved, showAttributes: true)]),
          ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 30), children: [PromptsForm(submitLabel: 'Save', onSaved: saved)]),
        ]),
      ),
    );
  }
}
