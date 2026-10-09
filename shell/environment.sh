# shellcheck shell=bash
# Shared Bash/Zsh environment for setup, existing hosts and explicit agent commands.
# Preserve non-system PATH order (including activated project runtimes), then
# add missing fallback paths ahead of system directories. No prompt hooks, pager, network or package-manager calls.
_dotfiles_environment() {
    local rest entry result='' prefix='' system_paths='' inherited=''
    for entry in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew "$HOME/.linuxbrew"; do
        if [ -x "$entry/bin/brew" ]; then prefix="$entry"; break; fi
    done
    rest="${PATH:-/usr/bin:/bin}"
    while [ -n "$rest" ]; do
        entry="${rest%%:*}"
        if [ "$rest" = "$entry" ]; then rest=''; else rest="${rest#*:}"; fi
        case "$entry" in
            /usr/bin|/bin|/usr/sbin|/sbin) system_paths="${system_paths:+$system_paths:}$entry" ;;
            '') ;;
            *) inherited="${inherited:+$inherited:}$entry" ;;
        esac
    done
    rest="$inherited:$HOME/.local/bin:$HOME/.bun/bin:$HOME/.npm-global/bin:$HOME/.cargo/bin:$HOME/go/bin"
    if [ -n "$prefix" ]; then
        rest="$rest:$prefix/bin:$prefix/sbin:$prefix/opt/python/libexec/bin"
        export HOMEBREW_PREFIX="$prefix"
    fi
    if [ -d /usr/local/cuda/bin ]; then
        export CUDA_HOME=/usr/local/cuda
        rest="$rest:/usr/local/cuda/bin"
    fi
    rest="$rest:$system_paths"
    # Parameter expansion works identically in Bash and Zsh; no implicit splitting.
    while [ -n "$rest" ]; do
        entry="${rest%%:*}"
        if [ "$rest" = "$entry" ]; then rest=''; else rest="${rest#*:}"; fi
        [ -n "$entry" ] || continue
        case ":$result:" in *":$entry:"*) ;; *) result="${result:+$result:}$entry" ;; esac
    done
    export PATH="$result"
}
_dotfiles_environment
unset -f _dotfiles_environment
