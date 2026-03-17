# 毎日朝7時に実行する日次ニュース影響分析スクリプト (Windows PowerShell版)
# 依存関係: claude CLI (Claude Codeのインストールのみ必要)
#
# LINE通知の設定:
#   $env:LINE_NOTIFY_TOKEN = "your-token"
#   または .env ファイルに LINE_NOTIFY_TOKEN=your-token と記載
#   トークン取得: https://notify-bot.line.me/ → マイページ → トークンを発行する
#
# 実行方法:
#   .\daily_news_analyzer.ps1
#
# タスクスケジューラで毎朝自動実行する場合:
#   setup_scheduler.ps1 を実行してください

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# .env ファイルがあれば読み込む
$envFile = Join-Path $ScriptDir ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^\s*([^#][^=]*?)\s*=\s*(.*)\s*$") {
            [System.Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], "Process")
        }
    }
}

$ReportsDir = Join-Path $ScriptDir "reports"
$Yesterday = (Get-Date).AddDays(-1)
$YesterdayJp = $Yesterday.ToString("yyyy年MM月dd日")
$YesterdayFile = $Yesterday.ToString("yyyyMMdd")
$Today = (Get-Date).ToString("yyyy年MM月dd日")
$ReportPath = Join-Path $ReportsDir "news_$YesterdayFile.md"

New-Item -ItemType Directory -Force -Path $ReportsDir | Out-Null

Write-Host "========================================"
Write-Host "📰 日次ニュース影響分析レポート"
Write-Host "実行日時: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "========================================"
Write-Host ""

$Prompt = @"
本日は${Today}です。
${YesterdayJp}（昨日）の世界のニュースの中から、最も影響力が大きいと判断される3件を選んでください。

WebSearchツールを使って昨日(${YesterdayJp})の実際のニュースを調べてから分析してください。
経済・テクノロジー・地政学・社会変化など多様な分野から選ぶようにしてください。

各ニュースについて以下のMarkdown形式でまとめてください：

# ${YesterdayJp} 重要ニュース分析レポート

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
3つのニュースを踏まえた、今後の大きなトレンドと示唆
"@

# claude CLIで分析実行（APIキー不要 / WebSearch有効）
$ReportBody = claude -p $Prompt --allowedTools "WebSearch" --output-format text

# ヘッダーを付けてファイルに保存
$Header = @"
---
生成日時: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
対象日: $YesterdayJp
---

"@
($Header + $ReportBody) | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "✅ 分析完了: $ReportPath"
Write-Host "========================================"

# LINE通知（LINE_NOTIFY_TOKENが設定されている場合のみ送信）
$LineToken = [System.Environment]::GetEnvironmentVariable("LINE_NOTIFY_TOKEN", "Process")
if ($LineToken) {
    Write-Host "LINE通知を送信中..."

    # タイトル行とニュース見出しだけを抽出してサマリーを作成
    $SummaryLines = $ReportBody -split "`n" | Where-Object { $_ -match "^#" } | Select-Object -First 20
    $Summary = $SummaryLines | ForEach-Object {
        $_ -replace "^### ", "  ・" -replace "^## ", "▶ " -replace "^# ", "📰 "
    }
    $SummaryText = ($Summary -join "`n")

    $LineMessage = "`n`n${YesterdayJp} 重要ニュース分析レポート`n`n${SummaryText}`n`n詳細: reports/news_${YesterdayFile}.md"
    # 900文字に収める
    if ($LineMessage.Length -gt 900) {
        $LineMessage = $LineMessage.Substring(0, 900)
    }

    $Body = "message=$([System.Uri]::EscapeDataString($LineMessage))"
    Invoke-RestMethod -Uri "https://notify-api.line.me/api/notify" `
        -Method Post `
        -Headers @{ Authorization = "Bearer $LineToken" } `
        -ContentType "application/x-www-form-urlencoded" `
        -Body $Body | Out-Null

    Write-Host "✅ LINE通知を送信しました"
} else {
    Write-Host "（LINE_NOTIFY_TOKEN未設定のためLINE通知はスキップ）"
}
