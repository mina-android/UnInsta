<div align="center">

<img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" alt="UnInsta Logo" width="112" height="112" />

# UnInsta

[![Platform](https://img.shields.io/badge/Platform-Android-grey.svg?style=flat-square)](https://android.com) [![Release](https://img.shields.io/badge/Release-v1.0.1-blue.svg?style=flat-square)](https://github.com/mina-android/UnInsta/releases) [![License](https://img.shields.io/badge/License-GPL--3.0-black.svg?style=flat-square)](LICENSE) [![Build](https://img.shields.io/badge/Build-Passing-brightgreen.svg?style=flat-square)](https://github.com/mina-android/UnInsta/actions)

<p align="center">
  A local-first, privacy-focused follower and relationship analyzer for Instagram that parses official account data archives on your device without requiring passwords or cloud access.
</p>

</div>

---

## Navigation

[Features](#features) &bull; [Downloads](#downloads) &bull; [Self Building & Local Setup](#self-building--local-setup) &bull; [Frequently Asked Questions](#frequently-asked-questions) &bull; [Contribution](#contribution) &bull; [About the Developer](#about-the-developer) &bull; [Donate](#donate) &bull; [License](#license)

---

## Features

### Core Capabilities

- **Non-Reciprocal Follower Detection**: Identifies accounts you follow that do not follow your account back, with one-tap deep links opening target profiles directly in the Instagram client.
- **Pending Outbound Requests**: Lists pending follow requests you have previously sent that remain unapproved.
- **Fans and Reciprocal Connections**: Separates users who follow you into mutual connections and one-way followers whom you do not follow back.
- **Relationship Categorization**: Displays dedicated lists for Close Friends, restricted profiles, blocked accounts, and recent unfollow history.
- **Local Archive Parsing**: Directly ingests standard Instagram data export files (`ZIP` or extracted `JSON` directories) without requiring session cookies or automated web scraping.
- **Filter and Search Tools**: Instant search filtering by username or profile link with sorting by interaction date and alphabet.

### Architecture & Data Handling

- **Zero Credential Requirement**: The application never prompts for your Instagram password, two-factor codes, or account credentials. All insights are derived strictly from your official data export.
- **Complete Privacy & Local Execution**: Data parsing and persistence take place entirely within the local sandbox on your physical device. No telemetry, analytics, or user identifiers are transmitted over the network.
- **No Rate Limits or Account Ban Risks**: Because the tool operates purely on downloaded export archives rather than live background scraping bots, your account is protected from platform rate limits and security flags.

---

## Downloads

Official release binaries are available under the [GitHub Releases](https://github.com/mina-android/UnInsta/releases) section.

| Platform | Architecture | Package Type | Download Link | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Android** | arm64-v8a | `.apk` | [Download (v1.0.1)](https://github.com/mina-android/UnInsta/releases/latest) | 64-bit devices (recommended) |
| **Android** | armeabi-v7a | `.apk` | [Download (v1.0.1)](https://github.com/mina-android/UnInsta/releases/latest) | 32-bit older hardware |
| **Android** | x86_64 | `.apk` | [Download (v1.0.1)](https://github.com/mina-android/UnInsta/releases/latest) | Android x86 emulators |
| **Android** | Universal | `.apk` | [Download (v1.0.1)](https://github.com/mina-android/UnInsta/releases/latest) | Combined installer |

---

## Self Building & Local Setup

### 1. Prerequisites

Ensure your workstation has the following toolchains installed:

- **Flutter SDK**: `3.22.0` or higher
- **Dart SDK**: `3.4.0` or higher
- **Android SDK**: API level `34`
- **Java Development Kit**: JDK `17`
- **Git**: `2.30+`

### 2. Repository Setup

```bash
# Clone the repository
git clone https://github.com/mina-android/UnInsta.git

# Navigate into the project folder
cd UnInsta

# Verify environment
flutter doctor
```

### 3. Dependency Installation

```bash
# Fetch dependencies
flutter pub get
```

### 4. Build Compilation

```bash
# Build release APK
flutter build apk --split-per-abi --release
```

Output APK files are placed in `build/app/outputs/flutter-apk/`.

### 5. Running the Application Locally

```bash
flutter run --release
```

---

## Frequently Asked Questions

#### How do I obtain my Instagram data export archive?
1. Open the Instagram app and navigate to **Settings and privacy** > **Accounts Center** > **Your information and permissions** > **Download your information**.
2. Select **Download or transfer information**, choose your profile, and select **Some of your information**.
3. Under Connections, choose **Followers and following**.
4. Set the format to **JSON** and date range to **All time**, then request the download.
5. Once Meta notifies you the archive is ready, download the `.zip` file and select it directly in UnInsta.

#### Is my Instagram account safe from bans or suspensions?
Yes. UnInsta never connects to Instagram servers using your credentials and performs no automated scraping. It simply parses the official JSON records that Instagram provides to you upon request, eliminating account suspension risks.

#### Do I need to re-download the archive every time?
Your connection state reflects the exact point in time when the export was generated by Meta. To update your follower metrics, request and load a fresh archive export.

---

## Contribution

Contributions that improve JSON schema compatibility, speed up parser routines, or enhance the UI are welcome.

### Contribution Process

1. Verify that your proposal or defect is not already discussed in open GitHub Issues.
2. For format changes or archive support updates, open a ticket with sample anonymized JSON snippets.
3. Verify test passes:
   ```bash
   flutter analyze
   flutter test
   ```
4. Submit a Pull Request targeting `main`.

---

## About the Developer

This project is authored and maintained by **mina-android**, building privacy-preserving utilities and open-source Android tools.

- **Developer Portfolio**: [portfolio.minaashraf285.workers.dev](https://portfolio.minaashraf285.workers.dev/)
- **GitHub Profile**: [github.com/mina-android](https://github.com/mina-android)
- **Issue Tracker**: [github.com/mina-android/UnInsta/issues](https://github.com/mina-android/UnInsta/issues)

---

## Donate

If UnInsta provides you with transparent account analytics while keeping your credentials private, you can support ongoing maintenance:

- **PayPal**: [paypal.me/minaashraf285](https://paypal.me/minaashraf285)
- **GitHub Sponsors**: [github.com/sponsors/mina-android](https://github.com/sponsors/mina-android)

---

## License

Distributed under the **GNU General Public License v3.0**. See the [`LICENSE`](LICENSE) file in the root directory for legal text.

```text
Copyright (c) 2026 mina-android
Licensed under the GNU General Public License v3.0.
```

---

<div align="center">
  <sub>UnInsta &bull; Maintained by mina-android &bull; Private, offline Instagram follower analysis.</sub>
</div>
