# ChandleryOS: Detailed Analysis of the Project Document

This is a review of [PROJECT.md](PROJECT.md): what is strong, what is ambiguous or contradictory, what is missing, and what to settle before Sprint 1.

> Tax and legal points below are flagged for the CA and are not tax advice. Treat every "(verify)" as an open question, not a fact.

---

## 0. Verdict in one paragraph

The plan is sound in its main choices. It targets the real bottleneck (reading lists and pricing them), keeps AI to reading only, keeps money in plain code, requires a person to send anything, and uses a stack one developer can run. The weak spots are in the details that decide whether the numbers are right and whether the build fits the timeline:

1. The pricing formula is underspecified. "Commission" is really **markup**, the margin threshold isn't defined, quote-level discounts across mixed GST rates aren't defined, and freight allocation isn't defined.
2. The GST rule "Maharashtra port = CGST+SGST, else IGST" is too simple for ship supply. Place of supply, bill-to/ship-to, zero-rating for foreign-going vessels, and GST on charges all need CA answers **before the pricing engine is written**, not before go-live.
3. The role model contradicts itself. Staff are said to enter vendor prices yet not see costs.
4. Real-world flows are missing: partial acceptance, short or substituted supply, cancellations after the vessel sails, credit notes, vendor payables, and advances.
5. The WhatsApp path has onboarding dependencies (Coexistence via embedded signup, usually through a BSP, and Meta verification) that can push Sprint 2 back.
6. Sprint 1 is overloaded for two weeks, and the "30 minutes" goal is only possible when prices are already known.

None of these block the project. All of them are cheaper to fix on paper now than in code later.

---

## 1. What the document gets right

| Area | Why it's good |
|---|---|
| AI boundary (§8) | AI only reads messy input and always produces drafts. Pricing, tax and vendor choice are deterministic. This is the right design for a money system and makes it auditable. |
| Human-in-the-loop sending | Nothing leaves without a click, so a bad AI read can't embarrass the company in front of a client. |
| Alias memory (§5.2, §5.3) | Learning "SS bolt 12mm → Steel bolt M12" from staff confirmations is where most of the long-term speed will come from. It costs nothing to run. |
| Price history with dates and currency (§5.4) | This turns people's memory into a company asset. It's the core data moat. |
| Revisions kept immutable (§5.8) | Correct for negotiation and disputes. |
| PDF never shows cost, vendor or margin (§5.7) | Correct and must be enforced by tests (see §6.3). |
| Single Django app + Postgres | Right size for one developer. There's no need for microservices or a separate frontend. |
| Explicit "not in v1" list (§12) | Good scope discipline. |
| Decisions list (§15) | Most of the right questions are already asked. Some are missing (see §10). |

---

## 2. Pricing engine: ambiguities that must be fixed first

Money correctness is success metric #3 ("zero calculation errors"). These points need a written, signed-off specification before code.

### 2.1 "Commission" is markup, and "margin" isn't defined

The formula `Landed cost + commission (20–40%) = Selling price` is a **markup on cost**. The low-margin rule (§5.6, "below 10%") uses the word **margin**, which is normally measured on the selling price. The two differ a lot:

| Markup on cost | Margin on selling price |
|---|---|
| 20% | 16.7% |
| 30% | 23.1% |
| 40% | 28.6% |
| 11.1% | 10% |

**Decide:** does "minimum 10%" mean markup ≥ 10% or margin ≥ 10%? Use the term *markup* in the UI for the 20–40% figure and reserve *margin* for `(selling − landed) / selling`. Also avoid "commission" in any client-facing text, because in shipping it can be read as an agency commission.

### 2.2 Where discounts sit

"Selling price × quantity − discount" handles a **line** discount. In practice masters ask for "5% off the total" or "round it to ₹2,50,000". A quote-level discount over items with different GST rates (5%, 12%, 18%, 28%) must be **allocated to lines** (normally in proportion to taxable value) so that GST per rate stays correct. Specify:

- Line discount (% or amount) and quote discount (% or amount), and the allocation rule.
- Whether discount is before or after port and delivery charges.
- Rounding of the allocated amounts, so they sum exactly to the discount.
- Whether a discount is shown on the PDF or folded silently into the rates. Clients usually prefer seeing it.

