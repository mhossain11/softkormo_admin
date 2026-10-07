# SoftKormo Admin Panel

A production-ready **Flutter Web admin panel** that acts as the CMS for the SoftKormo
corporate website. Every page you see in the admin is backed by real Firestore CRUD —
there is no mock data and no hard-coded content anywhere in the app.

The public website reads the **same** Firestore collections, so publishing a project,
changing a price or swapping the company logo in the admin updates the site instantly.

* Firebase project: **`softkormo-8ea9c`**
* Stack: Flutter Web · Dart · Material 3 · GetX · GetIt · Firebase (Auth / Firestore / Storage)

---

## Table of contents

1. [Features](#features)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Getting started](#getting-started)
5. [Firebase setup](#firebase-setup)
   - [Create the first administrator](#1-create-the-first-administrator)
   - [Authentication provider](#2-enable-the-emailpassword-provider)
   - [Security rules and indexes](#3-security-rules-and-indexes)
   - [Cloud Storage](#4-cloud-storage)
6. [Data model](#data-model)
7. [Storage layout](#storage-layout)
8. [Security rules summary](#security-rules-summary)
9. [Performance and rebuild strategy](#performance-and-rebuild-strategy)
10. [Responsive design and theming](#responsive-design-and-theming)
11. [Testing](#testing)
12. [Build and deploy](#build-and-deploy)
13. [Project structure](#project-structure)
14. [Troubleshooting](#troubleshooting)

---

## Features

| Area | What it does |
| --- | --- |
| **Login** | Firebase Auth sign-in → `admins/{uid}` profile check (`active` + `role`) → dashboard. Unknown or deactivated accounts are signed out immediately. |
| **Dashboard** | Count-aggregation stats, 6 most recent contacts, monthly contact volume (6 months) and contact-status breakdown — each section loads independently with its own loading/error state. |
| **Contacts (CRM)** | List, search, status filter, status change, detail view, delete. Ordered by `createdAt` desc. |
| **Projects** | Full CRUD, thumbnail + gallery upload with client-side compression, category filter, featured/published flags, drag-free reorder, batch delete with Storage cleanup. |
| **Services** | Full CRUD, feature list, icon picker, publish toggle, reorder. |
| **Packages** | Full CRUD, price/currency/billing label, feature list, recommended/active flags, reorder. |
| **Testimonials** | Full CRUD, avatar upload, rating (1–5), featured/published flags, reorder. |
| **Settings** | Single document `settings/site`: company profile, contact details, social links, logo upload. |
| **UI** | Light + dark themes, sidebar/header shell that never rebuilds on navigation, toasts through one notification system, tooltips on icon buttons, loading / empty / error states everywhere. |

Every CMS list shares the same behaviour: **400 ms debounced search → filter → sort →
cursor pagination (20 per page)** with an aggregation count for the total, so a page
load never downloads more than one page of documents.

---

## Architecture

Strict layering — UI code never touches the Firebase SDK:

```
UI (page/widget)
   └── GetX controller (state, small Obx scopes)
         └── Repository (query + model mapping)
               └── FirebaseService / FirestoreService / StorageService / AuthService
                     └── Firebase SDK
```

* **Feature-first** layout: `lib/{app,core,shared,features}` — `app` (shell, routes,
  theme), `core` (services, state base classes, theme tokens, widgets, utils),
  `features/*` (one folder per module with `data/`, `domain/`, `presentation/`).
* **Dependency injection** with GetIt (`lib/core/di/injection.dart`): Firebase services
  are registered eagerly, repositories and controllers lazily — a controller is only
  created the first time its page opens.
* **Reusable base classes**: `ListRepository<T>` implements pagination, search, filters,
  CRUD and batch reorder once; `PagedController` / `CmsListController` implement the
  state machine once. A new CMS module is ~4 small files.
* **Design tokens** live in `lib/core/theme/` (`AppColors`, `AppTypography`,
  `AppSpacing`, `AppRadius`, `AppDimensions`, `AppBreakpoints`) — no magic numbers.

---

## Prerequisites

* Flutter **3.44.x** (Dart 3.10+) — `flutter --version`
* Node.js + Firebase CLI (`npm i -g firebase-tools`) for deploying rules/indexes
* A Firebase project with the **Blaze plan** if you need Cloud Storage (see
  [Cloud Storage](#4-cloud-storage))

---

## Getting started

```bash
flutter pub get
flutter run -d chrome          # development
flutter analyze                # must print "No issues found!"
flutter test                   # all tests must pass
flutter build web --release    # output in build/web
```

`lib/firebase_options.dart` is already generated for project **`softkormo-8ea9c`** and is
wired up in `lib/main.dart` — nothing else is required to talk to Firebase. If you ever
migrate projects, regenerate it with:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project softkormo-8ea9c
```

---

## Firebase setup

### 1. Create the first administrator

Authentication and Firestore are separate: signing in is not enough, the user must also
have a profile document.

1. **Firebase Console → Authentication → Users → Add user**
   (e.g. `admin@softkormo.com` / a strong password). Copy the generated **UID**.
2. **Firestore Database → Start collection `admins`**
   * Document ID = **the UID from step 1**
   * `name` (string) — display name
   * `email` (string) — must match the Auth user
   * `role` (string) — `super_admin` or `admin`
   * `active` (boolean) — `true`
   * `createdAt` (timestamp) — now

Sign in at `/login`. Setting `active` to `false` revokes access on the next
authentication check; deleting the document does the same.

> Passwords are never stored in Firestore. `admins/*` is readable only by its own owner
> and is not writable by any client — provision users through the console or the
> Admin SDK.

### 2. Enable the email/password provider

**Firebase Console → Authentication → Sign-in method → Email/Password → Enable.**

### 3. Security rules and indexes

Both files are in the repository root and already deployed to `softkormo-8ea9c`:

| File | Purpose |
| --- | --- |
| `firestore.rules` | Admin-only writes, public reads of published/active content, contacts create-only, catch-all deny. |
| `firestore.indexes.json` | 11 composite indexes backing the list filters. |
| `storage.rules` | Public read of published assets, authenticated, size/type-limited writes. |

```bash
firebase deploy --only firestore:rules,firestore:indexes --project softkormo-8ea9c
firebase deploy --only storage:rules                   --project softkormo-8ea9c
```

`firebase.json` points at all three files, so a plain `firebase deploy` keeps them in
sync too.

### 4. Cloud Storage

Image uploads (project thumbnails/galleries, testimonial avatars, site logo) go through
Firebase Storage. Storage requires the **Blaze plan** — if the project's billing account
is closed you will see:

```
Firebase Storage has not been set up on project 'softkormo-8ea9c'.
Go to https://console.firebase.google.com/project/softkormo-8ea9c/storage and click 'Get Started'.
```

To fix it: enable billing on the project, open the Storage page, click **Get Started**
(default bucket `softkormo-8ea9c.appspot.com`), then deploy `storage.rules` with the
command above. Everything else (auth, Firestore CRUD, dashboard) works without billing.

---

## Data model

| Collection / doc | Key fields | Written by | Read by the website |
| --- | --- | --- | --- |
| `admins/{uid}` | `name`, `email`, `role`, `active`, `createdAt` | console / Admin SDK | no |
| `contacts/{id}` | `name`, `email`, `phone`, `service`, `message`, `status`, `source`, `createdAt` | public form (**create only**), admins update `status` | never (admin only) |
| `projects/{id}` | `title`, `slug`, `shortDescription`, `description`, `category`, `year`, `thumbnail`, `images[]`, `technologies[]`, `client`, `githubUrl`, `projectUrl`, `featured`, `published`, `order`, `createdAt`, `updatedAt` | admin | `published == true` |
| `services/{id}` | `title`, `shortDescription`, `description`, `icon`, `features[]`, `order`, `published`, timestamps | admin | `published == true` |
| `packages/{id}` | `name`, `subtitle`, `price`, `currency`, `billingLabel`, `description`, `features[]`, `recommended`, `active`, `order`, `ctaLabel`, timestamps | admin | `active == true` |
| `testimonials/{id}` | `name`, `designation`, `company`, `message`, `rating`, `imageUrl`, `featured`, `published`, `order`, timestamps | admin | `published == true` |
| `settings/site` | `companyName`, `tagline`, `email`, `phone`, `address`, `facebook`, `linkedin`, `github`, `youtube`, `logoUrl`, `updatedAt` | admin | yes (public by definition) |

List queries per module:

| Module | Order | Search field | Filter field |
| --- | --- | --- | --- |
| Contacts | `createdAt` desc | `name` | `status` |
| Projects | `order` | `title` | `category` |
| Services | `order` | `title` | `published` |
| Packages | `order` | `name` | `active` |
| Testimonials | `order` | `name` | `published` |

New CMS entries default to `published` / `active = true`, `order = max + 1`, and get
`createdAt`/`updatedAt` timestamps written by the controller.

---

## Storage layout

```
projects/{projectId}/thumbnail                 # compressed project thumbnail
projects/{projectId}/gallery/{ts}_{name}       # gallery images
testimonials/{id}/{ts}_{name}                  # testimonial avatar
settings/logo/{ts}_{name}                      # company logo
```

Images are resized/re-encoded client-side (`lib/core/utils/image_optimizer.dart`)
before upload; list screens only ever render thumbnails. Deleting an entry also deletes
its files — failures are reported to the user, never swallowed
(`MediaStorage.deleteUrls` returns the URLs that could not be removed).

---

## Security rules summary

`firestore.rules`:

* `isAdmin()` = signed in **and** `admins/{uid}.active == true` **and**
  `role in ['admin','super_admin']` (one `get()` per request).
* `contacts`: `create` only, with `keys().hasOnly([...])`, `status == 'new'` and
  `createdAt == request.time`; reading/updating/deleting is admin-only — the public
  can never read leads.
* `projects` / `services` / `testimonials`: `read` if admin or `published == true`;
  `packages`: `read` if admin or `active == true`; **writes always require admin**.
* `admins`: owner `get()` only, writes denied.
* `settings`: public read, admin write.
* Everything else: denied.

`storage.rules`: world-readable for `settings/` and `testimonials/` (published assets),
authenticated reads for `projects/`, writes limited to authenticated users, `image/*`
content type and < 1 MB. Storage rules cannot read Firestore, so role enforcement there
relies on Authentication; the upload paths are only reachable from the admin panel.

---

## Performance and rebuild strategy

* **Pagination** — `orderBy + limit(20) + startAfterDocument`; totals come from
  count aggregation, which reads no documents.
* **Dashboard** — every stat/chart is a `count()` query or a `limit()` query.
* **Search** — 400 ms debounce, single-field prefix range (no full collection scan).
* **Rebuilds** — small `Obx` scopes around individual rows/cards; `AdminShell`
  (sidebar/header) is outside the nested navigator, so navigating never rebuilds it.
* **Images** — `cached_network_image` + thumbnails only in lists.
* **Routes** — a single root route `/login` plus `/admin`; CMS pages live in the admin
  shell's own `Navigator` with zero-transition `PageRouteBuilder`s.

---

## Responsive design and theming

* Breakpoints: **768 / 1024 / 1440** (`lib/core/theme/app_breakpoints.dart`), sidebar
  collapses to a drawer on small screens.
* Layouts are verified at **360 / 768 / 1024 / 1440 / 1920** by widget tests —
  `RenderFlex` overflow = test failure.
* Material 3 light **and** dark themes, toggle persisted by `ThemeController`.
* Icon-only controls carry tooltips; forms use labels, not placeholder-only fields.

---

## Testing

```bash
flutter test
```

97 tests across:

| Suite | Covers |
| --- | --- |
| `test/core/map_reader_test.dart`, `validators_test.dart` | null-safe parsing and form validation |
| `test/core/list_repository_test.dart` | query building, batch reorder, error guard |
| `test/core/paged_controller_test.dart`, `cms_list_controller_test.dart` | pagination, debounce, filters, optimistic mutations |
| `test/core/media_storage_test.dart` | Storage path parsing and file naming |
| `test/models/models_test.dart` | every model's `fromMap`/`toMap` round trip and legacy data tolerance |
| `test/features/auth_controller_test.dart` | session restore, unknown/inactive accounts, sign-out |
| `test/widgets/responsive_test.dart` | breakpoint logic + overflow checks at 5 widths |

Tests never construct real Firebase objects: repositories are faked above
`ListRepository`, so the suite runs offline and fast.

---

## Build and deploy

```bash
# 1. quality gates
flutter analyze
flutter test

# 2. production build (output: build/web)
flutter build web --release

# 3. deploy rules + indexes
firebase deploy --only firestore:rules,firestore:indexes --project softkormo-8ea9c
firebase deploy --only storage:rules --project softkormo-8ea9c

# 4. deploy the site to Firebase Hosting (uploads build/web)
firebase deploy --only hosting --project softkormo-8ea9c
```

`firebase.json` already contains the Hosting configuration:

* `public: build/web` with an SPA rewrite to `/index.html`, so deep links such as
  `/admin/contacts` resolve (the app itself uses the `#/...` hash routes).
* `index.html`, `flutter_bootstrap.js`, `main.dart.js`, `version.json` and
  `flutter_service_worker.js` are served `no-cache` so a new release reaches users
  immediately; `canvaskit/**` and `/assets/**` get long-lived caching.

To deploy everything at once (Firestore + Hosting, Storage only once billing is
enabled): `firebase deploy --project softkormo-8ea9c`.

---

## Project structure

```
lib/
├── main.dart                 # Firebase init, DI, AuthController.start()
├── firebase_options.dart     # softkormo-8ea9c (generated — keep)
├── app/
│   ├── app.dart              # GetMaterialApp, root routes, theme
│   ├── routes/app_routes.dart
│   ├── theme_controller.dart
│   └── shell/                # AdminShell nested navigator + sidebar state
├── core/
│   ├── data/                 # ListRepository, PageResult, MediaStorage
│   ├── di/injection.dart     # GetIt registrations
│   ├── errors/               # AppException, user facing messages
│   ├── services/             # Firebase/Auth/Firestore/Storage services
│   ├── state/                # PagedController, CmsListController
│   ├── theme/                # design tokens, breakpoints, AppTheme
│   ├── utils/                # debouncer, validators, formatters, image optimizer
│   └── widgets/              # AppCard, ListToolbar, AppDataTable, forms, states…
└── features/
    ├── auth/                 # login, AuthMiddleware, AdminUser
    ├── dashboard/            # stats, charts
    ├── contacts/  projects/  services/  packages/  testimonials/  settings/
    │   ├── data/             # repository (extends ListRepository)
    │   ├── domain/           # model with fromMap/toMap
    │   └── presentation/     # page, form, controller
test/                         # models, repositories, controllers, widgets
firebase.json
firestore.rules
firestore.indexes.json
storage.rules
```

---

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `permission-denied` on save | The signed-in user has no active `admins/{uid}` document, or the rules were not deployed. |
| `failed-precondition` / index error | A filter+sort combination has no composite index — add it to `firestore.indexes.json` and redeploy (the console link in the error names the exact index). |
| Login loops back to `/login` | Profile missing or `active: false`; the app signs the user out by design. |
| Uploads fail with a Storage error | Cloud Storage not provisioned → enable billing and click **Get Started** (see [Cloud Storage](#4-cloud-storage)). |
| `No issues found!` regresses after an edit | `flutter analyze` treats lints from `flutter_lints` as issues — keep it at zero. |
| A release seems not to reach users | Keep the `no-cache` rules for `index.html` / `flutter_bootstrap.js` / `main.dart.js` in `firebase.json`; without them browsers cache the bundle for a year. |
