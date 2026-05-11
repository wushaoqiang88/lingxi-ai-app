# AI 超级 App 详细设计方案

> 目标：把 11 个 AI App 能力集成到 1 个统一产品中，形成高频、高传播、多场景、可订阅变现的 AI 工具与陪伴平台。

---

## 1. 产品总定位

### 1.1 产品名称建议

| 名称 | 定位感 | 适合方向 |
|---|---|---|
| 灵犀 AI | 亲和、聪明、陪伴感强 | 大众 AI 助手 |
| 万能 AI 助手 | 直接、搜索友好 | 工具型获客 |
| 小灵 AI | 轻量、好记、人格化 | 陪伴 + 工具 |
| AI 百宝箱 | 功能集合感强 | 工具集合 |
| Muse AI | 国际化、创作感 | 海外市场 |

推荐：**灵犀 AI**

一句话定位：

> 一个会陪你、帮你写、帮你修图、帮你学习、帮你求职的全能 AI 生活助手。

### 1.2 核心产品逻辑

这个产品不是把 11 个 App 简单堆在一起，而是抽象成 5 个高频入口：

1. **陪伴**：AI 情感陪伴、数字分身、匿名树洞
2. **创作**：万能写作、职场写作
3. **影像**：AI 修图、虚拟试衣
4. **学习**：拍照解题、知识问答
5. **求职**：简历优化、模拟面试、职业规划

底层统一：账号、会员、AI 调用、素材库、任务中心、历史记录、分享系统、支付系统、风控系统。

---

## 2. 一体化信息架构

### 2.1 App 底部导航

建议使用 5 个底部 Tab：

| Tab | 包含能力 | 设计目的 |
|---|---|---|
| 首页 | 今日推荐、最近使用、快捷入口 | 降低用户选择成本 |
| 陪伴 | 灵伴、分身、树洞 | 高频情绪与社交入口 |
| 创作 | 写作、职场文档、修图、试衣 | 生产力与传播入口 |
| 学习 | 解题、作文、口语、知识问答 | 学生与知识用户入口 |
| 我的 | 会员、历史、素材、设置 | 账号与商业化入口 |

求职功能可以放在首页快捷入口和“创作/学习”之间，也可以在首页设置“求职季”专区。第一版不建议底部单独给求职 Tab，因为求职是阶段性高频，不如陪伴、创作、学习稳定。

### 2.2 首页结构

首页目标：让用户 3 秒内知道能做什么，并直接开始。

页面结构：

1. 顶部问候：`晚上好，今天想让 AI 帮你做什么？`
2. 全局输入框：支持文字、图片、语音、文件
3. 智能意图识别：输入后自动分发到对应模块
4. 常用快捷卡片：写文案、修照片、拍题、聊一聊、优化简历
5. 最近任务：继续未完成的图片处理、文章、简历、聊天
6. 今日灵感：可分享的卡片、模板、热门玩法

### 2.3 全局输入分发

用户不需要先选模块，可以直接输入：

| 用户输入 | 自动分发 |
|---|---|
| 上传自拍 | 秒修 / 换装 |
| 拍一道数学题 | 解题侠 |
| “帮我写小红书文案” | 妙笔 |
| “我今天很难受” | 灵伴 / 树洞 |
| 上传简历 + JD | 职达 |
| “我适合什么职业” | 职画 |
| “帮我回这条消息” | 分身 |

意图识别服务输出结构：

```json
{
  "intent": "resume_optimize",
  "module": "jobpro",
  "confidence": 0.93,
  "required_inputs": ["resume_file", "job_description"],
  "next_action": "open_resume_match_flow"
}
```

---

## 3. 总体技术架构

### 3.1 客户端技术选型

MVP 推荐：**Flutter**

理由：

1. 一套代码同时做 iOS / Android，开发速度快
2. 图片、音频、聊天、编辑器、表单都能覆盖
3. 后续海外版复用成本低
4. 对小团队更友好

