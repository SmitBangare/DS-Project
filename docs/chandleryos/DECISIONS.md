# ChandleryOS: Decision Log

Decisions taken after the master plan, and what each one changes. Newest first.

---

## D-001 · New dedicated WhatsApp business number

**Date:** 2026-09-30
**Decision:** The co-founder is buying a **new number** for the business WhatsApp account. His personal number is not migrated.
**Resolves:** Master plan open decision "Migrate the co-founder's number (Coexistence) or start a new business number?"

### Sub-decision to confirm: how the new number is used

| | **Option A: Cloud API only (recommended)** | Option B: Business app + Coexistence |
|---|---|---|
| Where chats happen | Only inside ChandleryOS (inbox works on phone and laptop) | WhatsApp Business app on a phone **and** ChandleryOS |
| Meta onboarding | Standard Cloud API setup with Tech Shipping's own Meta app; no Coexistence / Embedded Signup | Coexistence via Embedded Signup (Tech Provider setup or a BSP) |
| "Phone must stay active" risk | None | Link can drop if the app isn't opened regularly or the phone changes |
| Bot and human in the same chat | No clash: everyone works in one inbox | Co-founder and system both reply; risk of crossed messages |
| Record of conversations | Complete by design | Messages sent from the phone arrive as echoes; must be handled |
| Downside | The number can't be used in the WhatsApp app at all; the team must reply from ChandleryOS | More moving parts, more to break |

**Recommendation: Option A.** A fresh number has no chat history to preserve, so Coexistence's main benefit disappears, while its risks remain. Option A is simpler to build and more reliable.

(verify) Confirm against current Meta documentation during setup: a number registered on the Cloud API only cannot be used in the WhatsApp or WhatsApp Business app at the same time.

### What changes in the plan

**Removed or simplified**
- Coexistence onboarding, the Tech Provider / Embedded Signup question, and the "direct vs BSP" check (MASTER_PLAN_REVIEW §6) no longer apply under Option A.
- Risks removed: "WhatsApp link drops on phone change" and echo-message handling.
- No old chat history to import.

**New or raised in priority**
1. **The ChandleryOS inbox becomes the co-founder's WhatsApp.** It must be good on a phone: fast, with image/PDF preview, reply box, attachment upload and **new-message notifications** (browser push or at least an alert/sound). Plan this as a Sprint 2 must-have, not a nice-to-have.
2. **The 24-hour rule matters more.** Replies after 24 hours of client silence need approved templates. Draft a generic "follow-up on your inquiry" utility template in Week 0 so the team is never stuck.
3. **Transition period.** Clients will keep sending lists to the personal number for weeks or months.
   - Announce the new number **from the personal number** (a normal personal message or broadcast, free, no Meta rules) and on email signatures, quotations and invoices.
   - Staff can **forward** a list received on the personal number to the business number. ChandleryOS should let staff mark such a message "forwarded on behalf of <client>" so the inquiry is linked to the right client, not to the co-founder.
   - The email path (IMAP) still works for everything.
4. **Clients must message first, or opt in.** The new number cannot freely start conversations with clients who never contacted it. Business-initiated messages need an approved template and client opt-in (verify current Meta policy).
5. **Messaging limits.** A new number starts with a limit on business-initiated conversations per day, which rises with verification and good quality (verify current tiers). Not an issue for normal volume; avoid bulk announcements from the new number.

**Number requirements (Week 0)**
- The number must be able to receive an SMS or voice call for verification (a landline works with voice).
- It must **not** already be registered on WhatsApp. If it was, delete that WhatsApp account first.
- Keep the SIM/number in the **company's name** and keep it active (recharged).
- Display name must match the business (e.g. "Tech Shipping"); Meta reviews it.
- Meta Business verification of Tech Shipping is still required.

**Documents to update**
- Master plan: WhatsApp section, migration steps, risks table, open decisions.
- Staff guide ("For clients, nothing changes" is no longer true): tell staff about the new number and the forwarding rule.
