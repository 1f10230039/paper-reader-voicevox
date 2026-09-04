# 0002. 音声は VOICEVOX ENGINE を使い、Web Speech API をフォールバックにする

- Status: Accepted

## Context

ブラウザには `speechSynthesis`（Web Speech API）があり、追加のソフト無しで日本語を読める。
ただし声の選択肢が少なく、長い文で途中で止まる癖があり、読みの辞書を持てない。
VOICEVOX ENGINE はローカルで動く HTTP サーバーで、話者が選べ、ユーザー辞書 API がある。

## Decision Drivers

- 長時間聞いても疲れない声であること
- 専門用語の読みを直せること（辞書）
- VOICEVOX が入っていない環境でも、最低限は動くこと

## Considered Options

1. **VOICEVOX を主にし、つながらないときは Web Speech API に切り替える**
2. Web Speech API だけ — 依存ゼロだが、読みを直せず、声も選べない
3. VOICEVOX だけ — エンジンが無いと何も読めない

## Decision

オプション 1 を採用する。起動時に `/version` へ疎通確認し、つながれば VOICEVOX、
つながらなければ Web Speech API で読む。つながるまで 1.2 秒おきに 45 回まで再試行するので、
ランチャーがエンジンを起動している最中に開いても、途中から VOICEVOX に切り替わる。

## Consequences

- (+) VOICEVOX があれば声と辞書が使え、無くても読める
- (+) 再試行のおかげで、エンジンの起動を待たずにページを開ける
- (−) 再生経路が 2 本になる。発話の世代番号（`seq`）など、停止・ジャンプの制御を両方で揃える必要がある
- (−) 英単語の自動登録は VOICEVOX 側の機能なので、Web Speech API では効かない
