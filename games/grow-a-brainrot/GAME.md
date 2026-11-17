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

### 2. Pack shop (built in M1.5)
- Players buy **seed packs**, not seeds. Opening one plays **two spins back to back**: a reel lands on the brainrot, then a slot machine rolls its mutation. The seed already "knows" both; the pop only rolls size.
- **10 pack tiers** (`Config/Packs.luau`): Basic Bag $25 → Rizz → Sigma → Aura → Mewing → Ohio → Gigachad → Tralala → 67 Pack → Cosmic Brainrot Pack $100M. Each tier costs about 6–8× the last while expected income grows a bit slower, so payback stretches from seconds to about 20+ minutes. Higher tiers also have better mutation luck and are rarer in stock.
- Stock restocks every **5 minutes** (a real, server-synced timer), with per-player quantities. Open x1 or x10.
- **Pity:** each pack guarantees its pity rarity after N opens without it (shown as a bar on the card).
- **Odds & Pity** page per pack shows rarity, per-brainrot and mutation chances, live-updated during luck events (`shared/Odds.luau` is used by both the UI and the server roll).
- Night-only packs bought with **Moon Shards** come with M3.

### Luck, admin events, fame (built in M1.5)
- **Server luck events** every 15–25 min: LUCK STORM (x2 luck), 67 SECONDS OF CHAOS (x6.7 mutations), BRAINROT FRENZY. Luck boosts higher rarity tiers' weights.
- **Admin controls** (creator, `Config.Game.Admins`, everyone in Studio): an **ADMIN panel** (bottom-left button or F2) with quick actions + a command box, and the same commands in chat with `/`. Full list in `shared/AdminCommands.luau`: luck, mutluck, custom-named `event`, endevent, givepack, seed, cash, setcash, restock, stock, grow, clear, reset, announce, speed, tp. Targets: me / all / player name.
- **Wild brainrots** (`WanderService`): every 2.5–5 min a rare, often mutated, oversized brainrot with a light beam walks one lap of the road around the plaza. Server-wide alert; first player to buy it (price = 90s of its income) gets its seed. 20% are FREE (Rare/Epic): pure race. Luck events improve them. Admin: `wander [brainrot] [mutation] [free]`.
- **Pull announcements:** Legendary+ or Rainbow+ pulls are announced to the server and go on the **Wall of Fame** board in the plaza. Secrets and 67 mutations are announced to **every server** via MessagingService.

### 3. Growing
- Stages: seed → sprout → wiggling pod → **POP** (the brainrot bursts out with confetti, a sound and a screen bump).
- Growth time scales with rarity: Common 30s → Secret ~2h. Plants keep growing while offline.
- Every grown brainrot gets a random **size** (0.8×–2.5×) that multiplies its value. Huge ones get a server shout-out.

### 4. Brainrots (the real Italian brainrot roster)
Decision (Nov 2026): use the real meme names and looks. Known risk: trademark claims exist (Mementum Lab and others) and are being fought in court (Spyder Games v. Mementum, trial Nov 2027); a Rights Manager takedown is possible. **Verity is excluded** (a human-made character with real copyright, actively licensed by its creator). "67" is fine as a number/monster; no Skrilla audio.

27 brainrots in `Config/Brainrots.luau` (the source of truth):

| Rarity | Brainrots | Earn/sec (base) |
|---|---|---|
| Common | Lirilì Larilà, Brr Brr Patapim, Trippi Troppi, Boneca Ambalabu | 1–4 |
| Uncommon | Chimpanzini Bananini, Bombombini Gusini, Ta Ta Ta Ta Sahur, Frigo Camelo | 10–18 |
| Rare | Ballerina Cappuccina, Cappuccino Assassino, Bobrito Bandito, Glorbo Fruttodrillo | 45–85 |
| Epic | Bombardiro Crocodilo, Udin Din Din Dun, Tric Trac Baraboom, Orangutini Ananassini, Trulimero Trulicina | 280–550 |
| Legendary | **Tung Tung Tung Sahur**, Brri Brri Bicus Dicus Bombicus, Cocofanto Elefanto, **Tralalero Tralala** | 2K–3.5K |
| Mythic | La Vacca Saturno Saturnita, Graipussi Medussi, Strawberry Elephant | 15K–25K |
| Secret | Los Tralaleritos, Pot Hotspot, **Lil 67** | 100K–200K |

The most famous characters are deliberately at the top rarities: those are the "I GOT TUNG TUNG!!" clip moments.

