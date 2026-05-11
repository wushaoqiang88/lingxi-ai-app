# 🏗️ AI App 详细架构设计文档

> 11 个 App 全量技术架构 · 含系统架构图、技术栈、数据库设计、核心模块、API设计
> 编写日期：2026年5月2日

---

# 📐 通用架构基础

## 通用技术栈

```
前端（iOS）: Swift + SwiftUI + Combine
前端（Android）: Kotlin + Jetpack Compose
跨平台备选: Flutter (Dart) / React Native
后端: Node.js (NestJS) / Python (FastAPI)
数据库: PostgreSQL + Redis + MongoDB
AI层: OpenAI GPT-4o API / Claude API / 自训练模型
对象存储: AWS S3 / 阿里云 OSS
推送: APNs + Firebase Cloud Messaging
监控: Sentry + Prometheus + Grafana
CI/CD: GitHub Actions + Fastlane
```

## 通用架构模式

```
┌─────────────────────────────────────────────┐
│                 客户端层                      │
│  iOS App / Android App / Web App             │
└──────────────┬──────────────────────────────┘
               │ HTTPS / WebSocket
┌──────────────▼──────────────────────────────┐
│              API Gateway                     │
│  Nginx / Kong / AWS API Gateway              │
│  (限流 · 鉴权 · 日志 · 路由)                 │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│           微服务层                            │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐       │
│  │用户服务│ │AI服务 │ │业务服务│ │支付服务│       │
│  └──────┘ └──────┘ └──────┘ └──────┘       │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│           数据层                              │
│  PostgreSQL · Redis · MongoDB · S3           │
└─────────────────────────────────────────────┘
```

---

---

# 🧠 方案 1：灵伴 SoulMate — AI 情感陪伴

## 系统架构

```
┌─────────────────────────────────────────────────────────┐
│                      iOS / Android App                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────┐  │
│  │ 聊天界面  │ │ 心情日记  │ │ 情绪疗愈  │ │ 个人中心   │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └─────┬─────┘  │
│       │            │            │              │         │
│  ┌────▼────────────▼────────────▼──────────────▼─────┐  │
│  │              本地缓存层 (SQLite + Realm)            │  │
│  │   聊天记录缓存 · 用户偏好 · 离线数据                   │  │
│  └───────────────────┬───────────────────────────────┘  │
└──────────────────────┼──────────────────────────────────┘
                       │ HTTPS + WebSocket (实时聊天)
┌──────────────────────▼──────────────────────────────────┐
│                   API Gateway (Kong)                     │
│            JWT鉴权 · 限流(100次/分钟) · WAF              │
└──────┬────────┬────────┬────────┬───────────────────────┘
       │        │        │        │
┌──────▼───┐┌───▼────┐┌──▼─────┐┌─▼──────────┐
│  用户服务  ││ 聊天服务 ││ AI服务  ││  情绪分析服务 │
│          ││        ││        ││             │
│ 注册/登录 ││ 消息路由 ││ LLM调用 ││ 情感识别     │
│ 会员管理  ││ 历史记录 ││ 人格管理 ││ 趋势分析     │
│ 偏好设置  ││ 上下文窗口││ Prompt  ││ 危机检测     │
└──────┬───┘└───┬────┘└──┬─────┘└─┬──────────┘
       │        │        │        │
┌──────▼────────▼────────▼────────▼───────────┐
│              数据层                           │
│  ┌──────────┐ ┌───────┐ ┌────────────────┐  │
│  │PostgreSQL │ │ Redis │ │   MongoDB       │  │
│  │用户表     │ │会话缓存│ │ 聊天记录(NoSQL) │  │
│  │订阅表     │ │在线状态│ │ 情绪日志       │  │
│  │人格配置表 │ │限流   │ │ 用户画像       │  │
│  └──────────┘ └───────┘ └────────────────┘  │
└─────────────────────────────────────────────┘
```

## 核心数据库设计

```sql
-- 用户表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) UNIQUE,
    nickname VARCHAR(50),
    avatar_url TEXT,
    membership_level VARCHAR(20) DEFAULT 'free', -- free/monthly/yearly
    membership_expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI 人格表
CREATE TABLE ai_personas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL,         -- "温柔姐姐"
    description TEXT,
    system_prompt TEXT NOT NULL,         -- LLM system prompt
    voice_id VARCHAR(50),               -- TTS voice ID
    avatar_url TEXT,
    is_premium BOOLEAN DEFAULT FALSE,
    category VARCHAR(30)                -- '温暖','理性','搞笑','毒舌'
);

-- 对话会话表
CREATE TABLE chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    persona_id UUID REFERENCES ai_personas(id),
    title VARCHAR(100),
    context_summary TEXT,               -- 压缩的上下文摘要
    message_count INT DEFAULT 0,
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 消息表 (MongoDB)
-- Collection: messages
{
    _id: ObjectId,
    session_id: UUID,
    role: "user" | "assistant",
    content: String,
    emotion_label: String,              -- "开心","焦虑","悲伤"...
    emotion_score: Float,               -- 0-1
    tokens_used: Int,
    created_at: ISODate
}

-- 情绪日志表
CREATE TABLE mood_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    mood_score INT CHECK (mood_score BETWEEN 1 AND 10),
    mood_label VARCHAR(20),
    ai_summary TEXT,                    -- AI 生成的每日心情总结
    log_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, log_date)
);
```

