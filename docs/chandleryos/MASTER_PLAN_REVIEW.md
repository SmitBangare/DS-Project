# Review: "Tech Shipping Operations Automation — Final Master Plan"

Reviewed documents (copies in `source/`):

- *Tech Shipping Operations Automation — Final Master Plan* (18 pages, Sep 29, 2026)
- *Our New Operations System — A Simple Guide* (6 pages, staff-facing)

Earlier review of the first project document: [ANALYSIS.md](ANALYSIS.md). Later decisions (e.g. the new WhatsApp number): [DECISIONS.md](DECISIONS.md).

> Tax, legal and Meta-platform points are marked **(verify)** where they need confirmation from the CA or current Meta documentation. They are open questions, not facts.

---

## 1. Verdict

**The master plan is buildable and much stronger than the first document.** It already fixes most gaps raised in the first analysis: partial acceptance, unit conversion, proforma and advances, credit notes, vendor bills and real profit, new-item handling, a staging environment with a test number, an AI accuracy test set, a background worker without Redis, private file storage, and a realistic 10–12-week timeline with a "what to cut first" list.

What's left falls into four groups:

1. **The pricing spec is still not precise enough to code without guessing.** This covers markup vs margin, the floor rule, round-off, freight allocation, and GST place-of-supply. It is the #1 risk to "zero calculation errors".
2. **The document contradicts itself in several places**, mostly where older text was not updated: pgvector, AI vendor search, bot autonomy, sprint lengths, and sample-data counts. The build prompts may inherit these contradictions.
3. **The WhatsApp direct-connection route needs checking.** Coexistence onboarding runs through Meta's Embedded Signup, and doing that without a provider needs extra Meta setup.
4. **A few compliance items are still missing:** e-invoicing threshold, e-way bill number, the invoice numbering rule, LUT, and bill-to vs ship-to.

**Readiness: about 85%.** The items in §8 should be closed in Week 0, before the pricing engine is written. The four build-pack files (`CLAUDE.md`, `SPEC.md`, `BUILD_PROMPTS.md`, `.env.example`) are referenced but weren't shared. They are what actually drives the build and need the same review.

---

## 2. What the master plan gets right

| Area | Assessment |
|---|---|
| Design principles (p.1–2) | Excellent. The plan has one app and one database, uses the Django admin for master data, keeps money in code, lets AI only draft, deploys on push, ships every sprint, and adds agents one at a time. Keep this page as the tie-breaker for every future decision. |
| Real-world cases table (p.3) | This is the most valuable addition. It covers the flows that usually break ops software. |
| AI task table (p.7–8) | Correct. After review, most "agents" became plain rules. Web vendor search and predictions are deferred. There is a fallback to manual entry when AI fails. |
| AI accuracy gate | "A change is kept only if accuracy does not drop" on 20+ real lists. This is the right discipline. |
| Stack simplification (p.10–11) | Django + HTMX + Bootstrap, Django-Q2 on Postgres, pg_trgm, R2, Render with staging, GitHub Actions, and Sentry. Removing React, Qdrant, LangChain, Celery and Redis is the right call. |
| Safety in development | Real client messages are blocked outside production. This is essential and often forgotten. |
| Data tables (p.11–12) | These cover almost everything needed, including the AI call log, notifications and inquiry timing. |
| Risks table (p.15) | Realistic, including "AI-written code nobody understands" and the single-developer risk. |
| Staff guide | Clear, reassuring ("Will I lose my job? No"), and asks staff for the right data. Good change management. |

---

## 3. Pricing formula: still the highest-risk area

The formula on p.9 in full:

```
Line total = (Vendor price × FX + Freight) / Conversion × (1 + Margin) × Qty × (1 − Discount) × (1 + GST rate)
```

### 3.1 "Margin" is used as markup