### 2.3 Landed cost is more than "× exchange rate + freight"

- **Freight is per shipment, not per item.** It needs an allocation rule (by value, weight, or manual).
- If Tech Shipping imports directly (decision #2), landed cost also includes **customs duty, clearing/CHA charges, and bank/forex charges**. Import IGST is usually creditable, so it shouldn't be in cost.
- Domestic vendors: is the vendor price stored **ex-GST**? It should be, with the vendor's GST stored separately, since input tax credit makes it recoverable. If some vendors are unregistered, their GST isn't creditable and becomes a cost.
- Local cartage from the vendor to the warehouse or port is a cost too.

### 2.4 Rounding and number types

- Use `Decimal` everywhere (never `float`), with an explicit rounding mode (ROUND_HALF_UP).
- Define rounding at each step: unit rate to 2 dp, line taxable to 2 dp, GST per line or per rate-group (pick one and match what the CA and Tally expect), and a single round-off line at the grand total.
- CGST and SGST each computed and rounded, so CGST + SGST = total GST with no paisa drift.
- Store the **computed** values on each revision (snapshot) as well as the inputs. A later change to a GST rate or exchange rate must never change an already-sent quote.

### 2.5 Exchange rate policy

Specify which rate is used (RBI reference, bank TT selling rate, or manual), who sets it, whether a buffer is added for currency risk, and how long it's valid. Snapshot it on each revision.

### 2.6 Suggested pricing spec (to confirm)

```
per line:
  landed_unit   = vendor_price_fc × fx_rate + allocated_freight_per_unit + duty_per_unit + other_costs_per_unit
  selling_unit  = round2(landed_unit × (1 + markup_pct))            # or manual override
  gross         = selling_unit × qty
  line_disc     = line discount + allocated share of quote discount
  taxable       = gross − line_disc
  gst           = round2(taxable × gst_rate)  → split CGST/SGST or IGST, or 0 if zero-rated
  margin_pct    = (taxable − landed_unit × qty) / taxable

per quote:
  charges (port, delivery, launch/boat, documentation) each with their own taxable + GST
  grand_total   = Σ(taxable + gst) over lines and charges
  round_off     = round(grand_total) − grand_total
  checks        = any line taxable < landed cost → BLOCK
                  quote margin < minimum         → needs manager approval
```

Build this as a pure function with no database access, and cover it with table-driven tests built from **real past quotations** re-computed and compared with what was actually sent.

---

## 3. GST: why "which state is the port in" isn't enough

These must go to the CA in Week 0, and the answers must be back **before Sprint 1 day 3**, because they shape the data model and the pricing engine.

1. **Place of supply for goods delivered on board.** For goods, the general rule is where movement ends (the port), but **bill-to/ship-to** supplies follow a different rule: when goods go to a vessel on the instruction of a third party (owner or manager), place of supply is that third party's principal place of business (IGST Act s.10(1)(b)) (verify). Many clients are managers in other states or abroad. So tax type may depend on **who is billed**, not only the port. The model needs `bill_to` (with GSTIN and state) separate from `ship_to` (vessel and port).
2. **Foreign-going vessels.** Ship stores supplied to foreign-going vessels are generally treated as exports only when the customs formalities for ship stores are completed (e.g. shipping bill), and zero-rating needs either a **LUT** (no IGST) or payment of IGST with a refund claim (verify). This affects documents (LUT declaration text on the invoice), workflow (a customs paperwork step), and cash flow. Zero-rated supplies are inter-state in nature, so the CGST/SGST split doesn't apply to them.
3. **Coastal vs foreign-going** status can change voyage to voyage. It belongs on the **inquiry or quote**, not on the vessel master.
4. **GST on port, delivery and launch charges.** If they are charged together with the goods, they may be a **composite supply** taxed at the principal supply's rate, and with mixed-rate goods that's non-trivial (verify). Get a clear rule per charge type.
5. **Clients without a GSTIN**, or foreign clients: invoice format, currency, and whether to invoice in USD.
6. **TDS/TCS:** large clients may deduct TDS under s.194Q (0.1%), and the company may have its own TDS/TCS duties on purchases. The payment screen already has "TDS deducted". Confirm which sections apply.
7. **E-invoicing threshold.** If aggregate turnover is **above ₹5 crore**, e-invoicing (IRN + QR) is mandatory, and an invoice without IRN isn't valid (verify the company's turnover). §12 says "done on the government portal for now", which is acceptable only if the system's invoice PDF can **carry the IRN, ack number and signed QR** entered after generating them on the portal. Add fields for these in v1.
8. **E-way bills** are generally needed for goods movements above ₹50,000 (state thresholds vary) (verify). Even if generated on the portal, the delivery record needs an **EWB number** field, and the dispatch screen should warn when one is missing.
9. **Invoice numbering:** GST rules require a consecutive series, unique per financial year, **at most 16 characters**. Postgres sequences can leave gaps on rollback, so use a counter row locked with `SELECT … FOR UPDATE` inside the invoice-creation transaction. Cancelled invoices keep their number and are marked cancelled, never deleted.

