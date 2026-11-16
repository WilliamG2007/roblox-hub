# Grow a Brainrot (working title)

Status: designing. Based on `research/grow-a-brainrot-market-research.md` (Nov 2026).

## The pitch (one line)
**Grow brainrots by day. They protect you by night.**

Plant seeds that hatch into ridiculous brainrot creatures who earn you cash. When night falls, monsters (led by **THE 67**) come for your garden, and your brainrots fight back.

### Why this angle
- Plain "grow a brainrot" games are crowded: several use that exact title, and all are now near zero players. We need a twist.
- **Day/night threat is the open gap**: nobody combines growing creatures with those creatures defending you. Day/night horror is trending now.
- It produces exactly the thumbnail you liked: a bright day half and a dark night half with a giant 67 looming.

### Title options (decide before launch)
Avoid the exact "Grow a Brainrot" (taken many times). Real character names are used in-game (see Brainrots); putting them in the title too raises takedown risk the most.
1. **Brainrot Garden 🌙 67 Nights** (recommended: says grow + night + meme in three words)
2. Grow Brainrots, Survive the Night
3. Night Garden: Brainrot Defense

---

## Core loop (what a player does every minute)

```
DAY (6 min)                                NIGHT (2.5 min)
buy seeds → plant → watch them grow  ──►   monsters raid gardens
   ▲            brainrot POPS out             your brainrots auto-fight
   │            earns cash/sec                you whack monsters with your tool
   │                                          defeated monsters drop Moon Shards
   └──── spend cash + shards on better seeds, plots, defenses ◄──┘
```

**Session hooks:** the seed shop restocks every 5 min, night comes every 8.5 min, plants keep growing offline, and weather events hit randomly.

---

## Systems

### 1. Garden plot
- Each player gets a plot: a starting 3×4 grid of planting tiles. Buy more rows with cash, up to 6×8.
- Grown brainrots stand on their tile, bob around, and show a floating "+$" over their head.

### 2. Seed shop
- Restocks every **5 minutes** (a real, server-synced timer, never fake).
- Each restock rolls 4–6 seed types from rarity weights. Show the odds in the shop: it's good practice and builds trust.
- Bought with **Cash** (in-game). Night seeds cost **Moon Shards**.

### 3. Growing
- Stages: seed → sprout → wiggling pod → **POP** (the brainrot bursts out with confetti, a sound and a screen bump).
- Growth time scales with rarity: Common 30s → Secret ~2h. Plants keep growing while offline.
- Every grown brainrot gets a random **size** (0.8×–2.5×) that multiplies its value. Huge ones get a server shout-out.

### 4. Brainrots (the real Italian brainrot roster)
Decision (Nov 2026): use the real meme names and looks. Known risk: trademark claims exist (Mementum Lab and others) and are being fought in court (Spyder Games v. Mementum, trial Nov 2027); a Rights Manager takedown is possible. **Verity is excluded** (a human-made character with real copyright, actively licensed by its creator). "67" is fine as a number/monster; no Skrilla audio.

| Rarity | Brainrots | Earn/sec (base) |
|---|---|---|
| Common | Lirilì Larilà, Brr Brr Patapim, Trippi Troppi, Boneca Ambalabu | 1–3 |
| Uncommon | Chimpanzini Bananini, Bombombini Gusini, Frigo Camelo | 8–15 |
| Rare | Ballerina Cappuccina, Cappuccino Assassino, Glorbo Fruttodrillo | 40–80 |
| Epic | Bombardiro Crocodilo, Udin Din Din Dun, Trulimero Trulicina | 250–500 |
| Legendary | **Tung Tung Tung Sahur**, **Tralalero Tralala** | 2K–4K |
| Mythic | La Vacca Saturno Saturnita, Strawberry Elephant | 15K–30K |
| Secret | **Lil 67** (a tiny friendly 67, drops from the 67 boss), Moonlit Tung Tung | 100K+ |

The most famous characters are deliberately at the top rarities: those are the "I GOT TUNG TUNG!!" clip moments.

Each has a **power** stat (defense at night) and a **value** (sell price). Selling is optional: you keep them to earn, or sell them for a burst of cash.

### 5. Day / night
- Server-wide cycle: **6 min day, 2.5 min night**, with a big countdown and a sky that fades to purple.
- **Night monsters:** "Grumblers" (small, slow, funny) walk toward gardens. Every 3rd night is a **67 NIGHT**, when the giant blocky **67** boss stomps across the map.
- **Defense:** brainrots auto-attack monsters in range, based on their power. Players hit monsters with a starter tool (a giant spoon).
- **Losing is mild, never brutal (to keep a kid-friendly maturity rating):**
  - A monster that reaches a plant **steals growth progress**, or **grabs a brainrot and slowly runs off**.
  - Click or chase it to **rescue** the brainrot. That's a dopamine moment, and good clip material.
  - If it escapes, the brainrot goes to the **Lost & Found**, where you buy it back for cash. It is never gone forever.
- **Rewards:** defeated monsters drop **Moon Shards**. The 67 boss drops a guaranteed big shard pile plus a chance at a **Secret seed**.
- **Moonlit:** anything that finishes growing at night has a 1-in-10 chance to become **Moonlit** (glowing).

### 6. Mutations (value multipliers)
| Mutation | How | Multiplier |
|---|---|---|
| Gold | 1/50 on any pop | ×5 |
| Rainbow | 1/300 | ×20 |
| Moonlit | grew at night, 1/10 | ×3 |
| Saucy | during Pasta Rain weather | ×4 |
| Zapped | during Thunderstorm | ×6 |
| **Sixty-Seven** | during the 67 Meteor Shower event | **×67** |

