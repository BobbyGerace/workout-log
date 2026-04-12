# Workout Log

This is Bobby's personal workout log. Workouts are written in a custom DSL
(`.gym` files) and managed with a CLI tool called
[gym](https://github.com/bobbygerace/gym). The main work here is writing Ruby
scripts (`programs/`) that generate `.gym` files for structured training programs.

## .gym File Syntax

### Frontmatter

YAML-like block at the top of the file, delimited by `---`:

```
---
name: Squat
date: Monday, April 7, 2026
program: Olympus
week: 1
training-max: 225
deload: false
---
```

Only `name` is required. Other keys are optional metadata. Order is preserved and
meaningful — keep it consistent across programs.

### Exercises

`#` starts a primary exercise block:

```
# Front Squat
225x5,5,5
```

`&` starts a superset exercise (paired with the preceding `#` block):

```
# Incline Curl
3x10-20

& Lateral Raise
3x10-20
```

### Sets and Reps

Weight and reps are written as `weightxreps`. Multiple sets at the same weight
use comma-separated rep counts:

```
225x5,5,5       # 3 sets of 5 at 225
225x8,6,5       # sets where reps varied
BWx15,15,15     # bodyweight
```

A `+` suffix means AMRAP on that set:

```
225x5+
```

RPE can be appended with `@`:

```
205x7 @8.5
```

### Comments and Template Hints

`//` is a comment or prescription (used in templates and program generators):

```
// 3x8-12
// Work up to a top single
// ?x5   (? means weight TBD)
```

Free-text comments at the workout level (outside an exercise block) are also
valid:

```
// Felt strong today, added a back-off set
```

## Repository Structure

```
programs/          # Ruby scripts that generate .gym files
  lib/
    util.rb        # Util module — static helpers (Util.ceil5)
    workout.rb     # Abstract Workout base class
    protocols.rb   # Protocols module — reusable set/rep schemes
  vars.json        # Per-program config (maxes, reps, overrides)
  fahves.rb        # Fahves program (9-week powerbuilding)
  olympus.rb       # Olympus program (4-week wave loading)
  531-fsl.rb       # 5/3/1 FSL (older, procedural style)
  531-triumvirate.rb
templates/         # Static .tmpl.gym files for manual use
workouts/          # Logged workout files
gymconfig.json     # gym CLI config (editor, db path, git behavior)
```

## Writing Program Scripts

Programs inherit from `Workout` (`lib/workout.rb`) and must implement:

- `day_names` — hash mapping CLI argument → frontmatter `name:`
- `frontmatter` — returns the `--- ... ---` block as a string
- `exercises` — returns an array of exercise hashes (see below)

Optionally override:
- `readme` — shown when the first argument is `"readme"` (default: `"No readme defined"`)
- `exercise_overrides` (private) — hash of `key => name` substitutions from config

### Exercise Hash Format

```ruby
{ key: 'squat_main', name: 'Front Squat', protocol: proto }
{ key: 'squat_secondary', name: 'Romanian Deadlift', protocol: '3x8-12', superset: true }
```

- `key` — used to look up overrides from `exercise_overrides`
- `name` — default exercise name
- `protocol` — anything that responds to `to_s`; becomes the `//` comment lines
- `superset:` — optional boolean, uses `&` prefix instead of `#`

### Protocols

`Protocols::PercentageWaveLoading` (`lib/protocols.rb`) — 4-week block with a
top set / backoff scheme. Takes `goal_weight`, `reps`, `backoffs`, `week`.

| Week     | Top set        | Backoffs               |
|----------|----------------|------------------------|
| 1        | 90% goal       | 90% of top × backoffs  |
| 2        | 95% goal       | 90% of top × backoffs  |
| 3        | 100% goal (+)  | 90% of top × backoffs  |
| deload   | none           | 80% goal × backoffs    |

### vars.json

Each program has a key in `programs/vars.json`:

```json
"olympus": {
  "reps": 10,
  "backoffs": 2,
  "maxes": { "squat": 205, "bench": 195, "deadlift": 335, "press": 115 },
  "exercise_overrides": {}
}
```

`exercise_overrides` maps a key (e.g. `"squat_main"`) to a replacement exercise
name. This lets the user swap out an exercise without editing the script.

### Running a Program

```bash
ruby programs/olympus.rb deadlift 2
ruby programs/olympus.rb readme 1   # second arg ignored for readme
```

Pipe into `gym` to create a new workout file:

```bash
gym w new -t <(ruby ./programs/olympus.rb deadlift 1)
```

## Conventions

- All weights are in lbs (imperial).
- `Util.ceil5` rounds up to the nearest 5 — use it whenever calculating weights
  from percentages.
- Keep `MainLiftProtocol` and other program-specific protocols in their own
  program file. Only extract to `lib/protocols.rb` when a protocol will be
  reused across programs.
- `day_names` keys are the CLI arguments (e.g. `"squat"`, `"bench"`). The
  values become the `name:` in frontmatter.