---

## 4. Contradictions and gaps inside the document

### 4.1 The staff role contradiction

§3 says Staff "enters vendor prices" and "prepares draft quotes" but "cannot see costs or margins". Vendor prices **are** costs. Pick one:

- **Option A (recommended):** staff see vendor prices and landed cost, since they handle RFQs and vendor replies anyway, but **not** markup %, margin, or the profit column. This is realistic because staff will read vendor quotes in the inbox regardless.
- **Option B:** strict. Staff can enter prices but can't read them back, and the quote builder shows only selling prices. This is harder to build, slower to use, and leaks anyway through the inbox and RFQ replies.

Whichever is chosen, hide the fields in **every** channel: screens, the JSON/HTMX endpoints, Excel exports, the dashboard, search results, the AI assistant, and audit-log views.

### 4.2 Invoice "from the final accepted quotation"

In chandlery, what's delivered often differs from what's quoted: items short-supplied, substituted, quantities changed on board, some items rejected on delivery. The invoice should be built from **delivered quantities** (quote → PO → delivery → invoice), with a clear rule for substitutes and price differences.

### 4.3 Partial acceptance

Masters often approve some lines and not others ("supply items 1–14, cancel 15–22"). Acceptance needs line-level selection, and POs should be generated only for accepted lines.

### 4.4 Missing documents and flows

| Missing | Why it matters |
|---|---|
| **Credit notes / debit notes** | Legally required to correct an issued invoice (returns, rate disputes, post-sale discounts). Without them, staff will edit invoices, which is not allowed. |
| **Vendor payables** | The company pays vendors, often in advance for foreign vendors. v1 tracks client receivables only, so cash position and vendor dues stay in Excel. At minimum record vendor bills and payments against POs. |
| **Client advances** | New or foreign clients often pay in advance. Payments need to exist before an invoice and be adjusted later. GST on advances for goods is generally not payable, but confirm. |
| **Cancellation / vessel sailed** | ETA slips, the vessel sails early, the order is cancelled after POs are placed. Need statuses and a way to handle stock left over. |
| **Stock / leftover inventory** | Cancelled or returned goods become stock. v1 can treat this as a simple "available stock" list that shows up as a vendor option ("own stock", cost = purchase cost). |
| **Quote expiry and follow-up** | Validity is printed but nothing acts on it. Add "expired" status and a follow-up reminder for sent-but-unanswered quotes, since quotes won is a KPI. |
| **Duplicate inquiry detection** | The same list often arrives on WhatsApp and email, or is resent with changes. Flag "similar inquiry for this vessel in the last N days". |
| **Ship agent as a party** | Deliveries often go through the vessel's local agent (port passes, boarding). Store agent contacts per port call. |
| **Port pass / gate pass / boarding permissions** | Deliveries inside JNPT/Mumbai Port need passes. At least a checklist field on the delivery. |

### 4.5 Data model: the party structure

A single "client" isn't enough. Minimum:

- **Company** (owner / manager / charterer), with GSTIN, state, country, credit terms, and currency
- **Vessel**, keyed by **IMO number** (names change and repeat), with flag, type, and managing company (can change over time)
- **Contact** (master, chief engineer, superintendent, purchaser), linked to a company or vessel, with WhatsApp number and email
- **Port call / inquiry**: vessel + port + ETA/ETD + coastal/foreign-going status + agent
- **Bill-to** company per inquiry, since it can differ from the vessel's usual manager

