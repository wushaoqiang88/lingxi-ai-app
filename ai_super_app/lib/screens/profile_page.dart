import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/modules.dart';
import '../l10n/app_strings.dart';
import '../services/api_client.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Future<Map<String, dynamic>> _providerFuture;

  @override
  void initState() {
    super.initState();
    _providerFuture = const ApiClient().provider();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profile,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.text(
                          '管理 AI 模型、会员与设置',
                          'Manage AI models, plans, and settings',
                        ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: _providerFuture,
            builder: (context, snapshot) {
              final provider =
                  snapshot.data?['provider']?.toString() ??
                  l10n.text('检测中', 'Checking');
              final model =
                  snapshot.data?['model']?.toString() ??
                  l10n.text('等待后端响应', 'Waiting for backend');
              final hasKey = snapshot.data?['has_api_key'] == true
                  ? l10n.text('Key 已配置', 'Key configured')
                  : l10n.text('Key 未配置', 'Key missing');
              final value = snapshot.hasError
                  ? l10n.text(
                      '无法连接后端，点此诊断',
                      'Backend unreachable. Tap to diagnose',
                    )
                  : '$provider / $model / $hasKey';
              return ProfileActionCard(
                icon: Icons.hub_outlined,
                title: l10n.text('AI 模型', 'AI Model'),
                value: value,
                onTap: () =>
                    openProfilePage(context, const BackendStatusPage()),
              );
            },
          ),
          ProfileActionCard(
            icon: Icons.workspace_premium_outlined,
            title: l10n.text('会员方案', 'Plans'),
            value: l10n.text(
              '选择计划、查看额度、保存当前会员状态',
              'Choose plans, view quota, and save membership status',
            ),
            onTap: () => openProfilePage(context, const MembershipPage()),
          ),
          ProfileActionCard(
            icon: Icons.task_alt_outlined,
            title: l10n.text('任务中心', 'Task Center'),
            value: l10n.text(
              '跟踪修图、试衣、简历、学习等模块任务',
              'Track image, outfit, resume, and study tasks',
            ),
            onTap: () => openProfilePage(context, const TaskCenterPage()),
          ),
          ProfileActionCard(
            icon: Icons.folder_copy_outlined,
            title: l10n.text('素材库', 'Asset Library'),
            value: l10n.text(
              '保存文本、图片、分享卡片素材记录',
              'Save text, images, and share card assets',
            ),
            onTap: () => openProfilePage(context, const AssetLibraryPage()),
          ),
          ProfileActionCard(
            icon: Icons.local_fire_department_outlined,
            title: l10n.text('增长系统', 'Growth'),
            value: l10n.text(
              '每日签到、灵感值、邀请口令',
              'Daily check-ins, inspiration points, and invite codes',
            ),
            onTap: () => openProfilePage(context, const GrowthPage()),
          ),
          ProfileActionCard(
            icon: Icons.settings_ethernet_outlined,
            title: l10n.text('后端接口', 'Backend API'),
            value: apiBaseUrl,
            onTap: () => openProfilePage(context, const BackendStatusPage()),
          ),
        ],
      ),
    );
  }
}

class ProfileActionCard extends StatelessWidget {
  const ProfileActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MembershipPage extends StatefulWidget {
  const MembershipPage({super.key});

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  static const storageKey = 'profile.membership.plan';
  final plans = const [
    Plan('free', '体验版', '适合轻量试用', '每日 10 次 AI 调用', '分享卡片带本地保存'),
    Plan('pro', 'Pro', '适合高频创作', '每日 200 次 AI 调用', '优先模型与素材库'),
    Plan('study', '学习版', '适合作业与知识卡片', '拍题讲解 + 错题计划', '学习素材分类'),
    Plan('career', '求职版', '适合简历和面试准备', 'JD 匹配 + 面试题库', '求职素材归档'),
  ];
  String selected = 'free';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => selected = prefs.getString(storageKey) ?? 'free');
  }

  Future<void> selectPlan(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, id);
    if (!mounted) return;
    setState(() => selected = id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('会员方案已保存')));
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScaffold(
      title: '会员方案',
      children: [
        for (final plan in plans)
          PlanOptionCard(
            plan: plan,
            selected: selected == plan.id,
            onTap: () => selectPlan(plan.id),
          ),
      ],
    );
  }
}