## 核心 API 设计

```
POST   /api/v1/auth/login              # 登录
POST   /api/v1/chat/sessions           # 创建聊天会话
POST   /api/v1/chat/messages           # 发送消息
GET    /api/v1/chat/sessions/:id/history # 获取聊天历史
PUT    /api/v1/personas/:id/select     # 切换人格
GET    /api/v1/mood/weekly             # 获取每周情绪报告
POST   /api/v1/mood/log                # 记录今日心情
GET    /api/v1/healing/recommend       # 获取疗愈推荐
POST   /api/v1/share/mood-card         # 生成心情分享卡片
WebSocket /ws/chat                      # 实时聊天通道
```

## AI 核心流程

```
用户输入 → 情感分析(本地轻量模型)
         → 构建 Prompt (人格 + 上下文 + 用户画像)
         → LLM API 调用 (流式输出)
         → 后处理 (敏感词过滤 + 危机检测)
         → 情感标注存储
         → 返回用户
```

---

---

# 🤖 方案 2：分身 Avatar — AI 数字分身

## 系统架构

```
┌──────────────────────────────────────────────┐
│                   App 客户端                   │
│  ┌─────────┐ ┌─────────┐ ┌─────────────────┐ │
│  │训练分身   │ │代回消息  │ │ 社交报告        │ │
│  └────┬────┘ └────┬────┘ └────────┬────────┘ │
└───────┼───────────┼───────────────┼──────────┘
        │           │               │
┌───────▼───────────▼───────────────▼──────────┐
│                 API Gateway                    │
└───────┬───────────┬───────────────┬──────────┘
        │           │               │
┌───────▼───┐ ┌─────▼─────┐ ┌──────▼──────┐
│  用户服务   │ │ 分身引擎   │ │  分析服务    │
│           │ │            │ │             │
│ 注册/订阅  │ │ 风格学习   │ │ 聊天风格分析 │
│ 数据导入   │ │ 文本生成   │ │ 高频词统计   │
│           │ │ 场景适配   │ │ 报告生成    │
└───────┬───┘ └─────┬─────┘ └──────┬──────┘
        │           │               │
┌───────▼───────────▼───────────────▼──────────┐
│   PostgreSQL      │  Redis    │  Vector DB    │
│   用户/订阅       │  缓存     │  风格嵌入向量  │
└──────────────────────────────────────────────┘
```

## 核心数据库设计

```sql
-- 分身模型表
CREATE TABLE avatars (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    name VARCHAR(50),                    -- "工作版", "朋友版"
    style_profile JSONB,                 -- {tone, vocabulary, emoji_freq, ...}
    training_status VARCHAR(20),         -- 'pending','training','ready'
    training_data_count INT DEFAULT 0,
    system_prompt TEXT,                  -- 从训练数据生成的 prompt
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 训练数据表
CREATE TABLE training_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    avatar_id UUID REFERENCES avatars(id),
    source VARCHAR(30),                  -- 'wechat','manual','sms'
    content TEXT NOT NULL,
    role VARCHAR(10),                    -- 'user' 用户原话
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 生成记录表
CREATE TABLE generation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    avatar_id UUID REFERENCES avatars(id),
    input_text TEXT,                     -- 收到的消息
    output_text TEXT,                    -- AI 生成的回复
    scene VARCHAR(20),                  -- 'reply','post','email'
    satisfaction INT,                   -- 用户评分 1-5
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## 风格学习 Pipeline

```
导入聊天记录 → 文本清洗(去隐私)
            → 语言特征提取:
              · 句式结构
              · 常用词/口头禅
              · emoji 使用频率
              · 标点习惯
              · 语气词偏好
            → 生成 Style Prompt
            → Fine-tune / Few-shot 配置
            → 验证测试 (生成样本 → 用户确认)
            → 上线分身
```

---

---

# 🕳️ 方案 3：树洞 TreeHole — 匿名 AI 倾听者

## 系统架构

```
┌──────────────────────────────────────┐
│              App 客户端               │
│  ┌──────────────────────────────┐   │
│  │    本地加密存储 (AES-256)     │   │
│  │    对话数据不上传服务器        │   │
│  │    情绪统计数据脱敏后上传      │   │
│  └──────────────┬───────────────┘   │
└─────────────────┼───────────────────┘
                  │ (仅脱敏数据)