Each has a **power** stat (defense at night) and a **value** (sell price). Selling is optional: you keep them to earn, or sell them for a burst of cash.

### Backpack (built)
- BAG button / **B** key: every seed with rarity filters. Sell 1, sell all of a kind, or sell every Normal seed of a rarity. Seed sell value = 10s of its income.
- **Auto-sell** toggles (Common–Epic, Normal only): those pulls still play in the reveal (marked SOLD) and turn into cash.

### Roll speed + gamepass (built)
- Reveals are slower by default (5s reel, 2.6s mutation spin) and can't be skipped.
- **2x Roll Speed** gamepass (`Config/GamePasses.luau`, set the real ID after creating it on the Creator Dashboard): half-length reveals + click/Space to skip. Upsell button shows during reveals once the ID is set. Admin `pass FastRoll` toggles it for testing.

### 5. Day / night (built in M3, first version)
- Server-wide cycle: **6 min day, 2.5 min night**, with a big countdown and a sky that fades to purple.
- **Night monsters:** "Grumblers" (small, slow, funny) walk toward gardens. Every 3rd night is a **67 NIGHT**, when the giant blocky **67** boss stomps across the map.
- **Defense:** brainrots auto-attack monsters in range, based on their power. Players hit monsters with a starter tool (a giant spoon).
- **Losing is mild, never brutal (to keep a kid-friendly maturity rating):**
  - A monster that reaches a plant **steals growth progress**, or **grabs a brainrot and slowly runs off**.
  - Click or chase it to **rescue** the brainrot. That's a dopamine moment, and good clip material.
  - If it escapes, the brainrot goes to the **Lost & Found**, where you buy it back for cash. It is never gone forever.
- **Rewards:** defeated monsters drop **Moon Shards**. The 67 boss drops a guaranteed big shard pile plus a chance at a **Secret seed**.
- **Moonlit:** a special ×5 mutation that only comes from the **Moon Pack** (25 Moon Shards, always in stock, 50% Moonlit). 
- **Built so far:** `DayNightService` (6 min day / 2.5 min night, lighting fade, HUD timer), `MonsterService` (Grumbler waves every 20s scaling with players and night number; brainrot defense zaps; Giant Spoon tool; THE 67 boss with knockback stomps on every 3rd night; Moon Shard drops; Lil 67 seed chance from the boss), `LostFoundService` (booth by the plaza; buy back stolen brainrots as seeds, cheapest first). At dawn all monsters flee and drop what they carried.
- Not yet: rescue chase polish, monster animations, sounds, balancing.

### 6. Mutations (value multipliers)
Rolled at pack open (`Config/Mutations.luau`), boosted by pack mutation luck × server mutation luck:

| Mutation | Base chance | Multiplier |
|---|---|---|
| Gold | 6% | ×3 |
| Diamond | 2.5% | ×6 |
| Rainbow | 0.8% | ×12 |
| Galaxy | 0.2% | ×30 |
| **67** | 0.067% | **×67** |

Planned for later (M3/M4): Moonlit (grew at night), weather mutations (Saucy, Zapped), and stacking.

### 7. Weather events (server-wide hype)
Random, about every 15–25 min, lasting 2–3 min: **Pasta Rain**, **Thunderstorm**, **67 Meteor Shower** (rare). Each has a banner, music swap, particles, and its own mutation.

### 8. Brainrot Index (collection book)
- Every brainrot × mutation combination you've grown gets a filled entry.
- Completing a rarity row gives permanent rewards (+income %, a free seed, a title).

### 9. ~~Rebirth~~ (scrapped, Nov 2026)
- Decided against: wiping players' brainrots feels bad in a collecting game. Long-term progression comes from the Index bonuses, pack tiers, mutations and dailies instead. If we want a prestige-like loop later, it must never take brainrots away.

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

