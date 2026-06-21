# Hairmap Admin Web

Hairmap 的營運後台 MVP。這個網站只使用 Supabase publishable key，真正權限由 Supabase `admin_users` + RLS 控制。

## Local Run

```sh
cd admin-web
npm install
npm run dev
```

Open `http://localhost:5174`.

## Required Supabase Setup

登入的帳號必須在 `public.admin_users` 內有以下其中一個角色：

- `super_admin`
- `admin`
- `moderator`

目前後台支援：

- 髮型師申請：查看、批准、拒絕、下架
- 沙龍申請：查看、批准、拒絕、下架
- Catalog：髮型師/沙龍上下架、推薦、排序
- 靈感內容：上下架、推薦、排序、留言隱藏
- 檢舉：更新處理狀態
- 首頁/排行榜：查看與快速設定排序

## Deploy

### GitHub Pages

這個 repo 已支援把後台輸出到 `docs/admin`，再由 GitHub Pages 公開：

```sh
cd admin-web
pnpm exec tsc --noEmit
VITE_GITHUB_PAGES=true pnpm exec vite build --outDir ../docs/admin --emptyOutDir
cp ../docs/admin/index.html ../docs/admin/404.html
```

公開網址：

```text
https://kelvinfung398398-sudo.github.io/Hairmap/admin/
```

### Vercel Alternative

如果之後改用 Vercel，請設定：

```text
VITE_SUPABASE_URL
VITE_SUPABASE_PUBLISHABLE_KEY
```

不要在 Web 後台放 Supabase service role key。
