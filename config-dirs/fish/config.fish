if status is-interactive
  # Zellij 0.45.x queries the host terminal for cell size at startup and can
  # forward the reply (ESC [ 6 ; height ; width t) into this pane if fish issues
  # its own queries too soon. That leftover shows up as "6;40;18t" on the first
  # prompt. Wait until Zellij has consumed the reply. Drop this once Zellij
  # includes the fix from https://github.com/zellij-org/zellij/pull/5655.
  if set -q ZELLIJ
    sleep 0.1
  end

  # Commands to run in interactive sessions can go here
  set fish_key_bindings fish_vi_key_bindings
  set -U fish_greeting
  alias q exit
  alias :q exit
  alias yy yazi
  alias docker podman
  alias watts "awk '{print \$1*10^-6 \"W\"}' /sys/class/power_supply/BAT0/power_now"

  set -x BAT_THEME 1337

  set -x EDITOR nvim
  set -x VISUAL nvim


# enable my bins
  set -x PATH "$HOME/bin:$PATH"
  set -x PATH "$HOME/.config/bin:$PATH"
  set -x PATH "$HOME/go/bin:$PATH"
  set -x PATH "$HOME/.cargo/bin:$PATH"
  export PATH="$HOME/.local/bin:$PATH"
  export PATH="$HOME/.npm-global/bin:$PATH"
# allow local ./bin
  export PATH="./bin:$PATH"


  set -x BUN_INSTALL "$HOME/.bun"
  set -x PATH "$BUN_INSTALL/bin:$PATH"
  
  direnv hook fish | source

end

# >>> grok installer >>>
fish_add_path $HOME/.grok/bin
# <<< grok installer <<<

# >>> Added by `rbenv init` on Tue Oct  6 10:22:57 AM CDT 2026
status --is-interactive; and rbenv init - --no-rehash fish | source
# <<< `rbenv init`