关键插件：

| 能力 | Flutter 插件 |
|---|---|
| 状态管理 | riverpod / bloc |
| 网络请求 | dio |
| 本地数据库 | drift / sqlite |
| 图片选择 | image_picker |
| 相机 | camera |
| 文件选择 | file_picker |
| 录音 | record |
| 播放 | just_audio |
| 富文本编辑 | appflowy_editor / flutter_quill |
| 支付 | in_app_purchase |
| 推送 | firebase_messaging |
| 埋点 | firebase_analytics / 自建埋点 |

### 3.2 后端技术选型

MVP 推荐：**FastAPI + PostgreSQL + Redis + S3/OSS + Celery**

| 层级 | 技术 |
|---|---|
| API 服务 | Python FastAPI |
| 数据库 | PostgreSQL |
| 缓存 | Redis |
| 队列 | Celery + Redis / RabbitMQ |
| 文件存储 | 阿里云 OSS / AWS S3 |
| AI 网关 | 自建 AI Gateway |
| 图片推理 | Replicate / Fal.ai / 自建 GPU 服务 |
| 日志监控 | Sentry + Grafana |

### 3.3 统一服务拆分

```text
Client App
  -> API Gateway
    -> Auth Service              账号、登录、设备、权限
    -> User Profile Service      用户画像、偏好、成长记录
    -> AI Gateway                LLM、视觉模型、语音模型统一调度
    -> Intent Router             全局输入意图识别
    -> Conversation Service      聊天、上下文、记忆
    -> Creation Service          写作、文档、分享卡片
    -> Image Service             修图、换装、证件照、任务队列
    -> Learning Service          解题、作文、知识问答、错题本
    -> Career Service            简历、面试、职业规划
    -> Payment Service           订阅、积分、用量
    -> Growth Service            分享、邀请码、裂变活动
    -> Notification Service      推送、提醒、打卡
```

### 3.4 AI Gateway 设计

统一 AI 网关非常重要，避免每个模块单独接模型导致成本失控。

核心职责：

1. 多模型路由：GPT-4o、Claude、Gemini、DeepSeek、本地模型
2. 成本控制：按用户等级、任务类型、模型成本动态分配
3. Prompt 模板管理：所有模块 Prompt 版本化
4. 内容安全：输入输出审核
5. 流式输出：聊天、写作、面试实时返回
6. 失败降级：主模型失败自动切换备用模型
7. 用量统计：按用户、模块、任务记录 token 和费用

模型路由策略：

| 任务 | 推荐模型 |
|---|---|
| 情感陪伴 | Claude / GPT-4o |
| 普通写作 | DeepSeek / GPT-4o mini |
| 简历优化 | GPT-4o / Claude |
| 解题推理 | GPT-4o / Gemini |
| 图片理解 | GPT-4o Vision / Gemini Vision |
| 修图生成 | SDXL / Flux / ControlNet |
| 语音识别 | Whisper |
| 语音合成 | ElevenLabs / Azure TTS |

---

## 4. 统一数据库核心设计

### 4.1 用户与会员

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(32) UNIQUE,
    email VARCHAR(128) UNIQUE,
    nickname VARCHAR(64),
    avatar_url TEXT,
    locale VARCHAR(16) DEFAULT 'zh-CN',
    timezone VARCHAR(64),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    plan VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL,
    started_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    platform VARCHAR(32),
    original_transaction_id VARCHAR(128),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE usage_quotas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    module VARCHAR(32),
    quota_date DATE DEFAULT CURRENT_DATE,
    free_count INT DEFAULT 0,
    paid_count INT DEFAULT 0,
    token_used INT DEFAULT 0,
    cost_cents INT DEFAULT 0,
    UNIQUE(user_id, module, quota_date)
);
```

### 4.2 任务中心

所有长任务统一进入任务表：修图、换装、简历导出、长文生成、作业识别等。

```sql
CREATE TABLE ai_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    module VARCHAR(32) NOT NULL,
    task_type VARCHAR(64) NOT NULL,
    status VARCHAR(32) DEFAULT 'queued',
    input JSONB,
    output JSONB,
    progress INT DEFAULT 0,
    error_message TEXT,
    cost_cents INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);
