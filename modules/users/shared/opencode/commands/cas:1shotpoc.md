---
description: creates a new project based on the existing context my way
---
Can you create a set of artifacts I can use to let opencode
autonomously build the PoC which could serve as an alpha base for
later development.

We will use beans as internal ticket system for milestones and epics.
Run `beans init` to setup and `beans prime` to undestand how it
works. opencode should administer the milestones and epics.
Milestone title should start with an incremental two digit
number:starting with `01`

We will use OpenSpec for creating proposals and keeping track of all
tasks within an epic. OpenSpec needs to be fully setup before the
project can take off. start with `openspec init.

We need thourough testing and e2e testcases to prove our PoC is
working as it should.

The PoC need to work with nix and nix flakes from the start. Do
not use flake-utils but plain nix to setup supported architectures.

We will use jj for version control. Luca will give you the url of the
remote repository. You should commit after every archival of a
openspec change. Commit as Luca Kasper, no self promotion.