Mutations stack multiplicatively, so a Gold Moonlit is ×15. Rare stacks trigger server-wide announcements.

### 7. Weather events (server-wide hype)
Random, about every 15–25 min, lasting 2–3 min: **Pasta Rain**, **Thunderstorm**, **67 Meteor Shower** (rare). Each has a banner, music swap, particles, and its own mutation.

### 8. Brainrot Index (collection book)
- Every brainrot × mutation combination you've grown gets a filled entry.
- Completing a rarity row gives permanent rewards (+income %, a free seed, a title).

### 9. Rebirth
- Unlocked at a cash milestone. Resets cash, plot size and brainrots. Keeps the Index, Moon Shards and gamepasses.
- Gives a permanent **+50% income** per rebirth and unlocks a new seed tier in the shop.

### 10. Social and co-op
- **Server announcements:** "PLAYER grew a RAINBOW Disco Pandarino!!" with a sound on everyone's screen.
- **Night Watch:** friends standing in each other's gardens at night get +25% shards, and their brainrots help defend. (Intentional co-play is a ranking signal.)

---

## Monetization (compliant from day one)

| Product | Type | Price (R$) | Notes |
|---|---|---|---|
| 2x Cash | Gamepass | 299 | genre standard |
| VIP | Gamepass | 249 | +25% income, chat tag, VIP-only cosmetic seed |
| Auto-Collect | Gamepass | 149 | cash flows in without walking to brainrots |
| Extra Plot Rows | Gamepass | 199 | +2 rows above the normal cap |
| Instant Restock | Dev product | 39 | rerolls your shop |
| Starter Pack | Dev product | 99 | **fixed contents**, not random |
| Luck Potion (15 min) | Dev product | 179 | **affects random results, so live odds UI required** |
| Mystery Seed Pack | Dev product | 199 | **random: odds shown before purchase + PolicyService gating** |
| Moon Lantern | Dev product | 49 | protects your garden for one night |

**Hard rules (Roblox policy; breaking them can get the game removed):**
- Every paid random item shows all outcomes with % odds behind a labelled "Odds" button, before purchase, and updates live while a luck boost is active.
- Check `PolicyService:GetPolicyInfoForPlayerAsync()`: if `ArePaidRandomItemsRestricted`, hide the random packs (and luck potions) for that player. If `IsPaidItemTradingAllowed` is false, no trading of Robux-bought items (once trading exists).
- No fake timers, no surprise purchase popups, no confusing currency bundles. Free players must be able to get everything except passes and cosmetics.

---

## The first 60 seconds (top ranking signals: play-through and bounce rate)
1. Spawn **inside your own garden**. An arrow points to the shop, and one free Common seed is already in your hand.
2. Plant it, and it pops **within ~15 seconds**: first confetti moment.
3. Cash starts ticking up. The arrow points to the shop again: buy 2 more seeds.
4. The first night arrives at **~3 minutes** (shortened just for new players). It's a tiny, easy Grumbler wave so they win and get shards.
5. A short "Night is coming…" sting and sky change sells the hook the thumbnail promised.

---

## Feel (dopamine checklist)
- Saturated colors, chunky shapes, bouncy idle animations on every brainrot.
- Big, satisfying number popups, coin bursts, a screen bump on rare pops, and rarity-colored light beams.
- Distinct sounds per rarity (our own audio, no meme clips).
- The night stays **mild-spooky, never scary** (keeps the rating at Minimal/Mild so under-9s can play).

---

## Tech architecture
- `src/shared/`: `Config` (seeds, brainrots, rarities, mutations, prices, timings), `Format` (number formatting).
- `src/server/`: `DataService` (DataStore with session locking + retries), `PlotService`, `ShopService`, `GrowthService`, `DayNightService`, `MonsterService`, `WeatherService`, `MonetizationService` (MarketplaceService receipts, PolicyService gating), `Main.server.luau` (wires them together).
- `src/client/`: HUD and shop UI, odds UI, effects (pops, number popups, announcements), day/night visuals.
- Everything that touches money or items is server-side; the client only sends requests.

---

## Build milestones
| # | Milestone | Done when |
|---|---|---|
| M1 | **Core grow loop** | plot, shop, plant → grow → pop → earn cash, and it saves |
| M2 | **Juice + roster** | rarities, sizes, pop effects, number popups, Index |
| M3 | **Night** | day/night cycle, Grumblers, 67 boss, defense, rescue, Moon Shards |
| M4 | **Hype** | mutations, weather, server announcements |
| M5 | **Progression + money** | rebirth, gamepasses, dev products, odds UI, PolicyService |
| M6 | **Launch prep** | first-60-seconds polish, icon + 3–5 thumbnails, maturity questionnaire, performance pass |

## Launch plan (Roblox's 2026 rules)
- New games are first shown **only to age-checked 16+ players**. To reach Kids (<9) and Select (9–15), the game needs **250 unique plays by highly engaged age-checked users within 60 days**, then a safety review.
- The publisher needs: an **ID / face age check**, **2FA**, and **Premium for 2+ months** or a refundable fee.
- Plan: friends/Discord + a small Roblox Ads budget aimed at 16+ to clear the 250 engaged plays, while posting TikTok/Shorts daily.
- After launch: a **weekly update on the same day** with a lobby countdown, plus an admin-abuse style live event right before each update.

## First updates (after launch)
Fusion (deterministic recipes), new night bosses each update (trend monsters as original homages), season pass (~299), trading (PolicyService-gated), optional light raiding at night, codes + holiday event seeds.

## Owners
- TBD: split by system once your friend is set up (suggestion: one person on garden/economy/shop, the other on night/monsters/effects).