```

### 4.3 素材与历史

```sql
CREATE TABLE assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    asset_type VARCHAR(32),
    file_url TEXT NOT NULL,
    thumbnail_url TEXT,
    mime_type VARCHAR(64),
    size_bytes BIGINT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE user_histories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    module VARCHAR(32),
    entity_type VARCHAR(32),
    entity_id UUID,
    title VARCHAR(256),
    summary TEXT,
    cover_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 4.4 分享增长

```sql
CREATE TABLE share_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    module VARCHAR(32),
    card_type VARCHAR(64),
    image_url TEXT,
    share_text TEXT,
    landing_url TEXT,
    view_count INT DEFAULT 0,
    signup_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE invite_relations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inviter_id UUID REFERENCES users(id),
    invitee_id UUID REFERENCES users(id),
    invite_code VARCHAR(32),
    reward_granted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

# 5. 11 个模块详细设计

---

## 5.1 灵伴 SoulMate 模块

### 模块目标

让用户形成每日聊天习惯，承担情绪陪伴、减压、复盘、早晚安触达。

### 核心页面

| 页面 | 功能 |
|---|---|
| 陪伴首页 | 人格卡片、最近对话、今日心情 |
| 聊天页 | 流式对话、语音输入、表情回应 |
| 人格选择页 | 温柔姐姐、理性导师、搞笑朋友、毒舌闺蜜 |
| 心情日记页 | 每日心情曲线、AI 总结 |
| 疗愈页 | 呼吸练习、音乐、安慰话术 |

### 核心流程

```text
打开陪伴 Tab
  -> 选择人格 / 默认上次人格
  -> 用户输入文字或语音
  -> 情绪识别
  -> 读取用户记忆与最近上下文
  -> AI Gateway 调用陪伴模型
  -> 流式回复
  -> 自动生成心情标签
  -> 晚间生成今日心情日记
```

### 详细数据表

```sql
CREATE TABLE companion_personas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(64),
    role_label VARCHAR(64),
    avatar_url TEXT,
    system_prompt TEXT,
    voice_id VARCHAR(64),
    tags TEXT[],
    is_premium BOOLEAN DEFAULT FALSE
);

CREATE TABLE companion_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    persona_id UUID REFERENCES companion_personas(id),
    title VARCHAR(128),
    summary TEXT,
    last_message_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE companion_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES companion_sessions(id),
    user_id UUID REFERENCES users(id),
    role VARCHAR(16),
    content TEXT,
    emotion VARCHAR(32),
    sentiment_score FLOAT,
    token_used INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE companion_memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    memory_type VARCHAR(32),
    content TEXT,
    importance INT DEFAULT 1,
    source_message_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Prompt 设计

```text
你是用户选择的 AI 陪伴人格：{persona_name}。
你的说话风格：{persona_style}。
用户长期记忆：{memories}。
用户今天的情绪：{today_mood}。
最近对话摘要：{session_summary}。

要求：
1. 先共情，再回应。
2. 不要说教，不要机械列清单。
3. 如果检测到极端风险，温柔建议用户联系可信任的人或专业热线。
4. 回复控制在 80-180 字，除非用户要求详细聊。
```

### MVP 边界

第一版只做：文字聊天、3 个预设人格、心情标签、每日总结、分享心情卡片。

---

## 5.2 分身 Avatar 模块

### 模块目标

学习用户表达风格，帮助生成“像我说的话”，用于回消息、朋友圈、小红书、邮件。

### 核心页面

