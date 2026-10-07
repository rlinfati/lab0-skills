# lab0-skills

Agent skills for operations research and optimization, for [Claude Code](https://claude.com/claude-code) and other agents that read the `SKILL.md` format. They turn a paper or the name of a classic problem into a traceable specification, instances and code.

## Pipeline

```
problem name ─► problem-literature ─► sources.md ─┐
                                                  ├─► paper-to-modelspec ─► modelspec ─► modelspec-to-code ─► gurobipy / JuMP
paper (PDF) ──────────────────────────────────────┤                              │
                                                  └─► paper-to-mhspec ───► mhspec ─► mhspec-to-code ─► Julia heuristics
                                                                                 │
                                                             model-instances ◄───┘   (instances, reference values, catalog)
```

Each stage writes a file to disk (never only a chat message), and the next stage reads it. Traceability runs through the whole chain: constraint and part names in the code come from the paper's equation, step and line numbers.

## Skills

Grouped by area under `skills/<group>/<skill>`; the installer flattens them, so each skill is installed under its own name.

| Group           | Skill                | What it does                                                                                                                              |
| --------------- | -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| orshared        | `problem-literature` | Finds and verifies the original paper, canonical reference, famous reformulations and benchmarks of a classic problem or method.          |
| orshared        | `model-instances`    | Finds literature instances with reference values, or generates random ones with a seed; writes a catalog.                                 |
| mathprogramming | `paper-to-modelspec` | Paper to a Markdown model specification (`.modelspec.md`) with equation numbers, errata and variants.                                     |
| mathprogramming | `modelspec-to-code`  | Modelspec to solver code: gurobipy or JuMP, as a teaching notebook or a research package.                                                 |
| metaheuristics  | `paper-to-mhspec`    | Paper to a metaheuristic specification (`.mhspec.md`): family, algorithm, parts, parameters, pseudocode.                                  |
| metaheuristics  | `mhspec-to-code`     | Mhspec to Julia heuristics (neighborhood, evolutionary, swarm) on a tested reference implementation, with TSP, CVRP and VRPTW extensions. |
| documents       | `pdf-to-markdown`    | Converts PDFs, including scanned ones, to clean Markdown.                                                                                 |

Where a new skill goes:

- specific to one area: in that area's group (`mathprogramming`, `metaheuristics`);
- shared by several areas of operations research, such as literature or instances: in `orshared`;
- not about optimization: in `documents`, or a new group.

The skills are kept out of git (`skills/` is in `.gitignore`) until they are ready to be published; this table lists them for reference.

## Install

```sh
./lab0-skills.sh
```

Links every folder that has a `SKILL.md` (at any depth under `skills/`) into `~/.claude/skills` and `~/.agents/skills`, and removes the links of skills that no longer exist in the repo.

It also links the optional launchers `claude.sh` and `chatgpt.sh` (macOS desktop-bundled CLIs):

- `BIN_DIR=/some/dir ./lab0-skills.sh` uses that directory, and warns if it is not in `$PATH`.
- Without `BIN_DIR`, the first directory of `BIN_DIR_DEFAULTS` (list at the top of the script) that is **already in `$PATH`** is used.
- If none is in `$PATH`, the launchers are skipped.
- The script never modifies `$PATH`.

## Defaults and customization

The conventions in each skill's `references/` (naming, layout, solver, parameters, result files) are defaults. Tell the agent what you want instead and it follows you; to change the defaults for good, edit the reference files.

## Requirements

- The skills need an agent with file tools and web search (the literature and instance skills use the web).
- `skills/metaheuristics/mhspec-to-code/assets/mh` is a Julia package with its own tests: `julia --project=. -e 'using Pkg; Pkg.test()'` (the CI workflow is also kept out of git for now).
- Gurobi is the default solver in `modelspec-to-code`. No credentials are stored: Gurobi finds a license file in `GRB_LICENSE_FILE`, `/opt/gurobi/gurobi.lic`, `/Library/gurobi/gurobi.lic` or `~/gurobi.lic`; otherwise put your WLS values in your own copy (or in the environment variables the research code reads). Never commit real values.

## Adding a skill

Create `skills/<group>/<skill>/SKILL.md` with `name` (equal to the folder name) and `description` frontmatter, then run `./lab0-skills.sh` again. A new group is just a new folder under `skills/`.

```
skills/<group>/my-skill/
├── SKILL.md
└── references/      optional, loaded on demand
```

## Git maintenance

```sh
# Reset history to a single initial commit
git update-ref -d HEAD && git commit -a -m "Initial commit" && git push -f

# Quick commit and push
git commit -a -m commit-$(date +'%Y-%m-%d-%H-%M-%S') && git push

# Clean up and verify the repository
git gc --prune=now && git fsck
```

## License

See [LICENSE](LICENSE).
