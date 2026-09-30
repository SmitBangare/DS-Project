# ChandleryOS: Decision Log

Decisions taken after the master plan, and what each one changes. Newest first.

---

## D-001 · New dedicated WhatsApp business number

**Date:** 2026-09-30 (recommendation revised the same day, see below)
**Decision:** The co-founder is buying a **new number** for the business WhatsApp account. His personal number is not migrated.
**Status:** Adopted in master plan v2: new number on the WhatsApp Business app on a **company phone**, connected via Coexistence (Option B below). Open: who keeps the company phone day to day. See [MASTER_PLAN_V2_REVIEW.md](MASTER_PLAN_V2_REVIEW.md).
**Resolves:** Master plan open decision "Migrate the co-founder's number (Coexistence) or start a new business number?"

### Sub-decision: how the new number is used

| | Option A: Cloud API only | **Option B: Business app now, Coexistence later (recommended)** |
|---|---|---|
| Where chats happen | Only inside ChandleryOS | WhatsApp Business app on the co-founder's phone **and**, once connected, ChandleryOS |
| Usable from day one | **No**: the number is useless until the ChandleryOS inbox is built (Sprint 2, weeks 4–6) | **Yes**: works on the phone the day it's bought |
| If ChandleryOS is down or buggy | The business can't talk to clients | The phone app keeps working |
| Meta onboarding | Standard Cloud API setup | Coexistence via Embedded Signup (Tech Provider setup or a BSP) |
| Risks | Replaces the co-founder's main work tool with new software on day one | Link can drop if the app isn't opened regularly or the phone changes; co-founder and system both reply in the same chat; phone-sent messages arrive as echoes |

**Recommendation: Option B.** All client requirements arrive on WhatsApp and email, and WhatsApp on the phone is how the co-founder works. That tool must keep working from the day the number is bought, and independently of ChandleryOS. Option A was recommended first for technical simplicity, but it makes the business depend on software that won't exist until Sprint 2 and that is still being proven. Option B keeps WhatsApp as it is and adds the system alongside it.

### Plan

1. **Now (Week 0):** buy the number, install **WhatsApp Business** (not regular WhatsApp) on the co-founder's phone, set up the business profile (name, logo, address, email), and start using it with clients. Start Meta Business verification.
2. **Sprint 2:** connect the number to ChandleryOS through Coexistence. From then on every message also lands in the system.
3. **Test the Coexistence route early,** with a spare number, in Week 0 or Sprint 1: either Tech Shipping's own Meta app registered as a Tech Provider, or a BSP (Gupshup, Interakt, etc.). Keep the WhatsApp code behind one small module so switching is cheap.
4. **Later, optional:** once the team trusts the ChandleryOS inbox, the co-founder may reply from there more and from the phone less. No switch-over is forced.

(verify) during setup, against current Meta documentation:
- Coexistence onboarding may require the number to have been active on the Business app for some time first. Using the number from day one satisfies this naturally.
- Which Business app features stop working after Coexistence is connected (e.g. some linked-device, broadcast or disappearing-message features).
- The rule on how often the phone app must be opened to keep the link alive.

### What changes in the plan

**Kept from the master plan:** Coexistence, echo-message handling, the "link dropped" alert, and the rule that the system never messages clients on its own while the co-founder is chatting (the bot drafts; people send).

**New or different because it's a new number**
1. **Transition period.** Clients will keep sending lists to the personal number for weeks or months.
   - Announce the new number **from the personal number** (a normal message or broadcast list, no Meta rules) and on email signatures, quotations and invoices.
   - Staff can **forward** lists received on the personal number to the business number. ChandleryOS should let staff mark such a message "forwarded on behalf of <client>", so the inquiry is linked to the right client, not to the co-founder.
2. **No old chat history** on the new number, so nothing to import. Past supply lists for the AI test set come from the personal number's chats (export or screenshots).
3. **Email stays a first-class channel.** It works from Sprint 2 regardless of WhatsApp status, and is the fallback if Meta onboarding is delayed.

**Number requirements (Week 0)**
- The number must be able to receive an SMS or voice call for verification.
- It must **not** already be registered on WhatsApp. If it was, delete that account first.
- Keep the SIM/number in the **company's name** and keep it active (recharged).
- Business profile name should match the company (e.g. "Tech Shipping").
- Meta Business verification of Tech Shipping is still required.

**Documents to update**
- Master plan: WhatsApp migration steps (new number instead of converting the personal one), open decisions.
- Staff guide ("For clients, nothing changes" is no longer true): tell staff about the new number and the forwarding rule.
