#!/usr/bin/env python3
"""
毎日朝7時に実行する日次ニュース影響分析スクリプト
昨日の重要ニュース3件を取り上げ、要約と5〜10年の長期的影響を分析します。
"""

import os
import json
from datetime import datetime, timedelta
from pathlib import Path
import anthropic

# レポート保存先ディレクトリ
REPORTS_DIR = Path(__file__).parent / "reports"


def get_yesterday_date() -> str:
    yesterday = datetime.now() - timedelta(days=1)
    return yesterday.strftime("%Y年%m月%d日")


def get_report_filename() -> Path:
    REPORTS_DIR.mkdir(exist_ok=True)
    yesterday = datetime.now() - timedelta(days=1)
    filename = yesterday.strftime("news_%Y%m%d.md")
    return REPORTS_DIR / filename


def analyze_news() -> str:
    client = anthropic.Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))
    yesterday = get_yesterday_date()

    system_prompt = """あなたは世界情勢・経済・テクノロジーに精通した優秀なアナリストです。
ニュースを分析する際は、以下の点を重視してください：
1. 社会・経済・テクノロジー・地政学的な影響力の大きさ
2. 長期的なトレンドとの関連性
3. 具体的で実践的な洞察
日本語で回答してください。"""

    user_message = f"""本日は{datetime.now().strftime('%Y年%m月%d日')}です。
{yesterday}（昨日）の世界のニュースの中から、最も影響力が大きいと判断される3件を選んでください。

各ニュースについて以下の形式でまとめてください：

---

# {yesterday} 重要ニュース分析レポート

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

（ニュース2、ニュース3も同じ形式で）

---

## 総括
3つのニュースを踏まえた、今後の大きなトレンドと示唆

---

web_searchツールを使って昨日({yesterday})の実際のニュースを調べてから分析してください。
経済、テクノロジー、地政学、社会変化など多様な分野から選ぶようにしてください。"""

    print(f"ニュース分析を開始します... ({yesterday})", flush=True)

    # ストリーミングで長い応答を処理
    with client.messages.stream(
        model="claude-opus-4-6",
        max_tokens=4000,
        thinking={"type": "adaptive"},
        system=system_prompt,
        tools=[
            {
                "type": "web_search_20260209",
                "name": "web_search",
            }
        ],
        messages=[{"role": "user", "content": user_message}],
    ) as stream:
        full_text = ""
        for event in stream:
            if event.type == "content_block_delta":
                if hasattr(event.delta, "text"):
                    print(event.delta.text, end="", flush=True)
                    full_text += event.delta.text

        final_message = stream.get_final_message()

    # テキストブロックを結合して最終レポートを取得
    report_text = ""
    for block in final_message.content:
        if block.type == "text":
            report_text += block.text

    return report_text


def save_report(content: str) -> Path:
    report_path = get_report_filename()
    yesterday = get_yesterday_date()

    header = f"""---
生成日時: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
対象日: {yesterday}
モデル: claude-opus-4-6
---

"""
    report_path.write_text(header + content, encoding="utf-8")
    print(f"\n\nレポートを保存しました: {report_path}")
    return report_path


def main():
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("エラー: ANTHROPIC_API_KEY 環境変数が設定されていません。")
        print("export ANTHROPIC_API_KEY='your-api-key' を実行してから再試行してください。")
        exit(1)

    print("=" * 60)
    print("📰 日次ニュース影響分析レポート")
    print(f"実行日時: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    print()

    report_content = analyze_news()
    report_path = save_report(report_content)

    print()
    print("=" * 60)
    print(f"✅ 分析完了: {report_path}")
    print("=" * 60)


if __name__ == "__main__":
    main()
