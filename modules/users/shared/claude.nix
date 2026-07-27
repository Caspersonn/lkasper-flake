{ inputs, ... } : {

  flake.modules.homeManager.shared-claude = { unstable, ... }: {

    programs.claude-code = {
      enable = true;
      package = unstable.claude-code;

      commands = {

        "cas:1shotpoc" = ''
          ---
          description: creates a new project based on the existing context my way
          ---
          Can you create a set of artifacts I can use to let claude code
          autonomously build the PoC which could serve as an alpha base for
          later development.

          We will use beans as internal ticket system for milestones and epics.
          Run `beans init` to setup and `beans prime` to undestand how it
          works. Claude Code should administer the milestones and epics.
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
        '';

        "cas:flaker" = ''
          ---
          description: creates a flake.nix for the current project
          ---
          check which programming langauge is used for this project and use the instructions from https://github.com/mipmip/agent-do-it-my-way for make a flake for this project-type. If the language is not listed create a flake in the spirit of add-flake-to-nodejs-project.md.
        '';

        "cas:translate" = ''
          ---
          argument-hint: [message]
          description: translates between Dutch and English
          ---
          Translate the following between Dutch and English. Auto-detect
          the source language. Keep the tone and register of the original.

          the following can be
            - a text fragment -> translate in this session
            - a file path -> translate the complete file overwriting the existing text
            - a file path with range -> translate the text withing the range overwriting the existing text

          $ARGUMENTS
        '';
        "cas:cleanup" = ''
          ---
          description: Cleans up messy code, removes duplication, and improves maintainability across code and documentation files
          tools: ["read", "search", "edit"]
          ---

          You are a cleanup specialist focused on making codebases cleaner and more maintainable. Your focus is on simplifying safely. Your approach:

          **When a specific file or directory is mentioned:**
          - Focus only on cleaning up the specified file(s) or directory
          - Apply all cleanup principles but limit scope to the target area
          - Don't make changes outside the specified scope

          **When no specific target is provided:**
          - Scan the entire codebase for cleanup opportunities
          - Prioritize the most impactful cleanup tasks first

          **Your cleanup responsibilities:**

          **Code Cleanup:**
          - Remove unused variables, functions, imports, and dead code
          - Identify and fix messy, confusing, or poorly structured code
          - Simplify overly complex logic and nested structures
          - Apply consistent formatting and naming conventions
          - Update outdated patterns to modern alternatives

          **Duplication Removal:**
          - Find and consolidate duplicate code into reusable functions
          - Identify repeated patterns across multiple files and extract common utilities
          - Remove duplicate documentation sections and consolidate into shared content
          - Clean up redundant comments
          - Merge similar configuration or setup instructions

          **Documentation Cleanup:**
          - Remove outdated and stale documentation
          - Delete redundant inline comments and boilerplate
          - Update broken references and links

          **Quality Assurance:**
          - Ensure all changes maintain existing functionality
          - Test cleanup changes thoroughly before completion
          - Prioritize readability and maintainability improvements

          **Guidelines**:
          - Always test changes before and after cleanup
          - Focus on one improvement at a time
          - Verify nothing breaks during removal

          Focus on cleaning up existing code rather than adding new features. Work on both code files (.js, .py, etc.) and documentation files (.md, .txt, etc.) when removing duplication and improving consistency.
          '';
      };

    };
  };

}

