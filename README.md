# Roblox Game Hub

Two devs, two Claudes, many games. One repo.

## One-time setup (each person)

1. **Install the tools**
   - [Git](https://git-scm.com/downloads) and a GitHub account
   - [GitHub CLI](https://cli.github.com/), then run `gh auth login`
   - [Claude Code](https://claude.com/claude-code) (desktop app or CLI)
   - [Rokit](https://github.com/rojo-rbx/rokit) (installs Rojo for you)
   - Roblox Studio + the **Rojo** plugin (by Rojo Foundation) from the Creator Store
2. **Get the repo**
   - The owner invites the other person: GitHub repo → Settings → Collaborators → Add people.
   - Clone it: `gh repo clone <owner>/<repo-name>`, then `cd` into it.
3. **Install the pinned tools**: `rokit install`
4. **Open the folder in Claude Code.** Claude reads `CLAUDE.md` automatically.

## Daily workflow

1. Get the latest code: `git checkout main` then `git pull`
2. Make a branch for what you're doing: `git checkout -b yourname/feature-name`
3. Start syncing the game you're working on into Studio:
   `rojo serve games/<game-name>/default.project.json`
   then in Studio click **Plugins → Rojo → Connect**.
4. Vibe code with Claude. Test in Studio.
5. When the feature works, ask Claude to commit, push and open a pull request.
6. The other person reviews the pull request (their Claude can review it too) and merges it.

Tip: just tell Claude what you want ("start my day on grow-a-brainrot", "open a PR for this") and it will run the git commands for you.

## Starting a new game

Tell Claude "make a new game called X from the template". It will copy `templates/game-template` to `games/x`, rename it, and create a `GAME.md`. Or do it by hand: copy the folder, then change `"name"` in `default.project.json`.

## Splitting work

Split by **feature**, not by file. Write who owns what in each game's `GAME.md`. Two people editing the same file at the same time causes merge conflicts.

For building the 3D world together live, use **Team Create** in Studio (File → Collaborate). Scripts stay in git, the world lives in Team Create.

## Games

| Game | Folder | Status |
|---|---|---|
| Grow a Brainrot (working title) | `games/grow-a-brainrot` | Designed, building M1 next |