class TaskCenterPage extends StatefulWidget {
  const TaskCenterPage({super.key});

  @override
  State<TaskCenterPage> createState() => _TaskCenterPageState();
}

class PlanOptionCard extends StatelessWidget {
  const PlanOptionCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final Plan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan.summary,
                      style: const TextStyle(color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    Text(plan.quota),
                    Text(plan.benefit),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCenterPageState extends State<TaskCenterPage> {
  static const storageKey = 'profile.tasks.done';
  Set<String> done = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => done = prefs.getStringList(storageKey)?.toSet() ?? {});
  }

  Future<void> toggle(String id, bool checked) async {
    final next = {...done};
    checked ? next.add(id) : next.remove(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(storageKey, next.toList());
    if (!mounted) return;
    setState(() => done = next);
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScaffold(
      title: '任务中心',
      children: [
        MetricBand(
          label: '今日完成',
          value: '${done.length} / ${modules.length}',
          detail: '勾选后会本地保存',
        ),
        for (final module in modules)
          Card(
            child: CheckboxListTile(
              value: done.contains(module.id),
              onChanged: (value) => toggle(module.id, value ?? false),
              secondary: Icon(module.icon, color: module.color),
              title: Text(
                '${module.name} · ${module.actions.first}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(module.tagline),
            ),
          ),
      ],
    );
  }
}

class AssetLibraryPage extends StatefulWidget {
  const AssetLibraryPage({super.key});

  @override
  State<AssetLibraryPage> createState() => _AssetLibraryPageState();
}

class _AssetLibraryPageState extends State<AssetLibraryPage> {
  static const storageKey = 'profile.assets';
  final titleController = TextEditingController();
  final noteController = TextEditingController();
  String type = '文本';
  List<Map<String, dynamic>> assets = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(storageKey) ?? [];
    if (!mounted) return;
    setState(
      () => assets = raw
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList(),
    );
  }

  Future<void> save() async {
    final title = titleController.text.trim();
    if (title.isEmpty) return;
    final item = {
      'title': title,
      'type': type,
      'note': noteController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    final next = [item, ...assets];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(storageKey, next.map(jsonEncode).toList());
    titleController.clear();
    noteController.clear();
    if (!mounted) return;
    setState(() => assets = next);
  }

  Future<void> remove(int index) async {
    final next = [...assets]..removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(storageKey, next.map(jsonEncode).toList());
    if (!mounted) return;
    setState(() => assets = next);
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScaffold(
      title: '素材库',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '登记素材',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '文本', label: Text('文本')),
                    ButtonSegment(value: '图片', label: Text('图片')),
                    ButtonSegment(value: '卡片', label: Text('卡片')),
                  ],
                  selected: {type},
                  onSelectionChanged: (values) =>
                      setState(() => type = values.first),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '素材标题'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: '备注'),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('保存素材'),
                ),
              ],
            ),
          ),
        ),
        if (assets.isEmpty) const EmptyHint(text: '还没有素材，先保存一条文本、图片或分享卡片记录。'),
        for (var index = 0; index < assets.length; index++)
          Card(
            child: ListTile(
              leading: Icon(
                assetIcon(assets[index]['type'].toString()),
                color: const Color(0xFF2563EB),
              ),
              title: Text(
                assets[index]['title'].toString(),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${assets[index]['type']} · ${assets[index]['note'] ?? ''}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => remove(index),
              ),
            ),
          ),
      ],
    );
  }
}

