[![Deploy static content to Pages](https://github.com/gtref/tools-hub/actions/workflows/static.yml/badge.svg)](https://github.com/gtref/tools-hub/actions/workflows/static.yml)

# 🛠️ Linux Dev Tools Hub

A modern, responsive, open-source web application for discovering and showcasing essential Linux CLI tools, system utilities, and developer productivity software.

---

## ✨ Features

- 🎨 **Modern Dark UI**: Inspired by GitHub's dark theme with sleek typography, responsive cards, and clean controls.
- 🔐 **User Accounts & Authentication**: Full Supabase Auth integration supporting email/password Sign Up, Sign In, and Sign Out.
- 🔍 **Search & Filter**: Real-time search across package titles, descriptions, and authors, plus category filtering (`CLI Tool`, `System Monitor`, `Dev Utilities`, `Networking`, `Security`).
- ⚡ **Sorting Options**: Sort tools by **🔥 Most Upvoted** or **✨ Newest First**.
- 🔼 **Upvoting System**: Instant upvoting with state persistence for authenticated users.
- 💬 **Interactive Toast Notifications & Loaders**: Responsive feedback for auth actions, package submissions, and data fetching.

---

## 🛠️ Local Development & Quick Start

### 1. Prerequisites
- Node.js (v18+)
- npm or yarn

### 2. Start Local Server
Run the local static development server:

```bash
npm start
```

Or open `index.html` directly in any modern browser! The single-file architecture requires no build step or bundler.

---

## 🗄️ Database Setup (Supabase SQL)

To set up your own Supabase database backend:

1. Create a project at [supabase.com](https://supabase.com).
2. Go to the **SQL Editor** in your Supabase dashboard.
3. Paste and run the contents of `schema.sql`.

The schema creates `packages` and `upvotes` tables with foreign keys linked to `auth.users`, configures Row Level Security (RLS) policies, and sets up indexes for fast queries.

---

## 📁 Repository Structure

```
├── index.html       # Single-page web app (HTML + CSS + ES Module JavaScript)
├── schema.sql       # PostgreSQL / Supabase Database Schema & RLS policies
├── package.json     # Node project definition & development scripts
├── .env.example     # Environment variable reference
└── README.md        # Project documentation & setup guide
```

---

## 🤝 Contributing

1. Fork the repository.
2. Submit your favorite Linux tools using the **Submit Tool** button in the app.
3. Open a PR for any new feature or bug fix!