┌─────────────────▼───────────────────┐
│            轻量后端                   │
│  ┌──────────┐  ┌──────────────────┐ │
│  │ AI代理服务│  │ 匿名统计服务      │ │
│  │ 转发LLM  │  │ 情绪趋势(脱敏)    │ │
│  │ 无状态   │  │ 危机检测          │ │
│  └──────────┘  └──────────────────┘ │
└─────────────────────────────────────┘
```

## 隐私架构（核心差异化）

```
本地端:
  ┌────────────────────────────────┐
  │  对话内容 → AES-256加密 → 本地DB │
  │  用户可随时"焚烧"(不可恢复删除)   │
  │  生物识别解锁 (Face ID/指纹)     │
  └────────────────────────────────┘

发送到服务器的数据 (匿名+脱敏):
  ┌────────────────────────────────┐
  │  · anonymous_id (非用户ID)      │
  │  · emotion_label: "焦虑"       │
  │  · emotion_score: 0.7          │
  │  · timestamp (精确到小时)       │
  │  · ❌ 不传输对话原文            │
  └────────────────────────────────┘

AI 调用流程:
  本地构建prompt → HTTPS发送 → AI返回 → 本地解密展示
  服务端不存储对话内容，仅做转发
```

## 数据库设计

```sql
-- 本地 SQLite (设备端，加密)
CREATE TABLE local_conversations (
    id TEXT PRIMARY KEY,
    encrypted_content BLOB,    -- AES-256 加密的对话内容
    emotion_label TEXT,
    emotion_score REAL,
    is_burned INTEGER DEFAULT 0,
    created_at TEXT
);

-- 服务端 PostgreSQL (仅匿名统计)
CREATE TABLE anonymous_mood_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    anonymous_id VARCHAR(64),   -- 哈希ID，不可逆
    emotion_label VARCHAR(20),
    emotion_score FLOAT,
    hour_of_day INT,
    day_of_week INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 危机检测日志 (服务端)
CREATE TABLE crisis_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    anonymous_id VARCHAR(64),
    risk_level VARCHAR(10),     -- 'low','medium','high','critical'
    detected_keywords TEXT[],
    hotline_shown BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

---

# ✍️ 方案 4：妙笔 MiaoWrite — AI 万能写作助手

## 系统架构

```
┌─────────────────────────────────────────────────┐
│                    App 客户端                     │
│  ┌────────┐ ┌────────┐ ┌──────┐ ┌────────────┐  │
│  │ 闪写    │ │ 模板库  │ │ 改写  │ │ 小红书生成器│  │
│  └───┬────┘ └───┬────┘ └──┬───┘ └─────┬──────┘  │
│      │          │         │           │          │
│  ┌───▼──────────▼─────────▼───────────▼───────┐  │
│  │         富文本编辑器 (Markdown + WYSIWYG)    │  │
│  │         实时预览 · 导出 PDF/Word/图片         │  │
│  └────────────────────┬───────────────────────┘  │
└───────────────────────┼──────────────────────────┘
                        │
┌───────────────────────▼──────────────────────────┐
│                  API Gateway                      │
│          限流: 免费5次/天, 会员无限               │
└──────┬─────────┬─────────┬───────────────────────┘
       │         │         │
┌──────▼───┐┌────▼────┐┌───▼─────────┐
│  写作引擎  ││ 模板服务 ││  媒体处理服务 │
│          ││         ││              │
│ 闪写     ││ 模板CRUD ││ 图片识别     │
│ 改写/润色 ││ 分类检索 ││ 文案卡片生成  │
│ 续写     ││ 热门推荐 ││ PDF/Word导出 │
│ 风格切换  ││         ││              │
└──────┬───┘└────┬────┘└───┬─────────┘
       │         │         │
┌──────▼─────────▼─────────▼─────────────────────┐
│  PostgreSQL    │  Redis      │  S3/OSS          │
│  用户/文章     │  热门模板    │  生成的图片/文件   │
│  模板数据      │  使用量计数  │                   │
└────────────────────────────────────────────────┘
```

## 核心数据库设计

```sql
-- 写作模板表
CREATE TABLE writing_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(30) NOT NULL,       -- '周报','简历','小红书','邮件'...
    name VARCHAR(100) NOT NULL,
    description TEXT,
    system_prompt TEXT NOT NULL,          -- AI 指令模板
    example_output TEXT,                 -- 示例输出
    variables JSONB,                     -- 可填充的变量 [{name,label,type}]
    use_count INT DEFAULT 0,
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用户文章表
CREATE TABLE articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    template_id UUID REFERENCES writing_templates(id),
    title VARCHAR(200),
    content TEXT,
    style VARCHAR(20),                   -- '正式','活泼','文艺','搞笑'
    word_count INT,
    source_type VARCHAR(20),             -- 'flash','rewrite','template','photo'
    input_keywords TEXT,
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 使用统计表
CREATE TABLE usage_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(30),                  -- 'generate','rewrite','share'
    tokens_used INT,
    date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## 核心 API

```
POST   /api/v1/write/flash              # 闪写（关键词→文章）
POST   /api/v1/write/rewrite            # 改写/润色
POST   /api/v1/write/continue           # 续写
POST   /api/v1/write/from-photo         # 拍照生成文案
GET    /api/v1/templates?category=       # 获取模板列表
POST   /api/v1/templates/:id/generate   # 使用模板生成
POST   /api/v1/export/pdf               # 导出 PDF
POST   /api/v1/export/image             # 导出分享图片
POST   /api/v1/share/card               # 生成分享卡片
```

## AI Prompt 架构

```
System Prompt 构成:
┌─────────────────────────────────────┐
│ 1. 角色设定 (写作专家)               │
│ 2. 风格指令 (正式/活泼/文艺/搞笑)    │
│ 3. 模板结构 (特定文体的结构要求)      │
│ 4. 输出格式 (Markdown/纯文本/HTML)   │
│ 5. 约束条件 (字数/语言/禁忌词)       │
└─────────────────────────────────────┘

