#!/bin/bash
# 毎朝7時に日次ニュース分析を実行するcronジョブを設定するスクリプト

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_PATH="$(which python3)"
LOG_DIR="$SCRIPT_DIR/logs"

mkdir -p "$LOG_DIR"

# ANTHROPIC_API_KEYが設定されているか確認
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "警告: ANTHROPIC_API_KEY が設定されていません。"
    echo "cronジョブにAPIキーを設定するには、以下のいずれかを実行してください:"
    echo "  1. ~/.bashrc または ~/.zshrc に export ANTHROPIC_API_KEY='your-key' を追加"
    echo "  2. setup_cron.sh を直接編集して ANTHROPIC_API_KEY を設定"
    echo ""
fi

# cronエントリーを生成（毎朝7時に実行）
# ANTHROPIC_API_KEYはcron環境では引き継がれないため、明示的に設定
CRON_JOB="0 7 * * * ANTHROPIC_API_KEY=\"${ANTHROPIC_API_KEY}\" $PYTHON_PATH $SCRIPT_DIR/daily_news_analyzer.py >> $LOG_DIR/news_analyzer.log 2>&1"

echo "設定するcronジョブ:"
echo "  $CRON_JOB"
echo ""

# 既存のcronジョブから重複を除いて新しいジョブを追加
(crontab -l 2>/dev/null | grep -v "daily_news_analyzer.py"; echo "$CRON_JOB") | crontab -

echo "✅ cronジョブを設定しました。毎朝7時に自動実行されます。"
echo ""
echo "確認方法: crontab -l"
echo "ログ確認: tail -f $LOG_DIR/news_analyzer.log"
echo "手動実行: python3 $SCRIPT_DIR/daily_news_analyzer.py"
echo ""
echo "cronジョブを削除するには:"
echo "  crontab -l | grep -v 'daily_news_analyzer.py' | crontab -"
