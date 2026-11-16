# "Grow a Brainrot" — Roblox Market Research

*Prepared 2026-11-16. Sources are listed at the end and cited inline as [S#]. Third-party tracker numbers (CCU, revenue) are estimates and often disagree with each other. Where a claim could not be verified or the source is weak, it is marked **(unverified)** or **(low confidence)**.*

---

## Executive summary

1. **The brainrot and grow wave peaked in 2025 and has mostly faded.** Steal a Brainrot peaked at about 25.4–25.8M CCU in Oct 2025 and Grow a Garden at 22.3M in Aug 2025. On 16 Nov 2026 they sit at roughly **41–44K** and **15K** CCU. Plants vs Brainrots has dropped from 8.65M to about **2–3K** [S1][S2][S5][S6][S8][S9].
2. **The current #1 game, Steal An Egg (14.3M peak, Sep 2026), uses the same core idea in a new skin:** collect creatures, earn passive income, hatch eggs, mutate them, and steal from other players. The loop still works. What has worn out is the "brainrot" label [S10][S11].
3. **A pure "Grow a Brainrot" is already a crowded niche.** Several titles with that exact name exist. The best one peaked at 44K CCU and now has single-digit players, and the others flatlined below about 3K [S13][S14]. We need a twist. The open space is **grow by day, defend by night, using the creatures you grew**. That fits the current "day/night horror" trend [S12]. No big game owns this combination yet.
4. **Kid trends right now:** "67" was the most-searched Gen Alpha term from Jan to Aug 2026, but kids now use it more ironically [S20]. **"Verity" is the hottest new meme (Aug–Oct 2026).** It is a yellow smiley-faced evil AI from ThatMob's Minecraft horror series. Italian brainrot characters are still recognised but are no longer new [S21][S22][S23].
5. **IP risk is real and still unsettled.** The Italian brainrot characters are AI-generated and probably can't be copyrighted. However, Mementum Lab holds a French and Madrid-system trademark and is fighting Steal a Brainrot's owners in a US court case, with trial set for Nov 2027. Other companies have filed trademarks for "Tralalero Tralala" and "Tung Tung Tung Sahur" [S15][S16][S17][S18]. **Verity is an original, human-made character owned by ThatMob**, so copying it carries more risk than the Italian roster [S22]. Recommendation: make our own parody-style characters and keep real meme names out of the title, icon and thumbnails.
6. **The biggest launch blocker is Roblox's 2026 rules for reaching kids.** A new game is first shown only to **age-checked 16+ players**. It becomes visible to Roblox Kids (under 9) and Select (9–15) only after **250 unique plays by "highly engaged" age-checked users within 60 days**. The publisher also needs ID or face age-check, 2FA, and either Plus/Premium or a refundable fee [S27][S28]. The launch plan has to account for this.
7. **Monetization must follow the paid-random-items rules.** Random eggs, seed packs and luck boosts bought with Robux need numerical odds shown before purchase, live updated odds while a boost is active, and region and age gating through `PolicyService` (`ArePaidRandomItemsRestricted`, `IsPaidItemTradingAllowed`). Breaking these rules can get the game removed [S24][S25].
8. **Typical price points in this genre:** 2x Money pass about 299 R$, VIP 249–375 R$, season pass 299–749 R$, instant restock about 39 R$, luck potions about 179 R$, random eggs or blocks 149–2,999 R$, and timed server luck 249–999 R$ [S29][S30][S31][S32]. **DevEx pays $0.0038 per Robux**, or $0.0054 for spending by verified US adults [S33]. **The median DevEx creator earned only about $1,500 a year**, while the top 1,000 averaged $1.4M [S34].
9. **What the algorithm rewards:** Since 15 Jun 2026, Recommended For You ranks games mainly on first-session play-through rate, first-play bounce rate, play days and playtime, measured over Day 1, Days 2–7 and Days 8–28. Paid ads do not count toward these signals, and clickbait thumbnails that cause players to bounce now hurt the game [S35][S36][S37].
10. **How to win:** ship a small, polished first version fast, then update weekly on the same day with admin-abuse style live events. Use bright 3D thumbnails with characters and expressive faces, and rotate several of them (88% of chart games run 2+) [S39]. Post short-form video daily, since TikTok and Shorts are the main way kids find games. Keep under-13 marketing organic, because Roblox Ads can't target under-13s [S41][S42].

---

## 1. Competitive landscape

### 1.1 Competitor table

| Game | Release | All-time peak CCU | CCU now (≈16 Nov 2026) | Visits | Revenue (reported / estimated) | Studio |
|---|---|---|---|---|---|---|
| **Grow a Garden** | 25–26 Mar 2025 | **22.3M** (23 Aug 2025, Admin War) [S1] | ~15.1K [S3] | ~36B [S3] | Bloomberg: ≥$148M profit in 8 months [S43]. Est. ~$372K/mo now, ~$287M lifetime (low confidence) [S3] | BMWLux (16-year-old original dev) + Splitting Point (Jandel) + DoBig minority share [S1] |
| **Steal a Brainrot** | 16 May 2025 | **25.4M** (Wikipedia) / 25.8M (trackers), Oct 2025. Platform-wide 47.4M during the Aug 2025 admin war [S2][S4] | ~41–44K [S5][S11] | ~74.5B [S5] | Est. $577M lifetime; $0.6–3.5M/mo in 2026, depending on tracker (low confidence) [S4][S5] | SpyderSammy / DoBig Studios (Spyder Games LLC). Team size not public [S2][S17] |
| **Plants vs Brainrots** ("Plants & Brainrots") | 1 Aug 2025 | **8.65M** [S6] | ~1.9–2.5K [S7][S8] | ~4.7B [S6] | Est. ~$24K/mo now (low confidence) [S7] | "Splitting Point – PVB" group / Yo Gurt Studio (Jandel-linked). 25+ staff reported [S6][S44] |
| **99 Nights in the Forest** | Created Mar 2025, broke out Jun 2025 | **14.15M** [S9] | ~114K (one 48h peak hit 1.41M) [S9][S11] | ~30.5B [S9] | Est. ~$1.27M/mo, $228M lifetime (low confidence) [S45] | Grandma's Favourite Games [S9] |
| **Steal An Egg** (current #1) | 25 Jul 2026 | **14.3M** (19 Sep 2026) [S10] | ~520K [S10][S11] | ~11.4B [S10] | Not reported | Not public [S10] |
| **Escape Tsunami For Brainrots** | 15 Dec 2025 | ~5M [S19] | ~164K (early 2026); declining [S19] | n/a | n/a | "Wave of Brainrots" [S19] |
| **Grow a Garden 2** | 21 May 2026 | ~688K [S46] | ~721 [S46] | ~1.7B [S46] | Est. $13.4M lifetime (low confidence) [S46] | Strawberreh Squad [S46] |
| **Steal A Verity** (several versions) | 23 Jul 2026 onward | ~53–55K per version [S23] | ~13K [S23] | 24–64M per version [S23] | n/a | various |
| **[👶] Grow a BRAINROT!** | 10 Oct 2025 | 44K [S13] | **9** | 56M | 3 passes, 199–449 R$ [S13] | Mightystudios & Waredev |
| **Grow a Brainrot [Blood Moon]** | ~2025 | 3.3K [S14] | 0 | 5.6M | Passes 349–499 R$ [S14] | Brainrot Simulator Group |
| **Plant Brainrot Simulator** | ~Dec 2025 | 31K [S47] | ~25 | 42M | Passes 59–699 R$ [S47] | Rainbow Isle Studio |
| **99 Nights on a GARDEN** / "Survive in the Forest" | 17 May 2025 | 10.9K [S48] | ~12 | 65M | n/a | DGABzd |

Context: Roblox averaged **138M DAU in Q3 2026, down 9% year on year**, the platform's first annual decline. Hours played fell 15% and monthly payers fell 16%, mostly because of new age checks and chat limits. An August 2026 bot purge also cut many games' visible CCU [S49][S50]. Every peak in the table above was reached before these changes.

### 1.2 Core loops and what made them work

| Game | Core loop | Progression systems | What players and press credit for success |
|---|---|---|---|
| Grow a Garden | Buy seeds from a shop that restocks on a timer → plant → crops grow (including **while offline**) → harvest and sell → buy rarer seeds [S1][S3] | Seed rarities, **mutations**, **weather events** (Blood Moon, Lunar Glow and others), pets from eggs, gear (sprinklers, watering cans), stealing crops, season pass [S1][S29] | **The same weekly update every Saturday since Apr 2025** [S51]. Very easy to understand. Restock timers create "come back in 5 minutes" urgency. Admin-abuse events and creator collaborations [S52] |
| Steal a Brainrot | Buy brainrots from a conveyor belt → they earn passive income in your base → **steal from other players' bases** (bases have a timed lock) [S2] | Rarity tiers, mutations (e.g. "Cursed" Jan 2026), rebirths, lucky blocks, trade machine (Feb 2026) [S2][S53] | Stealing clips spread on TikTok. **Twice-weekly admin-abuse live streams** where the dev spawns rare units [S52]. Steady weekly content [S19] |
| Plants vs Brainrots | Plant seeds → plants auto-attack brainrots walking down a lane → defeated brainrots go into your base and earn money → reinvest [S44] | Seed rarities, **weather-driven mutations** (Galaxy, Rainbow, Freeze), rebirth with luck stacking, fusion, season pass [S44][S31] | A known formula (Plants vs Zombies + tycoon) with easy early wins and meme humour [S44] |
| 99 Nights in the Forest | Co-op survival: gather by day, protect the campfire and rescue kids by night from the Deer monster [S9] | Classes, diamonds, nightly difficulty ramp | Day/night tension, co-op play, friendly to YouTubers. Mostly cosmetic monetization (main pass 199 R$) [S45] |
| Steal An Egg | Steal and hatch eggs → collect rare pets → passive income → upgrade, mutate, steal from players [S10] | Rarities, mutations, upgrades | The Steal a Brainrot loop with a cuter pet theme; spawned many egg spin-offs [S12] |

### 1.3 Clones that failed or flatlined, and why

- **Pure "Grow a Brainrot" clones** (see table) reached 3K–44K CCU and are now near zero. The pattern is a short spike from the trending name followed by collapse. They had no distinct hook and stopped updating; the Blood Moon one was last updated about 10 months ago [S13][S14].
- **Grow a Garden 2** went from about 688K peak to about 700 CCU. Reasons cited: recycled content, repetitive events, confusing progression, pay-to-win Robux shortcuts, a shift away from the relaxed social feel, and the bot purge [S46][S54].
- **Grow a Garden itself** lost about 78% of its average CCU between May and Oct 2026, falling 19–41% every month. Cited causes: exploit and economy problems, events that felt recycled, update fatigue, and the bot purge [S55][S56].
- **Genre-wide:** Roblox developers clone fast (26 clones of one Steam hit appeared within about 3 weeks), and most clones die quickly. Roblox now demotes games whose presentation looks the same as existing games [S57][S36].

### 1.4 Saturation and remaining gaps

- **Saturation:** very high. One source counts about 12,400 "Brainrot" games on Roblox **(unverified)** [S57]. Several games already use the exact title "Grow a Brainrot" [S13][S14][S58]. Analysts call the genre "normalising" rather than dead. Their advice is to use brainrot as a **skin on an underserved mechanic** [S19][S57].

| Twist | Already claimed? | Opportunity |
|---|---|---|
| **Day/night threat** (grow by day, survive by night) | Partly. Grow a Garden 2 has night stealing; 99 Nights on a GARDEN and Nights in the GARDEN have garden defense. All are small or dead [S46][S48][S59] | **High.** Nobody combines growing brainrot creatures from seeds with having those creatures defend you at night. Day/night horror is trending in Nov 2026 (Sell Fries!) [S12] |
| Raiding / stealing | Heavily claimed (Steal a Brainrot, Steal An Egg) | Low as the main hook. Fine as a light side feature |
| Fusion / breeding | Claimed (Plants vs Brainrots fusion, Grow a Brainrot "mix") [S44][S58] | Medium. Good secondary system |
| Co-op survival | 99 Nights owns it; few garden versions | Medium–high when combined with growing |
| Tower defense | Plants vs Brainrots owns it | Low |

**Identifying the reference game (unverified).** We could not identify for certain the game behind the "DAY / NIGHT 67 monster" thumbnail or the "keep planting seeds until garden reaches 100%" clip. Closest matches:

- **Nights in the GARDEN** (A Survival Studio): "grow 2,000 lbs of crops while something hunts your harvest". It was inspired by Grow a Garden, Dead Rails and 99 Nights, and had no running servers when checked [S59].
- **99 Nights on a GARDEN** (DGABzd) [S48].
- Grow a Garden 2's night-stealing mode [S46].
- "GROW A 67" (Wobbler United) is a 67 meme game, but it is an eat-and-grow game, not planting [S60].

Ask the dev for the game name or link to confirm.

---

## 2. Characters and trends

### 2.1 Popularity ranking (best estimate, Nov 2026)

| Rank | Meme | Status | Evidence |
|---|---|---|---|
| 1 | **Verity** ("Hey, it's me, it's Verity!") | **Hottest new meme.** Viral Aug–Oct 2026, a top Halloween costume in Oct 2026. Kids add "-ity" to words and call any yellow smiley "Verity" | ThatMob's series (30M+ views) plus Horror Skunx's song (33M+ views), Anne Hathaway film promo tie-in, HuffPost and Forbes coverage, Steal A Verity games [S21][S22][S23] |
| 2 | **67 / 6-7** | Very widely known: most-searched Gen Alpha term Jan–Aug 2026 and Dictionary.com 2025 Word of the Year. Now used more ironically and is fading with teens, but still big with younger kids. Roblox itself sold "67" avatar items for 6/7 day (Jun 2026) | [S20][S61][S62] |
| 3 | **Italian brainrot core roster:** Tralalero Tralala, Tung Tung Tung Sahur, Bombardiro Crocodilo | Recognised by most kids but now "legacy". Commercialised (Fortnite skins Apr 2026, Panini cards) | [S16][S63] |
| 4 | Lirilì Larilà, Brr Brr Patapim, Ballerina Cappuccina, Chimpanzini Bananini, Strawberry Elephant, La Vacca Saturno Saturnita | Second tier, used as rare or secret units in the big games | [S63][S64] |
| 5 | Pets and eggs (not a meme but the current dominant theme) | Steal An Egg and its spin-offs lead the charts | [S10][S12] |

*Exact ranking is approximate. We had no direct Google Trends or TikTok data access, so the ranking is based on press coverage, search-term reports and Roblox game titles.*

### 2.2 What "Verity" is
- **Verity** is a cheerful yellow smiley-faced sphere: an AI assistant mod that turns evil in ThatMob's Minecraft found-footage horror web series (30 May–8 Jul 2026). ThatMob is a Canadian YouTuber [S22].
- It spread through Horror Skunx's July 2026 song "It's Me, It's Verity" and its endless remixes. ThatMob officially supports three Minecraft mods based on the character, which means **he actively manages the character as his IP** [S22][S21].

### 2.3 IP and legal status

| Character / name | Copyright | Trademark | Disputes / takedowns |
|---|---|---|---|
| Tung Tung Tung Sahur | Created with DALL-E by "Noxa". Likely **not copyrightable** in the US as AI output [S15] | Filings by Innovatex Labs (May 2025), Mementum Lab (Jun 2025), and a German individual (Ruben Hornung) [S18] | Mementum sent a cease-and-desist to Steal a Brainrot (Sep 2025). The character was removed, then **restored 29 Nov 2025**, and Spyder Games sued for a declaration that its use is lawful. Mementum counterclaimed for trademark infringement (Apr 2026). **7-day jury trial set for 8 Nov 2027** [S2][S15][S17] |
| Tralalero Tralala | Origin is AI and remix-based | Officina Comunicazione S.R.L. filed in several countries (late 2025). Innovatex also filed [S18] | — |
| Wider brainrot roster | — | **Mementum Lab: French trademark extended via the Madrid system, classes 9/16/25/28/35/41/42 (covering video games)**. Mementum says it holds rights from creators "Noxa" and "Breno" and has licensed titles including Plants vs Brainrots and Brainrot Fight **(the Plants vs Brainrots licence is reported by one source only)** [S16] | Steal a Brainrot also sued a Fortnite copy, "Stealing Brainrots", over UI, art and level design [S65] |
| 67 / 6-7 | It's a number and phrase. The song "Doot Doot (6 7)" by Skrilla is copyrighted | **No trademark filing found** (searched, unverified) [S61] | None found. Roblox itself sells 67 items [S62] |
| Verity | **Human-made original character** with clear copyright (ThatMob) | Not checked / none found | ThatMob licenses official mods. Could file Rights Manager claims on Roblox [S22][S66] |

**What the big games do:** Steal a Brainrot, Plants vs Brainrots and Escape Tsunami **use the meme characters and names directly**, recreated as voxel models. Big studios have the money for lawyers or licence deals (Plants vs Brainrots reportedly licensed through Mementum) [S2][S16].

**Practical risk for a two-person team:**
- Roblox's **Rights Manager** lets any rights holder request removal of a game or asset, and Roblox removes it when the request is approved [S66].
- A name in the game title or a character in the thumbnail is the most visible target.
- Legal fights here are slow and expensive; Steal a Brainrot's case won't reach trial until 2027 [S17].
- **Recommendation:**
  - (a) Design **original "brainrot-style" characters** with parody or pun names, e.g. a sneaker-shark hybrid with its own name.
  - (b) Don't put trademarked names (Tralalero Tralala, Tung Tung Tung Sahur) in the title, icon or thumbnails.
  - (c) The **number "67" is low risk** to use as a design motif (a blocky 67 monster). Avoid Skrilla's audio and the likeness of the real "67 kid".
  - (d) **Don't copy Verity's design.** Use a generic "creepy smiley" homage at most.
  - (e) Write our own audio rather than using meme sound clips. *This is not legal advice.*

---

## 3. Monetization

### 3.1 What top games sell (Robux)

| Item type | Examples and prices | Source |
|---|---|---|
| Income multiplier pass | Steal a Brainrot 2x Money **299**; Grow a BRAINROT! 2x Money (199–449 range) | [S30][S13] |
| VIP pass | Steal a Brainrot VIP **375** (0.5x extra money, +10s base lock); Plants vs Brainrots VIP **249** (+25% income) | [S30][S31] |
| Season / battle pass | Grow a Garden premium **749**; Plants vs Brainrots **299** | [S29][S31] |
| Restock / skip timer | Grow a Garden instant restock **~39** | [S29] |
| Seed packs / random eggs | Grow a Garden Prime Seed Pack **199**, Night Seed Pack x10 **1,699**; Plants vs Brainrots Meme Lucky Egg **299** / 3 for **699** / 10 for **1,999** | [S29][S31][S67] |
| Lucky blocks (random) | Steal a Brainrot Mythic **149**, God **799**, Secret **2,999** (may be 2025 prices) | [S32] |
| Luck boosts | Plants vs Brainrots Lucky Potion **179**; Steal a Brainrot 2x server luck **249** / 4x **999** for 15 minutes | [S31][S32] |
| Growth accelerators | Grow a Garden Grow All **375**, fertilizer **129**, level-up lollipop **79** | [S29] |
| Robux-exclusive premium unit | Grow a Garden Dragon's Breath seed **~1,499** | [S29] |
| Admin / flex | Steal a Brainrot Admin Commands **7,999** | [S30] |
| Cosmetic-first model | 99 Nights: main Decorator pass **199**, otherwise mostly cosmetic | [S45] |
| Private servers | Common. 99 Nights on a GARDEN offers them free | [S48] |

### 3.2 Revenue split and earnings
- **DevEx: $0.0038 per earned Robux** (raised from $0.0035 on 5 Sep 2025). Since 8 Jun 2026, **$0.0054** applies to qualifying spend by verified US players aged 18+. Minimum cash-out is 30,000 R$ (about $114) [S33][S68].
- Developers typically keep about **70%** of Robux spent on passes and products; trackers use this figure in their models [S3].
- Distribution (12 months to 30 Jun 2026, RDC 2026 figures):
  - Top 10 creators: **$65.7M** average
  - Top 100: **$10.8M**
  - Top 1,000: **$1.4M**
  - **Median DevEx participant: about $1,500 a year**
  - 42K+ creators cash out [S34]
- **Realistic ranges** (inference from the above): most small games earn under a few hundred dollars a month. A modest hit with about 1–5K steady CCU might earn low-to-mid thousands of dollars a month **(low confidence)**. Breakouts earn millions (Grow a Garden ≥$148M profit in 8 months) [S43].

### 3.3 Policy rules we must comply with

| Area | Requirement | Source |
|---|---|---|
| **Paid random items** (eggs, random seed packs, lucky blocks, random mutations bought with Robux, **luck potions**, pity systems; includes buying with in-game currency that was bought with Robux) | Show **every outcome with numerical % odds before purchase**, summing to 100%. Odds must be reachable through a labelled "Info/Details" button; a bare "(i)" is not enough. **Odds must update live while a luck boost is active.** No outcome can be worth nothing | [S24][S25] |
| Region and age gating | Call `PolicyService:GetPolicyInfoForPlayerAsync()`. If `ArePaidRandomItemsRestricted` is true, hide or block the purchase or offer a non-random alternative. **Don't hard-code country lists**; Roblox maintains them (currently includes BE, NL, UK, AU, BR) | [S24][S25] |
| Trading | If `IsPaidItemTradingAllowed` is false, the player can't trade anything bought with Robux or with Robux-funded currency (Korea and others) | [S24][S69] |
| Enforcement | Violations can lead to **game removal and account suspension** | [S25] |
| **Maturity questionnaire** | Required. Unrated games are **not playable by anyone**. Kids (under 9) only see Minimal/Mild; Select (9–15) sees Moderate and below | [S26][S27] |
| **Kids & Select publishing** (2026) | ID check (face age-estimation if under 18, government ID if 18+), **2FA**, Plus/Premium for 2+ months **or** a one-time refundable fee (reported as 1,000 R$). A **trial phase with age-checked 16+ users only** until **250 unique plays by highly engaged age-checked users within 60 days**, followed by a safety review | [S27][S28] |
| Ads and young users | Roblox blocks ads, sponsored experiences and sponsored items for under-13s. Ads Manager **can't target under 13** | [S41][S42] |
| Manipulative design | In May 2026, Fairplay and NCOSE filed an **FTC complaint** about Roblox's manipulative monetization. Research found deceptive purchase flows in most Roblox games. Expect tighter enforcement: avoid fake timers, surprise prompts and confusing currencies | [S40][S70] |
| Real-money trading | Off-platform sales of items (eBay, Discord) break the Terms of Service. Grow a Garden had this problem [S1] | [S1] |

---

## 4. Discovery and marketing

### 4.1 How Roblox ranks games (official, 2026)
- **Main RFY signals in priority order:**
  1. Play-through rate (first session)
  2. First-play bounce rate
  3. **Play days per user** (Days 2–7, 8–28)
  4. Playtime per user [S35]
- **Secondary signals:** intentional co-play days, qualified play sessions, spend days, Robux spent [S35][S36].
- Since **15 Jun 2026**, signals are measured over **28 days** in three buckets (D1, D2–7, D8–28) [S36]. Metrics are **per-user averages**, so small games aren't penalised for size [S35].
- New games are judged in stages: first PTR and bounce, then D1, then D2–7, then D8–28 [S35].
- **Paid ads don't feed RFY signals.** Track organic traffic under Analytics > Acquisition > Home Recommendations [S36].
- Misleading or mismatched metadata and look-alike presentation reduce visibility. Roblox explicitly targeted "flashy thumbnail, bores you in 10 minutes" games [S35][S37].
- Reported (secondary source): recommendation credit is capped at the first **60 minutes per user per day** **(unverified)**, so return frequency matters more than long sessions [S38].

### 4.2 Thumbnails and icons that perform
Data from a study of 905 chart thumbnails (6 Nov 2026) [S39]:
- **72% show a character or creature; 46% show an expressive face** (shock, joy, anger, smugness), rising to 60% in Up-and-Coming games.
- **66% are polished 3D renders, rising to 83% among 2026's new hits.** Default avatars appear in 25% (34% in Up-and-Coming).
- **57% have no text other than the logo**; 29% use 1–3 words; only 14% use 4 or more.
- 75% are "quite colourful" or more. **Blue and orange are the main colours in 60%.** Survival thumbnails are darker (27% brightness) than obby thumbnails (57%).
- 36% use marks: glowing prizes 17%, arrows 9%, first-person hands 8%.
- **88% of chart games run 2+ thumbnails, and 50% run 5+.**

Brainrot-specific style: huge saturated characters, red arrows, glowing eyes, shocked faces, busy layouts [S71]. The dev's **DAY/NIGHT split** fits the data well: a bright, warm day half against a dark half with a giant looming character gives contrast and a clear threat-and-promise story. Make sure the first session actually delivers that night threat, because a bounce now costs ranking [S36].

### 4.3 Short-form video, YouTubers, cadence, ads
- **TikTok and YouTube Shorts are the main way new players find games** in 2026. A viral clip can spike traffic within about 48 hours (agency source, low confidence) [S72].
- **Developers promoting their own events works:** Jandel and SpyderSammy hyped admin-abuse events on TikTok, X and Discord. These pushed both games to about 15M CCU each, and the combined Aug 2025 event hit 47.4M across the platform [S2][S52].
- **Cadence:** Grow a Garden's same-day weekly update (Saturday) became the genre benchmark. Steal a Brainrot timed its admin abuse about 1 hour before each weekly update [S51][S52].
- **YouTubers:** KreekCraft funded a brainrot game ("Sail a Brainrot") with about $100K. Creator-backed games are now common competition [S73].
- **Roblox Ads:**
  - 1 ad credit = 285 R$; minimum bid 0.01 credit per play.
  - No targeting of under-13s.
  - Reported small-game costs of roughly $0.01–0.50 per visit or click (agency estimates, low confidence) [S42][S74].
  - Best use: getting the first highly engaged **16+** players during the Kids/Select trial phase.

---

## 5. Design recommendations

### 5.1 Launch version (first playable release): 14 features

| # | Feature | Why |
|---|---|---|
| 1 | **Seed → brainrot grow loop** with a visible growth % bar and harvest/sell | The proven Grow a Garden core; easy to understand in seconds [S1] |
| 2 | **Offline growth** | Brings players back on later days, which counts for play days in RFY [S1][S35] |
| 3 | **Timed seed shop restock** with a countdown | Gives a "come back in 5 minutes" urgency loop [S29] |
| 4 | **Rarity tiers** (Common → Secret) with original parody characters | Collection drive without IP risk [S15][S16] |
| 5 | **Grown brainrots earn passive cash** in your garden | The tycoon payoff all the top games share [S2][S44] |
| 6 | **Day/night cycle with a night threat** (giant blocky "67"-style monster raids gardens; your grown brainrots defend) | Our unclaimed twist; matches the day/night horror trend [S12] |
| 7 | **Short nights (about 2–3 minutes) within short cycles** | Gives a clear moment to come back for and keeps first-session play-through high [S35] |
| 8 | **Mutations** (Gold, Rainbow, plus a night-only "Moonlit" mutation) | Proven value multiplier and source of excitement [S44] |
| 9 | **Weather events** that cause mutations | Server-wide hype moments [S44] |
| 10 | **Rebirth** with a permanent multiplier | Long-term progression for Days 8–28 retention [S44] |
| 11 | **Server-wide announcements** of rare drops and mutations | Social proof and dopamine; good clip material |
| 12 | **Basic monetization:** 2x Cash (~299), VIP (~249), instant restock (~39), starter pack. **All Robux random items with an odds UI plus PolicyService gating from day one** | Matches genre prices; required for compliance [S24][S30][S31] |
| 13 | **Co-op night defense bonus** (friends' brainrots help) | Intentional co-play days is an RFY signal [S35] |
| 14 | **Polished first 60 seconds:** tutorial arrow, first brainrot within about 30 seconds, first night within about 3 minutes | Play-through and bounce rate are the top-ranked signals [S35] |

### 5.2 First updates: 8 features

| # | Feature | Why |
|---|---|---|
| 1 | **Weekly update on the same day, with a countdown timer in the lobby** | Grow a Garden's benchmark for keeping players [S51] |
| 2 | **Admin-abuse live events** right before updates | Proven CCU spikes and TikTok material [S52] |
| 3 | **Fusion / combine** two brainrots into a hybrid | Collection depth; deterministic recipes avoid random-item rules |
| 4 | **New night bosses each update** (rotating trend monsters, e.g. a "creepy smiley" homage) | Keeps up with memes without copying them |
| 5 | **Season pass** (~299 R$) | Proven, compliant revenue [S31] |
| 6 | **Trading** (gated by `IsPaidItemTradingAllowed`) | Social and economy depth, as with Steal a Brainrot's trade machine [S53][S24] |
| 7 | **Light garden raiding during the night** (opt-in, with protection) | Adds Steal a Brainrot-style tension without making it the main hook |
| 8 | **Codes and limited-time event seeds** (holidays) | Sources of return visits and video content |

### 5.3 Don'ts
- **Don't use trademarked meme names or Verity's design** in the title, icon or thumbnails. This invites Rights Manager takedowns [S16][S22][S66].
- **Don't sell random items without numerical odds and PolicyService gating**, and don't hide luck-boost effects. Penalties include removal and suspension [S25].
- **Don't make clickbait thumbnails the game doesn't deliver.** Bounces now cost ranking [S36][S37].
- **Don't copy another game's layout exactly.** Look-alike presentation is demoted, and Steal a Brainrot has sued a copy [S35][S65].
- **Don't use manipulative prompts:** popups every few minutes, fake scarcity, misleading currency bundles. Regulators are watching [S40][S70].
- **Don't go pay-to-win or recycle events.** These are the cited reasons Grow a Garden and Grow a Garden 2 lost players [S54][S55].
- **Don't break the weekly update promise** or let exploits wreck the economy. Grow a Garden's "legitimacy collapse" is the warning [S56].
- **Don't skip the maturity questionnaire or the Kids/Select requirements.** Unrated games aren't playable, and without eligibility kids can't find the game [S26][S27].
- **Don't make the night scary enough to push the rating to Moderate+** if we want the under-9 audience. Keep the threat at "mild fear" [S26].
- **Don't count on ads to reach kids.** Under-13 targeting isn't allowed [S42].

---

## Sources

- [S1] Grow a Garden — Wikipedia: https://en.wikipedia.org/wiki/Grow_a_Garden
- [S2] Steal a Brainrot — Wikipedia: https://en.wikipedia.org/wiki/Steal_a_Brainrot
- [S3] profitable.app, Grow a Garden (Nov 2026): https://profitable.app/roblox/games/grow-a-garden
- [S4] profitable.app / bloxprices, Steal a Brainrot: https://profitable.app/roblox/games/steal-a-brainrot ; https://www.bloxprices.com/stats/steal-a-brainrot/
- [S5] BloxBunny, Steal a Brainrot: https://bloxbunny.com/games/7709344486/steal-a-brainrot
- [S6] Roblox Wiki, Plants & Brainrots: https://roblox.fandom.com/wiki/Yo_Gurt_Studio/Plants_Vs_Brainrots
- [S7] BloxBunny, Plants & Brainrots: https://bloxbunny.com/games/8316902627/plants-brainrots
- [S8] Rolimons, Plants & Brainrots: https://www.rolimons.com/game/127742093697776
- [S9] Roblox Wiki / GGAID, 99 Nights in the Forest: https://roblox.fandom.com/wiki/Grandma's_Favourite_Games/99_Nights_in_the_Forest ; https://www.ggaid.com/roblox/games/99-nights-in-the-forest-7326934954
- [S10] RivalDucks, Steal An Egg: https://rivalducks.com/apps/radar/games/10563114921-steal-an-egg
- [S11] Endgame Tools top 50 (16 Nov 2026): https://endgametools.com/en/roblox/charts
- [S12] GGRecon, fastest-growing new Roblox games Nov 2026: https://www.ggrecon.com/articles/fastest-growing-new-roblox-games-november-2026/
- [S13] Rolimons, [👶] Grow a BRAINROT!: https://www.rolimons.com/game/95100120849093
- [S14] Rolimons, Grow a Brainrot [Blood Moon]: https://www.rolimons.com/game/78093976388531
- [S15] Tung Tung Tung Sahur — Wikipedia: https://en.wikipedia.org/wiki/Tung_Tung_Tung_Sahur
- [S16] IPKat, "The law (or lore) of brainrot characters" (Nov 2026): https://ipkitten.blogspot.com/2026/11/the-law-or-lore-of-infamous-generative.html
- [S17] Plagiarism Today (Oct 2026): https://www.plagiarismtoday.com/2026/10/07/who-owns-this-brainrot-character/ ; Unilad Tech: https://www.uniladtech.com/news/ai/steal-a-brainrot-lawsuit-ai-generated-roblox-242885-20260630
- [S18] The Mary Sue / Ponsip, trademark filings: https://www.themarysue.com/someone-else-is-trying-to-trademark-tung-tung-tung-sahur-and-the-viral-memes-ownership-fight-is-getting-messier/ ; https://ponsip.com/en/ip-news/colombia-news/italian-brainrot-as-a-distinctive-sign-can-it-be-registered-as-a-trademark/
- [S19] RoWatcher, "Is the brainrot trend dying?": https://rowatcher.com/news/is-the-brainrot-trend-dying-what-ccu-data-from-three-top-games-reveals
- [S20] GenPPT, Gen Alpha slang 2026 (citing Euronews, Sep 2026): https://genppt.com/blog/gen-alpha-slang
- [S21] HuffPost UK, Verity meme explained (23 Sep 2026): https://www.huffingtonpost.co.uk/entry/verity-meme-explained_uk_6ab2995be4b085277b5396cb
- [S22] Verity (web series) — Wikipedia: https://en.wikipedia.org/wiki/Verity_(web_series) ; Forbes: https://www.forbes.com/sites/danidiplacido/2026/09/27/tiktoks-its-me-its-verity-meme-explained/
- [S23] Steal A Verity stats: https://www.rolimons.com/game/107164765081465 ; https://rivalducks.com/apps/radar/games/10550257968-steal-a-verity
- [S24] Roblox Creator Docs, Paid random items: https://create.roblox.com/docs/production/monetization/paid-random-items
- [S25] ZehnStudio, PRI odds disclosure (26 May 2026): https://zehn-studio26.com/news/paid-random-items-odds-disclosure/ ; DevForum: https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622
- [S26] Roblox Creator Docs, Content maturity: https://create.roblox.com/docs/en-us/production/promotion/content-maturity.md
- [S27] Roblox Creator Docs, Roblox Kids and Select: https://create.roblox.com/docs/production/publishing/kids-and-select
- [S28] BloxBot, 2026 publishing requirements: https://bloxbot.ai/guide/roblox-new-publishing-requirements-2026 ; DevForum: https://devforum.roblox.com/t/alternate-publishing-requirements-for-roblox-kids-and-select/4630944
- [S29] Grow a Garden Robux items (Sportskeeda / AllThings.How / rblxguide): https://www.sportskeeda.com/roblox-news/grow-garden-season-1-pass-all-tier-rewards-premium-price ; https://allthings.how/grow-a-gardens-prime-seed-pack-all-seeds-and-how-to-get-it ; https://rblxguide.com/games/grow-a-garden/crops/robux-price
- [S30] Buffget, Steal a Brainrot gamepass prices (Nov 2026): https://buffget.com/news/steal-a-brainrot-game-pass-prices-robux-2026
- [S31] Beebom / Deltia's, Plants vs Brainrots season pass and VIP: https://beebom.com/plants-vs-brainrots-season-pass-guide ; https://deltiasgaming.com/?p=392035
- [S32] Sportskeeda, Steal a Brainrot lucky blocks: https://www.sportskeeda.com/roblox-news/steal-brainrot-lucky-blocks-all-lucky-blocks-price-list
- [S33] Roblox Newsroom, DevEx increase (Apr 2026): https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42
- [S34] Dexerto, RDC 2026 earnings distribution: https://www.dexerto.com/roblox/robloxs-top-creators-average-65-7-million-a-year-but-most-make-far-less-3408675/
- [S35] Roblox Creator Docs, Discovery FAQ: https://create.roblox.com/docs/discovery-faq
- [S36] ZehnStudio, RFY 28-day retention (15 Jun 2026): https://zehn-studio26.com/news/recommended-for-you-retention-update/
- [S37] Endsights, Roblox algorithm vs clickbait: https://endsights.com/roblox-optimizing-discovery-how-great-games-reach-millions-of-players-on-roblox
- [S38] AllThings.How, RFY algorithm: https://allthings.how/robloxs-new-recommended-for-you-algorithm-rewards-games-that-keep-you-hooked/
- [S39] ClipClip, 905-thumbnail study (6 Nov 2026): https://clipclip.io/guides/roblox-thumbnail-ctr
- [S40] Univ. of Sydney, Misleading and Deceptive Monetisation in Roblox: https://ses.library.usyd.edu.au/bitstream/handle/2123/35033/Misleading%20and%20Deceptive%20Monetisation%20in%20Roblox%20-%20Final.pdf
- [S41] IEEE ConPro'25, Roblox monetization ecosystem: https://conpro25.ieee-security.org/papers/eiger-conpro25.pdf
- [S42] BloxG, Roblox ads guide 2026: https://bloxg.com/guides/roblox-ads-guide ; Roblox Advertising Terms: https://en.help.roblox.com/hc/en-us/articles/15494846263060-Roblox-Advertising-Terms
- [S43] Tubefilter (citing Bloomberg): https://www.tubefilter.com/2026/03/09/kreekcraft-has-spent-over-100000-making-a-roblox-game-whats-the-roi-for-developers/
- [S44] Games.gg / Sportskeeda, Plants vs Brainrots overview and studio: https://games.gg/news/plants-vs-brainrots-roblox-viral-hit/ ; https://www.sportskeeda.com/roblox-news/who-made-plants-vs-brainrots ; https://beebom.com/plants-vs-brainrots-mutation-guide
- [S45] profitable.app, 99 Nights in the Forest: https://profitable.app/roblox/games/99-nights-in-the-forest
- [S46] profitable.app, Grow a Garden 2: https://profitable.app/roblox/games/grow-a-garden-2
- [S47] Rolimons, Plant Brainrot Simulator: https://www.rolimons.com/game/92814019058536
- [S48] Rolimons / Roblox, 99 Nights on a GARDEN: https://www.rolimons.com/game/126215798502579
- [S49] GGRecon, Roblox DAU fall Q3 2026: https://www.ggrecon.com/articles/roblox-daily-players-fall-q3-2026/
- [S50] MMOExp, MM2 bot purge Aug 2026: https://www.mmoexp.com/News/murder-mystery-2-2026-player-count-drop-is-mm2-actually-dying-after-bot-purge.html
- [S51] InGameNews, Grow a Garden weekly updates: https://ingamenews.com/2025/10/grow-garden-weekly-updates-whats-next.html
- [S52] Tubefilter, admin-abuse war: https://www.tubefilter.com/?p=188004 ; https://findingdulcinea.com/steal-a-brainrot-admin-abuse-schedule/
- [S53] Sportskeeda, Steal a Brainrot Trade Machine update: https://www.sportskeeda.com/roblox-news/news-steal-brainrot-trade-machine-update-patch-notes
- [S54] MMOExp, Grow a Garden 2 losing players (Aug 2026): https://www.mmoexp.com/News/grow-a-garden-2-is-losing-players-what-really-happened-to-the-roblox-hit.html
- [S55] ROLearn, Grow a Garden case study: https://rolearn.dev/case-studies/idle-garden-zero-to-20m-ccu/
- [S56] SSEGold, Is Grow a Garden dying?: https://www.ssegold.com/is-grow-a-garden-dying
- [S57] RoWatcher, number of games on Roblox 2026: https://rowatcher.com/news/how-many-games-are-on-roblox-in-2026
- [S58] Roblox, Grow a Brainrot listings: https://www.roblox.com/games/91765504095391/Grow-A-Brainrot ; https://www.roblox.com/games/98920421455863/Grow-a-Brainrot
- [S59] Roblox, Nights in the GARDEN: https://www.roblox.com/games/83910851545777/Nights-in-the-GARDEN
- [S60] Roblox, GROW A 67: https://www.roblox.com/games/108139974584424/GROW-A-67
- [S61] 6-7 meme — Wikipedia: https://en.wikipedia.org/wiki/6-7_meme
- [S62] X trending, Roblox 67 items: https://x.com/i/trending/2063364032502071421
- [S63] Italian brainrot — Wikipedia: https://en.wikipedia.org/wiki/Italian_brainrot
- [S64] Revid / BrainrotHub character lists: https://www.revid.ai/blog/italian-brainrot-names ; https://brainrothub.com/blog/all-brainrot-names-complete-list-2026
- [S65] PC Gamer, Steal a Brainrot sues Fortnite copy: https://www.pcgamer.com/games/a-brainrot-themed-roblox-game-is-taking-a-brainrot-themed-fortnite-game-to-court-for-being-a-copy/
- [S66] Roblox Creator Docs, Rights Manager: https://create.roblox.com/docs/production/publishing/rights-manager
- [S67] Sportskeeda, Grow a Garden Night Seed Pack: https://www.sportskeeda.com/roblox-news/grow-garden-night-seed-pack-all-seeds
- [S68] DevEx.gg rates 2026: https://devex.gg/devex-rates
- [S69] DevForum, IsPaidItemTradingAllowed: https://devforum.roblox.com/t/seeking-clarifications-for-ispaiditemtradingallowed/3623462
- [S70] Fortune, FTC complaint (20 May 2026): https://fortune.com/2026/05/20/exclusive-advocacy-groups-file-complaint-roblox-manipulative-design/
- [S71] Thumbs.ai, Steal a Brainrot thumbnail style: https://www.thumbs.ai/steal-a-brainrot-thumbnail-maker
- [S72] BloxG, growing a Roblox game 2026: https://bloxg.com/grow-roblox-game
- [S73] Tubefilter, KreekCraft ROI: https://www.tubefilter.com/2026/03/09/kreekcraft-has-spent-over-100000-making-a-roblox-game-whats-the-roi-for-developers/
- [S74] MetaClip, Roblox ad costs 2026: https://metaclip.app/guides/roblox-game-marketing-cost