| 页面 | 功能 |
|---|---|
| 分身首页 | 我的分身、训练进度、快捷生成 |
| 风格训练页 | 输入 20 条自己的表达样本 |
| 代回消息页 | 粘贴对方消息，生成 3 种回复 |
| 朋友圈生成页 | 输入事件/图片，生成用户风格文案 |
| 风格报告页 | 高频词、语气、emoji 偏好 |

### 核心流程

```text
用户创建分身
  -> 输入样本文本 / 粘贴历史聊天
  -> 本地隐私提醒和脱敏
  -> 风格分析服务提取特征
  -> 生成 style_profile
  -> 用户测试“像不像我”
  -> 保存为分身配置
```

### 风格画像结构

```json
{
  "tone": "轻松幽默",
  "sentence_length": "short",
  "emoji_level": "medium",
  "punctuation_style": "多用省略号和感叹号",
  "common_phrases": ["哈哈哈", "救命", "我真的会谢"],
  "avoid_words": ["亲", "宝子"],
  "reply_strategy": "先接住情绪，再给轻松回应"
}
```

### 数据表

```sql
CREATE TABLE avatars (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    name VARCHAR(64),
    style_profile JSONB,
    sample_count INT DEFAULT 0,
    status VARCHAR(32) DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE avatar_samples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    avatar_id UUID REFERENCES avatars(id),
    content TEXT,
    scene VARCHAR(32),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE avatar_generations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    avatar_id UUID REFERENCES avatars(id),
    input_text TEXT,
    output_options JSONB,
    selected_index INT,
    rating INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### MVP 边界

第一版不导入微信聊天记录，避免隐私与平台风险。只支持用户手动输入样本，生成代回消息和朋友圈文案。

---

## 5.3 树洞 TreeHole 模块

### 模块目标

提供更隐私、更安全、更轻量的倾诉空间。区别于灵伴：树洞强调匿名、焚烧、无压力表达。

### 核心页面

| 页面 | 功能 |
|---|---|
| 树洞首页 | 开始倾诉、焚烧记录、情绪天气 |
| 倾诉页 | 极简输入、AI 温柔回应 |
| 焚烧页 | 对话销毁动画和确认 |
| 情绪天气页 | 今日情绪可视化卡片 |

### 隐私策略

1. 默认不保存原文到云端
2. 本地加密存储
3. 用户可一键焚烧
4. 服务端只存匿名情绪统计
5. 极端风险只展示求助建议，不做社交扩散

### 数据表

服务端只保存匿名摘要：

```sql
CREATE TABLE treehole_anonymous_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    anonymous_hash VARCHAR(128),
    emotion VARCHAR(32),
    risk_level VARCHAR(32),
    message_length INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

本地 SQLite：

```sql
CREATE TABLE local_treehole_entries (
    id TEXT PRIMARY KEY,
    encrypted_text BLOB,
    emotion TEXT,
    is_burned INTEGER DEFAULT 0,
    created_at TEXT
);
```

### MVP 边界

第一版做：匿名倾诉、焚烧、本地记录、情绪天气卡片。

---

## 5.4 妙笔 MiaoWrite 模块

### 模块目标

成为用户最高频使用的创作工具，覆盖小红书、朋友圈、短视频脚本、工作总结、情书、道歉、邮件。

### 核心页面

| 页面 | 功能 |
|---|---|
| 写作首页 | 模板分类、最近文章、闪写输入 |
| 闪写页 | 关键词生成完整文案 |
| 模板页 | 小红书、朋友圈、周报、邮件、故事 |
| 编辑页 | AI 续写、改写、扩写、缩写、换风格 |
| 分享页 | 生成图片卡片、复制文案 |

### 写作任务类型

| 类型 | 输入 | 输出 |
|---|---|---|
| 闪写 | 关键词 | 完整文章 |
| 小红书 | 图片 + 卖点 | 标题 + 正文 + 标签 |
| 朋友圈 | 场景 + 情绪 | 短文案 |
| 改写 | 原文 + 风格 | 新版本 |
| 续写 | 开头 | 后续内容 |
| 总结 | 长文本 | 摘要 |

