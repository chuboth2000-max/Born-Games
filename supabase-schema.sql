-- ============================================================
--  ライアーズ・デッキ / 人狼  用の Supabase スキーマ
--  使い方: Supabase ダッシュボード → SQL Editor → 「New query」に
--          このファイルの中身をすべて貼り付けて「Run」を押します（1回だけ）。
-- ============================================================

-- ゲームの状態を「パス」単位で保存するテーブル
--   path : rooms/ABCD（部屋の状態）, emotes/ABCD（絵文字）, wchat/ABCD_xxxx（人狼のチャット）など
--   room : 部屋コード（4文字）。リアルタイム通知を部屋ごとに絞るために使います
--   ver  : 更新のたびに自動で増える番号。同時に書き込んだときの競合検出に使います
create table if not exists public.docs (
  path       text primary key,
  room       text not null,
  data       jsonb not null default '{}'::jsonb,
  ver        bigint not null default 1,
  updated_at timestamptz not null default now()
);

create index if not exists docs_room_idx on public.docs (room);
create index if not exists docs_updated_idx on public.docs (updated_at);

-- 更新のたびに ver を +1 し、更新時刻を記録する
create or replace function public.docs_bump()
returns trigger
language plpgsql
as $$
begin
  new.ver := old.ver + 1;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists docs_bump_t on public.docs;
create trigger docs_bump_t
  before update on public.docs
  for each row execute function public.docs_bump();

-- アクセス権（Row Level Security）
--   ログイン不要の簡易ゲームなので、anon キーで読み書きできるようにします。
--   削除（delete）はゲームからは行わないので許可しません。
alter table public.docs enable row level security;

drop policy if exists "docs read"   on public.docs;
drop policy if exists "docs insert" on public.docs;
drop policy if exists "docs update" on public.docs;

create policy "docs read"   on public.docs for select to anon using (true);
create policy "docs insert" on public.docs for insert to anon with check (true);
create policy "docs update" on public.docs for update to anon using (true) with check (true);

-- リアルタイム（変更を全員の画面へすぐ届ける）を有効にする
alter publication supabase_realtime add table public.docs;

-- ============================================================
--  おまけ: 古い部屋データの掃除（容量を節約したいときに SQL Editor で実行）
-- ============================================================
-- delete from public.docs where updated_at < now() - interval '1 day';
--
-- 自動で毎日掃除したい場合（Database → Extensions で pg_cron を有効にしてから実行）:
-- select cron.schedule('docs-cleanup', '0 4 * * *',
--   $$ delete from public.docs where updated_at < now() - interval '1 day' $$);
