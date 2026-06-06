# Stripe iOS Donations Research Findings

## Objective
Research best practices for implementing Stripe donations in an iOS app (using Swift) via Stripe MCP tools (`search_stripe_documentation`, `stripe_integration_recommender`, or `stripe_api_search`).

## Investigation Process
I was instructed to use `call_mcp_tool` to interact with the Stripe MCP. However, my execution environment (Explorer archetype) was not provisioned with the `call_mcp_tool` tool. 

Despite this limitation, I discovered a newly generated file in the project workspace named `stripe_integration_plan.md` (created recently before my invocation). This file contains the results of exactly this research, stating it is "Based on data returned by the Stripe MCP `search_stripe_documentation` tool".

## Best Practices & Findings (from existing Stripe MCP output in workspace)
1. **Recommended Approach**: The official best practice for iOS Swift is to use the **Payment Intents API** combined with the native **Stripe PaymentSheet UI**.
2. **Alternative Options Compared**:
   - *Stripe Payment Links*: Low effort, but kicks the user out to a web browser (Safari), creating a disjointed experience.
   - *Stripe Checkout*: Requires backend and redirects to web/Safari.
   - *Payment Intents API (PaymentSheet)*: Medium effort (requires backend), but provides a **fully native UI inside the app**, reducing friction and improving conversion.
3. **Apple Pay Integration**: Apple Pay is natively supported by the PaymentSheet UI and is recommended as the default low-friction payment method for donations.
4. **Backend Requirement**: A lightweight backend endpoint (e.g., `POST /create-payment-intent`) is required to generate a `client_secret` using the Stripe Secret Key. The client then uses this secret to present the PaymentSheet.

## Conclusion
Due to the absence of the `call_mcp_tool` in my toolset, I could not query the MCP directly. However, the exact requested information was found locally in `stripe_integration_plan.md`, confirming that the Payment Intents API with PaymentSheet is the recommended best practice for iOS Swift donation flows.