### 4.6 Vendor selection rule

"Lowest recent price, faster/reliable wins a tie" needs:

- A definition of **recent** (e.g. 90 days), with stale prices shown but flagged.
- Price **validity**, MOQ, pack size, and lead time versus the vessel ETA. A cheap vendor that can't deliver before the vessel sails is not the best vendor.
- **Consolidation:** the cheapest vendor per line can produce 12 POs and 12 pickups. Showing "cheapest overall incl. pickup costs" or at least a vendor-count indicator helps.
- Exact ties are rare with real prices. Use a small tolerance (e.g. within 2%) before reliability decides.

### 4.7 Units and pack sizes

Client lists say "2 tins", "5 ltr", "1 drum", "3 pcs", "1 set". Vendor prices are per litre, per 20 L drum, per box of 100. The item master needs a **base unit plus conversion factors**, or the pricing engine will multiply the wrong units, which is the most likely real-world source of calculation errors.

---

## 5. WhatsApp: practical realities

| Point | Detail / action |
|---|---|
| Onboarding route | Coexistence is onboarded through Meta's **Embedded Signup**, which in practice means using a **BSP / Tech Provider** (e.g. Gupshup, Interakt, 360dialog, Twilio) or registering as a Tech Provider yourself (verify current rules). Picking a BSP early is probably simplest; it adds a small monthly fee. |
| Business verification | Can take days to weeks and is sometimes rejected over document mismatches (GST certificate name vs website vs Facebook page). Start it in Week 0 as planned, and **don't make Sprint 2 depend on it**. |
| History | Meta's Coexistence onboarding offers an optional import of recent chat history (verify current limits). If available, it's useful for seeding contacts and past inquiries. §7 currently says old chats never reach the system. |
| Phone must stay active | Coexistence expects the WhatsApp Business app on the phone to be opened regularly, or the link can drop (verify the current rule). Add a health check: alert if no webhook has arrived in X hours. |
| Echoes | Messages the co-founder sends from the phone arrive as "echo" events. Store them so the inbox shows the full conversation, not just the client side. |
| Groups | Not supported. If clients or vendors coordinate in groups today, that traffic stays manual. Ask the co-founder how much business comes through groups. |
| 24-hour window and templates | Payment reminders and dispatch updates almost always fall outside 24 h, so they need **utility templates** approved in advance. Draft these in Week 0. Meta's pricing is per template message by category (verify current India rates). |
| Webhook security | Verify `X-Hub-Signature-256` on every call, respond fast (enqueue, don't process inline), and make processing idempotent on message ID, because Meta retries. |
| Media | Media URLs expire. Download media to your own storage immediately on receipt. |
| Fallback | Build the **email** path first in Sprint 2. It has no approval dependency and exercises the same inbox → inquiry → AI pipeline. |

---

## 6. AI: design notes

### 6.1 Extraction

- Use the Claude API with **structured output (tool use / JSON schema)** per line: `raw_text, item, spec, qty, unit, confidence, needs_clarification, question`. Force the model to copy the raw text of each line so staff can compare.
- Handle images (handwritten, rotated, low-light), PDFs, Excel, and mixed Hindi/English/Marathi abbreviations. Excel supply lists should be parsed with code first (openpyxl) and only sent to AI when the layout is unknown.
- **Build an evaluation set in Week 0**: 30–50 real past lists (text, photos, PDFs) with the correct extraction typed out. Every prompt or model change is measured against it. Without this, "unclear lines are never guessed" can't be verified.
- Pick the model by measuring on the evaluation set: a smaller, cheaper model may be enough for typed text, with a stronger one used for handwriting. Log tokens and cost per call (already planned).
- Use prompt caching for the fixed instructions and, if helpful, a short list of the most common item names and aliases.

### 6.2 Prompt injection and untrusted input

Every client and vendor message is untrusted text going into the AI. Since output is only a draft and AI has no tools that act, the risk is low, but keep it that way: the extractor has no tools, output is validated against the schema, and extracted prices are never auto-accepted.

### 6.3 The assistant (§5.13) can leak margins

A "read-only" assistant still **reads**. If a staff user asks "what's our margin on the last Maersk quote?" and the assistant queries the whole database, it bypasses role permissions. Implement it with a fixed set of **permission-aware query tools** (e.g. `search_quotes`, `last_purchase_price` that return only fields the user's role may see), never free SQL, and run it under the asking user's permissions. Given the risk and the "optional" label, it's reasonable to push it past v1.

---

## 7. Technology and operations notes

| Topic | Note |
|---|---|
| Background work | Webhooks, AI calls, email polling, PDF generation and reminders need a **worker and a scheduler** (e.g. Celery + Redis, or a simpler Postgres-backed queue such as django-q2 / Procrastinate). Render needs a separate worker service and cron jobs, which adds to hosting cost. |
| File storage | Render's filesystem is ephemeral. Photos, PDFs, POD images and attachments must go to object storage (S3, Cloudflare R2, or an Indian region bucket if data residency is chosen). |
| Hosting region | Render doesn't have an India region (verify current list; Singapore is nearest). If DPDP or client contracts require India, choose AWS Mumbai / DigitalOcean Bangalore / Azure Pune etc. early, since moving later is painful. |
| Backups | Use managed Postgres with point-in-time recovery **plus** a nightly off-provider dump. Test a restore once before go-live. |
| Audit trail | `django-simple-history` (or similar) on prices, quotes, invoices and payments. It covers §10's "who changed what". |
| Screens | Django templates + HTMX (or Alpine.js) give "totals update instantly" without a separate SPA. Design the quote builder for laptop first; the phone is mainly for the inbox, approvals and delivery updates (POD photo from camera). |
| Auth | Enforce 2FA for Admin and Manager, since they can see margins and approve money. |
| PDFs | WeasyPrint is fine. Test Indian number formatting (₹12,34,567.00), amount in words (lakh/crore), and Unicode fonts for ₹ and Devanagari. |
| Excel import | Past prices in scattered Excel files will be messy (merged cells, units in names, no dates). Budget real time and build an import-review screen rather than a one-shot script. |
| Environments | A staging environment with a WhatsApp test number avoids sending test messages to real masters. |

---

## 8. Timeline assessment

| Stage | Assessment |
|---|---|
| Week 0 | Fine, but add: evaluation dataset, 20–30 real past quotations for pricing tests, WhatsApp template drafts, BSP choice, and a CA meeting (not just "questions sent"). |
| Sprint 1 (2 weeks) | **Overloaded.** Master data, Excel import, pricing engine, builder, PDF, approvals, revisions and deployment is 3–4 weeks of careful work for one developer, even with AI coding help. Suggest Sprint 1 = master data + pricing engine (fully tested) + builder + PDF + deploy, and Sprint 1b = Excel import + approvals + revisions. Alternatively, keep two weeks but import only one clean price list at first. |
| Sprint 2 | Depends on Meta verification. Do email first and WhatsApp last. |
| Sprint 3 | Also heavy (PO, delivery, invoice, payments, credit notes, dashboard). Vendor ratings can wait. They need months of delivery data to mean anything. |
| Sprint 4 | Fine. Security review should include the permission tests in §4.1. |
| Parallel run (2 weeks) | Reasonable. Define exit criteria, e.g. 50 quotes produced in-system with no calculation mismatches against Excel. |

A realistic end-to-end is **10–12 weeks plus the parallel run**, with the first usable quotation tool around **week 3**.

---

## 9. Success metrics: make them measurable

| Metric as written | Problem | Suggested version |
|---|---|---|
| Inquiry → quote in < 30 min | Impossible when new vendor prices are needed: vendors take hours or days. | (a) **Staff handling time** per quote < 30 min; (b) inquiry → quote sent < 30 min **when all items have a price from the last 90 days**; (c) median inquiry → quote sent overall, tracked monthly. |
| Manual typing down 80% | Not measured anywhere. | % of inquiry lines accepted from AI without edits; % of lines auto-matched to the item master. |
| Zero calculation errors | Needs a definition. | Zero mismatches between system totals and an independent check during the parallel run; zero credit notes caused by pricing or tax errors. |
| Conversion and margin | Good. | Also track **time-to-quote vs win rate**, which is the business case for speed. |

The system must record timestamps at each step (message received, inquiry created, lines confirmed, quote approved, quote sent) from day one, or none of these can be measured.

---

## 10. Additional decisions to add to §15

8. Is the "minimum 10%" a **markup** or a **margin**? (§2.1)
9. Staff visibility: Option A or B in §4.1?
10. What is the company's aggregate turnover? (Decides whether e-invoicing is mandatory now.)
11. Is there a GST **LUT** in place for zero-rated supplies?
12. Who is usually billed: the vessel's owner, its manager, or a local agent? Any bill-to/ship-to cases across states?
13. Which WhatsApp BSP (or direct Tech Provider route)?
14. How is the exchange rate chosen, and is a buffer added?
15. How much business comes through WhatsApp **groups** today?
16. Are vendor payables and client advances in v1 scope?
17. Should the discount be visible on the PDF or folded into rates?
18. Invoice number format (≤ 16 characters, e.g. `TS/25-26/00123`).

---

## 11. Suggested core data model (starting point)

```
Company(name, type[owner|manager|agent|vendor|other], gstin, state, country, currency, credit_days)
Contact(company?, vessel?, name, role, phone_wa, email)
Vessel(imo, name, flag, type, manager→Company)
Port(name, code, state, is_in_home_state, default_charges)
Item(name, impa_code?, hsn, gst_rate, category, base_unit)
ItemAlias(item, text, source, confirmed_by)
UnitConversion(item?, from_unit, to_unit, factor)
Vendor(→Company, lead_time_days, payment_terms, categories)
VendorPrice(vendor, item, price, currency, unit, pack_size, fx_rate?, freight?, valid_until, source_msg?, date)
Message(channel, direction, from, to, body, media[], external_id UNIQUE, received_at)
Inquiry(vessel, port, eta, etd, required_by, voyage_type[foreign|coastal], bill_to→Company, agent?, status, source_msgs[])
InquiryLine(inquiry, raw_text, item?, spec, qty, unit, confidence, needs_check, question)
RFQ(vendor, lines[], sent_at, channel, status)  /  RFQReply(rfq, message, draft_prices[])
Quote(inquiry, number, status)  /  QuoteRevision(quote, rev_no, fx_snapshot, gst_mode, totals…, approved_by, sent_at)  ← immutable once sent
QuoteLine(revision, inquiry_line, item, vendor, landed_unit, markup_pct, selling_unit, qty, discount, taxable, gst_rate, cgst, sgst, igst, accepted?)
QuoteCharge(revision, type, taxable, gst_rate, …)
PurchaseOrder(vendor, quote, lines[], status)  /  GoodsReceipt
Delivery(inquiry, method, vehicle_or_lr, ewb_no, dispatched_at, delivered_at, received_by, pod_file)
Invoice(number UNIQUE per FY, bill_to, lines from delivered qty, irn?, ack_no?, qr?, status)
CreditNote / DebitNote(invoice, lines, reason)
Payment(company, amount, mode, ref, tds, date)  /  PaymentAllocation(payment, invoice, amount)
VendorBill / VendorPayment (if in scope)
AIRun(kind, model, input_ref, output_json, tokens_in, tokens_out, cost, created_at)
AuditLog (via django-simple-history)
```

---

## 12. Top 10 actions before writing code

1. Get CA answers on §3 items 1–9, in a meeting, before Sprint 1 day 3.
2. Write the pricing spec (§2.6) with the markup/margin definition, discount allocation, rounding, and freight allocation, and have a co-founder sign off.
3. Collect 20–30 real past quotations as pricing test cases, and 30–50 real supply lists as the AI evaluation set.
4. Resolve the staff-visibility contradiction (§4.1).
5. Adopt the party model (§4.5): company / vessel (IMO) / contact / port call / bill-to.
6. Add units and pack-size conversion to the item master (§4.7).
7. Choose the WhatsApp BSP, start Meta verification, and draft the utility templates.
8. Decide hosting region now (Render vs India region) together with object storage.
9. Re-plan Sprint 1 to a scope that fits (§8), and add credit notes, partial acceptance and delivered-quantity invoicing to Sprint 3.
10. Add step timestamps from day one so the success metrics can be measured.