class GrowthPage extends StatefulWidget {
  const GrowthPage({super.key});

  @override
  State<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<GrowthPage> {
  static const pointsKey = 'profile.growth.points';
  static const checkinKey = 'profile.growth.lastCheckin';
  int points = 0;
  String lastCheckin = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      points = prefs.getInt(pointsKey) ?? 0;
      lastCheckin = prefs.getString(checkinKey) ?? '';
    });
  }

  Future<void> checkIn() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastCheckin == today) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('今天已经签到过')));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(checkinKey, today);
    await prefs.setInt(pointsKey, points + 10);
    if (!mounted) return;
    setState(() {
      lastCheckin = today;
      points += 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    const inviteCode = 'LINGXI-2026';
    return ProfileScaffold(
      title: '增长系统',
      children: [
        MetricBand(label: '灵感值', value: '$points', detail: '每日签到 +10'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.today_outlined, color: Color(0xFF2563EB)),
            title: const Text(
              '每日签到',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(lastCheckin.isEmpty ? '还未签到' : '上次签到：$lastCheckin'),
            trailing: FilledButton(onPressed: checkIn, child: const Text('签到')),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.ios_share_outlined,
              color: Color(0xFF2563EB),
            ),
            title: const Text(
              '邀请口令',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text(inviteCode),
            trailing: IconButton(
              icon: const Icon(Icons.copy_outlined),
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(text: inviteCode));
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('邀请口令已复制')));
              },
            ),
          ),
        ),
      ],
    );
  }
}

class BackendStatusPage extends StatefulWidget {
  const BackendStatusPage({super.key});

  @override
  State<BackendStatusPage> createState() => _BackendStatusPageState();
}

class _BackendStatusPageState extends State<BackendStatusPage> {
  final controller = TextEditingController(text: apiBaseUrl);
  Future<Map<String, dynamic>>? future;

  @override
  void initState() {
    super.initState();
    future = const ApiClient().provider();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void testUrl() {
    final baseUrl = controller.text.trim();
    setState(() => future = ApiClient(baseUrl: baseUrl).provider());
  }

  void saveUrl() {
    final baseUrl = controller.text.trim();
    saveApiUrl(baseUrl);
    testUrl();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('地址已保存，下次启动生效')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScaffold(
      title: '后端诊断',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: '接口地址'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: testUrl,
                      icon: const Icon(Icons.wifi_find_outlined),
                      label: const Text('测试连接'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: saveUrl,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('保存地址'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const MetricBand(
                label: '连接状态',
                value: '检测中',
                detail: '正在请求后端',
              );
            }
            if (snapshot.hasError) {
              return MetricBand(
                label: '连接状态',
                value: '失败',
                detail: snapshot.error.toString(),
              );
            }
            final data = snapshot.data ?? {};
            return MetricBand(
              label: '连接状态',
              value: '正常',
              detail:
                  '${data['provider']} / ${data['model']} / API Key ${data['has_api_key'] == true ? '已配置' : '未配置'}',
            );
          },
        ),
      ],
    );
  }
}

class ProfileScaffold extends StatelessWidget {
  const ProfileScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: children,
        ),
      ),
    );
  }
}

class MetricBand extends StatelessWidget {
  const MetricBand({
    super.key,
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFCBD5E1))),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(detail, style: const TextStyle(color: Color(0xFFE2E8F0))),
        ],
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(text, style: const TextStyle(color: Color(0xFF64748B))),
    );
  }
}

class Plan {
  const Plan(this.id, this.name, this.summary, this.quota, this.benefit);

  final String id;
  final String name;
  final String summary;
  final String quota;
  final String benefit;
}

IconData assetIcon(String type) {
  return switch (type) {
    '图片' => Icons.image_outlined,
    '卡片' => Icons.card_membership_outlined,
    _ => Icons.text_snippet_outlined,
  };
}

void openProfilePage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}