### 数据表

```sql
CREATE TABLE write_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(64),
    name VARCHAR(128),
    description TEXT,
    prompt_template TEXT,
    input_schema JSONB,
    output_schema JSONB,
    is_premium BOOLEAN DEFAULT FALSE,
    sort_order INT DEFAULT 0
);

CREATE TABLE write_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    template_id UUID REFERENCES write_templates(id),
    title VARCHAR(256),
    content TEXT,
    style VARCHAR(64),
    status VARCHAR(32) DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### MVP 边界

第一版重点做小红书文案、朋友圈文案、周报、邮件、改写润色。这是最容易传播和变现的模块。

---

## 5.5 快文 QuickDoc 模块

### 模块目标

服务职场用户，提供更正式、更结构化的办公文档生成。

### 核心页面

| 页面 | 功能 |
|---|---|
| 职场写作首页 | 公文、邮件、会议纪要、PPT 大纲 |
| 表单生成页 | 按结构填写背景信息 |
| 文档编辑页 | 正式程度、长度、语气调整 |
| 导出页 | Markdown、PDF、Word |

### 文档类型

1. 通知
2. 会议纪要
3. 项目方案
4. 工作总结
5. 年终总结
6. 商务邮件
7. 催办邮件
8. PPT 大纲

### 数据表

```sql
CREATE TABLE office_doc_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doc_type VARCHAR(64),
    name VARCHAR(128),
    structure JSONB,
    prompt_template TEXT,
    export_formats TEXT[] DEFAULT ARRAY['markdown','pdf'],
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE office_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    doc_type VARCHAR(64),
    title VARCHAR(256),
    content TEXT,
    form_input JSONB,
    exported_asset_id UUID REFERENCES assets(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### MVP 边界

第一版只做：邮件、周报、会议纪要、PPT 大纲。暂不做复杂 Word 排版。

---

## 5.6 秒修 SnapFix 模块

### 模块目标

提供强传播的图像处理能力，用“前后对比”带动自然分享。

### 核心页面

| 页面 | 功能 |
|---|---|
| 修图首页 | 一键美化、风格转换、换背景、证件照 |
| 图片编辑页 | 预览、对比、参数调整 |
| 任务进度页 | 生成中、队列位置 |
| 结果页 | 下载、去水印、分享对比图 |

### 功能优先级

| 优先级 | 功能 | 原因 |
|---|---|---|
| P0 | 一键美化 | 高频、成本低 |
| P0 | 风格转换 | 传播强 |
| P1 | 证件照 | 刚需变现 |
| P1 | 换背景 | 实用 |
| P2 | 老照片修复 | 情感传播 |
| P2 | 超分辨率 | 成本较高 |

### 任务流程

```text
用户上传图片
  -> 客户端压缩与裁剪
  -> 创建 ai_tasks
  -> 上传 OSS
  -> Image Worker 拉取任务
  -> 调用模型服务
  -> 生成结果图和缩略图
  -> 写入 assets
  -> 推送任务完成
```

### 数据表

```sql
CREATE TABLE image_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    task_id UUID REFERENCES ai_tasks(id),
    image_type VARCHAR(64),
    input_asset_id UUID REFERENCES assets(id),
    output_asset_id UUID REFERENCES assets(id),
    params JSONB,
    watermark BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE image_styles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(64),
    cover_url TEXT,
    model_provider VARCHAR(64),
    prompt TEXT,
    negative_prompt TEXT,
    is_premium BOOLEAN DEFAULT FALSE
);
```

### MVP 边界

第一版先接第三方模型 API，避免自建 GPU。上线验证后再自建推理服务降低成本。

---

## 5.7 换装 DressUp AI 模块

### 模块目标

让用户上传自拍后快速体验不同穿搭，适合小红书传播和电商导购。

### 核心页面

| 页面 | 功能 |
|---|---|
| 试衣首页 | 上传人像、选择风格 |
| 衣橱页 | 上衣、裙装、职业装、国风、礼服 |
| 生成页 | 试穿进度 |
| 搭配建议页 | AI 评价、购买建议、分享 OOTD |

### 详细流程

```text
上传全身/半身照
  -> 检测人体姿态和衣服区域
  -> 选择衣服模板
  -> 虚拟试穿模型生成结果
  -> AI 生成穿搭点评
  -> 一键生成小红书 OOTD 文案
```

### 数据表

```sql
CREATE TABLE dressup_clothes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(64),
    style VARCHAR(64),
    name VARCHAR(128),
    image_asset_id UUID REFERENCES assets(id),
    mask_asset_id UUID REFERENCES assets(id),
    tags TEXT[],
    shop_url TEXT,
    is_premium BOOLEAN DEFAULT FALSE
);

CREATE TABLE dressup_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    person_asset_id UUID REFERENCES assets(id),
    clothes_id UUID REFERENCES dressup_clothes(id),
    result_asset_id UUID REFERENCES assets(id),
    ai_comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### MVP 边界

第一版只做固定服装库，不做用户上传衣服；先覆盖职业装、约会装、旅行装、证件形象照。

---

## 5.8 解题侠 SolveHero 模块

### 模块目标

不只给答案，而是通过分步讲解和苏格拉底模式提升信任度与教育价值。

### 核心页面

| 页面 | 功能 |
|---|---|
| 学习首页 | 拍照解题、作文批改、口语陪练、错题本 |
| 拍题页 | 拍照、裁剪、识别 |
| 解题页 | 分步过程、追问、举一反三 |
| 错题本 | 按科目、知识点复习 |
| 学习报告 | 每周学习情况 |

### 解题流程

```text
拍题
  -> OCR / Vision 模型识别
  -> 学科分类
  -> 题型判断
  -> 解题模型生成标准答案
  -> 生成讲解步骤
  -> 判断是否开启苏格拉底模式
  -> 保存错题和知识点
```

### 数据表

```sql
CREATE TABLE study_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    subject VARCHAR(64),
    grade VARCHAR(64),
    question_text TEXT,
    image_asset_id UUID REFERENCES assets(id),
    answer TEXT,
    solution_steps JSONB,
    knowledge_points TEXT[],
    difficulty INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE wrong_book_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    question_id UUID REFERENCES study_questions(id),
    wrong_reason TEXT,
    review_stage INT DEFAULT 0,
    next_review_at TIMESTAMPTZ,
    mastered BOOLEAN DEFAULT FALSE
);

