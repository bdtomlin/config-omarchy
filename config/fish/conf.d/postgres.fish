# /usr/bin/psql (postgresql-libs) looks for a socket in /run/postgresql.
# OmaDBngin postgresql-18 listens only on its own socket and on 127.0.0.1:5432.
set -gx PGHOST $HOME/.local/share/omadbngin/servers/postgresql-18/run