`× (1 + Margin)` with 20–40% is a **markup on cost**. The floor warning ("warns below minimum margin") doesn't say which measure it uses. At 30% markup the true margin is 23.1%, and a "10% floor" means different things in each reading (10% margin = 11.1% markup). **Decide and name it in the spec:** e.g. *markup %* for the input, *margin %* = (selling − cost) / selling for reports and the floor.

### 3.2 Below-cost selling is not blocked

The first document blocked a price below cost. The master plan only warns below the floor. State both rules explicitly:

- below the floor → Manager approval with a reason
- below landed cost → blocked, or allowed only for Admin with a reason

### 3.3 Discount

- The formula handles only a **percentage** discount applied evenly to every line. That is correct for GST (proportional allocation), but negotiations often end with "make it ₹2,50,000 all-in" or "₹5,000 off". Decide whether an amount discount is supported. If yes, convert it to a percentage or allocate it by taxable value, with a rounding rule so the pieces add up exactly.
- Is the discount applied to port and delivery charges too? The formula implies no. Confirm.
- Does the PDF show the discount, or fold it into rates?

### 3.4 Round-off and rounding rules are missing

The first document had "round off to the nearest rupee". The master plan's grand total has no round-off step, and no rounding rules per step. Required in the spec:

- `Decimal` only, with ROUND_HALF_UP
- rounding points: unit selling rate, line taxable value, GST per line (or per rate group — pick one), CGST and SGST each
- a single round-off line on the grand total

Snapshot every computed value on the revision so later rate changes never alter a sent quote.

### 3.5 Freight

"+ Freight" is added per vendor unit, but freight is billed **per shipment**. Define how shipment freight is split across lines (by value, weight, or manual entry per line). Also define where local cartage from vendor to port sits: vendor price, freight, or delivery charge.

### 3.6 Duplicate numbering

There are two step 5s on p.9. It's cosmetic, but fix it before this goes into `SPEC.md`.

### 3.7 GST mode (see §5)

"CGST + SGST if the port is in Maharashtra, IGST otherwise" is correct only for the simple case. Bill-to/ship-to and zero-rated supplies change it.

### 3.8 Recommendation

Put a **worked example table** in `SPEC.md`: 3–4 lines at different GST rates, one foreign vendor, one unit conversion, one discount, port charges, and round-off, with every intermediate number written out. Then write the pricing tests from that table, and from 20 past quotations re-computed and compared.

---

## 4. Internal contradictions to resolve

| # | Where | Conflict | Recommendation |
|---|---|---|---|
| 1 | Module 2 (item master) and module 10 list **pgvector / embeddings / RAG** | The stack table lists only pg_trgm. The AI table says matching is "plain code: remembered names, then fuzzy text search". Principle 1 says no extra vector database. | Remove pgvector from v1. Aliases + pg_trgm are enough. Revisit only if matching accuracy is poor. |
| 2 | Module 3 (vendors) says "AI search for new vendors, web search, AI agent". Process step 3 says "AI helps find new ones". | The AI table says web vendor search is not built now. | Update module 3 and process step 3 to "Later". |
| 3 | WhatsApp bot section: "acknowledges each inquiry instantly", "asks for missing details" | Principle 4 says nothing reaches a client without a person approving. The staff guide says auto-reply comes only after testing. | v1: the bot sends **nothing on its own**. "Missing details" become a suggested message that staff send with one click. The auto-acknowledgement is a setting, off by default. |
| 4 | Vision: "Quotations go live in about 2 weeks" | Sprint 1 is weeks 1–3. | Say "about 3 weeks". |
| 5 | Glossary: "Sprint = two-week block" | Sprints are 3, 3, 3 and 2 weeks. | Update the glossary. |
| 6 | Week 0 is labelled "Weeks 1–2" | It is called Week 0 but runs in parallel. | Call it "Preparation (runs alongside Sprint 1)". |
| 7 | Sample data | Open decisions ask for 5–10 lists and 3–5 quotations. The staff guide asks for 20 lists, 10 vendor quotes and 5 past quotations. The AI section needs 20+. | Standardise to **20+ supply lists with correct answers, 10+ vendor quotations, 20 past quotations** (5 is too few to test pricing). |
| 8 | Data tables: Vessels have "foreign-going or coastal" | The GST section says each **quotation** carries the vessel-type flag. | Keep a default on the vessel, but the value that drives GST must be on the inquiry or quotation, since status can change per voyage. |
| 9 | Staff guide: "Bill made from the final quotation" | Master plan: deliveries record quantities per line, and an open decision is "invoice per order or per delivery". | Invoice from **delivered, accepted** quantities. Update the guide. |
| 10 | Open decisions list "Does Tech Shipping import directly?" twice | Duplicate question. | Merge. |

