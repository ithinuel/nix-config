if [[ ! -e $HOME/.local/bin/antigen.zsh ]]; then
    curl -L git.io/antigen > $HOME/.local/bin/antigen.zsh
fi

source $HOME/.local/bin/antigen.zsh
antigen use oh-my-zsh

antigen bundle git
antigen bundle command-not-found
antigen bundle dnf
antigen bundle python
antigen bundle zpm-zsh/autoenv
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle tonyseek/oh-my-zsh-virtualenv-prompt

antigen theme "af-magic"
antigen apply
fpath+=~/.zfunc

export LC_ALL="fr_FR.UTF-8"
export SKIM_DEFAULT_COMMAND="rg --follow --no-ignore --color=never --files || find ."

export NAVI_FINDER="skim"

# git tools
alias gk='gitk --all --branches --word-diff'
alias gg='git gui'
alias gdto='git difftool -y'
alias gsti='gst --ignored'
alias tig='tig --all'

# rust based tools
alias rg='rg -p --no-heading -g "!tags" --no-ignore --follow'
alias ske="sk -m | xargs -or nvim"
alias skg='sk --ansi -m -i -c "rg --color=always --line-number \"{}\"" | sed -r "s/([^:]+):([0-9]+)\:.*/\1:\2/" | xargs -or nvim'
alias fd="fd --no-ignore"
alias ll='exa -l --git -@'
alias lla='exa -la --git -@'
alias cat='bat -p'

# lulz
alias bwd='pwd | sed -e "s:/:🥖:g"'

export PATH="${HOME}/.local/opt/adr-tools/src:${PATH}"
export PATH="${HOME}/.local/bin:${PATH}"

[ ! -z "$(command -v navi)" ] && eval "$(navi widget zsh)"

# mac-os f-yeah
if [[ "$(uname -s)" == "Darwin" ]]; then
  alias vim='nvim'
  alias tig='tig --all'
  export PATH="/Applications/ARM/bin:${PATH}"
  export GPG_TTY=$(tty)

  [ -f "/Users/${USER}/.ghcup/env" ] && source "/Users/${USER}/.ghcup/env" # ghcup-env
fi

stty -ixon