User Prompt 构成:
┌─────────────────────────────────────┐
│ 1. 用户输入的关键词/原文              │
│ 2. 模板变量填充值                    │
│ 3. 额外要求                         │
└─────────────────────────────────────┘
```

---

---

# 📋 方案 5：快文 QuickDoc — AI 职场写作

## 系统架构

```
┌─────────────────────────────────────────────┐
│                App 客户端                    │
│  ┌─────────┐ ┌────────┐ ┌────────────────┐  │
│  │ 公文生成  │ │ 邮件助手│ │ PPT大纲生成    │  │
│  └────┬────┘ └───┬────┘ └───────┬────────┘  │
└───────┼──────────┼──────────────┼───────────┘
        │          │              │
┌───────▼──────────▼──────────────▼───────────┐
│              后端服务                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐ │
│  │ 公文引擎  │ │ 邮件引擎  │ │ 文档导出引擎  │ │
│  │          │ │          │ │              │ │
│  │ 通知/报告 │ │ 正式/催促 │ │ DOCX/PDF    │ │
│  │ 方案/纪要 │ │ 感谢/道歉 │ │ PPTX大纲    │ │
│  │ 总结     │ │ 跟进     │ │ Markdown    │ │
│  └──────────┘ └──────────┘ └──────────────┘ │
└─────────────────────────────────────────────┘
```

## 核心数据库

```sql
-- 公文模板表
CREATE TABLE doc_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doc_type VARCHAR(30),    -- 'notice','report','plan','minutes','summary'
    name VARCHAR(100),
    structure JSONB,          -- 文档结构定义
    system_prompt TEXT,
    example TEXT,
    industry VARCHAR(30),     -- 适用行业
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 生成历史
CREATE TABLE doc_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    template_id UUID,
    doc_type VARCHAR(30),
    title VARCHAR(200),
    content TEXT,
    export_format VARCHAR(10),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

---

# 📷 方案 6：秒修 SnapFix — AI 一键修图

## 系统架构

```
┌────────────────────────────────────────────────────┐
│                    App 客户端                       │
│  ┌─────────┐ ┌──────────┐ ┌─────────┐ ┌────────┐  │
│  │一键美化   │ │风格转换   │ │AI换背景  │ │证件照   │  │
│  └───┬─────┘ └────┬─────┘ └───┬─────┘ └───┬────┘  │
│      │            │           │            │       │
│  ┌───▼────────────▼───────────▼────────────▼────┐  │
│  │          图片预处理层 (本地)                    │  │
│  │  压缩 · 裁剪 · EXIF处理 · 人脸检测(Vision)    │  │
│  └──────────────────┬───────────────────────────┘  │
└─────────────────────┼──────────────────────────────┘
                      │ (压缩后的图片上传)
┌─────────────────────▼──────────────────────────────┐
│                  API Gateway                        │
│         图片大小限制 · 频率限制 · CDN缓存            │
└──────┬──────────┬──────────┬──────────┬─────────────┘
       │          │          │          │
┌──────▼───┐ ┌────▼────┐ ┌──▼──────┐ ┌─▼──────────┐
│  美化引擎  │ │风格转换  │ │ 抠图引擎 │ │  证件照引擎 │
│          │ │         │ │         │ │            │
│ 调色     │ │ Stable  │ │ U2-Net  │ │ 人脸对齐   │
│ 美颜     │ │Diffusion│ │ SAM     │ │ 背景替换   │
│ 去瑕疵   │ │ LoRA    │ │ 背景替换 │ │ 尺寸裁剪   │
│ 超分辨率  │ │         │ │         │ │            │
└──────┬───┘ └────┬────┘ └──┬──────┘ └─┬──────────┘
       │          │         │          │
┌──────▼──────────▼─────────▼──────────▼───────────┐
│          GPU 计算集群 (A100 / T4)                  │
│  模型推理服务 · 队列调度 · 自动扩缩                   │
└──────────────────────┬───────────────────────────┘
                       │
┌──────────────────────▼───────────────────────────┐
│        S3/OSS 存储 · CDN 分发                      │
│        原图 · 结果图 · 临时文件(24h自动清理)         │
└──────────────────────────────────────────────────┘
```

## 核心数据库设计