---

## 5. GST and compliance: still open

The CA list on p.9 is good but incomplete. Add these to the Week 0 CA meeting:

1. **Place of supply with bill-to/ship-to.** When goods go to a vessel on the instruction of a manager or owner, place of supply may follow the billed party's location, not the port (IGST Act s.10(1)(b)) (verify). The quote needs a **bill-to company (GSTIN, state)** separate from the vessel and port, and the GST mode must be derived from both.
2. **Zero-rated supplies to foreign-going vessels.** Which customs documents are needed, is a **LUT** in place, and what text goes on the invoice (verify). Zero-rated supplies are treated as inter-state, so no CGST/SGST split.
3. **Port and delivery charges at 18%.** If they are charged together with the goods, they may be a composite supply taxed at the goods' rate (verify). Get a rule per charge type.
4. **E-invoicing.** It's listed under "Later", but if aggregate turnover is **above ₹5 crore** it's mandatory now (verify turnover). If it's done on the portal, the invoice PDF still needs fields for **IRN, ack number and QR code**. Add these fields in Sprint 3 even if they're entered by hand.
5. **E-way bill.** Add an **EWB number** field on deliveries, with a warning above the threshold (₹50,000 generally; state rules vary) (verify).
6. **Invoice numbering.** Numbers must be consecutive and unique per financial year, **at most 16 characters**. Use a locked counter row, not a Postgres sequence, which can leave gaps. Proformas use a separate series. Cancelled invoices keep their number.
7. **Credit note time limit.** There is a statutory deadline for issuing credit notes against a financial year (verify). Show a warning in the credit-note screen.
8. **TDS/TCS** deducted by large clients (e.g. s.194Q) and any obligations on purchases (verify).
9. **USD quotes and invoices.** If needed, cover the exchange rate on the invoice date, the INR equivalent for GST, and forex gain or loss on receipt.

---

## 6. WhatsApp: points to check before committing to the direct route

