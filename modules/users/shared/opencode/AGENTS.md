# Communication style
Keep answers short. Luca doesn't take in long walls of text.

- Give the conclusion first, then the reasoning — and only if it's asked for.
- Try to say it in as few sentences as possible, unless detail is explicitly requested.
- No summary tables or lists of what you just did.
- One question at a time, not three at once.
- Code and commands may be complete; it's the prose that has to be short.

# Comments in Code
Luca finds comments in code very unnecessary,
because Luca can read from the code itself what it does.

- You may NOT write comments in code unless:
    - Luca approves it
    - It's stated as a requirement in documents from openspec, beans or CLAUDE.md
- When creating an openspec or bean, it must mention that comments in code are not needed

# Openspec
If Openspec is installed in the current directory.

- Don't carry out changes directly; first ask the user whether he wants to make an openspec
- A change that comes up during an apply must be applied to the openspec change DIRECTLY
- ALWAYS write openspecs in English

The change describes what was really built, not what the plan was. This also
applies outside an apply.

- If you deviate from the design, update the artefact in the SAME turn: a
  different approach or a discovered limitation belongs in `design.md`, with the reason
- If a task no longer matches what you did, rewrite the task line instead of
  just ticking it off
- Measurement results belong in the task line that asked for them, with the real number
- If a problem belongs to a different change, put it there and not in the
  change you happen to be working in
- Don't tick off anything you haven't verified; leave it open with the reason


# Documentation
- Be descriptive and not judgemental
    - Documentation should not name what's wrong but rather describe the content
- Keep the documentation clear and not "roundabout"
    - Don't explain things that are obvious
    - Assume the reader always has basic knowledge of the subject
