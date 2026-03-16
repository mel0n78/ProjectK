#!/bin/bash
# 毎日朝7時に実行する日次ニュース影響分析スクリプト
# 依存関係: claude CLI (Claude Codeのインストールのみ必要)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS_DIR="$SCRIPT_DIR/reports"
YESTERDAY=$(date -d "yesterday" +"%Y年%m月%d日" 2>/dev/null || date -v-1d +"%Y年%m月%d日")
YESTERDAY_FILE=$(date -d "yesterday" +"%Y%m%d" 2>/dev/null || date -v-1d +"%Y%m%d")
TODAY=$(date +"%Y年%m月%d日")
REPORT_PATH="$REPORTS_DIR/news_${YESTERDAY_FILE}.md"

mkdir -p "$REPORTS_DIR"

echo "========================================"
echo "📰 日次ニュース影響分析レポート"
echo "実行日時: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

PROMPT="本日は${TODAY}です。
${YESTERDAY}（昨日）の世界のニュースの中から、最も影響力が大きいと判断される3件を選んでください。

WebSearchツールを使って昨日(${YESTERDAY})の実際のニュースを調べてから分析してください。
経済・テクノロジー・地政学・社会変化など多様な分野から選ぶようにしてください。

各ニュースについて以下のMarkdown形式でまとめてください：

# ${YESTERDAY} 重要ニュース分析レポート

## ニュース1: [タイトル]

### 概要
（200字程度で要約）

### 5年後への影響
（このニュースが今後5年間でどのような変化をもたらすか）

### 10年後への影響
（このニュースが今後10年間でどのような変化をもたらすか）

### 注目すべきポイント
（投資家・ビジネスパーソン・個人として特に注目すべき点）

---

（ニュース2、ニュース3も同じ形式で続ける）

---

## 総括
3つのニュースを踏まえた、今後の大きなトレンドと示唆"

# claude CLIで分析実行（APIキー不要 / WebSearch有効）
REPORT_BODY=$(claude -p "$PROMPT" \
  --allowedTools "WebSearch" \
  --output-format text)

# ヘッダーを付けてファイルに保存
cat > "$REPORT_PATH" <<EOF
---
生成日時: $(date '+%Y-%m-%d %H:%M:%S')
対象日: ${YESTERDAY}
---

$REPORT_BODY
EOF

echo ""
echo "========================================"
echo "✅ 分析完了: $REPORT_PATH"
echo "========================================"