## Progression & live-game systems (built)
- **Tutorial** (`Config/Progress.Tutorial`, `ProgressService`, client `ProgressController`): 5 guided steps (claim → open pack → plant → pop → collect) with a quest card, bouncing arrow + beam to the target, rewards per step, skip button. Logged as an onboarding funnel in Roblox Analytics.
- **Daily login streak**: 7-day reward calendar, pops up after the tutorial when claimable; missing a day resets.
- **Daily quests**: 3 per day per player from a pool (open packs, plant, grow a Rare, collect, defeat monsters, sell, catch a wild brainrot, pull a mutation). Red dot on the Quests button when something is claimable.
- **Brainrot Index** (`IndexController`): collection book by rarity with ??? silhouettes; completing a row is claimable for +5% income forever.
- **Store** (`StoreController`, `MonetizationService`): passes FastRoll, 2x Cash, VIP (+25% + tag), Auto-Collect; products Cash Small/Large, Luck Potion (x2 pack luck 15 min, shown live in odds, hidden where paid random items are restricted), Instant Restock. Receipts are idempotent (stored in the save before granting). Set real IDs in `Config/GamePasses.luau`.
- **Leaderboards** (`LeaderboardService`): Richest + Collectors (brainrots discovered) boards in the lawns (OrderedDataStore), added at runtime if the baked map lacks them.
- **Friend boost** (`SocialService`): a Roblox friend in the server gives +10% income, +25% Moon Shards.
- **Analytics** (`AnalyticsService` wrapper): onboarding funnel, economy sources/sinks.
- **Signature models** in `BrainrotModels`: Tung Tung (log + bat), Tralalero (shark in sneakers), Bombardiro (croc bomber), Ballerina Cappuccina, Lirilì Larilà, Chimpanzini Bananini, Cappuccino Assassino, Lil 67, Strawberry Elephant, Brr Brr Patapim. Others use the generic bubbly body.
- Not done: ProfileStore migration (needs a third-party download; current DataService has session locking).

## The map lives in the place (baking)
The map is built by `server/World/WorldBuilder.luau`. Bake it into the place once so it's visible and editable in Studio:
Studio > View > Command Bar, run `require(game.ServerScriptService.Server.World.WorldBuilder:Clone()).bake()`, then File > Save.
At runtime `MapService` uses `Workspace.GrowABrainrotWorld` if it exists and only builds a fresh map when it's missing. `bake(true)` rebuilds over an existing bake (wipes manual edits inside it). Keep the names gameplay code looks for: ShopPrompt, LostFoundPrompt, WallOfFame, Plots/Plot<n>/(Tile<i>, CollectPad, SignPost, ClaimPrompt, ClaimSign), RoadX/RoadZ/RoadTop attributes. Code stays in git; the map is saved with the place (use Team Create to build together).

## Claiming gardens
No auto-assign or teleport on join. Players walk to an empty garden and use its "Claim this garden" prompt (`PlotService.claim`, fires `PlotService.Claimed`, then `GardenService.loadPlayer`). Until then the HUD shows a claim banner; the Home button teleports you to your garden afterwards.

## UI style v2 (matches the friend's reference)
White-to-cream panels, thick dark outlines, colored header bars with polka dots and LuckiestGuy titles; chunky saturated buttons with a 3D depth edge that physically presses down (`Kit.button`: set its BackgroundColor3/Text as usual; put custom children in `Kit.face(button)`, highlight with `Kit.outline(button)`); white currency pills with a gold coin; colored chips; emoji icons. Action colors: green buy, pink special, blue/teal secondary, purple rare, red close. Kid-friendly hype text on good pulls (`client/UI/Hype.luau`).

## Look & sound (overhaul, Nov 2026)
**Art direction:** bubbly, glossy, colorful plastic with real studs used as accents (ledges, corners, tops), not on every surface. Everything is built from `shared/Style` (palette, `roundedBox`, `cylinder`, `ball`, `studs`, `float`/`spin` decor tags). New props should use those builders and `Style.Palette`.
- **World** (`MapService`): layered plaza with a stud ring and floating gems, rounded pack shop with a floating sign and light bulbs, curbed road, candy and leafy trees, flower beds, rolling hills, drifting clouds; tuned lighting (bloom, sun rays, atmosphere, color correction).
- **Gardens** (`PlotService`): rounded grass bed on a colored ledge, stud strip, glowing corner orbs, inset dirt beds, glowing collect pad with a spinning coin, sign board.
- **Brainrot placeholders** (`BrainrotModels`): capsule/bean/blob bodies, googly eyes with shines, cheeks, smile, feet, shape-specific accessories, a stud on top. Real art in `ReplicatedStorage.Assets.Brainrots.<id>` still overrides.
- **Client animation**: `DecorController` (float/spin/clouds), `BrainrotAnimController` (springy pop-in, idle bob/sway), `GrowthController` (leaves, sparkles near popping, rarity pedestals).

**UI** (`client/UI/Kit`): glossy buttons with hover grow / press squish / bounce + sounds; `Kit.window` (gradient header, shadow, slide/fade); currency pills; toasts that slide in; coins fly into the cash counter. All screens use these; new UI should too.

