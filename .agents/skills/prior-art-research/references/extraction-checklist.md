# Extraction Checklist — What to pull from each source

When deep-fetching a source, your goal is NOT to summarize the post. Your goal is to extract the patterns and decisions worth carrying into the recommendation. Use this checklist per source.

## Mandatory (extract or downrank the source)

- [ ] **Architecture sketch** — components, data flow, network boundaries. Express in 1-2 sentences in your own words. If you can't, you haven't understood it.
- [ ] **Key decision and why** — the explicit "we chose X over Y because Z." Paraphrase tightly. Cite under 15 words verbatim.
- [ ] **Scale** — actual numbers: users, RPS, latency budget, data volume. If the source is fuzzy on scale, the lessons may not transfer.

## High-value (extract when present)

- [ ] **Migration history** — what they had before, why they replaced it. Migrations are the strongest evidence of which approaches FAIL. Worth more than what they currently run.
- [ ] **Trade-offs explicitly accepted** — what they gave up. Most-missed signal. Without this, the post is marketing.
- [ ] **Failure modes** — what breaks, how it's mitigated. Reveals the system's real shape.
- [ ] **Cost** — dollars/month, infra footprint. Constrains relevance to user's context.
- [ ] **Team size** — 2 engineers vs 200 changes everything.

## Anti-patterns to filter

Downrank a source if:

- It reads like marketing (no migration, no trade-offs, no failure modes)
- Scale is missing or hand-waved
- It's a tutorial reproducing a framework's docs (low signal vs framework docs themselves)
- It's a 2-page blog post on a 6-month migration (probably oversimplified)
- The author is selling consulting and the post is the lead-magnet

## When to discard a source entirely

- Cannot extract the architecture in your own words even after re-reading
- The scale or stack is so different from the user's that nothing transfers
- It contradicts itself or basic facts about the technology
- It's a paid-content piece with no concrete details

## Quote discipline

- Maximum ONE quote per source, under 15 words, in quotation marks
- Everything else paraphrased
- Never reconstruct an article's structure with detailed paraphrase
- If a quote crosses 15 words, extract the key phrase or paraphrase fully