| Point | Detail |
|---|---|
| Direct vs provider | The plan recommends the direct Meta Cloud API. Coexistence onboarding (the QR-code step) runs through **Embedded Signup**. Using that for your own number without a provider generally means setting up your Meta app as a **Tech Provider** (verify current requirements). It's doable but adds Meta setup and review. **Test this in Week 0 with a spare number.** If it stalls, a provider (Gupshup, Interakt, etc.) is the fallback, and it doesn't change the app code much if the WhatsApp layer is kept behind one small module. |
| Chat history | The plan says old chats are not pulled in. Meta's Coexistence onboarding has offered an optional import of recent history (verify current limits). If available, turn it on, because it seeds contacts and past lists. The "Export chat" fallback in the plan is still good. |
| Phone must stay active | Coexistence can disconnect if the Business app isn't opened regularly (verify current rule). The plan already has "alert in software". Make it concrete: an alert if no webhook is received for N hours during business hours. |
| Echo messages | Messages the co-founder sends from his phone reach the API as echoes. Store them so the inbox shows both sides of the chat. |
| Bot and co-founder in the same chat | This is the biggest usability risk. A bot asking "what is your ETA?" while the co-founder is negotiating looks unprofessional. This is another reason for "no autonomous messages in v1" (§4 #3). |
| Webhooks | Verify `X-Hub-Signature-256`, reply 200 immediately and process in Django-Q2, deduplicate on message ID, and **download media at once** (media URLs expire). |
| Pricing | The plan notes Meta pricing changes on Oct 1, 2026. Re-check rates before go-live, and budget for utility templates (dispatch, reminders). |
| Groups | The staff guide asks masters to message directly. Also ask the co-founder what share of inquiries comes through groups today. |

---

## 7. Technical notes

| Topic | Note |
|---|---|
| Data residency | The Mumbai fallback (AWS Lightsail) covers the app and database. **Cloudflare R2 has no India storage location** (verify current jurisdictions). If data must stay in India, file storage must move too (e.g. S3 ap-south-1). Decide hosting and storage together. |
| Django-Q2 on Render | Needs a separate **background worker service**, which the running-costs table already includes. Scheduled jobs (reminders, email polling, quote-expiry checks) also run there. |
| Email intake | IMAP polling every 1–2 minutes via Django-Q2. Track the last processed UID and handle attachments and inline images. |
| Roles | Open decision: who sees margins and vendor costs. Enforce it in views, HTMX partials, Excel exports, PDFs, the dashboard, search and the assistant, with tests for each. |
| AI copilot | "RAG" over company records can leak margins to staff. If it's built, use a fixed set of role-aware query tools running with the asking user's permissions, never free SQL or a vector dump. It's already the first thing to cut, which is fine. |
| Auth | Two-factor login for Admin and Manager. |
| Audit trail | Pick a library (e.g. django-simple-history) in Sprint 1 so history exists from the first price. |
| AI accuracy metric | Define it: e.g. per line, item correct %, quantity exact %, unit correct %, and flagged-when-wrong %. "Accuracy does not drop" needs numbers. |
| Timing for the 30-minute goal | Inquiries store timing. Also record timestamps for lines confirmed, quote approved and quote sent. Report two numbers: overall time, and time when all prices were already known. Vendor waits are outside the team's control. |
| Missing statuses | Quote validity and **expired**, **lost** with reason, and **cancelled / vessel sailed** after POs are placed. |
| Agent / port-call party | Ship agents (for boarding and port passes) aren't in the data tables. Add a contact field per inquiry. |

---

## 8. Close before Sprint 1 (Week 0 checklist)

| # | Item | Owner |
|---|---|---|
| 1 | Pricing spec with a worked example: markup vs margin, floor, below-cost rule, discount types, rounding, round-off, freight split (§3) | Developer + co-founder sign-off |
| 2 | CA meeting on §5 items 1–9, especially place of supply, zero-rating/LUT and e-invoicing turnover | Co-founder + CA |
| 3 | Fix the internal contradictions in §4 in the master plan and in `SPEC.md` / `BUILD_PROMPTS.md` | Developer |
| 4 | Confirm the WhatsApp direct-connection route (Tech Provider / Embedded Signup) with a test number, or choose a provider | Developer |
| 5 | Decide who sees margins and vendor costs | Co-founders |
| 6 | Decide hosting and file storage region together | Co-founders |
| 7 | Collect data: 20+ lists with answers, 10+ vendor quotes, 20 past quotations, vendor list, port charges, GST rates | Operations staff |
| 8 | Share and review the four build-pack files | Developer |
| 9 | A short written agreement: scope, payment, maintenance, code and data ownership, and who holds the Meta, Render and domain accounts (these should be in the company's name) | Both parties |

---

## 9. Bottom line

The master plan describes a system one developer with Claude Code can realistically build in about 12 weeks. The architecture is right, the AI boundaries are right, and the real-world cases are covered. The remaining risk isn't in the code. It sits in **three written answers**:

- the exact pricing rules
- the CA's GST answers
- a confirmed WhatsApp onboarding route

Get those in Week 0 and the build can start on solid ground.
