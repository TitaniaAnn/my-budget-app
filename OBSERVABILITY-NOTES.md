# Observability Engineering — concepts applied to myBudgetApp

Source: *Observability Engineering*, 2nd Edition (O'Reilly). Per-chapter key ideas distilled and
framed for this repo. Reference material — nothing here is built yet.

**Stack:** Flutter client + Supabase backend + an offline Python ML pipeline (on-device transaction categorizer, ONNX). Local-first.

**Current state / relevance:** Mobile-first with an ML component, so Ch19 (mobile) and Ch21 (model behavior) are the sharpest chapters.

**For this stack:**
- Ch19 mobile: device/OS/network cardinality explosion; instrument client-side but respect battery/bandwidth/privacy.
- Instrument the on-device categorizer's predictions/confidence as structured events; treat model output like Ch21 (evaluate over real data).
- Financial data — be careful what telemetry captures; log categories/outcomes, not raw transaction detail.

**Thesis:** In the AI era the binding constraint is validating and understanding code in production
fast enough to learn (Ch23). For code you write, capture one **arbitrarily wide, structured event**
per unit of work with high-cardinality context rather than siloed logs/metrics/traces (Ch3, Ch5).
The shape of the data you collect constrains the questions you can ask later.

---

## Part I — Foundations
- **What observability is (Ch1)** — Can you infer the system's full internal state from its outputs? (Control-theory duality: what you can't observe you can't control.) A property of dependability, not a tool category.
- **Test in prod is a flywheel (Ch2)** — instrumentation -> feature flags -> canaries -> automated rollbacks, each enabling the next, all grounded in trustworthy observability. "Production is reality."
- **Three pillars vs unified (Ch3)** — Separate logs/metrics/traces fit third-party infra; one wide structured event fits the code you write yourself. Misapplying one to the other is where "observability costs don't match value" comes from.

## Part II — Instrumentation
- **Instrumentation basics (Ch4)** — Auto-instrumentation = operational vital signs; custom instrumentation = business-function health.
- **Structured events (Ch5)** — One flat key/value record per unit of work; generate metric/log/trace views on demand. **The shape of the data you collect constrains the questions you can ask later** — pre-deciding the shape pre-decides the investigation.
- **Arbitrarily wide events (Ch6)** — Hundreds of attributes per event, high cardinality + dimensionality, so novel questions need no joins. A 30th attribute can be worth the previous 29 combined.
- **OpenTelemetry (Ch7)** — Open, vendor-neutral standard + semantic conventions; swap backends without rebuilding pipelines. Insist on OTel to avoid lock-in.

## Part III — Analysis & alerting
- **Core analysis loop (Ch8)** — Repeatable, data-led debugging that replaces senior-engineer intuition; best automated / AI-assisted, which only raises the premium on rich telemetry.
- **Observability-driven development (Ch9)** — Ship instrumentation *with* the feature; TDD proves "correct in theory," observability proves "correct in reality."
- **AI agents & the context layer (Ch10)** — Agents remove the "human at every gate"; the durable work is the machine-readable context they need to reason safely. Rich telemetry is what lets an agent debug this without you.
- **SLOs for reliability (Ch11)** — User-facing SLIs replace noisy threshold alerts; SLOs answer who/what, observability answers how/why.
- **SLO error budgets (Ch12)** — Alert on burn *rate* before the budget is spent; event-based budgets are debuggable (which users/services/behaviors are burning it).

## Part IV — Technical deep dives
- **Datastore requirements (Ch13)** — Sub-second queries, unaggregated events at full resolution, every field equally fast -> columnar storage. Don't pre-aggregate into counters.
- **ClickHouse (Ch14)** — Open-source columnar backend (millions of rows/sec, trillions queryable via SQL); self-hostable alternative to SaaS (OTel + ClickHouse + HyperDX).
- **Sampling (Ch15)** — Keep representative events + metadata to reconstruct the rest; head vs tail, static vs dynamic. Keep 100% at low scale; tail-sample errors/slow requests later.
- **Telemetry pipelines (Ch16)** — Collect/normalize/enrich/reduce/route; decouple producers from backends. Relevant once compliance or multi-backend retention enters.
- **Ontologies & semantic conventions (Ch17)** — Shared vocabulary prevents semantic failures (infra dashboard green while outcomes/bills are wrong).

## Part V — Use cases
- **CI/CD observability (Ch18)** — CI/CD is a production system for developer feedback; instrument builds (test suites, migrations, build steps) to find slow steps and real vs folklore flakes.
- **Frontend & mobile (Ch19)** — "Beyond the fence": uncontrolled runtimes/networks/versions, a cardinality explosion; client data is noisy but uniquely valuable. Be careful with anything affecting device performance, bandwidth, or user privacy.
- **Performance engineering (Ch20)** — Baselines + profiling; a war story where tracing alone missed a 17%-CPU regexp bug (per-request work) that profiling caught in a 5-line fix. Baseline before optimizing.
- **LLM observability (Ch21)** — LLMs are nondeterministic/opaque; no debugger, no guaranteed repeat output. Instrument prompts/outputs as wide events and use evaluations over production data.
- **Fin case study (Ch22)** — Tie every change/experiment to one customer-centric, *debuggable* metric (Fin's resolution rate); observability as a learning system, not a pile of tools.

## Part VI — Governance
- **Org learning speed (Ch23)** — The AI-era constraint is validate/understand/learn speed; the drag is unpaid sociotechnical debt (unencoded knowledge).
- **Systems thinking (Ch24)** — Software delivery is a sociotechnical system; you can't hire/buy your way out of debt. Observability is a leverage point that accelerates *every* feedback loop.
- **Landscape via systems lens (Ch25)** — Start from the feedback loops you need, not vendor feature lists. Most teams run a fast dev loop + slow ops loop, and only ops includes production.
- **Business case (Ch26)** — Anchor in the loop you're accelerating: operational (safety) vs developer (learning). Decide which is the current bottleneck.
- **Don't pay obs prices for monitoring (Ch27)** — Cost pressure usually = tool mismatch. Working signs: engineers answer novel prod questions, more frequent smaller deploys, debugging beyond a few experts, issues caught before users complain.
- **Organizational shift (Ch28)** — "The label doesn't change the capability." Five evidence tests, starting with the Ownership Test ("after you merge, how do you know it works in prod?"). A sustained capability, not a one-off project.
- **Build vs buy vs OSS (Ch29)** — An economic decision about where engineering cycles go; custom-build only what differentiates. Observability isn't the differentiator here — buy or use OSS.
- **Vendor partnerships (Ch30)** — "Vendor engineering" is high-leverage; design a real POC, encode it in SLAs, insist on OTel.
- **Instrumentation for obs teams (Ch31)** — Own instrumentation broadly; make "the right way the fast way" by baking it into shared entry points.
- **Future: developers return to production (Ch32)** — The book's one prediction: destroy the dev/ops divide. "Test in prod, or live a lie." Code shifts from sacred artifact to cache; the missing half of a green test suite is validating in production.
