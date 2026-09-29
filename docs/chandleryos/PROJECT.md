# ChandleryOS: Project Documentation

**Client:** Tech Shipping Pvt Ltd, Ballard Estate, Mumbai
**What it is:** An operations system that runs the full ship-supply business, from a master's WhatsApp message to delivery on board and payment.
**Status:** Planned; build starts with Sprint 1.

> A detailed review of this document (gaps, risks and recommendations) is in [ANALYSIS.md](ANALYSIS.md).

---

## 1. Background

Tech Shipping is a ship chandler and marine supplier. Masters and vessel companies contact the company when their ships need supplies: provisions, spare parts, paint, safety wear, chemicals, deck and engine stores.

**How the work is done today:**

1. A master or vessel company sends a supply list, mostly on the co-founder's personal WhatsApp, sometimes by email.
2. Staff read the list, often as a photo or handwritten note, and type it out.
3. Staff search the internet and call vendors, in India and abroad, to find each item at the best price.
4. The company adds its commission (20–40%) to the cost, adds GST for each item and the port charges, and prepares a quotation.
5. The quotation is sent to the master. Negotiation and discount requests follow.
6. Once the quotation is final, the company buys the goods from the vendors.
7. Goods are delivered to the vessel by tempo (nearby ports) or by train/transport (distant ports).
8. The company bills the client and follows up on payment.

**The problems with this:**

- Everything is manual: reading, typing, searching, calculating, following up.
- Past vendor prices and contacts live in people's heads, chats and scattered Excel files.
- GST and commission calculations by hand risk costly mistakes.
- Negotiation history is lost in chats.
- Client messages arrive on a personal WhatsApp number that software can't connect to.
- Nobody can easily see which quotes are pending, which orders are out for delivery, or who hasn't paid.

---

## 2. The Goal

> **A correct, professional quotation within 30 minutes of receiving a supply list, with every order tracked from inquiry to payment in one system.**

The system handles the typing, searching, calculating and tracking. People keep control of every decision: vendors, prices, discounts and what gets sent.

---

## 3. Who Uses It

| User | What they do in the system |
|---|---|
| **Admin** | Everything, plus company settings, GST rates, port charges and staff logins |
| **Manager** (e.g. co-founders) | Sees costs and margins, approves and sends quotations, handles discounts |
| **Staff** | Handles inquiries, confirms items, enters vendor prices, prepares draft quotes, updates deliveries. **Cannot see costs or margins** unless given permission. |

It works in a web browser on both laptop and phone.

---

## 4. The Full Process in the New System

```
Master sends list (WhatsApp / email)
        ↓
System saves the message and reads the list  [AI]
        ↓
Staff check and confirm the items
        ↓
System shows past vendors and prices for each item
        ↓
Staff request new prices from vendors (RFQ)
        ↓
Vendor replies are read into draft prices  [AI]  → staff confirm
        ↓
System builds the quotation: cost + commission + GST + port charges
        ↓
Manager approves → quotation PDF sent on WhatsApp/email
        ↓
Negotiation: revisions and discounts recorded, with a low-margin warning
        ↓
Client accepts → purchase orders sent to vendors
        ↓
Delivery by tempo/train tracked → proof of delivery photo
        ↓
GST invoice created → payments tracked → reminders
```

---

## 5. Features in Detail

### 5.1 Inbox (WhatsApp and email)
- All client and vendor messages arrive in one shared screen, including photos, PDFs and Excel files.
- The co-founder keeps using WhatsApp on his phone; the system receives the same messages.
- A staff member turns a message into an **inquiry** with one click.

### 5.2 Inquiries
- Each inquiry records the client, vessel, port, ship's arrival date (ETA) and required date.
- The system reads the list and fills in each line: item, size/specification, quantity, unit.
- The original message or photo is shown beside the extracted lines so staff can compare.
- Unclear lines are **highlighted for checking**, never guessed.
- The system suggests questions to ask the client (e.g. "Please confirm boot size").
- When staff confirm that "SS bolt 12mm" means "Steel bolt M12", the system **remembers it** for next time.

### 5.3 Product list (Item master)
- One standard name per product, with its IMPA code (marine catalogue code), HSN code (tax code), category, unit and GST rate.
- Alternative names used by clients are linked to each product, so matching improves over time.

### 5.4 Vendors and prices
- All vendors: country, city, contacts, what they supply, payment terms, typical delivery time.
- **Full price history** for every item from every vendor, with dates.
- Foreign vendor prices are stored in their currency along with the exchange rate and freight, so the true cost in rupees (**landed cost**) is always known.
- Vendor performance is calculated automatically: on-time delivery %, average delivery time, and how competitive their prices are.

