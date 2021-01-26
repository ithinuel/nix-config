source /usr/share/zsh-antigen/antigen.zsh
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

# rust based tools
alias rg='rg -p --no-heading -g "!tags" --no-ignore --follow'
alias ske="sk -m | xargs -or vim"
alias skg='sk --ansi -m -i -c "rg --color=always --line-number \"{}\"" | sed -r "s/([^:]+):([0-9]+)\:.*/\1:\2/" | xargs -or vim'
alias fd="fd --no-ignore"
alias ll='exa -l --git -@'
alias lla='exa -la --git -@'
alias cat='bat -p'

# lulz
alias bwd='pwd | sed -e "s:/:🥖:g"'

export PATH="${HOME}/.local/opt/adr-tools/src:${HOME}/Documents/3d_printing/sam-ba/sam-ba_2.18:${PATH}"

stty -ixon

eval "$(navi widget zsh)"
