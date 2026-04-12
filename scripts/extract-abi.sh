#!/bin/bash
# Extract ABI from compiled contract artifact into frontend/src/abi.js
set -e

ARTIFACT="target/dev/veritas_Veritas.contract_class.json"
OUTPUT="frontend/src/abi.js"

if [ ! -f "$ARTIFACT" ]; then
    echo "Artifact not found. Run: scarb build"
    exit 1
fi

ABI=$(node -e "
const fs = require('fs');
const a = JSON.parse(fs.readFileSync('$ARTIFACT', 'utf8'));
console.log(JSON.stringify(a.abi, null, 2));
")

cat > "$OUTPUT" << 'HEADER'
// Auto-generated from target/dev/veritas_Veritas.contract_class.json
// Run: ./scripts/extract-abi.sh
HEADER

echo "export const VERITAS_ABI = $ABI;" >> "$OUTPUT"

echo "ABI extracted to $OUTPUT"
