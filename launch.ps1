# 読み上げアプリ ランチャー
#   1. VOICEVOX ENGINE を裏で起動（既に動いていれば触らない）
#   2. Edge を専用プロファイルの --app モードで開く
#   3. ウィンドウが閉じたら、自分が起動したエンジンだけを終了する
#
# 注意: このファイルは必ず BOM 付き UTF-8 で保存すること。
#       BOM が無いと PowerShell 5.1 が Shift-JIS として読み、日本語パスが壊れる。

$ErrorActionPreference = 'SilentlyContinue'

$dir     = $PSScriptRoot
$html    = Join-Path $dir 'reader.html'
$profDir = Join-Path $env:LOCALAPPDATA 'yomiage-edge'
$logFile = Join-Path $dir 'launch.log'
$port    = 50021
$base    = "http://127.0.0.1:$port"

function Log($m) { "$(Get-Date -Format 'HH:mm:ss')  $m" | Out-File $logFile -Append -Encoding UTF8 }
"--- $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ---" | Out-File $logFile -Encoding UTF8
Log "dir = $dir"

# --- VOICEVOX ENGINE を探す ---
# 1つ上のフォルダの vv-engine\run.exe → VOICEVOX 本体のインストール先、の順に探す
$engine = @(
  (Join-Path (Split-Path -Parent $dir) 'vv-engine\run.exe'),
  "$env:LOCALAPPDATA\Programs\VOICEVOX\vv-engine\run.exe"
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
Log "engine = $engine"

# --- Edge を探す ---
$edge = @(
  'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
  'C:\Program Files\Microsoft\Edge\Application\msedge.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $edge) { Log 'Edge が見つかりません'; exit 1 }

function Test-Engine {
  try { $null = Invoke-WebRequest "$base/version" -TimeoutSec 1 -UseBasicParsing; return $true }
  catch { return $false }
}

# --- 1. エンジン起動 ---
$spawned = $null
if ($engine -and -not (Test-Engine)) {
  $spawned = Start-Process $engine -PassThru -WindowStyle Hidden `
             -ArgumentList '--host','127.0.0.1','--port',"$port",'--allow_origin','null'
  Log "engine spawned PID=$($spawned.Id)"
} else {
  Log 'engine: 起動済みか未検出のためスキップ'
}

# --- 2. Edge 起動 ---
# プロファイルを分けないと既存の Edge に吸収され、ウィンドウを閉じても
# プロセスが終わらず（＝終了を検知できず）エンジンを止められない
$uri = ([System.Uri]$html).AbsoluteUri
$browser = Start-Process $edge -PassThru -ArgumentList @(
  "--app=$uri",
  "--user-data-dir=$profDir",
  '--window-size=420,640',
  '--no-first-run',
  '--no-default-browser-check',
  '--disable-background-mode'   # 閉じたら確実にプロセスを終わらせる（終了検知のため）
)
Log "edge spawned PID=$($browser.Id)"

# --- 3. ウォームアップ（初回合成の待ち時間を消す） ---
if ($spawned) {
  for ($i = 0; $i -lt 60; $i++) {
    if (Test-Engine) {
      Log "engine ready ($i 秒)"
      try {
        $q = Invoke-WebRequest "$base/audio_query?speaker=3&text=$([uri]::EscapeDataString('あ'))" `
             -Method Post -UseBasicParsing -TimeoutSec 30
        $b = [Text.Encoding]::UTF8.GetString($q.RawContentStream.ToArray())
        $null = Invoke-WebRequest "$base/synthesis?speaker=3" -Method Post -Body $b `
                -ContentType 'application/json' -UseBasicParsing -TimeoutSec 60
        Log 'warmup 完了'
      } catch { Log "warmup 失敗: $_" }
      break
    }
    Start-Sleep -Milliseconds 1000
  }
}

# --- 4. ウィンドウが閉じるまで待つ ---
if ($browser) { Wait-Process -Id $browser.Id }
Log 'edge 終了を検知'

# --- 5. 自分が起動したエンジンだけ止める（子プロセスごと） ---
if ($spawned -and -not $spawned.HasExited) {
  & taskkill.exe /PID $spawned.Id /T /F 2>&1 | Out-Null
  Log "engine 停止 PID=$($spawned.Id)"
}
Log 'END'