### 5.5 Requests for quotation (RFQs)
- Staff select vendors, and the system writes a clear price request listing the items.
- It's sent by email or WhatsApp **only when staff click Send**.
- When vendors reply, the system reads their prices into drafts for staff to confirm.

### 5.6 Quotation builder
- For each item, the system suggests the best vendor: the lowest recent price, with faster and more reliable vendors winning a tie. Staff can change it.
- Commission defaults to the company's standard (e.g. 30%) and can be changed per item.
- GST and port charges are added automatically based on the item and port.
- Totals update instantly as anything changes.
- **Low-margin warning:** if a discount pushes margin below the company's minimum (e.g. 10%), a manager must confirm. A price below cost is blocked.

### 5.7 Quotation PDF
A professional, branded quotation containing:
- Company logo, address, GSTIN and contacts
- Quote number and revision, date, validity, client, vessel, port
- Each item with HSN code, quantity, rate, GST % and amount
- Port and delivery charges, GST breakup, round-off and grand total
- Amount in words (in lakh/crore format), and terms and conditions

**It never shows** vendor names, cost prices or the company's margin.

### 5.8 Negotiation and revisions
- Each change creates a new revision (Rev 1, Rev 2…), and all older versions are kept.
- Revisions can be compared side by side: totals, discount and margin.
- Discounts reduce the taxable value, so GST stays correct.

### 5.9 Purchase orders
- Once a quotation is accepted, purchase orders are created automatically, grouped by vendor.
- PO PDFs are sent to vendors on click, and received goods are marked.

### 5.10 Delivery tracking
- Delivery method: tempo, train/transport, courier or boat.
- Vehicle or LR number, dispatch time, delivery time, and the name of the person who received it on board.
- A **proof of delivery photo** (signed delivery note) is uploaded.
- The client can be sent a "dispatched" update on WhatsApp.

### 5.11 Invoices and payments
- A GST tax invoice is created from the final accepted quotation.
- Invoice numbers run in sequence, with no gaps, per financial year, as GST rules require.
- Payments are recorded with mode, reference and TDS deducted.
- An outstanding list shows how old each unpaid bill is (0–30, 31–60, 60+ days).
- Payment reminders go out on WhatsApp.
- Invoices can be exported to Excel for the accountant.

### 5.12 Dashboard
- New inquiries, quotes awaiting approval, quotes sent, pending orders, today's deliveries, unpaid invoices.
- Monthly revenue, quotes won and lost, and conversion rate.
- Margin figures are visible to managers only.

### 5.13 Smart assistant (optional, final stage)
- Staff can type questions such as *"What did we pay for anti-fouling paint last time?"* or *"Show pending quotes at JNPT."*
- It can **only read** information. It can never change, send or approve anything.

---

## 6. How Prices Are Calculated

For each item:

```
Vendor price × exchange rate + freight     = Landed cost
Landed cost + commission (20–40%)          = Selling price
Selling price × quantity − discount        = Taxable value
Taxable value × GST rate for that item     = GST
Taxable value + GST                        = Item total
```

For the whole quotation:

```
All item totals
+ Port charges and delivery charges (with their GST)
± Round off to the nearest rupee
= GRAND TOTAL
```

**GST type:**
- **Port in Maharashtra** (same state as the company): the GST is split into CGST + SGST.
- **Port in another state** (e.g. Gujarat): the GST is charged as IGST.

**Foreign-going vessels:** supplies may qualify as zero-rated (no GST) under certain conditions.

**All GST rules will be confirmed with the company's CA before go-live**, and they stay adjustable in settings.

---

## 7. The WhatsApp Setup

**The problem:** clients message the co-founder's *personal* WhatsApp, which no software can legally connect to.

**The solution:** his number switches to **WhatsApp Business** and connects to the system through Meta's **Coexistence** feature.
- Clients keep messaging the **same number**.
- The co-founder keeps using WhatsApp **on his phone**, and his chats stay.
- The system receives every new message automatically.

**What the system sends on WhatsApp,** always after a person clicks Send:
- Quotation PDFs
- Dispatch updates
- Payment reminders
- Optionally, an automatic "we've received your list" reply (switched off until tested)

**Rules and limits:**
- Free replies are possible only within 24 hours of the client's last message; after that, only pre-approved message templates.
- The system can't read WhatsApp **groups**.
- Old chats stay on the phone; only new messages reach the system.
- Tech Shipping must complete Meta business verification.

