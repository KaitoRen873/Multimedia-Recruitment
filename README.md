# MSHS Multimedia Club — Join Portal

A recruitment site for the MSHS Multimedia Club. Registering here **creates a real
Supabase Auth account** (email + password) in the same Supabase project as your main
club website, so members can log in there with the same credentials. It also includes
an **admin dashboard** (`admin.html`) for officers to review and manage applications.

## Files

- `index.html` — the public recruitment site + registration form.
- `admin.html` — officer-only login and applications dashboard.
- `schema.sql` — Supabase tables, triggers, and Row Level Security policies.
- `netlify.toml` — optional deployment config for Netlify (safe to ignore/delete if you're using GitHub Pages or another host).

## 1. Set up Supabase

1. Use the **same Supabase project** as your main club website (this is what lets an
   account created here log in over there).
2. Open the **SQL Editor** and run all of `schema.sql`. This creates:
   - `public.profiles` — one row per user, with a `role` of `'member'` or `'admin'`, auto-created whenever someone signs up.
   - `public.applications` — the membership applications, with a `user_id` linking each one to the applicant's account.
   - RLS policies so that: anyone can submit an application; only admins can view, update, or delete applications; every user can see their own profile row (needed for the admin dashboard's role check).
3. In **Authentication → Providers**, make sure **Email** sign-up is enabled. Under
   **Authentication → Settings**, decide whether "Confirm email" is on — if it's on,
   new members must click a confirmation link before they can log in (the form already
   tells them this when it applies).
4. Go to **Project Settings → API** and copy your **Project URL** and **anon public key**.

## 2. Connect both pages to Supabase

In **both** `index.html` and `admin.html`, find:

```js
const SUPABASE_URL = "YOUR_SUPABASE_PROJECT_URL";
const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
```

and replace with your real values — **the same values in both files**, since they
need to point at the same project.

## 3. Point registration at your main site's login page

In `index.html`, find:

```js
const MAIN_SITE_LOGIN_URL = "https://your-main-club-website.example.com/login";
```

and set it to your main website's actual login URL. After a successful registration,
members see a "Go to Member Login" button that sends them there.

## 4. Create your first admin

New accounts default to `role = 'member'`. To make yourself an admin:

1. Register once through the Join Portal's form (or sign up directly in Supabase Auth) using the account you want to use as an officer/admin.
2. In the Supabase SQL Editor, run:
   ```sql
   update public.profiles set role = 'admin' where email = 'your-email@example.com';
   ```
3. You can now sign in at `admin.html` with that email and password.

Promote additional officers the same way — this must be done from the SQL editor
(or your own internal tool using the service role key), never from the public site,
so nobody can grant themselves admin access.

## 5. Run it locally

No build step needed — both pages are static files. Open `index.html` or `admin.html`
directly in a browser, or serve the folder with:

```bash
npx serve .
```

## 6. Deploy

**GitHub Pages:** push this folder to a repo, then in **Settings → Pages** set the
source to your branch/folder. You'll get a URL like
`https://yourusername.github.io/your-repo-name/` — `admin.html` will be reachable at
`.../admin.html`. (`netlify.toml` isn't used here — you can leave or delete it.)

**Netlify:** drag the folder into [app.netlify.com/drop](https://app.netlify.com/drop),
or connect a Git repo. `netlify.toml` is already configured for a no-build static deploy.

> `admin.html` isn't linked from the public navigation, but it isn't secret either —
> anyone can find the URL. That's fine: the real protection is the Supabase login +
> admin role check, not the URL being hidden.

## How it fits together

- **Join Portal (`index.html`)** — public. Registering calls `supabase.auth.signUp()`
  to create the member's login, then inserts a row into `applications` linked to that
  account. No admin powers here.
- **Main club website** — separate, existing site. Members log in there using the
  email/password they set on the Join Portal, since it's the same Supabase project.
- **Admin Dashboard (`admin.html`)** — officers sign in, the page checks their
  `profiles.role`, and only admins get past the login screen. From there they can
  search, filter (by status/specialty/grade), update an application's status
  (Pending/Reviewed/Approved/Declined), or delete an entry.
