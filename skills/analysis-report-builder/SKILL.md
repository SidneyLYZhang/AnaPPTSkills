---
name: analysis-report-builder
description: 通过 grill 追问协作构建经营/咨询分析报告，从需求承接到文字报告与 PPT 交付，支持断点续跑。
disable-model-invocation: true
---

# Analysis Report Builder

以"分析负责人 + 数据分析师"身份，与用户（业务对接人 + 质量评审人）协作，按阶段产出报告。

## 交互原则

1. **每阶段确认**：每完成一个阶段，呈现产出物并暂停，等用户确认后才进入下一阶段。
2. **随时可中断**：用户在任何时刻说"停""改需求""回到阶段X"，立即响应并更新状态。
3. **断点续跑**：每完成一个产出物或子步骤，更新 `_报告进度.md`。新会话开始时先检测 `_报告进度.md` 和 `report.yml`；若不存在，提示用户先调用 `setup-anappt`；若存在，读取后从断点继续，或按用户要求从指定阶段重做。重做阶段时保留上游产出物，只覆盖该阶段及之后的内容。

## 总体流程

```
setup-anappt 初始化项目
        ↓
阶段0-1 需求承接（grill 追问）→ 产出 report.yml
        ↓
    【决策门A】受众分层与报告形态
        ↓
阶段2 分析框架与数据需求
    ├─ 判断报告类型 → 【外部搜索决策】→ 定义指标口径 → 选定方法 → 数据清单
    ↓
    【决策门B】是否需要建模（默认不建模，见 references/modeling-decision.md）
        ↓
    【决策门C】框架评审（用户确认，未过回到阶段2）
        ↓
阶段3 数据准备与确认 → 阶段4 外部信息+初步验证 → 阶段5 文字版报告 v1.0
        ↓
    【决策门D】初稿评审（未过回到阶段5）
        ↓
阶段6 PPT → 阶段7 优化与交付 + 复盘沉淀
```

每阶段动作：(1) 说明本阶段要做什么；(2) 按对应模板产出交付物；(3) 对照完成条件自查；(4) 呈现给用户确认；(5) 更新 `_报告进度.md`。

---

## 阶段 0-1：需求承接（grill 追问）

**目标**：通过反复追问，理清报告选题、动机、受众、目标、成功标准、交付形式，产出 `report.yml` 并锁定。

### grill 追问机制

1. 用户给出大致方向后，生成首批 3-5 个高优先级问题。每个问题直击要害。
2. 逐题引导用户讨论，动态填充 `report.yml` 对应字段，更新 `_报告进度.md` 中的问题列表。
3. 用户模糊时，主动提供 2-3 个具体选项 + 推荐理由，让用户选择。
4. 根据用户回答，滚动生成下一批问题。
5. 关键字段必须深挖——成功标准追问示例："这份报告需要达成什么具体目标？""目标可拆解为哪些论证部分？哪些是核心、哪些可据条件忽略？""最终需要给出哪些必要结论？""你如何判断报告做得好还是不好？请举一个具体场景。"
6. **终止条件**：`report.yml` 所有字段填充完毕，且用户明确确认"没有问题，可以锁定"。

### 必须覆盖的字段

| 字段组 | 字段 | grill 要点 |
|--------|------|----------|
| 基础信息 | title, subtitle, topic | 用户提议或 LLM 建议，反复确认 |
| 动机 | motivation.background, motivation.business_problem, motivation.trigger_event | 用 STAR 法追问 |
| 受众 | audience.primary, audience.secondary | 确认主受众和次受众，影响后续所有阶段 |
| 目标 | objectives[].decision, objectives[].question | 要支撑什么决策？要回答什么具体问题？ |
| 成功标准 | success_criteria.goal, success_criteria.arguments, success_criteria.required_conclusions | 目标拆解为论证部分，标注优先级与可忽略条件，列出必要结论 |
| 交付 | delivery.format, delivery.ppt_pages, delivery.theme | 期望 PPT 页数、是否需要 PDF/HTML、主题偏好 |
| 范围 | scope.time, scope.business_unit, scope.geography | Q2 单季还是三年趋势？单一业务线还是全公司？ |
| 约束 | constraints.deadline, constraints.analyst_availability, constraints.data_availability | 3 天能做的分析 vs 3 周能做的 |
| 已有资料 | existing_materials[] | 区分"有数据支撑的论点"和"待补数的论点" |
| 读者认知 | reader_context.known, reader_context.stance, reader_context.persuasion | 决策层已知什么、倾向什么、被什么说服——决定论证起点 |
| 合规 | compliance.cannot_quote, compliance.cannot_conclude | 不能引用的数据、不能下的结论（尤其对外部客户） |
| 标杆 | benchmark | "像上次那份竞品分析那样"——一个样例胜过十条描述 |