```sql
-- 处理任务表
CREATE TABLE image_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    task_type VARCHAR(30),       -- 'enhance','style','cutout','idphoto','restore'
    status VARCHAR(20),          -- 'queued','processing','done','failed'
    input_url TEXT NOT NULL,
    output_url TEXT,
    params JSONB,                -- {style:'ghibli', bg:'beach', size:'1inch'...}
    processing_time_ms INT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- 风格模型表
CREATE TABLE style_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50),            -- '吉卜力','赛博朋克','水墨画','油画'
    model_path TEXT,             -- LoRA 模型路径
    preview_url TEXT,
    is_premium BOOLEAN DEFAULT FALSE,
    use_count INT DEFAULT 0
);

-- 证件照尺寸表
CREATE TABLE id_photo_sizes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),            -- '一寸','二寸','护照','签证'
    width_px INT,
    height_px INT,
    bg_color VARCHAR(7),         -- '#FFFFFF','#438EDB'
    dpi INT DEFAULT 300
);
```

## 核心 API

```
POST   /api/v1/image/enhance          # 一键美化
POST   /api/v1/image/style-transfer   # 风格转换
POST   /api/v1/image/cutout           # AI抠图
POST   /api/v1/image/change-bg        # 换背景
POST   /api/v1/image/id-photo         # 证件照生成
POST   /api/v1/image/restore          # 老照片修复
POST   /api/v1/image/super-res        # 超分辨率
GET    /api/v1/image/task/:id/status   # 查询处理状态
GET    /api/v1/image/task/:id/result   # 获取结果
GET    /api/v1/styles                  # 获取风格列表
```

## AI 模型栈

```
美化: 自训练的图像增强模型 (Real-ESRGAN + 色彩校正)
风格转换: Stable Diffusion + ControlNet + LoRA
抠图: SAM2 (Segment Anything Model 2) + U2-Net
超分辨率: Real-ESRGAN x4
人脸美颜: MediaPipe Face + 自研美颜算法
老照片修复: GFPGAN + CodeFormer
```

---

---

# 👗 方案 7：换装 DressUp AI — AI 虚拟试衣

## 系统架构

```
┌────────────────────────────────────────────┐
│                App 客户端                   │
│  ┌─────────┐ ┌──────────┐ ┌────────────┐  │
│  │上传自拍   │ │选择衣服   │ │穿搭建议    │  │
│  └───┬─────┘ └────┬─────┘ └─────┬──────┘  │
└──────┼────────────┼─────────────┼──────────┘
       │            │             │
┌──────▼────────────▼─────────────▼──────────┐
│              后端服务集群                     │
│  ┌──────────┐ ┌──────────┐ ┌────────────┐  │
│  │ 人体解析   │ │ 虚拟试穿  │ │ 搭配推荐   │  │
│  │ 姿态估计   │ │ 衣服变形  │ │ 肤色分析   │  │
│  │ 分割      │ │ 光照匹配  │ │ 体型分析   │  │
│  └──────────┘ └──────────┘ └────────────┘  │
│                                             │
│  GPU集群: A100 / T4                         │
│  模型: Virtual Try-On (VITON-HD / DCI-VTON) │
└─────────────────────────────────────────────┘
```

## 核心数据库

```sql
-- 衣服库表
CREATE TABLE clothes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100),
    category VARCHAR(30),     -- 'top','bottom','dress','outerwear'
    style VARCHAR(30),        -- 'casual','formal','sporty'
    image_url TEXT,
    mask_url TEXT,             -- 衣服蒙版（用于试穿）
    brand VARCHAR(50),
    price DECIMAL(10,2),
    shop_url TEXT,             -- 电商链接
    tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 试穿记录
CREATE TABLE try_on_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    person_image_url TEXT,
    clothes_id UUID REFERENCES clothes(id),
    result_image_url TEXT,
    liked BOOLEAN,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

---

# 📚 方案 8：解题侠 SolveHero — AI 作业帮手

## 系统架构

```
┌──────────────────────────────────────────────────────┐
│                      App 客户端                       │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐ ┌───────────┐ │
│  │ 拍照解题  │ │ AI老师   │ │ 作文批改  │ │ 口语陪练  │ │
│  └───┬─────┘ └───┬─────┘ └────┬─────┘ └─────┬─────┘ │
│      │           │            │              │       │
│  ┌───▼───────────▼────────────▼──────────────▼────┐  │
│  │           本地层                                 │  │
│  │  OCR预处理 · 语音识别(Whisper) · 错题缓存         │  │
│  └────────────────────┬───────────────────────────┘  │
└───────────────────────┼──────────────────────────────┘
                        │
┌───────────────────────▼──────────────────────────────┐
│                   API Gateway                         │
│           学生安全过滤 · 年龄分级 · 限流               │
└──────┬──────────┬──────────┬──────────┬───────────────┘
       │          │          │          │
