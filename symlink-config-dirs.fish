#!/usr/bin/env fish
# Symlink every directory in ~/omarchy-config/config-dirs into ~/.config.
# An existing directory of the same name is replaced by that symlink.

set -l stow_dir $HOME/omarchy-config
set -l package config-dirs
set -l source_root $stow_dir/$package
set -l target $HOME/.config

if not test -d $source_root
    echo "symlinks.fish: $source_root does not exist" >&2
    exit 1
end

if not command -q stow
    echo "symlinks.fish: stow is not installed" >&2
    exit 1
end

mkdir -p $target

set -l holding (mktemp -d)
set -l moved

for dir in $source_root/*/
    set -l name (path basename $dir)
    set -l dest $target/$name

    if test -L $dest
        set -l current (path resolve $dest)
        set -l wanted (path resolve $dir)
        if test "$current" = "$wanted"
            continue
        end
        rm -f -- $dest
    else if test -d $dest
        mv -- $dest $holding/$name
        set -a moved $name
    end
end

if not stow --dir $stow_dir --target $target --restow $package
    for name in $moved
        mv -- $holding/$name $target/$name
    end
    rm -rf -- $holding
    exit 1
end

rm -rf -- $holding
