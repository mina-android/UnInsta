<div align="center">

<img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" alt="UnInsta Logo" width="120" height="120" style="border-radius: 24px"/>

<h1>UnInsta</h1>

<h3>An Instagram follower analyzer that stays on your phone, not in the cloud</h3>

[![Platform](https://img.shields.io/badge/Platform-Flutter%20%7C%20Android%20%7C%20iOS%20%7C%20Desktop-3DDC84?logo=flutter&logoColor=white)](https://flutter.dev) [![Version](https://img.shields.io/badge/Version-1.0.1-brightgreen)](changelog.md) [![License](https://img.shields.io/badge/License-GPL--3.0-blue)](LICENSE)

UnInsta is a simple, private app that helps anyone analyze their Instagram follower dynamics with complete peace of mind.  
It works completely offline, with no sign-ups or ads, and your personal Instagram data never leaves your device.

[**Download**](#-download) · [**Features**](#-what-you-can-do) · [**Getting Started**](#-getting-started) · [**FAQ**](#-questions-you-might-have) · [**For Developers**](#-for-developers)

</div>

---

## ✨ What you can do

- **🚫 Don't Follow Back**: Instantly spot accounts you follow that don't follow you back, and open their profiles in one tap.
- **⏳ Pending Follow Requests**: View all outbound follow requests you sent that are still waiting to be accepted.
- **⭐ Fans**: Discover who follows your profile even though you don't follow them back.
- **🤝 Mutual Connections**: Easily see all accounts with two-way, reciprocal following.
- **📉 Who Unfollowed Me**: Compare consecutive exports to see exactly which accounts unfollowed you over time.
- **🚪 Recently Unfollowed by Me**: Review the accounts you recently unfollowed, combining snapshot diffs with Instagram's logs.
- **🖼️ 3-Layer Resilient Avatars**: Seamless profile picture resolution cascading from web profile endpoints to public proxies, down to offline gradient monograms.
- **💾 Automatic Session Restoration**: Re-open the app and pick up right where you left off without re-importing the ZIP file.
- **🔍 Smart Filters & Sorting**: Narrow down accounts with date chips (`< 30 Days`, `< 6 Months`, `> 1 Year`), mutual toggles, and duration sorting.

---

## 🧭 Getting started

1. **Request your data from Instagram**:
   - Open **Instagram** $\rightarrow$ **Settings** $\rightarrow$ **Accounts Center**
   - Tap **Your information and permissions** $\rightarrow$ **Download your information**
   - Choose **Download or transfer information**, pick your profile, select **Some of your information**, and choose **Followers and following**
   - Select **Download to device**, format **JSON** or **HTML**, date range **All time**, and tap **Create files**
2. **Download the ZIP**: When Instagram sends the notification that your download is ready, save the `.zip` archive to your device.
3. **Open UnInsta**: Tap **Select Instagram .zip File** and choose your downloaded archive.
4. **Explore your insights**: Flip through tabs, filter by date, compare who unfollowed you, and review your network securely!

---

## 📲 Download

1. Head over to the [**Releases page**](https://github.com/minaa/UnInsta/releases)
2. Grab the latest APK. If you're not sure which one, pick the file ending in `arm64-v8a`, since most modern phones use that
3. Open it, and if Android asks, allow installs from unknown sources

It runs on Android 5.0 (Lollipop) or newer and takes up about 18 MB.

---

## 🔒 Your privacy

I take this seriously, so here's the plain version:

- **Everything stays on your phone**: All ZIP decompression, HTML/JSON extraction, and mathematical set comparisons take place locally inside a Dart background isolate.
- **No accounts, no passwords, no tokens**: You never enter your Instagram password or generate access tokens. Your account is completely safe from suspicious logins and bans.
- **No tracking or third-party cloud analytics**: No sign-up screens, no telemetry, no analytics SDKs, and zero cloud databases pinging external servers.
- **Network requests are strictly limited**: The only optional network calls are read-only public avatar image fetches to display profile pictures, with a 100% offline monogram fallback when disconnected.

---

## ❓ Questions you might have

**Do I need an internet connection to use it?**  
No. UnInsta works completely offline. You can analyze your Instagram archive in airplane mode. The only thing internet is used for is optionally loading public profile pictures.

**Is it safe? Can Instagram ban my account?**  
Yes, it is 100% safe. Traditional follower apps require your Instagram login and passwords, which violates Instagram's terms and triggers account flags. UnInsta never asks for your credentials—it parses official data exports provided directly to you by Meta.

**Do I have to re-select my ZIP file every time I open the app?**  
No! Starting with version 1.1.0, UnInsta automatically saves your parsed analysis to local storage. Whenever you re-open the app, your previous analysis is restored immediately.

**What happens when I download a new export next month?**  
Simply tap **Import New ZIP** (or the folder icon). UnInsta will analyze the new file, automatically compare it against your previous snapshot, and tell you who unfollowed you and who followed you since your last export.

**Does it support both HTML and JSON exports?**  
Yes! UnInsta automatically detects whether your ZIP file contains HTML tables or Meta's JSON schema and parses both seamlessly.

---

## 💬 Say hello

- Ran into a bug or want a new feature? [Open an issue](https://github.com/minaa/UnInsta/issues)
- Just want to chat or give feedback? Reach me via GitHub Issues or discussions
- If the app has made your life a little easier, a ⭐ on the repo would make my day

---

## 🛠 For developers

<details>
<summary><strong>What it's built with</strong></summary>

- **Flutter & Dart**: Flutter 3.12+ / Dart 3.12+ targeting Android, iOS, Windows, and macOS.
- **Archive Engine**: `archive: ^4.3.0` decoding `.zip` exports inside a background `compute()` isolate to guarantee fluid 60fps UI.
- **Persistence**: `shared_preferences: ^2.5.5` storing snapshot comparison history and serialized `AnalysisResult` JSON sessions.
- **3-Layer Avatar Resolution**: Cascade from Instagram Web Profile API (`api/v1/users/web_profile_info/`) $\rightarrow$ Public Proxy Mirror (`ui-avatars.com`) $\rightarrow$ Deterministic high-contrast gradient initials.
- **System Architecture**: Complete architecture breakdown and data flow diagrams are documented in [`structure.md`](structure.md), with AI agent conventions in [`ai_instructions.md`](ai_instructions.md) and version history in [`changelog.md`](changelog.md).

</details>

<details>
<summary><strong>Run it yourself</strong></summary>

You'll need Flutter (3.12+) and Dart SDK. Then:

```bash
git clone https://github.com/minaa/UnInsta.git
cd UnInsta
flutter pub get
flutter run
```

To build release split-per-ABI APKs:
```bash
flutter build apk --release --split-per-abi
```

To run tests and code analyzer:
```bash
flutter test
flutter analyze
```

</details>

<details>
<summary><strong>Want to help out?</strong></summary>

Contributions are welcome! Here's how:

1. Fork the repo
2. Create a branch: `git checkout -b feature/my-new-feature`
3. Make your changes and push them
4. Open a Pull Request and tell me what you changed

Please run `flutter test` and `flutter analyze` before opening a pull request to keep code quality clean.

</details>

---

## 📄 License

GNU General Public License v3.0. Have a look at [LICENSE](LICENSE) for the details.  
Copyright © 2026 [Mina Android](https://github.com/mina-android)

<div align="center">

Made with ❤️ for anyone who wants privacy-friendly Instagram insights · [**See my other projects**](https://github.com/mina-android)

</div>
