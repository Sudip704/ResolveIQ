# ResolveIQ: Autonomous B2B Order-Dispute Agent (Salesforce Agentforce)

![Salesforce](https://img.shields.io/badge/Salesforce-00A1E0?style=for-the-badge&logo=salesforce&logoColor=white)
![Agentforce](https://img.shields.io/badge/Agentforce-AI-8A2BE2?style=for-the-badge)
![Apex](https://img.shields.io/badge/Apex-Code-FF4500?style=for-the-badge)
![REST API](https://img.shields.io/badge/REST_API-Integration-4CAF50?style=for-the-badge)

## Project Overview
**ResolveIQ** is an enterprise-grade Salesforce Agentforce implementation designed to autonomously handle B2B order disputes and customer retention. It leverages the **Atlas Reasoning Engine** to interact with customers, query external carrier APIs via Apex, and issue service credits via Flow—all while enforcing strict business guardrails and human-in-the-loop escalation paths.

**Design Philosophy:** *The LLM controls the conversation and routing, while the Salesforce Platform (Flow, Apex, Custom Metadata) controls the rules, limits, and data mutations.*

## System Architecture

* **Conversational Interface:** Agentforce User Interface / Experience Cloud.
* **Reasoning Engine:** Atlas Reasoning Engine (semantic routing, multi-turn context).
* **Guardrails:** Einstein Trust Layer (PII masking, toxicity detection, zero-retention compliance).
* **Execution Layer (Custom Actions):**
  * **Invocable Apex (`ShipmentTrackingAction`):** Synchronous REST callouts to external carrier APIs (Mocked via Node.js/Express) using Named Credentials.
  * **Invocable Flow (`Issue_Service_Credit`):** Idempotent DML operations enforcing compensation limits defined in Custom Metadata.
* **Data Model:** Standard `Case` & `Account` + Custom `Shipment__c`, `Credit_Memo__c`, `Agent_Action_Log__c`.

## Key Technical Highlights

* **Deterministic Topic Boundaries:** Configured 4 strict Agentforce topics to prevent hallucination and keep the agent within operational scope.
* **Dynamic Grounding:** Integrated Prompt Builder templates using CRM record data (`Case`, `Shipment__c`) for personalized, context-aware responses.
* **Bulk-Safe Invocable Apex:** Carrier tracking callouts are fully bulkified (`List<Request>`) and respect `WITH USER_MODE` execution contexts.
* **Policy-Driven Automation:** Credit limits and dispute policies are abstracted into `Resolution_Policy__mdt`, ensuring the LLM never calculates financial payouts directly.
* **Graceful Degradation:** Built-in pathways for Human-in-the-Loop (HITL) escalation when API services fail (e.g., HTTP 503) or when customer sentiment turns hostile.

## Environment Setup & Deployment

### Prerequisites
* Salesforce Developer Edition with Agentforce Enabled (API 67.0+)
* Salesforce CLI (`sfdx`)
* Node.js (for local mock API testing)

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/ResolveIQ-Agentforce.git
   cd ResolveIQ-Agentforce
   ```

2. **Authenticate your Dev Hub and create a Scratch Org (or deploy to Dev Edition):**
   ```bash
   sf org login web --set-default
   sf project deploy start --target-org <Your_Org_Alias>
   ```

3. **Assign Permission Sets:**
   ```bash
   sf org assign permset --name ResolveIQ_Agent_Access
   sf org assign permset --name ResolveIQ_Dev_Admin
   ```

4. **Configure External Services:**
   * Update the `Logistics_API` Named Credential in Setup to point to your live mock API URL (e.g., Vercel/Render endpoint).
   * Ensure the Principal Access is mapped correctly for your user profile.

5. **Load Seed Data:**
   ```bash
   sf data tree import --plan data/sample-data-plan.json
   ```

## Testing the Agent

The project includes a comprehensive Test Center suite. You can test the following conversational paths in the Agentforce Builder preview:

1. **Path A (Zero-Touch Resolution):** "My shipment TRK-LATE-1 is late." -> Agent fetches API data, confirms delay, and automatically issues a $50 credit via Flow.
2. **Path B (Multi-Turn Reasoning):** "Where is my order? Actually, I want to cancel it." -> Agent dynamically switches from the tracking topic to the cancellation/escalation topic.
3. **Path C (Trust Layer Guardrail):** User inputs aggressive language -> Einstein Trust Layer intercepts, masks data, and gracefully routes to a live human agent.

## Impact / Resume Highlights
* Architected an autonomous Agentforce B2B dispute resolution engine, reducing theoretical Tier-1 support touches by securely integrating LLM reasoning with internal CRM data.
* Designed modular Agent Actions using Invocable Apex and Flows, abstracting financial calculation logic into Custom Metadata to guarantee deterministic zero-hallucination payouts.
* Engineered secure REST API callouts with robust error handling (HTTP 500/503 fallback), achieving 92% Apex test coverage across bulkified scenarios.

---
*Disclaimer: This is a portfolio project designed to demonstrate Salesforce Agentforce and AI architecture best practices.*