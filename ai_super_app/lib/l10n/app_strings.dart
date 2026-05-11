import 'package:flutter/widgets.dart';

import '../models/ai_module.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('zh'), Locale('en')];
  static const delegate = _AppStringsDelegate();

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings) ??
        const AppStrings(Locale('zh'));
  }

  bool get isEn => locale.languageCode == 'en';
  String get languageCode => isEn ? 'en' : 'zh';

  String text(String zh, String en) => isEn ? en : zh;

  String get appName => text('灵犀 AI', 'Lingxi AI');
  String get appTagline => text(
    '聊天、写作、修图、学习、求职，一个 AI 全搞定。',
    'Chat, write, edit images, study, and prepare for work in one AI app.',
  );
  String get home => text('首页', 'Home');
  String get companion => text('陪伴', 'Companion');
  String get creation => text('创作', 'Create');
  String get study => text('学习', 'Study');
  String get profile => text('我的', 'Me');
  String get frequent => text('高频入口', 'Frequent Tools');
  String modulesConnected(int count) =>
      text('已接入 $count 个模块', '$count modules connected');

  String get brainholeSpotTitle => text('灵犀脑洞', 'Idea Sparks');
  String get brainholeSpotSubtitle =>
      text('普通事物 -> 5 张奇想卡片', 'Everyday thing -> 5 idea cards');
  String get brainholeSpotBody => text(
    '输入“筷子”“电梯”“雨伞”这种日常词，它会生成离谱但可落地的故事、产品点子和分享短句。',
    'Enter an everyday word like umbrella, elevator, or mirror. It turns it into playful stories, product ideas, and shareable lines.',
  );
  String get brainholeBadge1 => text('不是聊天', 'Not a chat');
  String get brainholeBadge2 => text('创意游乐场', 'Creative playground');
  String get brainholeBadge3 => text('可生成分享卡', 'Share-ready cards');
  String get brainholeTodaySeed =>
      text('今日种子：雨伞如果有记忆？', 'Today: What if umbrellas had memories?');

  String get brainholeHeroTitle =>
      text('把日常词变成可分享的奇想卡', 'Turn ordinary words into shareable idea cards');
  String get brainholeHeroBody => text(
    '它不回答问题，它制造“如果世界偏离 1 度”的瞬间。适合写作、产品灵感、聊天破冰和朋友圈创意。',
    'It does not just answer. It creates a tiny “what if the world shifted by one degree” moment for writing, product ideas, icebreakers, and social posts.',
  );
  String get brainholeMetricCards => text('张脑洞卡', 'idea cards');
  String get brainholeMetricCall => text('次模型调用', 'model call');
  String get brainholeMetricExpand => text('可展开玩法', 'expansions');
  String get brainholePromptTitle =>
      text('今天拿什么开脑洞？', 'What should we twist today?');
  String get brainholeHint =>
      text('比如：筷子、雨伞、电梯、奶茶', 'Try: umbrella, elevator, mirror, backpack');
  String get brainholeRun => text('生成 5 张脑洞卡', 'Generate 5 Idea Cards');
  String get brainholeLoading => text(
    '正在把普通词拧出另一种宇宙...',
    'Turning an ordinary word into a stranger little world...',
  );
  String get brainholeEmpty => text(
    '输入一个越普通的词，生成结果反而越有反差。',
    'The more ordinary the word, the stronger the creative contrast.',
  );
  String get copy => text('复制', 'Copy');
  String get expand => text('展开', 'Expand');
  String get copiedIdea => text('已复制脑洞卡片', 'Idea card copied');
  String get backendMissingIdea => text(
    '《后端暂未连接》\n如果创意先在本地醒来会怎样？\n请启动 FastAPI 后再生成真实脑洞。\n可玩性：检查网络与后端服务。',
    'No backend yet\nWhat if the idea woke up locally first?\nStart FastAPI to generate real idea cards.\nPlayable angle: check network and backend service.',
  );
  String expandPrompt(String idea) => isEn
      ? 'Output in English. Expand this idea into a short story, a product concept, and a shareable line:\n$idea'
      : '请把这个脑洞扩写成短故事和产品概念：\n$idea';
  String runBrainholePrompt(String text) => isEn
      ? 'Output in English. Turn this ordinary thing into 5 imaginative idea cards: $text'
      : text;
  String expandFailed(Object error) =>
      text('展开失败：$error', 'Expansion failed: $error');

  List<String> get brainholeSeeds => isEn
      ? const [
          'Chopsticks',
          'Umbrella',
          'Elevator',
          'Milk tea',
          'Backpack',
          'Mirror',
        ]
      : const ['筷子', '雨伞', '电梯', '奶茶', '书包', '镜子'];

  String categoryLabel(String category) {
    return switch (category) {
      '陪伴' => companion,
      '创作' => creation,
      '影像' => text('影像', 'Images'),
      '学习' => study,
      '求职' => text('求职', 'Career'),
      '电台' => text('电台', 'Radio'),
      _ => category,
    };
  }

  String categorySubtitle(String category) {
    return switch (category) {
      '陪伴' => text(
        '情绪、表达、匿名倾诉都在这里。',
        'Mood, expression, and private reflection live here.',
      ),
      '学习' => text(
        '拍题、问知识、做复习计划。',
        'Solve problems, learn concepts, and plan reviews.',
      ),
      _ => text(
        '写作、修图、试衣、求职材料都能处理。',
        'Write, edit images, try outfits, and prepare career materials.',
      ),
    };
  }

  ModuleCopy module(AiModule module) =>
      _moduleCopies[module.id]?[languageCode] ??
      ModuleCopy(
        name: module.name,
        category: categoryLabel(module.category),
        tagline: module.tagline,
        actions: module.actions,
        scenarios: module.scenarios,
        placeholder: module.placeholder,
      );

  static const _moduleCopies = {
    'brainhole': {
      'zh': ModuleCopy(
        name: '灵犀脑洞',
        category: '创作',
        tagline: '把普通东西变成 5 个离谱但可落地的创意场景。',
        actions: ['五连脑洞', '故事展开', '产品概念'],
        scenarios: ['灵感卡片', '社交话题', '创意训练'],
        placeholder: '输入一个普通事物，比如：筷子、雨伞、电梯、奶茶、书包',
      ),
      'en': ModuleCopy(
        name: 'Idea Sparks',
        category: 'Create',
        tagline:
            'Turn ordinary things into 5 weird but usable creative scenarios.',
        actions: ['Five sparks', 'Story expansion', 'Product concept'],
        scenarios: ['Idea cards', 'Social prompts', 'Creative training'],
        placeholder:
            'Enter an ordinary thing, like umbrella, elevator, milk tea, or backpack',
      ),
    },
    'companion': {
      'en': ModuleCopy(
        name: 'Companion',
        category: 'Companion',
        tagline: '24/7 emotional companionship with gentle reflection.',
        actions: ['Warm chat', 'Mood summary', 'Healing advice'],
        scenarios: ['Late-night talk', 'Stress review', 'Morning check-in'],
        placeholder: 'For example: I feel tired today and want to talk',
      ),
    },
    'avatar': {
      'en': ModuleCopy(
        name: 'Persona',
        category: 'Companion',
        tagline: 'Generate replies that sound closer to your own style.',
        actions: ['Style samples', 'Reply for me', 'Social copy'],
        scenarios: ['Friend replies', 'Work messages', 'Social posts'],
        placeholder: 'Paste a message and let AI reply in your style',
      ),
    },
    'treehole': {
      'en': ModuleCopy(
        name: 'Safe Space',
        category: 'Companion',
        tagline: 'Anonymous venting, emotion naming, and release writing.',
        actions: ['Anonymous vent', 'Mood weather', 'Release text'],
        scenarios: ['Private expression', 'Emotional outlet', 'Safe notes'],
        placeholder: 'Write anything you do not want judged',
      ),
    },
    'writing': {
      'en': ModuleCopy(
        name: 'Writer',
        category: 'Create',
        tagline:
            'Draft social posts, updates, weekly reports, and emails quickly.',
        actions: ['Quick draft', 'Polish', 'Tags'],
        scenarios: ['Social posts', 'Captions', 'Weekly reports'],
        placeholder: 'For example: write a social post about an AI app',
      ),
    },
    'office_doc': {
      'en': ModuleCopy(
        name: 'Docs',
        category: 'Create',
        tagline: 'Workplace writing for notes, emails, and slide outlines.',
        actions: ['Meeting notes', 'Business email', 'Slide outline'],
        scenarios: ['Meeting recap', 'Client email', 'Project report'],
        placeholder: 'Enter meeting points to generate structured notes',
      ),
    },
    'image_fix': {
      'en': ModuleCopy(
        name: 'Retouch',
        category: 'Images',
        tagline:
            'Upload an image for real AI editing and parameter suggestions.',
        actions: ['Enhance', 'Style advice', 'ID photo'],
        scenarios: ['Selfie polish', 'Avatar style', 'ID photo'],
        placeholder: 'Describe the edit you want, like clean natural lighting',
      ),
    },
    'dressup': {
      'en': ModuleCopy(
        name: 'Dress Up',
        category: 'Images',
        tagline: 'Upload a portrait to generate outfit edits and OOTD copy.',
        actions: ['Business outfit', 'Travel look', 'Date look'],
        scenarios: ['Interview image', 'Travel outfit', 'Social OOTD'],
        placeholder: 'For example: design an interview outfit for me',
      ),
    },
    'study': {
      'en': ModuleCopy(
        name: 'Study Solver',
        category: 'Study',
        tagline:
            'Step-by-step explanations after typing or photographing questions.',
        actions: ['Photo solving', 'Essay review', 'Mistake book'],
        scenarios: ['Math solving', 'Essay polish', 'Review plan'],
        placeholder: 'Enter a question and AI will explain it step by step',
      ),
    },
    'knowledge': {
      'en': ModuleCopy(
        name: 'KnowIt',
        category: 'Study',
        tagline: 'Understand any concept and create shareable knowledge cards.',
        actions: ['Q&A', 'Daily card', 'Quiz'],
        scenarios: ['Concepts', 'Deep dives', 'Micro-learning'],
        placeholder: 'For example: what is a large language model?',
      ),
    },
    'resume': {
      'en': ModuleCopy(
        name: 'Career Fit',
        category: 'Career',
        tagline:
            'Resume scoring, JD matching, and interview practice in one place.',
        actions: ['Resume score', 'JD polish', 'Mock interview'],
        scenarios: ['New grad', 'Career change', 'Interview prep'],
        placeholder: 'Paste a resume or JD for improvement suggestions',
      ),
    },
    'career': {
      'en': ModuleCopy(
        name: 'Career Map',
        category: 'Career',
        tagline: 'Assess career direction and build a 30/60/90 day plan.',
        actions: ['Career test', 'Path plan', 'Skill gaps'],
        scenarios: ['Career confusion', 'Switching paths', 'Learning route'],
        placeholder:
            'For example: I code and create content. What career fits?',
      ),
    },
    'car_radio': {
      'zh': ModuleCopy(
        name: '灵犀电台',
        category: '陪伴',
        tagline: '上车一句话，私人 AI 音频陪你通勤。',
        actions: ['通勤播报', '情绪陪伴', '英语听力', '脑洞故事'],
        scenarios: ['上班路上', '下班放松', '堵车陪伴', '周末兜风'],
        placeholder: '说一句话开启你的私人电台，比如：来段通勤播报',
      ),
      'en': ModuleCopy(
        name: 'Lingxi Radio',
        category: 'Companion',
        tagline: 'One tap, your personal AI radio for the road.',
        actions: ['Commute brief', 'Mood radio', 'English micro', 'Idea story'],
        scenarios: ['Morning commute', 'After work', 'Traffic jam', 'Weekend drive'],
        placeholder: 'Start your personal radio, e.g.: give me a commute briefing',
      ),
    },
  };
}

class ModuleCopy {
  const ModuleCopy({
    required this.name,
    required this.category,
    required this.tagline,
    required this.actions,
    required this.scenarios,
    required this.placeholder,
  });

  final String name;
  final String category;
  final String tagline;
  final List<String> actions;
  final List<String> scenarios;
  final String placeholder;
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => ['zh', 'en'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async =>
      AppStrings(Locale(isSupported(locale) ? locale.languageCode : 'zh'));

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}

extension AppStringsContext on BuildContext {
  AppStrings get l10n => AppStrings.of(this);
}
