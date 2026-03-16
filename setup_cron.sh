#!/bin/bash
# 毎朝7時に日次ニュース分析を実行するcronジョブを設定するスクリプト
# APIキー不要 / Claude Codeのログイン状態を使用

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"

mkdir -p "$LOG_DIR"

# claude CLIが使えるか確認
if ! command -v claude &>/dev/null; then
    echo "エラー: claude コマンドが見つかりません。"
    echo "Claude Code をインストールしてから再試行してください。"
    echo "  https://claude.ai/code"
    exit 1
fi

echo "claude CLI: $(which claude)"
echo ""

# cronエントリー（毎朝7時に実行）
CRON_JOB="0 7 * * * $SCRIPT_DIR/daily_news_analyzer.sh >> $LOG_DIR/news_analyzer.log 2>&1"

echo "設定するcronジョブ:"
echo "  $CRON_JOB"
echo ""

# 既存のエントリーから重複を除いて新しいジョブを追加
(crontab -l 2>/dev/null | grep -v "daily_news_analyzer"; echo "$CRON_JOB") | crontab -

echo "✅ cronジョブを設定しました。毎朝7時に自動実行されます。"
echo ""
echo "確認方法:  crontab -l"
echo "ログ確認:  tail -f $LOG_DIR/news_analyzer.log"
echo "手動実行:  $SCRIPT_DIR/daily_news_analyzer.sh"
echo ""
echo "cronジョブを削除するには:"
echo "  crontab -l | grep -v 'daily_news_analyzer' | crontab -"
