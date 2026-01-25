# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/
#!/usr/bin/env zsh
# shellcheck disable=SC2139

# Easier navigation: .., ..., ...., ....., ~ and -
alias ..="z .."
alias ...="z ../.."
alias ....="z ../../.."
alias .....="z ../../../.."
alias ~="z ~" # `cd` is probably faster to type though
alias -- -="z -"

# Shortcuts
#alias copyssh="pbcopy < $HOME/.ssh/id_ed25519.pub"
alias reloadshell="omz reload"
alias reloaddns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"

## Copy public key to clipboard
alias pubkey="cat ~/.ssh/id_rsa.pub | pbcopy | echo '=> Public key copied to pasteboard.'"
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy | echo '=> Copied to pasteboard.'"

# Directories
alias dotfiles="z $DOTFILES"
alias vdotfiles="nvim $DOTFILES"
alias library="z $HOME/Library"
alias cdl="z ~/Downloads"
alias cdt="z ~/Desktop"
alias cg="z ~/git"

# Git
alias gs="git status"
alias gb="git branch"
alias gc="git checkout"
alias gd="git diff"
alias ga="git add"
alias gcm="git commit -m"
alias gp="git push"
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'
alias gl="git log --oneline --decorate --color"
alias amend="git add . && git commit --amend --no-edit"
alias commit="git add . && git commit -m"
alias force="git push --force-with-lease"
alias nuke="git clean -df && git reset --hard"
alias pop="git stash pop"
alias prune="git fetch --prune"
alias pull="git pull"
alias push="git push"
alias resolve="git add . && git commit --no-edit"
alias stash="git stash -u"
alias unstage="git restore --staged ."
alias lg="lazygit"
alias suri="git submodule update --init --recursive"
alias puri="git pull && git submodule update --init --recursive"

## Enable aliases to be sudo’ed
alias sudo='sudo '

## Get week number
alias week='date +%V'

# Brew rosetta aliases
alias ibrew='arch -x86_64 /usr/local/bin/brew'
alias mbrew='arch -ar64e /opt/homebrew/bin/brew'

## Get macOS Software Updates, and update installed Ruby gems, Homebrew, npm, and their installed packages
alias update='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup; npm install npm -g; npm update -g; sudo gem update --system; sudo gem update; sudo gem cleanup'

# Google Chrome
alias chrome='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'
alias canary='/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary'

# IP addresses
alias ip{4,}='dig @resolver4.opendns.com myip.opendns.com +short -4' #you can use ip4 or ip to get your ipv4
alias ip6='dig @ns1.google.com TXT o-o.myaddr.l.google.com +short -6' #https://unix.stackexchange.com/a/81699
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

## Show active network interfaces
alias ifactive="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active'"

## Flush Directory Service cache
alias flush="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"

## Clean up LaunchServices to remove duplicates in the “Open With” menu
alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"

## Use syntax highlight for `cat` (only in interactive shells)
alias catt="bat --paging auto --decorations auto --style auto"

## Alias for df alternative duf
alias df="duf"

## Alias for du alternative dust
alias du="dust"

## Alias for htop alternative bottom
alias htop="btm"
alias top="btm"

## Brew Services
alias bs="brew services"

## Canonical hex dump; some systems have this symlinked
command -v hd > /dev/null || alias hd="hexdump -C"

## macOS has no `md5sum`, so use `md5` as a fallback
command -v md5sum > /dev/null || alias md5sum="md5"

## macOS has no `sha1sum`, so use `shasum` as a fallback
command -v sha1sum > /dev/null || alias sha1sum="shasum"

# JavaScriptCore REPL
jscbin="/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc";
[ -e "${jscbin}" ] && alias jsc="${jscbin}";
unset jscbin;

## Trim new lines and copy to clipboard
alias c="tr -d '\n' | pbcopy"

## Recursively delete `.DS_Store` files
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"

## Empty the Trash on all mounted volumes and the main HDD.
# Also, clear Apple’s System Logs to improve shell startup speed.
# Finally, clear download history from quarantine. https://mths.be/bum
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl; sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent'"

## Show/hide hidden files in Finder
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
## Show/hide hidden files in Finder
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

## Hide/show all desktop icons (useful when presenting)
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
## Hide/show all desktop icons (useful when presenting)
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

## URL-encode strings
alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'

## Merge PDF files, preserving hyperlinks
# Usage: `mergepdf input{1,2,3}.pdf`
alias mergepdf='gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=_merged.pdf'

## Disable Spotlight
alias spotoff="sudo mdutil -a -i off"
## Enable Spotlight
alias spoton="sudo mdutil -a -i on"

## PlistBuddy alias, because sometimes `defaults` just doesn’t cut it
alias plistbuddy="/usr/libexec/PlistBuddy"

## Airport CLI alias
alias airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport'

## Intuitive map function
# For example, to list all directories that contain a certain file:
# find . -name .gitattributes | map dirname
alias map="xargs -n1"

# Stuff I never really use but cannot delete either because of http://xkcd.com/530/
alias stfu="osascript -e 'set volume output muted true' && echo 'shhh! I am trying to sleep!'"
alias pumpitup="osascript -e 'set volume 7' && echo 'Dialed to 11!'"

## Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"

## Lock the screen (when going AFK)
alias afk="osascript -e 'tell app \"System Events\" to key code 12 using {control down, command down}'"

## Reload the shell (i.e. invoke as a login shell)
alias reload="exec ${SHELL} -l"

## Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'

## k for kubectl, so you don't have to write kubectl everytime, but can use the single letter k instead (e.g. k get pods -n <your-namespace>)
alias k=kubectl "$@"

alias python='python3'
alias pip='pip3'
