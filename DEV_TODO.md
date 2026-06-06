# Pruneapple Donation Integration: Developer Todo List

This file tracks the manual tasks required to configure Stripe and host the redirection bridge to complete the donation integration.

---

## 🟩 Phase 1: Stripe Product & Link Setup

Stripe Payment Links are used to handle donations without a backend. You will need to configure products and links in both **Test Mode** (for development) and **Live Mode** (for production).

- [ ] **1. Create/Log in to Stripe**
  - Sign in to your [Stripe Dashboard](https://dashboard.stripe.com/).
- [ ] **2. Create Products in Stripe (Do for both Test & Live modes)**
  - Toggle **Test Mode** in the top-right corner to do test setup first.
  - Navigate to **Product catalog** -> **Products** -> Click **Add product**.
  - Add the following products:
    1. **Buy me a coffee**: One-time, `$5.00` USD.
    2. **Buy me a matcha**: One-time, `$10.00` USD.
    3. **Buy me a moka pot**: One-time, `$50.00` USD.
    4. **Espresso Machine**: One-time, check the **"Let customers pay what they want"** box. Set the currency to **USD**, minimum to `$1.00`, and suggested to `$25.00`.
- [ ] **3. Generate Stripe Payment Links**
  - For each of the 4 products, click **Create payment link** (or go to **Payments** -> **Payment Links** -> **New**).
  - Under **Options**:
    - **Disable** "Collect customers' addresses".
    - **Disable** "Require customers to provide a phone number".
    - Keep quantity adjustments and promotion codes disabled.

---

## 🟩 Phase 2: Host the Redirect Bridge Page

Because Stripe Payment Links do not allow custom URI schemes (like `pruneapple://`) directly in their redirect configuration, you must host a simple HTTPS landing page that performs the redirection to the app.

- [ ] **1. Upload the Redirect HTML**
  - Save the HTML code below as `index.html` (or `thank-you.html`) and host it on a secure HTTPS server (e.g., GitHub Pages, Vercel, Netlify, or your personal server `https://alex.caro.us/pruneapple/thank-you`).
  
  <details>
  <summary>Click to view Redirect Bridge HTML Code</summary>

  ```html
  <!DOCTYPE html>
  <html lang="en">
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Thank You for Supporting Pruneapple!</title>
      <style>
          :root {
              --bg-color: #1e1e1e;
              --text-color: #ffffff;
              --secondary-text: #a0a0a0;
              --accent-color: #ff3b30;
              --button-bg: #2c2c2e;
              --button-hover: #3a3a3c;
          }
          @media (prefers-color-scheme: light) {
              :root {
                  --bg-color: #f5f5f7;
                  --text-color: #1d1d1f;
                  --secondary-text: #86868b;
                  --accent-color: #ff2d55;
                  --button-bg: #e5e5ea;
                  --button-hover: #d1d1d6;
              }
          }
          body {
              font-family: -apple-system, BlinkMacSystemFont, sans-serif;
              background-color: var(--bg-color);
              color: var(--text-color);
              display: flex;
              flex-direction: column;
              align-items: center;
              justify-content: center;
              height: 100vh;
              margin: 0;
              padding: 20px;
              text-align: center;
              box-sizing: border-box;
          }
          .container {
              max-width: 480px;
              padding: 40px;
              background: rgba(255, 255, 255, 0.03);
              border-radius: 20px;
              box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.15);
              backdrop-filter: blur(10px);
              border: 1px solid rgba(255, 255, 255, 0.05);
          }
          @media (prefers-color-scheme: light) {
              .container {
                  background: rgba(255, 255, 255, 0.7);
                  border: 1px solid rgba(0, 0, 0, 0.05);
              }
          }
          .heart-icon {
              font-size: 64px;
              color: var(--accent-color);
              animation: pulse 1.5s infinite ease-in-out;
              margin-bottom: 24px;
          }
          h1 {
              font-size: 28px;
              font-weight: 700;
              margin: 0 0 12px 0;
          }
          p {
              font-size: 16px;
              color: var(--secondary-text);
              margin: 0 0 32px 0;
              line-height: 1.5;
          }
          .btn {
              display: inline-block;
              background-color: var(--accent-color);
              color: white;
              text-decoration: none;
              padding: 12px 28px;
              border-radius: 12px;
              font-weight: 600;
              font-size: 16px;
              transition: transform 0.2s ease, opacity 0.2s ease;
              box-shadow: 0 4px 12px rgba(255, 45, 85, 0.3);
          }
          .btn:hover {
              transform: translateY(-1px);
              opacity: 0.9;
          }
          .btn:active {
              transform: translateY(1px);
          }
          .fallback-text {
              margin-top: 16px;
              font-size: 12px;
              color: var(--secondary-text);
          }
          @keyframes pulse {
              0% { transform: scale(1); }
              50% { transform: scale(1.1); }
              100% { transform: scale(1); }
          }
      </style>
  </head>
<body>
    <div class="container">
        <div class="heart-icon">❤️</div>
        <h1>Thank You!</h1>
        <p>Your donation was processed successfully. Redirecting you back to Pruneapple to complete the process...</p>
        <a href="pruneapple://donate-success" class="btn">Open Pruneapple</a>
        <p class="fallback-text">If the app doesn't open automatically, click the button above.</p>
    </div>
    <script>
        window.onload = function() {
            setTimeout(function() {
                window.location.href = "pruneapple://donate-success";
            }, 1000);
        };
    </script>
</body>
</html>
```
  </details>

- [ ] **2. Link Stripe Payment Links to the Bridge Page**
  - On the **After payment** tab for each of your Payment Links:
    - Select **Redirect customers to your website**.
    - Enter the URL where you uploaded the HTML page (e.g., `https://alex.caro.us/pruneapple/thank-you`).

---

## 🟩 Phase 3: Update Client Code

Once you have generated your active Stripe links, you must replace the placeholder URLs in the client application code.

- [ ] **1. Replace URLs in `DonationView.swift`**
  - Open [DonationView.swift](file:///Users/appsandbox/projects/pruneapple/Targets/Pruneapple/Sources/DonationView.swift).
  - Update the `url` property for each tier inside the `tiers` array:
    - Replace the `"https://buy.stripe.com/test_555_xxx"` values with your actual Payment Link URLs.
    - *Tip*: Use your Stripe **Test Mode** links (`https://buy.stripe.com/test_...`) during development and local testing.
    - *Tip*: When archiving/submitting the app for production distribution, swap these with your Stripe **Live Mode** links (`https://buy.stripe.com/...`).

---

## 🟩 Phase 4: Test & Verify

- [ ] **1. Local System Deep-Link Verification**
  - Verify that macOS correctly opens the app when clicking the deep link. Run the following command in Terminal:
    ```bash
    open "pruneapple://donate-success"
    ```
    *Result expected:* The Pruneapple app should launch or gain focus and display the custom **Thank You!** modal window with the pulsing heart.
- [ ] **2. Full Transaction Verification**
  - Compile the app: `make build` (or run in Xcode).
  - Click a donation button in the app (e.g., "Buy me a coffee $5").
  - Complete the checkout process in the web browser using a Stripe test card (e.g., card number `4242 4242 4242 4242`, any future expiration date, and any CVC).
  - Verify the redirect:
    1. Browser redirects to your bridge page (`https://alex.caro.us/...`).
    2. Browser asks for permission to open **Pruneapple**.
    3. Clicking "Open" triggers the app window to wake up and display the "Thank You!" sheet.