CREATE TABLE essay_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    title VARCHAR(256),
    content TEXT,
    score INT,
    feedback JSONB,
    improved_version TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### MVP 边界

第一版做数学拍题、英语作文批改、错题本。口语陪练放第二版。

---

## 5.9 知了 ZhiLe 模块

### 模块目标

把知识问答做成轻量、好玩、可分享的每日学习入口。

### 核心页面

| 页面 | 功能 |
|---|---|
| 问答页 | 任意提问，图文解释 |
| 知识卡片页 | 每日一个知识点 |
| 闯关页 | 选择题、判断题、排行榜 |
| 知识图谱页 | 概念关系可视化 |

### RAG 流程

```text
用户提问
  -> 意图与领域分类
  -> 向量数据库检索相关知识
  -> LLM 基于检索内容回答
  -> 生成 3 个延伸问题
  -> 可生成分享知识卡片
```

### 数据表

```sql
CREATE TABLE knowledge_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(64),
    title VARCHAR(256),
    content TEXT,
    source_url TEXT,
    embedding_key VARCHAR(128),
    difficulty INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE quiz_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    category VARCHAR(64),
    score INT,
    correct_count INT,
    total_count INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### MVP 边界

第一版不做复杂知识图谱，只做问答、每日卡片、简单闯关。

---

## 5.10 职达 JobPro 模块

### 模块目标

帮助用户从“没有简历”到“拿到面试”，覆盖简历生成、JD 匹配、模拟面试、求职追踪。

### 核心页面

| 页面 | 功能 |
|---|---|
| 求职首页 | 简历评分、优化、模拟面试 |
| 简历编辑器 | 模块化填写、AI 改写经历 |
| JD 匹配页 | 粘贴 JD，生成匹配度和优化建议 |
| 模拟面试页 | AI 面试官提问和评分 |
| 投递追踪页 | 记录公司、状态、提醒 |

### 简历优化流程

```text
上传/填写简历
  -> 解析结构化数据
  -> AI 评分
  -> 粘贴目标 JD
  -> 提取 JD 关键词
  -> 对比缺口
  -> 生成优化建议
  -> 一键改写项目经历
  -> 导出 PDF