**Audio:** original synthesized pack: `tools/make_audio.py` → `assets/audio/*.wav` (30 SFX + day/night music). Upload with `tools/upload_audio.py` (Open Cloud API key, see the top of that file), which writes `shared/Config/SoundIds.luau`. Until uploaded, `Config/Sounds` falls back to the few sounds that ship with Roblox (verified in the install's content/sounds); music stays silent. Play sounds only through `client/UI/Sfx` (groups, pitch variation, cooldowns, 3D, music crossfade). Never put unverified asset IDs in code.

## Tech architecture
- `src/shared/`: `Config` (seeds, brainrots, rarities, mutations, prices, timings), `Format` (number formatting).
- `src/server/`: `DataService` (DataStore with session locking + retries), `PlotService`, `ShopService`, `GrowthService`, `DayNightService`, `MonsterService`, `WeatherService`, `MonetizationService` (MarketplaceService receipts, PolicyService gating), `Main.server.luau` (wires them together).
- `src/client/`: HUD and shop UI, odds UI, effects (pops, number popups, announcements), day/night visuals.
- Everything that touches money or items is server-side; the client only sends requests.

---

## Code map (M1 + M1.5)
- `shared/Config/`: `Game` (tuning), `Rarities`, `Brainrots` (roster). Balance changes go here.
- `shared/BrainrotModels`: builds a brainrot model; uses `ReplicatedStorage.Assets.Brainrots.<id>` if real art exists, otherwise a placeholder.
- `shared/Config/Packs`, `shared/Config/Mutations`; `shared/Odds` (all probability math, shared by UI + server); `shared/Seeds` (seed keys `id|mutation`); `shared/Style` (studded bricks); `shared/Remotes`, `shared/Format`.
- `server/Services/`: `DataService` (save + session lock), `EconomyService` (cash), `SyncService` (state to client), `MapService` (world), `PlotService` (gardens), `ShopService` (pack stock, buying, rolls, pity), `GardenService` (plant → grow → pop → earn → collect/sell), `LuckService` (server luck events), `FameService` (announcements, Wall of Fame, cross-server pulls), `AdminService` (chat commands + panel), `WanderService` (wild brainrots on the road).
- `client/Controllers/`: `State`, `HudController`, `ShopController`, `PlantController` (hotbar + planting), `GrowthController` (sprout visuals), `EffectsController` (pops, cash popups, toasts), `PackRevealController` (reel + mutation slot, 10x flips), `MutationFxController` (rainbow animation). `client/UI/Kit` = shared UI helpers.
- New system = new Service/Controller file + one line in `Main.server.luau` / `Main.client.luau`.

## Build milestones
| # | Milestone | Done when |
|---|---|---|
| M1 | **Core grow loop** | plot, shop, plant → grow → pop → earn cash, and it saves |
| M2 | **Juice + roster** | rarities, sizes, pop effects, number popups, Index |
| M3 | **Night** | day/night cycle, Grumblers, 67 boss, defense, rescue, Moon Shards |
| M4 | **Hype** | mutations, weather, server announcements |
| M5 | **Progression + money** | gamepasses, dev products, odds UI, PolicyService |
| M6 | **Launch prep** | first-60-seconds polish, icon + 3–5 thumbnails, maturity questionnaire, performance pass |

## Launch plan (Roblox's 2026 rules)
- New games are first shown **only to age-checked 16+ players**. To reach Kids (<9) and Select (9–15), the game needs **250 unique plays by highly engaged age-checked users within 60 days**, then a safety review.
- The publisher needs: an **ID / face age check**, **2FA**, and **Premium for 2+ months** or a refundable fee.
- Plan: friends/Discord + a small Roblox Ads budget aimed at 16+ to clear the 250 engaged plays, while posting TikTok/Shorts daily.
- After launch: a **weekly update on the same day** with a lobby countdown, plus an admin-abuse style live event right before each update.

## Limited-time events (planned)
- Event windows with **special mutations** (like Moonlit: `chance = 0`, granted only by event packs/weather) and **event-only brainrots** (roster entries flagged as event, sold in an event pack or dropped by an event boss while the event runs).
- Admin-startable, with a countdown banner; event items stay tradeable/collectable after the event ends.

## First updates (after launch)
Shovel stealing (backlog: preferably a free night mechanic with protection rather than a paid steal pass), fusion (deterministic recipes), new night bosses each update (trend monsters as original homages), season pass (~299), trading (PolicyService-gated), optional light raiding at night, codes + holiday event seeds.

## Owners
- TBD: split by system once your friend is set up (suggestion: one person on garden/economy/shop, the other on night/monsters/effects).
