# 毎朝7時に日次ニュース分析を実行するタスクスケジューラを設定するスクリプト
# APIキー不要 / Claude Codeのログイン状態を使用
#
# 実行方法（管理者権限は不要）:
#   .\setup_scheduler.ps1

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogDir = Join-Path $ScriptDir "logs"
$ScriptPath = Join-Path $ScriptDir "daily_news_analyzer.ps1"

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

# claude CLIが使えるか確認
$ClaudePath = Get-Command claude -ErrorAction SilentlyContinue
if (-not $ClaudePath) {
    Write-Host "エラー: claude コマンドが見つかりません。" -ForegroundColor Red
    Write-Host "Claude Code をインストールしてから再試行してください。"
    Write-Host "  https://claude.ai/code"
    exit 1
}

Write-Host "claude CLI: $($ClaudePath.Source)"
Write-Host ""

$TaskName = "DailyNewsAnalyzer"

# 既存のタスクがあれば削除
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "既存のタスクを削除しました。"
}

# タスクの設定
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NonInteractive -ExecutionPolicy Bypass -File `"$ScriptPath`" >> `"$LogDir\news_analyzer.log`" 2>&1"

# 毎朝7時に実行
$Trigger = New-ScheduledTaskTrigger -Daily -At "07:00"

$Settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 30) `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Description "毎朝7時に日次ニュース影響分析を実行" | Out-Null

Write-Host "✅ タスクスケジューラに登録しました。毎朝7時に自動実行されます。" -ForegroundColor Green
Write-Host ""
Write-Host "確認方法:  Get-ScheduledTask -TaskName '$TaskName'"
Write-Host "ログ確認:  Get-Content `"$LogDir\news_analyzer.log`" -Wait"
Write-Host "手動実行:  .\daily_news_analyzer.ps1"
Write-Host ""
Write-Host "タスクを削除するには:"
Write-Host "  Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false"