┌──────▼───┐ ┌────▼────┐ ┌──▼──────┐ ┌─▼──────────┐
│  OCR服务  │ │ 解题引擎 │ │ 作文引擎 │ │ 口语引擎    │
│          │ │         │ │         │ │            │
│ 题目识别  │ │ 数学解析 │ │ 批改打分 │ │ ASR识别    │
│ LaTeX转换 │ │ 物理推理 │ │ 修改建议 │ │ 对话生成   │
│ 公式识别  │ │ 化学配平 │ │ 范文生成 │ │ 发音评分   │
│          │ │ 编程解析 │ │         │ │            │
└──────┬───┘ └────┬────┘ └──┬──────┘ └─┬──────────┘
       │          │         │          │
┌──────▼──────────▼─────────▼──────────▼───────────┐
│  PostgreSQL     │ MongoDB    │ Redis   │ S3      │
│  用户/课程      │ 题目库      │ 会话    │ 图片    │
│  错题本        │ 解题记录    │ 限流    │ 音频    │
└──────────────────────────────────────────────────┘
```

## 核心数据库设计

```sql
-- 题目表 (MongoDB)
{
    _id: ObjectId,
    user_id: UUID,
    image_url: String,
    ocr_text: String,                    -- OCR 识别的原文
    subject: String,                     -- 'math','physics','chemistry','english'
    grade: String,                       -- '初一','高二'...
    question_type: String,               -- 'choice','fill','proof','essay'
    solution: {
        steps: [                         -- 分步解题
            { step: 1, content: "...", explanation: "..." }
        ],
        answer: String,
        knowledge_points: [String],
        difficulty: Number               -- 1-5
    },
    related_questions: [ObjectId],       -- 举一反三题目
    created_at: ISODate
}

-- 错题本 (PostgreSQL)
CREATE TABLE wrong_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    question_id VARCHAR(24),             -- MongoDB ObjectId
    subject VARCHAR(20),
    wrong_reason TEXT,                   -- AI分析的错误原因
    review_count INT DEFAULT 0,
    next_review_date DATE,               -- 艾宾浩斯遗忘曲线
    mastered BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 作文记录
CREATE TABLE essays (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    title VARCHAR(200),
    content TEXT,
    grade VARCHAR(10),
    score INT,                           -- AI 打分 0-100
    feedback JSONB,                      -- {grammar,structure,content,vocabulary}
    suggestions TEXT[],
    model_essay TEXT,                    -- AI生成的范文
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 口语练习记录
CREATE TABLE speaking_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    topic VARCHAR(200),
    audio_url TEXT,
    transcript TEXT,
    pronunciation_score FLOAT,
    fluency_score FLOAT,
    grammar_score FLOAT,
    ai_feedback TEXT,
    duration_seconds INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## 苏格拉底模式 AI 流程

```
学生拍题 → OCR识别题目
         → 判断题目类型和难度
         → 进入苏格拉底模式:
            AI: "这道题考的是什么知识点？你觉得呢？"
            学生: "好像是二次方程..."
            AI: "对！那二次方程的一般形式是什么？"
            学生: "ax² + bx + c = 0"
            AI: "很好！现在你能把题目整理成这个形式吗？"
            ... (逐步引导)
         → 学生自己推理出答案
         → AI给出评价和补充
```

---

---

# 🧩 方案 9：知了 ZhiLe — AI 知识问答

## 系统架构

```
┌──────────────────────────────────────┐
│              App 客户端               │
│  ┌──────┐ ┌──────┐ ┌──────────────┐ │
│  │问答   │ │闯关   │ │每日知识推送   │ │
│  └──┬───┘ └──┬───┘ └──────┬───────┘ │
└─────┼────────┼────────────┼─────────┘
      │        │            │
┌─────▼────────▼────────────▼─────────┐
│             后端服务                  │
│  ┌─────────┐ ┌────────┐ ┌────────┐  │
│  │ QA引擎   │ │ 闯关引擎│ │推送服务 │  │
│  │ RAG检索  │ │题目生成 │ │定时任务 │  │
│  │ LLM生成  │ │排行榜  │ │个性化  │  │
│  └─────────┘ └────────┘ └────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │   向量数据库 (Pinecone/Milvus) │  │
│  │   知识库嵌入 · 语义检索         │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

## 核心数据库

```sql
-- 知识条目
CREATE TABLE knowledge_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(30),       -- '科学','历史','文化','生活'
    title VARCHAR(200),
    content TEXT,
    source TEXT,
    embedding_id VARCHAR(100),   -- 向量数据库中的ID
    difficulty INT,
    view_count INT DEFAULT 0
);

-- 闯关题目
CREATE TABLE quiz_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(30),
    question TEXT,
    options JSONB,               -- ["A. xxx", "B. xxx", ...]
    correct_answer VARCHAR(5),
    explanation TEXT,
    difficulty INT
);

