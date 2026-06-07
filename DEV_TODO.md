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

## 3. In-App Donor Acknowledgement
- [ ] Implement a visual way to thank/acknowledge donors inside the app when `hasDonated == true`. Ideas:
  - Add a small gold "Supporter" badge or star next to the app name in the **About** tab.
  - Show a small "Thank you for your support!" label in the footer of the welcome screen instead of the standard scan rules text.

---

## 4. Notarization & Code Signing (Choose one path)

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

## 5. Sparkle Updates Setup
- [ ] Generate a public/private key pair for Sparkle updates using their tool:
  ```bash
  ./Pods/Sparkle/bin/generate_keys
  ```
- [ ] Place the public key in your app's `Info.plist` (under `SUPublicEDKey`).
- [ ] Host an `appcast.xml` feed at your updates URL (the `SUFeedURL` in `Info.plist`).
- [ ] Update the hosted `appcast.xml` with the new version details, URL, size, and ED signature.

---

## 6. Homebrew Cask Setup (Optional)
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

---

## 7. alex.caro.us Domain References Checklist
When you are ready to change the domain name from `alex.caro.us` to your new domain, make sure to update it in the following files:

- [ ] **Appcast / Update Feed URL**:
  - [Project.swift](file:///Users/appsandbox/projects/pruneapple/Project.swift#L24) (Value of `SUFeedURL` under `infoPlist` configurations)
- [ ] **Home Help Menu Link**:
  - [PruneappleApp.swift](file:///Users/appsandbox/projects/pruneapple/Targets/Pruneapple/Sources/PruneappleApp.swift#L49) (Help button action URL)
- [ ] **About Tab Credits Link**:
  - [SettingsView.swift](file:///Users/appsandbox/projects/pruneapple/Targets/Pruneapple/Sources/SettingsView.swift#L288) (Credits Link destination)
- [ ] **Project Readme links**:
  - [README.md](file:///Users/appsandbox/projects/pruneapple/README.md#L3) (Badge Link)
  - [README.md](file:///Users/appsandbox/projects/pruneapple/README.md#L21) (Download URL)
- [ ] **Local Launch Checklists / Configurations in this file**:
  - [DEV_TODO.md](file:///Users/appsandbox/projects/pruneapple/DEV_TODO.md#L14) (Stripe Redirect URL)
  - [DEV_TODO.md](file:///Users/appsandbox/projects/pruneapple/DEV_TODO.md#L21) (Web Landing Page Setup)
  - [DEV_TODO.md](file:///Users/appsandbox/projects/pruneapple/DEV_TODO.md#L50) (Gatekeeper bypass instructions URL)
  - [DEV_TODO.md](file:///Users/appsandbox/projects/pruneapple/DEV_TODO.md#L83) (Homebrew Cask homepage URL)

---

## 8. Compiled App Storage & Upload Locations
Ensure the compiled app (`Pruneapple.app` inside `Pruneapple.zip`) is uploaded to these locations during distribution:

- [ ] **GitHub Releases** (For Homebrew Cask download):
  - **Upload to**: `https://github.com/alexcarous/pruneapple/releases`
  - **Expected URL**: `https://github.com/alexcarous/pruneapple/releases/download/v{version}/Pruneapple.zip` (must match the version and name defined in the Homebrew cask).
- [ ] **Sparkle Update Server** (For in-app update updates):
  - **Upload to**: Your web server root under `pruneapple/` directory (e.g., `https://alex.caro.us/pruneapple/`).
  - **Files required**:
    - `Pruneapple.zip` (The signed update archive).
    - `appcast.xml` (The Sparkle appcast feed referencing the zip, size, version, and signature).
- [ ] **Website Landing Page / Stripe Success Redirect**:
  - **Upload to**: `https://alex.caro.us/thank-you`
  - **Purpose**: Let users trigger the custom `pruneapple://` deep link to activate the donor badge/status once payment succeeds.

---

## 9. Visual Redesign: Pineapple Disk Breakdown Chart
To make the app breakdown look like a **pineapple** instead of a regular concentric circle sunburst chart, follow these steps in [DiskMapView.swift](file:///Users/appsandbox/projects/pruneapple/Targets/Pruneapple/Sources/DiskMapView.swift):

- [ ] **Ovoid / Pineapple Body Shaping**:
  - Modify `radiusRange(for:depth:maxRadius:)` to shape the rings parametrically.
  - Scale the radius based on the angular direction `(startAngle + endAngle) / 2`. Scale the vertical radius factor (e.g., height/width ratio of `1.3` to `1.4`) to make it oval, and optionally make the lower half slightly wider.
- [ ] **Leafy Green Crown Overlay**:
  - Draw a green leafy crown at the top (around -90° / 270°).
  - Use a `Path` with Bezier curves (`addCurve` / `addQuadCurve`) representing overlapping leaves.
  - Fill it with a green gradient (e.g., green to forest-green) to sit neatly at the top of the body.
- [ ] **Pineapple Skin Texture & Colors**:
  - Instead of standard random gradients, use a warm tropical palette for the data wedges: yellows, gold, amber, and orange.
  - Draw the segments with a slight spacing (stroke/gap) and rounded wedge corners to look like the diamond segments of a pineapple.
- [ ] **Core / Center Circle**:
  - Make the central circle (depth 0 representing the root folder) a soft yellow color to symbolize the pineapple's core.


