# Source Tiers — Curated by Domain

> **Living document.** Source quality drifts — companies pivot, blogs go quiet, new orgs publish good engineering content. When this list feels stale (or you find a great source not on it during research), append it. Quarterly audits recommended. The list below was last reviewed: 2026-05-10.

High-signal engineering sources, organized by domain. Search these first before falling back to broad web search.

## Tier 0 — Modie's internal precedent

Always check these first when relevant. Your own ADRs and architecture writeups are the highest-signal source.

- `BeanBot` repo — NL2SQL, RAG, ECS Fargate, pgvector, LangGraph orchestration, prompt caching, multi-agent NL2SQL
- `salahi.app` repo — Next.js 15, React 19, Supabase, 4-tier scraping pipeline, provider abstraction, PWA push notifications
- `AEGIS` / BOL automation — Claude vision OCR, ECS workers, SQS, DynamoDB, document extraction pipelines
- `Spiff-App` — (add relevant domains)
- Any ADRs in `docs/agents/adrs/` of the current repo

## Tier 1 — Production engineering blogs by domain

### Data systems / databases / storage
- Stripe Engineering blog (idempotency, distributed systems, Postgres at scale)
- Discord Engineering (large-scale messaging, ScyllaDB migration, MongoDB story)
- Figma Engineering (sharding, multi-region)
- Notion Engineering (block storage, search, RAG)
- LinkedIn Engineering (Kafka, Pinot, Espresso)
- Uber Engineering (Cadence, M3, Ringpop, dispatch)
- Cloudflare Blog (edge databases, Durable Objects, R2)
- AWS Builders' Library (canonical patterns for SQS, DynamoDB, S3)
- PlanetScale blog (Vitess, online schema changes)
- Crunchy Data / Citus / Postgres-specific (Postgres at scale)

### Real-time / collaboration / sync
- Figma "How figma's multiplayer technology works"
- Linear (sync engine, real-time architecture)
- Liveblocks Engineering (presence, CRDTs in production)
- Convex Engineering (sync engine, reactive queries)
- Replicache / Reflect (incremental sync)
- Automerge / Yjs / Loro docs and benchmarks
- Google Docs engineering papers (OT background)

### Search / retrieval / RAG / vector
- Pinecone / Weaviate / Qdrant engineering blogs (production vector DB patterns)
- LangChain / LlamaIndex blogs (RAG patterns, evaluation)
- Anthropic engineering posts (Claude system prompts, tool use, RAG)
- OpenAI Cookbook
- Vespa engineering (hybrid search at scale)
- Elastic blog (lucene patterns, when to NOT use it)
- Uber QueryGPT writeup
- LinkedIn SQL Bot writeup
- Pinterest visual search

### Frontend / UI / state management
- Vercel blog (Next.js patterns, RSC, ISR)
- Shopify engineering (Hydrogen, Remix-era patterns)
- Linear (UI perf, sync engine UX)
- Figma (canvas perf, multiplayer UX)
- Discord client architecture
- Slack (Electron + React perf at scale)

### Infrastructure / DevOps / deployment
- AWS Builders' Library
- Google SRE Books (canonical, but read selectively)
- Honeycomb engineering (observability, sampling)
- Fly.io blog (edge deployment, networking)
- Cloudflare Workers (edge compute patterns)
- Vercel blog (deployment, ISR, edge)
- Render / Railway / Fly engineering posts

### ML / AI / LLMs / agents
- Anthropic posts (agentic patterns, tool use, "Building effective agents")
- OpenAI Cookbook
- LangChain / LangGraph blog
- Databricks blog (MosaicML, fine-tuning, RAG eval)
- HuggingFace blog
- Sebastian Raschka writeups
- Eugene Yan writeups
- Chip Huyen writeups
- Simon Willison's blog (practical agents)
- Hamel Husain's blog (eval, fine-tuning)

### Payments / billing / fintech
- Stripe Engineering (canonical for idempotency, webhooks, ledger)
- Block / Square engineering
- Plaid engineering
- Adyen engineering
- Modern Treasury blog
- Increase engineering (ledger design)

### Email / messaging / notifications
- Postmark blog
- Resend blog
- SendGrid engineering
- Twilio blog (SMS, voice)
- Knock notifications blog

### Authentication / authorization / security
- Auth0 / Okta engineering
- Stytch engineering
- WorkOS blog
- Clerk engineering
- Oso / Permit.io blog (authz patterns)
- AWS security blog

### Distributed systems / consensus / messaging
- Kafka summit talks
- NATS blog
- Temporal engineering
- Cadence (Uber)
- Confluent engineering
- Jepsen analyses (consistency claims testing)
- Aphyr's posts

## Tier 2 — GitHub repos to read code from

When researching, find 2-3 active OSS repos doing approximately-X. For natural-language feature descriptions ("local AI assistant that remembers screen activity"), run the **semantic-repo-discovery loop** in [`semantic-repo-discovery.md`](semantic-repo-discovery.md) (fire-rule-gated per [ADR-0017](../../../docs/agents/adrs/0017-semantic-repo-discovery-port.md); skipped under Quick tier). For precise-tech queries, use `gh search repos` or WebSearch directly. Either way, then read:

- Top-level README architecture section
- `docs/architecture.md` or equivalent
- The actual module structure
- The migration history (BREAKING CHANGES in CHANGELOG often documents lessons learned)
- Any ADRs

## Tier 3 — Talks, RFCs, ADRs

- QCon, Strange Loop, PWLConf, RailsConf, GOTO
- Rust RFCs, Kubernetes KEPs, Postgres mailing list
- Architectural Decision Records in popular OSS

## Tier 4 — Practitioner threads

- HackerNews comments (engineers > marketers, but watch for confidently-wrong takes)
- /r/programming, /r/devops, /r/datascience top threads
- lobste.rs
- Substack threads from named senior engineers

## Tier 5 — Official docs

Lowest priority. Usually theoretical. Use only when a real implementation doesn't exist or for API surface (and prefer Context7 for that).

## Anti-sources

Skip or downrank:
- SEO content farms (medium.com posts with no engineering depth, dev.to filler)
- Marketing posts disguised as engineering (no migration story, no trade-offs explicitly named)
- Generic "best practices" articles without scale numbers or trade-offs
- Stack Overflow for architecture questions (great for API surface, bad for architecture)
