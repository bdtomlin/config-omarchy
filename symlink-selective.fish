#!/usr/bin/env fish
# Symlink files in ~/omarchy-config/config-selective into ~/.config.
# The tree matches ~/.config. Stow creates missing directories and links
# only files. An existing file is replaced by that symlink.

set -l stow_dir $HOME/omarchy-config
set -l package config-selective
set -l source_root $stow_dir/$package
set -l target $HOME/.config

if not test -d $source_root
    echo "symlink-selective.fish: $source_root does not exist" >&2
    exit 1
end

if not command -q stow
    echo "symlink-selective.fish: stow is not installed" >&2
    exit 1
end

mkdir -p $target

function run_stow
    stow --dir $argv[1] --target $argv[2] --no-folding --restow $argv[3]
end

set -l log (mktemp)
if run_stow $stow_dir $target $package >$log 2>&1
    rm -f -- $log
    exit 0
end

set -l blockers
for line in (string split \n < $log)
    set -l match
    if set match (string match -r 'over existing target (.+) since neither a link nor a directory' -- $line)
        set -a blockers $match[2]
    else if set match (string match -r 'existing target is not owned by stow: (.+)$' -- $line)
        set -a blockers $match[2]
    else if set match (string match -r 'existing target is stowed to a different package: (.+) =>' -- $line)
        set -a blockers $match[2]
    end
end

set -l holding (mktemp -d)
set -l moved

for rel in $blockers
    set -l dest $target/$rel
    # Stow creates real directories and links the files inside them.
    if test -d $dest
        continue
    end
    if not test -e $dest; and not test -L $dest
        continue
    end
    mkdir -p -- $holding/(path dirname $rel)
    mv -- $dest $holding/$rel
    set -a moved $rel
end

if test (count $moved) -eq 0
    cat $log >&2
    rm -rf -- $holding $log
    exit 1
end

if not run_stow $stow_dir $target $package >$log 2>&1
    for rel in $moved
        mkdir -p -- $target/(path dirname $rel)
        mv -- $holding/$rel $target/$rel
    end
    cat $log >&2
    rm -rf -- $holding $log
    exit 1
end

rm -rf -- $holding $log
