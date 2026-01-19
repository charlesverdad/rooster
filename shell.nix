{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Python
    python312
    python312Packages.pip
    python312Packages.virtualenv

    # PostgreSQL
    postgresql_16

    # Flutter
    flutter

    # Useful tools
    just
    jq
    curl
  ];

  shellHook = ''
    echo "Rooster Development Environment"
    echo "================================"

    # Set up Python virtual environment
    if [ ! -d ".venv" ]; then
      echo "Creating Python virtual environment..."
      python -m venv .venv
    fi
    source .venv/bin/activate

    # Install Python dependencies if requirements.txt exists
    if [ -f "backend/requirements.txt" ]; then
      pip install -q -r backend/requirements.txt
    fi

    # Set up local PostgreSQL data directory
    export PGDATA="$PWD/.pgdata"
    export PGHOST="$PWD/.pgdata"
    export PGPORT="5433"
    export DATABASE_URL="postgresql://localhost:5433/rooster"

    if [ ! -d "$PGDATA" ]; then
      echo "Initializing PostgreSQL database..."
      initdb -D "$PGDATA" --no-locale --encoding=UTF8
      echo "unix_socket_directories = '$PGDATA'" >> "$PGDATA/postgresql.conf"
      echo "port = $PGPORT" >> "$PGDATA/postgresql.conf"
    fi

    # Function to start PostgreSQL
    start_db() {
      if ! pg_ctl status -D "$PGDATA" > /dev/null 2>&1; then
        echo "Starting PostgreSQL..."
        pg_ctl start -D "$PGDATA" -l "$PGDATA/postgresql.log"
        sleep 2
        createdb rooster 2>/dev/null || true
      else
        echo "PostgreSQL is already running"
      fi
    }

    # Function to stop PostgreSQL
    stop_db() {
      if pg_ctl status -D "$PGDATA" > /dev/null 2>&1; then
        echo "Stopping PostgreSQL..."
        pg_ctl stop -D "$PGDATA"
      fi
    }

    echo ""
    echo "Commands:"
    echo "  start_db  - Start PostgreSQL"
    echo "  stop_db   - Stop PostgreSQL"
    echo ""
    echo "Python: $(python --version)"
    echo "PostgreSQL: $(postgres --version)"
    echo "Flutter: $(flutter --version 2>/dev/null | head -1 || echo 'Run flutter doctor to check')"
    echo ""
  '';
}
