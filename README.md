# MSHS Multimedia Club — Join Portal

A standalone recruitment site for the MSHS Multimedia Club. It has no login/auth —
its only job is to explain the club and collect membership applications into Supabase.

## Files

- `index.html` — the entire site (HTML + CSS + JS in one file).
- `schema.sql` — the Supabase table + Row Level Security policies.
- `netlify.toml` — deployment config for Netlify.

## 1. Set up Supabase

1. Create a project at [supabase.com](https://supabase.com).
2. Open the **SQL Editor** and run the contents of `schema.sql`. This creates the
   `applications` table and locks it down with RLS so that:
   - anyone can **submit** an application (`insert`)
   - nobody using the public site can **read, edit, or delete** applications
   - officers/admins review submissions in the Supabase **Table Editor** (this uses
     your project credentials and bypasses RLS, exactly as intended for admins).
3. Go to **Project Settings → API** and copy your **Project URL** and **anon public key**.

## 2. Connect the site to your Supabase project

Open `index.html` and find this block near the bottom, inside the `<script>` tag:

```js
const SUPABASE_URL = "YOUR_SUPABASE_PROJECT_URL";
const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
```

Replace both values with the ones from your Supabase project. The anon/public key is
safe to expose in client-side code — it can only do what your RLS policies allow,
which here is limited to inserting new applications.

## 3. Run it locally

No build step needed — it's a static file. Just open `index.html` in a browser, or
serve the folder with any static server, e.g.:

```bash
npx serve .
```

## 4. Deploy to Netlify

**Option A — drag and drop:** go to [app.netlify.com/drop](https://app.netlify.com/drop)
and drag this folder in.

**Option B — Git:** push this folder to a repository, then in Netlify choose
"Import an existing project" and point it at the repo. `netlify.toml` is already
configured with `publish = "."`, so no build command is required.

## Managing applications

Applications land in the `applications` table with `status = 'Pending'`. Officers can
open the Supabase Table Editor to review each row and manually update `status` to
`Reviewed`, `Approved`, or `Declined` as they process applications. There is no
customer-facing login — review happens entirely on the Supabase side.