---

## 8. Where AI Is Used, and Where It Isn't

AI is used only where it clearly helps: reading messy human input.

| Task | How it's done | Why |
|---|---|---|
| Reading supply lists (text, photos, PDFs) | **AI** | Lists are messy and handwritten; rules can't read them |
| Reading vendor price replies | **AI** | Every vendor writes differently |
| Matching item names | Normal code (text search + remembered names) | Fast, free, reliable |
| Choosing the vendor | Normal code (fixed rules) | Predictable; staff can override |
| Calculating prices and GST | Normal code **only** | Money must never depend on AI |
| Reminders and follow-ups | Scheduled messages | No judgement needed |
| Vendor ratings | Simple calculations | No AI needed |
| Answering staff questions | AI (optional, read-only) | Useful once data builds up |

**Safety rules:**
- AI results are always **drafts** that a person confirms.
- AI never calculates, chooses or changes prices.
- Nothing is sent to clients or vendors without a person clicking Send.
- Every AI action is logged, including its cost.

---

## 9. Technology (short version)

| Part | Technology |
|---|---|
| Application | Python + Django (a single app) |
| Database | PostgreSQL (a single database, with daily backups) |
| Screens | Web pages that work on phone and laptop |
| AI | Claude API (Anthropic) |
| WhatsApp | Meta WhatsApp Cloud API (Coexistence) |
| Email | Standard email connection (works with the existing company email) |
| PDFs | WeasyPrint |
| Hosting | Render: updates go live automatically when code is pushed to GitHub |
| Error alerts | Sentry |

The whole system is designed so that **one developer can build, run and maintain it.**

---

## 10. Security and Data Protection

- Staff logins, with each role seeing only what it needs.
- Costs, vendor prices and margins are hidden from staff without permission.
- Every change to prices, quotes, invoices and payments is recorded: who changed what, and when.
- Secure (HTTPS) connections only; WhatsApp messages are verified as genuinely from Meta.
- Daily automatic database backups.
- The design follows India's Digital Personal Data Protection (DPDP) Act. If data must stay in India, it can be hosted on a Mumbai server instead.

---

## 11. Build Timeline

| Stage | What gets built | When |
|---|---|---|
| **Week 0** | WhatsApp Business switch, Meta verification started, sample data collected, GST questions sent to the CA | Week 1 (in parallel) |
| **Sprint 1** | Master data, Excel import, pricing engine, quotation builder, PDF, approvals, revisions, live on the internet | Weeks 1–2 |
| **Sprint 2** | WhatsApp and email connection, AI reading of lists and vendor replies, RFQs | Weeks 3–4 |
| **Sprint 3** | Purchase orders, deliveries, invoices, payments, vendor ratings, dashboard | Weeks 5–6 |
| **Sprint 4** | Security review, optional assistant, staff and admin guides | Weeks 7–8 |
| **Parallel run** | The team uses the system alongside Excel, then switches fully | Weeks 9–10 |

The first big win, **quotations in minutes**, arrives at the end of **week 2**.

---

## 12. Not Included in Version 1

- E-invoicing (IRN) and e-way bills: done on the government portal for now
- Direct Tally connection: an Excel export is provided instead
- A client self-service portal or mobile app
- AI that searches the internet for new vendors (revisit after about 3 months)
- Predictions of demand or quote success (revisit after 6+ months of data)

---

## 13. Running Costs (approximate, monthly)

| Item | Approximate cost |
|---|---|
| Hosting and database | ₹2,000–5,000 |
| AI usage | ₹2,000–10,000, depending on volume |
| WhatsApp | Per-message charges set by Meta (check current rates) |
| Domain and email | ₹500–1,000 |
| Error alerts, code storage | Free tiers |

These are estimates to be confirmed when accounts are set up.

---

## 14. How Success Is Measured

- Inquiry to quotation sent: **under 30 minutes**
- Manual typing: **reduced by 80% or more**
- **Zero calculation errors** in quotations
- Every order visible from inquiry to payment
- Quote-to-order conversion rate and margin tracked monthly

---

## 15. Decisions Still Needed

1. Confirm the WhatsApp switch of the co-founder's number (or choose a new business number)
2. Does Tech Shipping import goods directly, or only buy from vendors delivering in India?
3. Mostly foreign-going vessels, coastal vessels, or both?
4. Who should see costs and margins?
5. Are quotes in USD needed for some clients?
6. Hosting: Render (simplest) or a Mumbai server (data kept in India)?
7. GST answers from the CA
