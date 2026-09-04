# 0006. エンジンは `--allow_origin null` で起動し、ページは file:// から開く

- Status: Accepted

## Context

`reader.html` は `file://` で開く（→ [ADR-0001](0001-single-html-file.md)）。
`file://` から開いたページの origin は `null` になるため、VOICEVOX ENGINE の既定の CORS 設定では
`fetch` が弾かれる。

## Decision Drivers

- ページを静的ファイルのまま保つこと
- 追加のサーバーを立てないこと
- ローカル以外からエンジンに届かないこと

## Considered Options

1. **エンジンを `--allow_origin null` で起動する**
2. ページをローカル HTTP サーバーで配信する — origin が `http://127.0.0.1:port` になり CORS は通るが、
   サーバーが 1 つ増える
3. エンジンを `--allow_origin *` で起動する — 通るが、どのページからでも辞書を書き換えられる

## Decision

オプション 1 を採用する。エンジンは `--host 127.0.0.1 --port 50021 --allow_origin null` で起動する。
ランチャーはこの引数を必ず付け、手で起動する場合も同じ引数を使うよう使い方に書く。

## Consequences

- (+) ページは静的ファイルのままで、サーバーを増やさない
- (+) `--host 127.0.0.1` なので、LAN の他端末からはエンジンに届かない
- (−) `null` origin は file:// 全般に共通なので、同じ PC で開いた他のローカル HTML からも
  エンジンを叩ける。個人の PC で使う前提の割り切り
- (−) 引数を忘れると「未接続」になる。設定パネルにその旨の案内を出している
