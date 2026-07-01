# Pruneapple User Help Guide 📋

Welcome to the Pruneapple help guide. This document explains how to use the app, manage your supporter status, and resolve common macOS issues.

---

## 🔍 How to Use Pruneapple

Pruneapple is a disk space visualizer designed to help you quickly identify what folders and files are consuming the most storage on your Mac.

### 1. Scanning a Directory
* Launch Pruneapple.
* Click the **Select Folder** button in the sidebar or menu.
* Choose the folder, drive, or volume you want to scan (e.g., your User Home folder).
* Wait for the scan to complete. Progress is shown in the sidebar.

### 2. Reading the Disk Map
Pruneapple renders your disk usage as a multi-layered concentric sunburst chart:
* **The Center Core**: Represents the root folder you selected to scan.
* **Inner Rings**: Represent top-level directories within that folder (e.g., `Documents`, `Library`).
* **Outer Wedges**: Represent subdirectories and nested folders. The wider a wedge is, the more storage space it consumes.
* **Hovering**: Hover your mouse over any segment of the chart to see the folder name, exact size, and full directory path.

### 3. Taking Action
* **Locate in Finder**: Click on any segment of the chart to immediately open that folder in macOS Finder so you can delete or archive large files.
* **Smart Prune**: Navigate to the "Smart Prune" tab to let Pruneapple highlight safe-to-delete caches, log files, and duplicate directories.

---

## 💖 Supporter Status & Donations

Pruneapple is open-source and free to build from source. If you would like to support active development, you can make a donation.

### How to Activate Supporter Status
When you donate, you receive a custom badge and supporter status in the app. Here is how to activate it:
1. Click the **Support** tab in Pruneapple's Settings window.
2. Select your desired donation level or enter a custom amount to open the secure Stripe checkout page in your web browser.
3. Complete the checkout process.
4. On the confirmation page (or in your email receipt), find the transaction Session ID. It starts with **`cs_live_...`** (or `cs_test_...` if in developer mode).
5. Copy that entire Session ID string.
6. Return to Pruneapple, paste it into the **Redeem Code** field in the Support tab, and click **Activate**.

---

## 🛠️ Troubleshooting & FAQs

### "Pruneapple cannot be opened because the developer cannot be verified"
Because Pruneapple is distributed directly without a paid Apple Developer certificate, macOS Gatekeeper may show a warning on first launch.
* **To bypass**: Don't double-click the app. Instead, **Right-click (or Control-click)** the Pruneapple icon, select **Open**, and then click **Open** in the warning confirmation dialog. You will only need to do this once.

### Why is Pruneapple asking for permissions?
To calculate directory sizes accurately, Pruneapple requires read-only access to scan your files. 
* It may request access to your **Desktop**, **Documents**, or **Downloads** folders depending on what directory you choose to scan.
* If you deny these permissions, Pruneapple will not be able to measure folders in those locations and will report them as empty. You can re-enable permissions in **System Settings > Privacy & Security > Files and Folders**.
