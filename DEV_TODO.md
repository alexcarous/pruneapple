# Pruneapple Launch Todo list 🚀

This document outlines the manual setup steps required to publish Pruneapple, configure payments, and distribute the app.

---

## 1. Stripe Payment Link Setup
- [ ] Log in to your **Stripe Dashboard**.
- [ ] Go to **Product Catalog** -> **Add Product** and create a product named **Pruneapple macOS App** (one-time price, e.g. $9.99).
- [ ] Generate a **Payment Link** for the product.
- [ ] In the Payment Link settings, go to the **After payment** tab:
  - [ ] Select **Don't show confirmation page** (redirects customers to your site).
  - [ ] Set the redirect URL to:
    `https://alex.caro.us/thank-you?session_id={CHECKOUT_SESSION_ID}&utm_source=pruneapple`
- [ ] Place the Stripe Payment Link as the purchase URL on your website homepage.

---

## 2. Web Landing Page Deployment
- [ ] Locate the generated template at [temp/thank-you.html](file:///Users/appsandbox/projects/pruneapple/temp/thank-you.html).
- [ ] Host this file on your server at `https://alex.caro.us/thank-you` (make sure it responds to query parameters).
- [ ] Test the integration by making a test purchase (or visiting the URL directly with dummy query parameters) to verify the browser prompts to open Pruneapple.

---

## 3. Notarization & Code Signing (Choose one path)

### Path A: Official Apple Developer Program ($99/year)
- [ ] Register at [developer.apple.com](https://developer.apple.com).
- [ ] Create a **Developer ID Application** certificate inside Xcode or the Apple Developer Console.
- [ ] Update `Project.swift` (or the Tuist configuration) to use your developer signing team ID.
- [ ] Before distributing the zip, notarize the app via terminal:
  ```bash
  xcrun notarytool submit build/Build/Products/Release/Pruneapple.app.zip --keychain-profile "your-profile" --wait
  ```
- [ ] Staple the notarization ticket to the app:
  ```bash
  xcrun stapler staple build/Build/Products/Release/Pruneapple.app
  ```

### Path B: Free Distribution (No Developer Account)
- [ ] Keep the app signed to "Run Locally" (ad-hoc signed).
- [ ] Add instructions on `alex.caro.us` telling users to **Control-click (Right-click) -> Open** the app the first time to bypass Gatekeeper.
- [ ] (Optional) Create a public Homebrew Cask for the app so users can run `brew install --cask pruneapple` to bypass Gatekeeper warning dialogues automatically.

---

## 4. Sparkle Updates Setup
- [ ] Generate a public/private key pair for Sparkle updates using their tool:
  ```bash
  ./Pods/Sparkle/bin/generate_keys
  ```
- [ ] Place the public key in your app's `Info.plist` (under `SUPublicEDKey`).
- [ ] Host an `appcast.xml` feed at your updates URL (the `SUFeedURL` in `Info.plist`).
- [ ] Update the hosted `appcast.xml` with the new version details, URL, size, and ED signature.

---

## 5. Homebrew Cask Setup (Optional)
If you want to distribute Pruneapple via Homebrew (especially helpful as a free Gatekeeper bypass), follow these steps:

- [ ] Host the compiled `Pruneapple.zip` or `.dmg` file publicly (e.g., via GitHub Releases or your server).
- [ ] Calculate the SHA-256 checksum of the hosted archive:
  ```bash
  shasum -a 256 /path/to/Pruneapple.zip
  ```
- [ ] Create a `pruneapple.rb` cask file using the template below:
  ```ruby
  cask "pruneapple" do
    version "1.0.0"
    sha256 "REPLACE_WITH_SHA256_CHECKSUM"

    url "https://github.com/alexcarous/pruneapple/releases/download/v#{version}/Pruneapple.zip"
    name "Pruneapple"
    desc "Beautiful Liquid Glass disk space analyzer"
    homepage "https://alex.caro.us"

    auto_updates true
    depends_on macos: ">= :sequoia" # macOS 15.0+ (Sequoia)

    app "Pruneapple.app"

    zap trash: [
      "~/Library/Application Support/us.caro.alex.Pruneapple",
      "~/Library/Preferences/us.caro.alex.Pruneapple.plist",
      "~/Library/Saved Application State/us.caro.alex.Pruneapple.savedState",
    ]
  end
  ```
- [ ] **Distribute the Cask**:
  - **Path A: Official Tap (Public)**: Fork the `homebrew/homebrew-cask` repository on GitHub, add your cask file inside the `Casks/` folder, run local audits (`brew audit --cask Casks/pruneapple.rb`), and open a Pull Request.
  - **Path B: Custom Tap (Independent)**: Create a public GitHub repository named `homebrew-tap` (under your user profile). Place your cask file inside a `Casks/` folder in that repository. Users can tap and install directly:
    ```bash
    brew tap alexcarous/tap
    brew install pruneapple
    ```
