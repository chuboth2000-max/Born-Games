# ライアーズ・デッキ / 人狼（Supabase版）セットアップ手順

友達とリンクひとつで遊べるようにするための手順です。所要時間は約10分、すべて無料枠で動きます。

## ファイル構成

| ファイル | 役割 |
|---|---|
| `index.html` | ゲーム本体（これを公開します） |
| `supabase-config.js` | SupabaseのURLとキーを書く設定ファイル（**ここだけ書き換える**） |
| `supabase-schema.sql` | Supabase側のテーブルを作るSQL（最初に1回だけ実行） |
| `server.js` | 同じWi-Fi内だけで遊ぶ用のローカルサーバー。**Supabase公開では不要**です |
| `README.md` | この手順書 |

---

## 手順1：Supabaseプロジェクトを作る

1. <https://supabase.com> にサインアップ／ログインする
2. **New project** を押し、名前・データベースのパスワード・リージョン（日本なら `Northeast Asia (Tokyo)`）を決めて作成する
3. 1〜2分待つとプロジェクトが使えるようになります

## 手順2：テーブルを作る

1. 左メニュー **SQL Editor** → **New query**
2. `supabase-schema.sql` の中身をすべて貼り付けて **Run**
3. `Success. No rows returned` と出ればOKです（1回だけ実行すればよく、再実行しても問題ありません）

これで `docs` テーブル、更新ごとにバージョンを進めるトリガー、アクセス権、リアルタイム通知が一括で設定されます。

## 手順3：URLとキーを `supabase-config.js` に書く

1. Supabaseの **Project Settings → API**（または **Connect**）を開く
2. 次の2つをコピーする
   - **Project URL**（例：`https://abcdxyz.supabase.co`）
   - **anon public** キー（`eyJ...` で始まる長い文字列。新しい画面では *Publishable key* と表示されることもあります）
3. `supabase-config.js` をテキストエディタで開き、次の2行を書き換える

```js
const SUPABASE_URL='https://abcdxyz.supabase.co';
const SUPABASE_ANON_KEY='eyJ...（コピーしたキー）';
```

> ⚠ **`service_role` キーは絶対に使わないでください。** `anon`（公開用）キーだけを入れます。anonキーはHTMLに書いて公開される前提のキーなので、そのままで問題ありません。

## 手順4：動作確認（任意）

`index.html` をブラウザで直接開いて（`supabase-config.js` と同じフォルダに置く）、部屋を作れれば成功です。「Supabaseの設定がまだです」と出る場合は、手順3の書き換え漏れです。

## 手順5：リンクを公開する

`index.html` と `supabase-config.js` は静的ファイルなので、どの無料ホスティングでも公開できます。

### A. Netlify Drop（いちばん簡単・アカウントのみ）

1. <https://app.netlify.com/drop> を開く
2. `index.html` と `supabase-config.js` を入れたフォルダをドラッグ＆ドロップ
3. 表示されたURLを友達に共有

### B. GitHub Pages

1. GitHubで新しいリポジトリを作り、`index.html` と `supabase-config.js` をアップロード
2. **Settings → Pages** で Source を `Deploy from a branch`、Branch を `main` / `(root)` にして保存
3. 数分後に `https://ユーザー名.github.io/リポジトリ名/` で公開されます

### C. Cloudflare Pages / Vercel

フォルダをアップロードするだけで公開できます。

---

## 遊び方

1. 1人が部屋を作ると4文字の部屋コードが発行されます
2. 他の人は同じリンクを開き、部屋コードを入力して参加します

## よくあるトラブル

| 症状 | 原因と対処 |
|---|---|
| 「Supabaseの設定がまだです」と出る | `supabase-config.js` の値が `YOUR-...` のまま、または `index.html` と同じ場所に置いていない。手順3をやり直す |
| 部屋を作れない・エラーになる | SQLが未実行。手順2を実行する |
| 他の人の操作がすぐ反映されない | **Database → Replication**（または Publications）で `docs` が `supabase_realtime` に入っているか確認。SQLを実行済みなら入っています。なお数秒おきの自動確認もあるため、リアルタイムが効かなくても遅れて同期されます |
| 無料プロジェクトが止まった | Supabase無料枠は1週間アクセスがないと一時停止します。ダッシュボードの **Restore** で復活します |

## データの掃除（任意）

ゲームでは削除を許可していないため、古い部屋データは溜まっていきます。たまに **SQL Editor** で次を実行してください。

```sql
delete from public.docs where updated_at < now() - interval '1 day';
```

毎日自動で掃除したい場合は、**Database → Extensions** で `pg_cron` を有効にしてから `supabase-schema.sql` 末尾のコメントにある `cron.schedule` を実行します。

## セキュリティについて

ログイン不要の簡易ゲームなので、リンクを知っている人は誰でも `docs` テーブルを読み書きできます（削除は不可）。友達内で遊ぶ用途を想定しており、秘密情報は保存しないでください。