-- 用户排行
CREATE TABLE leaderboard (
    user_id UUID REFERENCES users(id),
    total_score INT DEFAULT 0,
    streak_days INT DEFAULT 0,
    rank INT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

---

# 📄 方案 10：职达 JobPro — AI 简历+求职助手

## 系统架构

```
┌──────────────────────────────────────────────────┐
│                    App 客户端                      │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐ ┌──────┐  │
│  │简历构建器 │ │JD匹配优化 │ │AI面试官   │ │求职板 │  │
│  └───┬─────┘ └────┬─────┘ └────┬─────┘ └──┬───┘  │
│      │            │            │           │      │
│  ┌───▼────────────▼────────────▼───────────▼───┐  │
│  │         简历编辑器 (模板引擎)                  │  │
│  │         实时预览 · 多模板切换 · PDF导出         │  │
│  └─────────────────────┬───────────────────────┘  │
└────────────────────────┼────────────────────────┘
                         │
┌────────────────────────▼────────────────────────┐
│                  后端服务                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │
│  │ 简历引擎  │ │ 面试引擎  │ │    NLP分析服务    │ │
│  │          │ │          │ │                  │ │
│  │ 生成简历  │ │ 题库管理  │ │ JD关键词提取     │ │
│  │ JD匹配   │ │ AI面试官  │ │ 简历评分        │ │
│  │ 评分诊断  │ │ 回答评估  │ │ 匹配度计算      │ │
│  │ 模板渲染  │ │ 面试报告  │ │                  │ │
│  └──────────┘ └──────────┘ └──────────────────┘ │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│  PostgreSQL │ MongoDB      │ Redis │ S3         │
│  用户/求职  │ 面试记录     │ 会话  │ PDF/简历    │
│  模板      │ 题库         │ 缓存  │            │
└─────────────────────────────────────────────────┘
```

## 核心数据库设计

```sql
-- 简历表
CREATE TABLE resumes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    template_id UUID,
    title VARCHAR(200),                  -- "前端工程师简历"
    content JSONB,                       -- 结构化简历数据
    -- content 结构:
    -- {
    --   basic: {name, phone, email, location},
    --   education: [{school, major, degree, start, end, gpa}],
    --   experience: [{company, title, start, end, description[]}],
    --   projects: [{name, role, description, tech_stack[]}],
    --   skills: [{category, items[]}],
    --   summary: "..."
    -- }
    score INT,                           -- AI 评分 0-100
    score_breakdown JSONB,               -- {format:85, content:72, keywords:90...}
    pdf_url TEXT,
    version INT DEFAULT 1,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 简历模板表
CREATE TABLE resume_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100),
    preview_url TEXT,
    html_template TEXT,                  -- Handlebars 模板
    css TEXT,
    category VARCHAR(30),               -- 'modern','classic','creative','minimal'
    is_premium BOOLEAN DEFAULT FALSE,
    use_count INT DEFAULT 0
);

-- JD 匹配记录
CREATE TABLE jd_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resume_id UUID REFERENCES resumes(id),
    jd_text TEXT,
    company VARCHAR(100),
    position VARCHAR(100),
    match_score FLOAT,                   -- 0-100
    missing_keywords TEXT[],             -- 缺少的关键词
    suggestions TEXT[],                  -- 优化建议
    optimized_resume_id UUID,           -- 优化后的简历
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 面试会话表
CREATE TABLE interview_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    company VARCHAR(100),
    position VARCHAR(100),
    industry VARCHAR(50),
    interview_type VARCHAR(20),          -- 'behavioral','technical','case'
    questions_asked JSONB,               -- [{question, user_answer, ai_feedback, score}]
    overall_score INT,
    strengths TEXT[],
    improvements TEXT[],
    duration_seconds INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 求职追踪
CREATE TABLE job_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    company VARCHAR(100),
    position VARCHAR(100),
    status VARCHAR(20),                  -- 'applied','screening','interview','offer','rejected'
    applied_date DATE,
    resume_id UUID,
    notes TEXT,
    next_action TEXT,
    next_action_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## AI 面试官流程

```
1. 选择目标公司 + 岗位 + 面试类型
2. AI 根据岗位JD生成面试题目（5-10题）
3. 面试流程:
   AI: "请做一个简短的自我介绍。" (语音/文字)
   用户: 回答 (语音转文字 / 直接文字)
   AI: 实时评估 → 追问 / 下一题
4. 面试结束:
   → 生成面试报告 (总分/各维度评分/改进建议)
   → 每题的参考答案
   → 录音回放 (会员功能)
```

---

---

# 🗺️ 方案 11：职画 CareerMap — AI 职业规划

## 系统架构

```
┌──────────────────────────────────────┐
│              App 客户端               │
│  ┌──────┐ ┌──────┐ ┌──────────────┐ │
│  │性格测试│ │路径图 │ │薪资分析      │ │
│  └──┬───┘ └──┬───┘ └──────┬───────┘ │
└─────┼────────┼────────────┼─────────┘
      │        │            │
┌─────▼────────▼────────────▼─────────┐
│             后端服务                  │
│  ┌─────────┐ ┌────────┐ ┌────────┐  │
│  │测评引擎  │ │路径推荐 │ │数据分析 │  │
│  │MBTI增强 │ │职业图谱 │ │薪资数据 │  │
│  │霍兰德   │ │技能匹配 │ │行业趋势 │  │
│  └─────────┘ └────────┘ └────────┘  │
└──────────────────────────────────────┘
```

## 核心数据库

```sql
-- 职业测评结果
CREATE TABLE career_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    mbti_type VARCHAR(4),
    holland_code VARCHAR(6),
    strengths TEXT[],
    values TEXT[],
    recommended_careers JSONB,    -- [{career, match_score, reason}]
    full_report JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 职业数据库
CREATE TABLE careers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100),
    category VARCHAR(50),
    description TEXT,
    required_skills TEXT[],
    salary_range JSONB,          -- {min, max, median, by_city:{}}
    growth_outlook VARCHAR(20),
    education_requirement VARCHAR(50),
    related_careers UUID[]
);

