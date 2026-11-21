#!/usr/bin/env fish
# Link ~/config-omarchy/config into ~/.config.
#
# A real directory at the root of config becomes one symlink in ~/.config.
# A real directory whose name starts with _ is synced file by file into
# ~/.config/<name without that leading underscore>. Missing directories are
# created. Only files (and symlinks) become symlinks, and directory symlinks
# in the source are not followed.
# A file at the root of config, including a dotfile, becomes a symlink.
#
# A plain file or real directory that blocks a new symlink is moved aside.
# Moved paths are put back if a later step fails. On success they are deleted.
# Nothing is copied back into config.

set -l source_root (path normalize -- $HOME/config-omarchy/config)
set -l target (path normalize -- $HOME/.config)

if not test -d $source_root
    echo "symlink-config.fish: $source_root does not exist" >&2
    exit 1
end

set -g sc_holding (mktemp -d)
or begin
    echo "symlink-config.fish: could not create a temp directory" >&2
    exit 1
end
set -g sc_log $sc_holding/log
touch $sc_log

function sc_record
    string join \t -- $argv >> $sc_log
end

function sc_restore
    set -l lines
    while read -l line
        set -p lines $line
    end < $sc_log

    set -l failed 0
    for line in $lines
        if test -z "$line"
            continue
        end
        set -l fields (string split \t -- $line)
        switch $fields[1]
            case mv
                mv -- $fields[3] $fields[2]
                or set failed 1
            case link
                rm -f -- $fields[2]
                or set failed 1
            case rmlink
                ln -s -- $fields[3] $fields[2]
                or set failed 1
            case mkdir
                rmdir -- $fields[2]
                or set failed 1
        end
    end

    if test $failed -eq 1
        echo "symlink-config.fish: restore failed; kept $sc_holding" >&2
        return 1
    end
    rm -rf -- $sc_holding
end

function sc_die
    if test (count $argv) -gt 0
        echo "symlink-config.fish: $argv" >&2
    end
    sc_restore
    exit 1
end

function sc_under -a abs root
    if test "$abs" = "$root"
        return 0
    end
    set -l n (string length -- $root)
    test (string sub --length $n -- $abs) = "$root"
    and test (string sub --start (math $n + 1) --length 1 -- $abs) = /
end

function sc_link_abs -a link
    set -l raw (readlink -- $link)
    or return 1
    if string match -q '/*' -- $raw
        path normalize -- $raw
    else
        path normalize -- (path dirname -- $link)/$raw
    end
end

function sc_move_aside -a path hold_rel
    set -l held $sc_holding/data/$hold_rel
    mkdir -p -- (path dirname -- $held)
    or return 1
    mv -- $path $held
    or return 1
    sc_record mv $path $held
end

function sc_remove_link -a path
    set -l text (readlink -- $path)
    or return 1
    rm -f -- $path
    or return 1
    sc_record rmlink $path $text
end

function sc_make_link -a path rel_target
    ln -s -- $rel_target $path
    or return 1
    sc_record link $path
end

# Replace path with a symlink to src. A real directory is moved only when
# replace_dir is yes. A real directory left in place is a conflict.
function sc_place_one -a src dest hold_rel replace_dir
    set -l parent (path dirname -- $dest)
    set -l wanted (realpath -s --relative-to=$parent -- $src)
    or return 1

    if test -L $dest
        set -l current (readlink -- $dest)
        if test "$current" = "$wanted"
            return 0
        end
        sc_remove_link $dest
        or return 1
    else if test -d $dest
        if test "$replace_dir" != yes
            echo "symlink-config.fish: $dest is a directory and cannot be replaced by $src" >&2
            return 1
        end
        sc_move_aside $dest $hold_rel
        or return 1
    else if test -e $dest
        sc_move_aside $dest $hold_rel
        or return 1
    end

    sc_make_link $dest $wanted
end

# Make path a real directory. A blocking symlink is removed. A blocking file
# is moved aside.
function sc_ensure_dir -a path hold_rel
    if test -L $path
        sc_remove_link $path
        or return 1
    else if test -e $path
        if not test -d $path
            sc_move_aside $path $hold_rel
            or return 1
        end
    end
    if not test -d $path
        mkdir -- $path
        or return 1
        sc_record mkdir $path
    end
end

function sc_sync_selective -a src dest
    set -l prefix sel/(path basename -- $dest)
    sc_ensure_dir $dest $prefix
    or return 1

    # Directories first so a file's parent exists before it is linked.
    for node in (find -P $src -mindepth 1 -type d)
        set -l rel (string replace -- $src/ '' $node)
        sc_ensure_dir $dest/$rel $prefix/$rel
        or return 1
    end
    for node in (find -P $src -mindepth 1 -not -type d)
        set -l rel (string replace -- $src/ '' $node)
        sc_place_one $node $dest/$rel $prefix/$rel no
        or return 1
    end

    # Drop symlinks left from source files that are gone. Leave every other
    # file and directory in the destination alone.
    for link in (find -P $dest -type l)
        set -l abs (sc_link_abs $link)
        or continue
        if sc_under $abs $src
            if not test -e $abs; and not test -L $abs
                sc_remove_link $link
                or return 1
            end
        end
    end
end

set -l dir_entries
set -l sel_entries
set -l file_entries

for entry in $source_root/{*,.*}
    if not test -e $entry; and not test -L $entry
        continue
    end
    set -l name (path basename -- $entry)
    if test -d $entry; and not test -L $entry
        if string match -q -- '_*' $name
            set -l dest_name (string sub --start 2 -- $name)
            if test -z "$dest_name"
                echo "symlink-config.fish: $entry has no destination name" >&2
                rm -rf -- $sc_holding
                exit 1
            end
            set -a sel_entries $entry
        else
            set -a dir_entries $entry
        end
    else
        set -a file_entries $entry
    end
end

set -l managed
for entry in $dir_entries $file_entries
    set -a managed (path basename -- $entry)
end
for entry in $sel_entries
    set -l dest_name (string sub --start 2 -- (path basename -- $entry))
    if contains -- $dest_name $managed
        echo "symlink-config.fish: $entry and $source_root/$dest_name both target $target/$dest_name" >&2
        rm -rf -- $sc_holding
        exit 1
    end
    set -a managed $dest_name
end

mkdir -p -- $target
or sc_die "could not create $target"

for entry in $dir_entries
    set -l name (path basename -- $entry)
    sc_place_one $entry $target/$name root/$name yes
    or sc_die
end

for entry in $file_entries
    set -l name (path basename -- $entry)
    sc_place_one $entry $target/$name root/$name no
    or sc_die
end

for entry in $sel_entries
    set -l dest_name (string sub --start 2 -- (path basename -- $entry))
    sc_sync_selective $entry $target/$dest_name
    or sc_die
end

# Remove root symlinks that pointed into config and are no longer entries.
# Symlinks that point somewhere else, including config-dirs, stay.
for entry in $target/{*,.*}
    if not test -L $entry
        continue
    end
    set -l name (path basename -- $entry)
    if contains -- $name $managed
        continue
    end
    set -l abs (sc_link_abs $entry)
    or continue
    if sc_under $abs $source_root
        sc_remove_link $entry
        or sc_die
    end
end

rm -rf -- $sc_holding
