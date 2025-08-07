# vim: set filetype=zsh:

# Show Terraform backend state with a Nerd Font icon (󱁢)
function tfbackend_prompt_info () {
  if [ -f .terraform/tfbackend.state ]; then
    echo "%{$fg[green]%}󱁢 $(cat .terraform/tfbackend.state)%{$reset_color%} "
  fi
}

# Show current AWS profile with a Nerd Font icon ()
function aws_prompt_info() {
  if [[ -n $AWS_PROFILE ]]; then
    echo "%{$fg[magenta]%} $AWS_PROFILE%{$reset_color%} "
  fi
}

function prompt_context() {
  prompt_segment $CURRENT_BG default  "  🌈  "
}

# Prompt symbol: green (✔) if last command succeeded, red (✘) if failed
PROMPT="%(:%{$fg_bold[green]%}:%{$fg_bold[red]%}) "

# Show AWS and Terraform state in the right prompt
RPROMPT='$(aws_prompt_info)$(tfbackend_prompt_info)'

# Show only current directory
PROMPT+='%{$fg[cyan]%}%c%{$reset_color%} '

# Show Git info
PROMPT+='$(git_prompt_info)'


# Git prompt settings with Nerd Fonts
#ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}(%{$fg[red]%}"
#ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
#ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
#ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"

# Git prompt settings with Nerd Fonts
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%} %{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[yellow]%} "
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[green]%} ✓"
