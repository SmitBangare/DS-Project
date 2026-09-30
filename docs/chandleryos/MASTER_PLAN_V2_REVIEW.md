# Review: Master Plan, updated version (v2)

Compared line by line with the previous version ([MASTER_PLAN_REVIEW.md](MASTER_PLAN_REVIEW.md)). Source: `source/Master_Plan_v2.pdf`.

> Points marked **(verify)** must be confirmed against current Meta documentation during setup.

## 1. What changed

**Only the WhatsApp content changed.** Every other page (modules, AI, pricing formula, stack, data tables, sprints, risks, glossary) has identical text, only reflowed across pages.

| Area | Before | Now |
|---|---|---|
| Number | Convert the co-founder's personal number (Coexistence) | **New dedicated company number** on WhatsApp Business + Coexistence; personal number stays private and unconnected |
| Device | Co-founder's own phone | A **company phone**; staff reply from it |
| Setup steps | Back up and migrate the personal number | Fresh SIM never used on WhatsApp, company's name, keep recharged; Business app on a company phone; use it early; Meta verification; Coexistence QR; **permanent access token** |
| Client migration | Not needed | Announce from the personal number; add to signatures, PDFs, website, cards; lists arriving on the personal number are **forwarded** or entered as a **manual inquiry** (paste text / upload photo) |
| Staging | Test number (unspecified) | Meta's **free developer test number**, no second SIM |
| Link drop | Reconnects after re-registration | Same, plus **Admins are alerted** |
| Alternative | "New number on Cloud API only" listed | Removed |
| Open decisions | Migrate or new number? | Decided. New question: **who keeps the company phone day to day?** |
| Week 0 | WhatsApp Business switch | New number set up and announced to clients |

## 2. Assessment of the new WhatsApp section

**Good, keep as is**
- Separating the business number from the personal one fixes the privacy and personal-chat problems cleanly.
- "Keep it recharged: if the SIM lapses, the business WhatsApp is lost" is an important, often missed operational point.
- "Start using it early" matches Meta's possible activity requirement before Coexistence linking (verify).
- The **manual inquiry** path (paste text or upload a photo, same AI reading) is a valuable addition. It covers the switch-over period, email screenshots and any channel outage. Build it in Sprint 1 or early Sprint 2, not only as a fallback.
- Permanent access token (System User token) is the right choice for production.
- Admin alert on link drop is now explicit.

**Issues to fix**

1. **The co-founder's own access.** WhatsApp is the co-founder's main work tool, but the plan now puts the number on a *company phone* that staff use. If he doesn't hold that phone, he loses direct mobile access to client chats. Options:
   - he keeps the company phone himself; or
   - he uses **linked devices** (WhatsApp Web/Desktop) on his own phone or laptop. Whether linked devices keep working after Coexistence is connected must be checked (verify); or
   - once connected, he uses the ChandleryOS inbox on his phone.
   Settle this together with the new open decision "who keeps the company phone".
2. **Coexistence route still untested, and the test number can't test it.** Meta's developer test number is API-only, so it's fine for staging but **cannot rehearse Coexistence onboarding** (the QR step from the Business app). The question from the previous review still stands: direct connection needs Tech Provider / Embedded Signup setup, otherwise a BSP (verify). The "How to connect" table still recommends direct without mentioning this. Rehearse the real onboarding with the actual company number as soon as Meta verification is done, well before Sprint 2 ends, and keep a BSP as the fallback.
3. **History from the weeks before connection.** The number will be in use from Week 0 but connected only in Sprint 2 (weeks 4–6). Coexistence onboarding may offer to import recent chat history (verify). If it does, enable it, since those weeks contain real inquiries and are perfect AI test data. The plan currently says the system "starts with messages to the new number", which may lose them.
4. **Forwarded messages show the wrong sender.** A list forwarded from the personal number arrives *from the co-founder*, not from the client. The inbox needs "forwarded on behalf of <client>" when creating the inquiry, or these inquiries get attached to the co-founder as the client.
5. **The bot still acts on its own.** The bot section still says it "acknowledges each inquiry instantly" and "asks for missing details". With staff now chatting on the company phone in the same threads, automatic messages from the system will cross with human replies. Principle 4 says nothing reaches a client without a person approving. Make v1: no automatic messages; "missing details" becomes a suggested message staff send with one click; auto-acknowledgement is a setting, off by default.
6. **Staff guide not updated.** The *Simple Guide* still says "For clients, nothing changes" and "The co-founder's WhatsApp number will be switched". Update it: new company number, the company phone, forwarding or manual inquiry during switch-over.
7. **Company phone security.** A shared phone holding every client conversation needs a screen lock, WhatsApp two-step verification PIN (held by an Admin), and no personal use. Add to the risks table.

## 3. Earlier findings that are still open

None of the non-WhatsApp findings from [MASTER_PLAN_REVIEW.md](MASTER_PLAN_REVIEW.md) have been addressed in this version, because those pages are unchanged:

- **Pricing (§3):** "margin" used as markup; floor rule undefined; below-cost not blocked; only % discount; **round-off missing**; rounding rules; freight split; duplicate step 5.
- **Contradictions (§4):** pgvector/RAG vs "no vector database"; AI vendor search listed but deferred; bot autonomy (see issue 5 above); "2 weeks" vs Sprint 1 = weeks 1–3; glossary "two-week sprint"; Week 0 labelled "Weeks 1–2"; sample-data counts differ between documents; vessel-type flag on vessel vs quotation; invoice "from final quote" in the staff guide; duplicate "imports directly?" question.
- **GST/compliance (§5):** bill-to/ship-to place of supply; zero-rating + LUT; GST on charges; **e-invoicing if turnover > ₹5 crore**; e-way bill number; invoice numbering (≤16 chars, gapless); credit-note deadline; TDS/TCS; USD invoices.
- **Technical (§7):** R2 has no India storage if data must stay in India; copilot can leak margins; 2FA for Admin/Manager; audit-trail library; AI accuracy metric definition; quote expired/lost/cancelled statuses; ship agent contact.
- **Build pack:** `CLAUDE.md`, `SPEC.md`, `BUILD_PROMPTS.md` and `.env.example` still not shared for review.

## 4. Verdict

The WhatsApp decision is sound and well written up. It's a real improvement: cleaner privacy, and the manual-inquiry path makes intake robust. The two things to act on are **who holds the company phone (and how the co-founder keeps access)** and **rehearsing the real Coexistence onboarding early**.

The document's overall readiness is unchanged, at about 85%. The pricing spec and the CA's GST answers remain the main blockers before Sprint 1 code.
