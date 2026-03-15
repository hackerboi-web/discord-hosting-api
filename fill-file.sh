#!/usr/bin/env bash
file="$1"
shift
cat > "$file" << 'EOT'
$@
EOT
