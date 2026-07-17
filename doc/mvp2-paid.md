# FoodieAI MVP2 — Paid Tier & Online Features

> Status: Design draft
> Locked: post-MVP1 ship

## Goals

1. Cover the long tail of dishes not in bundled DB (~100k+ dishes)
2. Add allergens / dietary safety info
3. Multi-language beyond EN/ZH
4. Restaurant recommendations near user
5. User-contributed content

## Architecture: Cloud Fallback

```
┌──────────────────────────────────────────┐
│  iOS App (MVP1 + online module)          │
│                                          │
│  Decision layer:                         │
│    1. Is dish in local DB? → local path  │
│    2. Else → online API (paid)           │
│    3. Online fail → "I don't know"       │
└──────────────────────────────────────────┘
            ↓ (online path)
┌──────────────────────────────────────────┐
│  API Gateway (OpenRouter recommended)    │
│                                          │
│  - Single key, multi-model               │
│  - Auto fallback                         │
│  - Per-request cost tracking             │
│  - Rate limiting per user tier           │
└──────────────────────────────────────────┘
            ↓
┌──────────────────────────────────────────┐
│  LLM Providers (selectable)              │
│  - Claude Sonnet 4.5  (best quality)     │
│  - GPT-4o              (best multilingual)│
│  - Gemini 2.5 Pro      (cost-effective)  │
│  - Qwen 3.5 (Alibaba)  (best Chinese)    │
│  - Groq + Llama 3.3 70B (fast fallback)  │
└──────────────────────────────────────────┘
```

## Pricing Tiers

| Tier | Price | Includes |
|---|---|---|
| Free | $0 | MVP1 (offline, bundled DB, EN/ZH) |
| Pro | $4.99/mo | + Online fallback, all languages, allergens, restaurant finder |
| Pro Annual | $39.99/yr | Pro features, 33% off |
| Family | $9.99/mo | Pro for up to 5 devices |

## Online API Cost Model (estimated)

| Action | Tokens | Cost (GPT-4o) | Cost (Qwen 3.5) |
|---|---|---|---|
| Dish description (online) | ~800 | $0.005 | $0.0004 |
| Allergen check | ~400 | $0.0025 | $0.0002 |
| Multi-lang translation | ~300 | $0.002 | $0.00015 |
| Per user per session (~10 dishes) | — | $0.05 | $0.004 |
| Monthly per active user (20 sessions) | — | $1.00 | $0.08 |

**Pro tier at $4.99/mo has 80% gross margin on GPT-4o, 98% on Qwen 3.5.**

## Premium Features (online-only)

1. **Allergens & dietary**: peanut, gluten, dairy, alcohol, halal, kosher, vegetarian, vegan
2. **Multi-language**: JP, KR, FR, ES, DE, RU, TH, VI, AR
3. **Dish suggestions**: "if you like 麻婆豆腐, you'll probably enjoy 水煮鱼"
4. **Restaurant finder**: Apple Maps integration, ratings, hours
5. **Custom DB updates**: weekly drop of new dishes (community + AI-curated)
6. **Offline DB sync**: keep local DB up to date

## Cost Mitigation Strategies

1. **Hybrid routing** — local first, online only when needed (estimated 70% of queries stay local)
2. **Aggressive caching** — popular dishes cached server-side
3. **Qwen 3.5 for Chinese** — 10x cheaper than GPT-4o for ZH content
4. **Free tier daily cap** — 20 online queries/day, then paywall
5. **Model downgrade for simple queries** — GPT-4o-mini or Haiku for straightforward translations

## Why Not Share a Personal Subscription

| | Shared Personal Account | Legitimate API Service |
|---|---|---|
| Legal risk | ❌ ToS violation | ✅ Fully legal |
| 1000 users? | ❌ Rate limited to death | ✅ No problem |
| Cost | $200/mo (Max sub) | $500-5000/mo (pay per use) |
| Stability | One account = single point of failure | Multi-model fallback |
| Model choice | Locked to one provider | 100+ models, switch anytime |
| Billing transparency | Opaque | Precise to the token |

## API Gateway Comparison

| Service | Scale | Price | Speed | Ease | Rating |
|---|---|---|---|---|---|
| **OpenRouter** | Personal → mid SaaS | Medium | Medium | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Portkey** | Mid → large | Medium | Medium | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Cloudflare Workers AI** | Any | Low | ⭐⭐⭐⭐⭐ (edge) | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Together AI** | OSS models | Low | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Groq** | Speed priority | Low | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

**MVP2 recommendation**: Start with OpenRouter (one API key, 100+ models), add Groq as fast fallback.

## Self-Hosted Option (for Scale)

When MVP2 reaches 1000+ paying users, evaluate self-hosting:

```
GPU Server ($2-3/hr cloud, or $30k one-time)
    └── Ollama + vLLM
        └── Qwen 3.5 / Llama 3.3 70B
            └── Your API
                └── foodieAI app
```

- 1000 concurrent users on H100: ~$500-2000/mo cloud
- 10x cheaper than cloud API at scale
- Requires DevOps capacity

## Legal / Compliance (for paid tier)

- App Store IAP integration (StoreKit 2)
- Subscription management via StoreKit
- Refund policy (Apple handles most)
- Privacy policy: online queries logged for 30 days for abuse detection
- GDPR / CCPA compliance for EU users
- Terms of service for paid features
- Ollama is MIT license — commercial use fully OK

## Out of Scope (MVP3+)

- Voice input (audio menu reading)
- AR overlay (point camera at menu, see translations floating)
- Social features (share discoveries, ratings)
- Recipe generation
- Cook-along mode

## Open Questions

1. Pricing right? ($4.99/mo vs $2.99 vs $6.99?)
2. Family tier cap at 5 or 6 devices?
3. Free tier cap: 20 online queries/day or weekly?
4. Should there be a "pay once" lifetime option?
5. Restaurant finder requires Apple Maps API key + Yelp integration — is the complexity worth MVP2?