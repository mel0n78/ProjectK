#!/bin/bash
# 毎日朝7時に実行する日次ニュース影響分析スクリプト
# 依存関係: claude CLI (Claude Codeのインストールのみ必要)
#
# LINE通知の設定:
#   export LINE_NOTIFY_TOKEN="your-token"
#   または .env ファイルに LINE_NOTIFY_TOKEN=your-token と記載
#   トークン取得: https://notify-bot.line.me/ → マイページ → トークンを発行する

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# .env ファイルがあれば読み込む
if [ -f "$SCRIPT_DIR/.env" ]; then
  # shellcheck disable=SC1091
  set -a; source "$SCRIPT_DIR/.env"; set +a
fi
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

# LINE通知（LINE_NOTIFY_TOKENが設定されている場合のみ送信）
if [ -n "${LINE_NOTIFY_TOKEN:-}" ]; then
  echo "LINE通知を送信中..."

  # レポートの冒頭部分を抽出（LINE Notifyは1メッセージ1000文字制限）
  # タイトル行とニュース見出しだけを抽出してサマリーを作成
  SUMMARY=$(echo "$REPORT_BODY" | grep -E "^#|^###" | head -20 | \
    sed 's/^### /  ・/g' | sed 's/^## /▶ /g' | sed 's/^# /📰 /g')

  LINE_MESSAGE="

${YESTERDAY} 重要ニュース分析レポート

${SUMMARY}

詳細: reports/news_${YESTERDAY_FILE}.md"

  # 1000文字に収める
  LINE_MESSAGE=$(echo "$LINE_MESSAGE" | cut -c1-900)

  curl -s -X POST https://notify-api.line.me/api/notify \
    -H "Authorization: Bearer ${LINE_NOTIFY_TOKEN}" \
    -F "message=${LINE_MESSAGE}" \
    -o /dev/null

  echo "✅ LINE通知を送信しました"
else
  echo "（LINE_NOTIFY_TOKEN未設定のためLINE通知はスキップ）"
fi
