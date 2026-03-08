#!/bin/bash
set -ouex pipefail

### Bun
curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr bash

### DuckDB
DUCKDB_VERSION=$(curl -s https://api.github.com/repos/duckdb/duckdb/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
curl -fsSL "https://github.com/duckdb/duckdb/releases/download/${DUCKDB_VERSION}/duckdb_cli-linux-amd64.gz" | gunzip > /tmp/duckdb
install -Dm755 /tmp/duckdb /usr/bin/duckdb

### ClickHouse
curl -fsSL https://builds.clickhouse.com/master/amd64/clickhouse -o /tmp/clickhouse
install -Dm755 /tmp/clickhouse /usr/bin/clickhouse