```

### 数据表

```sql
CREATE TABLE resumes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    title VARCHAR(256),
    structured_content JSONB,
    raw_text TEXT,
    score INT,
    template_id UUID,
    pdf_asset_id UUID REFERENCES assets(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE resume_jd_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resume_id UUID REFERENCES resumes(id),
    jd_text TEXT,
    company VARCHAR(128),
    position VARCHAR(128),
    match_score INT,
    missing_keywords TEXT[],
    suggestions JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE interview_practices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    position VARCHAR(128),
    questions JSONB,
    answers JSONB,
    report JSONB,
    overall_score INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### MVP 边界

第一版做：简历生成、简历评分、JD 匹配、PDF 导出。模拟面试第二版强化。

---

## 5.11 职画 CareerMap 模块

### 模块目标

帮助用户进行职业方向探索，适合学生、转行者、迷茫职场人。

### 核心页面

| 页面 | 功能 |
|---|---|
| 职业测试页 | MBTI/霍兰德/价值观问卷 |
| 结果报告页 | 适合职业、优势、风险 |
| 职业路径页 | 从当前状态到目标岗位 |
| 技能差距页 | 缺什么、怎么学 |
| 分享报告页 | 生成职业人格卡片 |

### 流程

```text
完成测试
  -> 结合用户学历、经验、兴趣
  -> 生成职业画像
  -> 匹配职业库
  -> 输出 3 条推荐路径
  -> 给出 30/60/90 天行动计划
```

### 数据表

```sql
CREATE TABLE career_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    mbti VARCHAR(8),
    holland VARCHAR(16),
    values JSONB,
    strengths TEXT[],
    report JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE career_paths (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    target_role VARCHAR(128),
    current_status TEXT,
    gap_analysis JSONB,
    action_plan JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### MVP 边界

第一版做职业测试、报告、分享卡片。路径规划第二版做深。

---

## 6. 统一会员与商业化设计

### 6.1 会员方案

| 版本 | 价格建议 | 权益 |
|---|---|---|
| 免费版 | 0 元 | 每日少量 AI 次数，结果带水印 |
| Pro 月卡 | 19.9-39.9 元/月 | 更多次数、去水印、高级模型 |
| Pro 年卡 | 198-298 元/年 | 年费折扣、专属模板 |
| 学习版 | 29.9 元/月 | 解题、作文、错题本强化 |
| 求职版 | 49.9 元/月 | 简历、JD 匹配、模拟面试 |

### 6.2 积分体系

统一用“灵感值”消耗高成本任务：

| 任务 | 消耗 |
|---|---|
| 普通聊天 | 低 |
| 文案生成 | 低 |
| 简历优化 | 中 |
| 图片风格转换 | 高 |
| 虚拟试衣 | 高 |
| 老照片修复 | 高 |

### 6.3 增长机制

1. 分享结果卡片，带下载入口
2. 邀请好友得灵感值
3. 每日签到得免费次数
4. 生成内容默认适配小红书/朋友圈/抖音
5. 每个模块都有“前后对比”或“人格报告”可分享

---

## 7. MVP 开发优先级

### 7.1 第一阶段：4-6 周上线可用版

优先做 5 个最容易形成高频和传播的能力：

1. 灵伴聊天
2. 妙笔写作
3. 秒修风格转换
4. 解题拍照
5. 简历优化

原因：覆盖情绪、内容、图片、学习、求职五类人群，可以快速验证哪个赛道最有留存和付费。

### 7.2 第二阶段：6-10 周增强

1. 数字分身
2. 树洞
3. 职场写作
4. 作文批改
5. 证件照
6. AI 面试官

### 7.3 第三阶段：10-16 周扩展

1. 虚拟试衣
2. 知识闯关
3. 职业规划
4. 口语陪练
5. 社区与模板市场

---

## 8. 开发目录建议

```text
ai_super_app/
  mobile/
    lib/
      app/
      core/
        api/
        auth/
        theme/
        router/
        analytics/
      features/
        home/
        companion/
        avatar/
        treehole/
        writing/
        office_doc/
        image_fix/
        dressup/
        study/
        knowledge/
        resume/
        career/
        membership/
  backend/
    app/
      api/
      core/
      db/
      services/
        auth_service/
        ai_gateway/
        intent_router/
        companion_service/
        creation_service/
        image_service/
        learning_service/
        career_service/
        payment_service/
      workers/
      prompts/
      tests/
  docs/
    product/
    architecture/
    api/
```

---

## 9. 核心风险与解决方案

| 风险 | 表现 | 解决方案 |
|---|---|---|
| 功能太多导致复杂 | 用户不知道点哪里 | 首页全局输入 + 智能分发 |
| AI 成本过高 | 图片和长文本消耗大 | 模型分级、积分制、缓存、异步队列 |
| 产品定位发散 | 像工具箱但不成体系 | 统一命名为“生活 AI 助手”，按场景聚合 |
| 隐私敏感 | 分身、树洞、简历涉及隐私 | 本地加密、脱敏、明确隐私提示 |
| 审核风险 | 情感、作业、医疗心理边界 | 风控词库、安全提示、拒答策略 |
| 图片生成慢 | 用户等待流失 | 任务中心、推送通知、排队进度 |
| 教育合规 | 直接给答案可能被质疑 | 主打讲解和引导，不鼓励作弊 |

---

## 10. 最推荐的落地版本

### App 第一版名称

**灵犀 AI**

### 第一版 Slogan

> 聊天、写作、修图、学习、求职，一个 AI 全搞定。

### 第一版功能

1. 首页全局输入
2. AI 陪伴聊天
3. 小红书/朋友圈/周报写作
4. AI 风格修图
5. 拍照解数学题
6. 简历评分与 JD 优化
7. 会员订阅
8. 分享卡片

### 第一版技术目标

1. Flutter 完成 iOS/Android 双端
2. FastAPI 后端
3. PostgreSQL + Redis + OSS
4. AI Gateway 接入文本模型和图片模型
5. 任务中心支持异步图片处理
6. 支付、埋点、崩溃监控上线

### 第一版成功指标

| 指标 | 目标 |
|---|---|
| 次日留存 | > 25% |
| 7 日留存 | > 10% |
| 分享率 | > 8% |
| 免费到付费转化 | > 2% |
| 单用户日均 AI 调用 | > 3 次 |
| 图片任务完成率 | > 90% |

---

## 11. 下一步建议

建议不要一次开发全部 11 个模块，而是先做统一底座 + 5 个核心入口。

最优开发顺序：

1. 先做首页全局输入、账号、会员、AI Gateway、任务中心
2. 同时做灵伴、妙笔、秒修、解题、职达 5 个 P0 模块
3. 上线后通过埋点看哪个功能留存最高
4. 把留存最高的模块做深，其他模块保持轻量入口
5. 第二阶段再补分身、树洞、快文、证件照、模拟面试

这样既能讲“一个 App 集成 11 种 AI 能力”的故事，又不会在第一版被复杂度拖垮。
