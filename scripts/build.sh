#!/bin/bash
set -e
echo "Building Veritas contracts..."
scarb build
echo "Build complete. Artifacts in target/dev/"