-- 学习路径
CREATE TABLE learning_paths (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    career_id UUID REFERENCES careers(id),
    name VARCHAR(200),
    steps JSONB,                 -- [{order, skill, resources[], duration}]
    difficulty VARCHAR(20),
    estimated_months INT
);
```

---

---

# 📊 部署架构（通用）

```
┌───────────────────────────────────────────────────────┐
│                     CDN (CloudFlare)                    │
│              静态资源 · 图片 · 前端文件                   │
└────────────────────────┬──────────────────────────────┘
                         │
┌────────────────────────▼──────────────────────────────┐
│              负载均衡 (ALB / Nginx)                     │
│         SSL终止 · 健康检查 · 自动故障转移                 │
└──────┬──────────┬──────────┬──────────────────────────┘
       │          │          │
┌──────▼───┐ ┌────▼────┐ ┌──▼──────────┐
│ Web服务器  │ │API服务器 │ │ WebSocket   │
│ (x2+)    │ │ (x3+)   │ │ 服务器(x2+)  │
│ 静态页面  │ │ REST API│ │ 实时通信     │
└──────┬───┘ └────┬────┘ └──┬──────────┘
       │          │         │
┌──────▼──────────▼─────────▼──────────────────────┐
│              Kubernetes 集群                       │
│  ┌──────────────────────────────────────────────┐ │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌───────┐ │ │
│  │  │用户Pod │ │AI推理Pod│ │业务Pod │ │定时任务│ │ │
│  │  │(x3)   │ │(x2 GPU)│ │(x3)   │ │(x1)  │ │ │
│  │  └────────┘ └────────┘ └────────┘ └───────┘ │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
│  ┌────────────────────────────────────────────┐   │
│  │  数据持久层                                 │   │
│  │  PostgreSQL(主从) · Redis集群 · MongoDB副本集│   │
│  └────────────────────────────────────────────┘   │
│                                                    │
│  ┌────────────────────────────────────────────┐   │
│  │  消息队列: RabbitMQ / Kafka                 │   │
│  │  (异步任务: 图片处理, AI推理, 通知推送)       │   │
│  └────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────┘

监控体系:
┌─────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐
│ Sentry  │ │Prometheus│ │ Grafana  │ │ELK Stack│
│ 错误追踪 │ │  指标    │ │  看板    │ │  日志   │
└─────────┘ └──────────┘ └──────────┘ └────────┘
```

---

# 💰 成本估算（MVP阶段/月）

| 项目 | 费用/月 |
|------|---------|
| 云服务器 (2核4G x3) | ¥600 |
| GPU推理 (T4 按需) | ¥1,000-3,000 |
| 数据库 (RDS) | ¥400 |
| Redis | ¥200 |
| 对象存储+CDN | ¥200 |
| AI API (GPT-4o) | ¥2,000-5,000 |
| 域名+SSL | ¥50 |
| 监控 | ¥100 |
| **合计** | **¥4,550-9,550** |

> MVP阶段建议：先用 Serverless (AWS Lambda / 阿里云函数计算) 降低成本
> 用户量起来后再迁移到 K8s

---

# 🗓️ 开发周期估算

| App | MVP开发周期 | 核心团队 |
|-----|------------|---------|
| 灵伴 SoulMate | 6-8周 | 1前端+1后端+1AI |
| 分身 Avatar | 8-10周 | 1前端+1后端+1AI |
| 树洞 TreeHole | 4-6周 | 1全栈+1AI |
| 妙笔 MiaoWrite | 4-6周 | 1前端+1后端 |
| 快文 QuickDoc | 3-4周 | 1全栈 |
| 秒修 SnapFix | 8-12周 | 1前端+1后端+1AI/CV |
| 换装 DressUp | 10-14周 | 1前端+1后端+1AI/CV |
| 解题侠 SolveHero | 8-10周 | 1前端+1后端+1AI |
| 知了 ZhiLe | 6-8周 | 1前端+1后端+1AI |
| 职达 JobPro | 6-8周 | 1前端+1后端 |
| 职画 CareerMap | 4-6周 | 1全栈 |
