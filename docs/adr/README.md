# ADR 一覧

アーキテクチャ上の重要な決定を [MADR](https://adr.github.io/madr/) 形式で記録する。
1 決定 = 1 ファイル。決定を覆すときは新しい ADR を起こし、古いものは Superseded にする。

| # | タイトル | 状態 |
|---|---|---|
| [0001](0001-single-html-file.md) | 単一の HTML ファイルで作り、依存を持たない | Accepted |
| [0002](0002-voicevox-with-web-speech-fallback.md) | 音声は VOICEVOX ENGINE を使い、Web Speech API をフォールバックにする | Accepted |
| [0003](0003-english-word-detection.md) | 読めない英単語は「1 文字読みの並び」で検出して辞書に登録する | Accepted |
| [0004](0004-split-and-prefetch.md) | 文は 90 文字で分割し、2 文先読みする | Accepted |
| [0005](0005-edge-app-launcher.md) | ランチャーは Edge の専用プロファイル＋ --app モードで開く | Accepted |
| [0006](0006-allow-origin-null.md) | エンジンは `--allow_origin null` で起動し、ページは file:// から開く | Accepted |
