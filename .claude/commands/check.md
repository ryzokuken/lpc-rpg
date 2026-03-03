Validate all GDScript files for syntax and type errors without running a full build.

Uses Godot's `--check-only` flag, which loads all scripts, checks types, and
exits without launching the game. Much faster than a full web export.

## Run

```bash
bash ".agent/scripts/check.sh"
```

## Interpreting output

- Exit code 0, "all GDScript files OK" → no errors
- Non-zero exit or error lines in output → script errors found

Godot error output format:
```
ERROR: Parse Error: <message>
   at: res://scripts/foo.gd:42
```

Report each error with its file path and line number. Use the line number to
locate the problem in the source file, then fix and run `/check` again.

## When to use

- After editing any `.gd` file before running `/test-web`
- When Claude edits scripts as part of implementing a feature
- To quickly verify a change without a full build cycle
