# Setup prompt for a new collaborator's Claude

Send this whole file to your friend. They paste everything below the line into Claude Code (desktop app → Code tab, or the `claude` CLI), after replacing https://github.com/WilliamG2007/roblox-hub with the GitHub link.

---

Hey Claude! My friend and I are making Roblox games together, each with our own Claude Code. I'm brand new to this setup, so please be my guide: walk me through everything **one step at a time**, explain each thing in plain words (what it is and why we need it), run the commands for me whenever you can, and check each step worked before moving on. Keep it fun and casual. If something fails, figure out why and fix it with me instead of just giving up.

**Our setup:**
- One shared GitHub repo, a "hub" with one folder per game: https://github.com/WilliamG2007/roblox-hub
- Games are Luau code synced into Roblox Studio with **Rojo**; tool versions are pinned in `rokit.toml`.
- Once the repo is cloned, read `CLAUDE.md` and `README.md` there. They hold our rules (branches, pull requests, who owns what, code conventions). Follow them from then on.

**Please guide me through:**
1. Check my OS and what's already installed (git, gh, rokit, rojo). Only install what's missing, using the official installers or package managers (winget on Windows, Homebrew on Mac), and tell me before installing anything.
2. Log me into GitHub with `gh auth login`. I'll handle the login myself in the browser; just tell me what to pick. Check I've accepted the collaborator invite to the repo.
3. Clone the repo into a sensible folder, `cd` into it, and run `rokit install`.
4. Have me install Roblox Studio (if needed) and the **Rojo** plugin by *Rojo Foundation* from the Creator Store. Then start `rojo serve` for one of the games (see `README.md`) and have me click **Plugins → Rojo → Connect** in Studio. Confirm the scripts appear in Studio's Explorer.
5. Optional but great: set up the **Roblox Studio MCP** so you can control Studio directly (build things, playtest, read the Output window). The repo has a `.mcp.json` for Windows. If I'm on Mac, figure out the right equivalent. Make sure the MCP option is turned on in Studio's Assistant settings, then check that you can see my open Studio.
6. Do a tiny test together: make a branch called `<myname>/hello`, add a small harmless change, commit it, push it, and open a pull request, so I've seen the whole workflow once. Explain each git step simply. Then help me close or merge it as my friend prefers.
7. Finish with a short cheat sheet of the 5 or so things I'll do every day (pull main, branch, rojo serve, test, open PR).

After setup, keep acting like my guide: before big changes tell me the plan in a couple of lines, never push straight to `main`, and check the game's `GAME.md` for who owns which feature before editing anything. Let's go!
