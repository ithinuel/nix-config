# install antigen
if [[ "$(uname -s)" == "Darwin" ]]; then
    source /opt/homebrew/share/antigen/antigen.zsh
else
    if [[ ! -e "$HOME/.local/bin/antigen.zsh" ]]; then
	mkdir -p $HOME/.local/bin
        curl -L git.io/antigen > $HOME/.local/bin/antigen.zsh
	chmod u+x $HOME/.local/bin/antigen.zsh
    fi
    source $HOME/.local/bin/antigen.zsh
fi

# ===============================================
# Setup plugins
antigen use oh-my-zsh

antigen bundle zpm-zsh/vte
antigen bundle git
antigen bundle command-not-found
antigen bundle dnf
antigen bundle python
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
antigen bundle tonyseek/oh-my-zsh-virtualenv-prompt
antigen bundle spwhitt/nix-zsh-completions.git
antigen bundle zpm-zsh/autoenv

antigen theme "af-magic"
antigen apply
fpath+="${0:h}/.zfunc"

# ===============================================
# Setup aliases

# git tools
alias gs='git submodule'
alias gk='gitk --all --branches --word-diff'
alias gg='git gui'
alias gdto='git difftool -y'
alias gsti='gst --ignored'
alias tig='tig --all'
alias gfa='git fetch --all --recurse-submodules --prune'

# rust based tools
alias rg='rg -p --no-heading -g "!tags" --no-ignore --follow'
alias ske="sk -m | xargs -or nvim"
alias skg='sk --ansi -m -i -c "rg --color=always --line-number \"{}\"" | sed -r "s/([^:]+):([0-9]+)\:.*/\1:\2/" | xargs -or nvim'
alias fd="fd --no-ignore"
alias ll='exa -l --git -@'
alias lla='exa -la --git -@'
alias cat='bat -p'
alias j='just'

# lulz
alias bwd='pwd | sed -e "s:/:🥖:g"'

# ===============================================
# Setup env

export SKIM_DEFAULT_COMMAND="rg --hidden --follow --no-ignore --color=never --files || find ."

export NAVI_FINDER="skim"
export PATH="${HOME}/.local/bin:${PATH}"

[ ! -z "$(command -v navi)" ] && eval "$(navi widget zsh)"

# mac-os f-yeah
if [[ "$(uname -s)" == "Darwin" ]]; then
  alias vim='nvim'
  alias tig='tig --all'
  export PATH="/Applications/ARM/bin:${PATH}"
  export PATH="/opt/homebrew/opt/bison/bin:$PATH"
  export PATH="/opt/homebrew/opt/flex/bin:$PATH"
  export PATH="$HOME/.local/opt/iverilog/bin:$PATH"
  export GPG_TTY=$(tty)

  [ -f "/Users/${USER}/.ghcup/env" ] && source "/Users/${USER}/.ghcup/env" # ghcup-env
fi

stty -ixon
