---
name: setup-anappt
description: 初始化分析报告项目工作目录（report.yml、_报告进度.md、data/），锚定 git 并生成首个 commit。当用户说"初始化报告项目""新建分析项目"或"setup-anappt"时调用。
---

# Setup AnaPPT

初始化分析报告项目的工作目录，并锚定 git、生成首个 commit。

## 执行步骤

### 1. 确认目录

询问用户："在当前目录初始化，还是创建一个新项目文件夹？"

- **无参数**：目标目录 = 当前工作目录。
- **有参数**：以参数为目录名，在当前工作目录下创建子目录，目标目录 = 该子目录。

完成条件：目标目录已存在。

### 2. 锚定 git（避免嵌套仓库）

在当前工作目录执行 `git rev-parse --is-inside-work-tree` 判断是否已被某个 git 仓库覆盖：

- **已覆盖**（当前目录本身或其祖先已是 git 仓库）→ 不再 `git init`，目标目录沿用既有仓库。
  - 子目录模式下：当前目录已是仓库，子目录随之被覆盖，无需再为子目录建仓库。
- **未覆盖** → 在目标目录执行 `git init`。

完成条件：在目标目录执行 `git rev-parse --is-inside-work-tree` 返回 `true`（自身 init 或继承自祖先）。

### 3. 创建目录结构与文件

```
<目标目录>/
├── report.yml           ← 从 assets/templates/report.yml 复制
├── _报告进度.md           ← 从 assets/templates/_报告进度.md 复制
└── data/                ← 空目录，用于存放用户提供的数据文件
```

- 复制两个模板文件到目标目录，内容保持不变（所有字段为空，等待阶段 0-1 填充）。
- 创建 data/ 空目录。

完成条件：report.yml、_报告进度.md、data/ 三者均在目标目录下存在。

### 4. 首次提交

在目标目录执行：

```
git add report.yml _报告进度.md data/
git commit -m "chore: 初始化分析报告项目"
```

无论目标目录是自身仓库还是继承自父目录，git 均能正确定位并提交。

完成条件：`git log --oneline -1` 显示该 commit；`git status` 中 report.yml 与 _报告进度.md 均已跟踪、无未跟踪的项目模板文件。

### 5. 完成告知

告知用户项目已初始化，列出：

- 已创建的文件；
- git 仓库状态（新建仓库 / 沿用既有仓库）；
- 下一步：使用 `analysis-report-builder` 开始阶段 0-1 需求承接。