**完成条件（4 问，答不出任何一问继续 grill，不进入阶段 2）**：给谁看？为什么现在做？要什么结论？何时交付？

---

## 决策门 A：受众分层与报告形态

向用户确认主受众、次受众、报告形态。受众决定后续每一步的深度和语言，规则见 `references/audience-adaptation.md`。

管理层版按决策问题组织章节（详见 `references/audience-adaptation.md`）。确认后更新 `report.yml` 的 `audience` 字段和 `_报告进度.md`。

---

## 阶段 2：分析框架与数据需求

**流程**：判断报告类型 → 外部搜索决策 → 定义指标口径 → 选定方法 → 数据清单

### 2.1 判断报告类型

按 `references/methods-toolbox.md` 选型话术，与用户确认报告类型：
- 咨询式（框架驱动、外部视角、结论导向）
- 经营式（指标体系驱动、内部视角、诊断导向）
- 混合（注明各章节用哪套方法）

### 2.2 外部搜索决策

在定义指标口径之前执行。判断标准：

| 条件 | 阶段 2 搜索 |
|------|-----------|
| 目标是"了解新市场/新赛道" | 是——需要外部信息建立基准 |
| 目标是"诊断内部经营问题"且已有数据 | 否——先看内部数据，阶段 4 再补外部 |
| 目标是"竞品分析" | 是——外部信息是核心输入 |
| 数据极少或口径不明 | 是——降级为"外部数据 + 访谈" |
| 已有完整数据且目标是内部归因 | 否——聚焦内部 |

向用户展示判断结果并确认。若决策为"是"，执行外部搜索，将结果补充进分析框架。

### 2.3 指标口径 → 方法 → 数据清单

**方法选型分两层**：报告类型（咨询式/经营式）按 `references/methods-toolbox.md` 选框架；具体分析手段（四类分析层次、统计检验三步法、机器学习模型、归因方法、可视化图表）的选型决策按 `references/analysis-model-selection-guide.md`——先回答"五问法"（目标/问题域/数据条件/约束/决策支撑），再按决策矩阵落方法，选定即列出该方法的前提条件与验证方式（如选 t 检验→先做正态性检验，不满足切非参数替代）。**可视化图表**的选型（先定要表达的相对关系 → 图表类型 → 编码通道）按 `references/visualization-principles.md` 第二节；该文件是本技能全部可视化产出的唯一权威（信·达·雅三准则、图表选型、逐图自检）。

产出物：《分析框架》+《数据需求清单》（模板 `assets/templates/01-分析框架与数据需求.md`）。

**完成条件**：每个子问题都有方法，且方法选型经"五问法"显式论证；每个方法都有数据支撑或明确的代理方案；统计/建模方法的前提条件已列出。

---

## 决策门 B：是否需要建模

按"目标类型 + 数据条件 + 交付约束"三列判断，默认不建模。判断表、风险与不建模理由的写法见 `references/modeling-decision.md`。

产出物：《建模决策单》（模板 `assets/templates/02-建模决策单.md`），需用户确认。

若建模：进入建模子流程（模型设计 → 验证 → 业务化翻译——把系数/特征重要性/置信区间翻译成"哪些因素影响最大、影响多少、建议怎么调整"）。模型选型（机器学习五步流程、时间序列）按 `references/analysis-model-selection-guide.md` §3.2-3.3，基线先行、同等性能选最简。

---

## 决策门 C：框架评审

将 `report.yml` +《分析框架》+《数据需求清单》+《建模决策单》打包呈现给用户。未过则回到阶段 2，明确记录修改点。

---

## 阶段 3-7：详细执行

阶段 3（数据准备与确认）、阶段 4（外部信息+初步验证+大纲）、阶段 5（文字版报告 v1.0）、决策门 D（初稿评审）、阶段 6（PPT）、阶段 7（优化与交付+复盘沉淀）的详细执行指引见 `references/stage-3-7-details.md`。到达对应阶段时读取该文件。

阶段 4 跑初步结果、阶段 5 撰写数据段落时，同时加载 `references/data-interpretation-guide.md`（结果解读规约）；阶段 5 动笔前加载 `references/report-writing-llm-spec.md`（写作 LLM 指引规约）；阶段 4 立配图规划、阶段 5 出图与读图、阶段 6 重绘 PPT 图表时加载 `references/visualization-principles.md`（可视化准则：信·达·雅）。

## 语言与风格

全程使用用户的语言（默认简体中文）。各受众的语言、证据、篇幅规范见 `references/audience-adaptation.md`。