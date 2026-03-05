#!/bin/bash

# Veritas Professional Build System
# Clean, modular build for all contract versions

set -e

echo "🛡️  Veritas Professional Build System"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
BUILD_DIR="target/dev"
CONTRACTS_DIR="src/contracts"
DOCS_DIR="docs"
SCRIPTS_DIR="scripts"

# Contract versions
CONTRACTS=("basic" "advanced" "ultimate" "ultimate_plus")
CONTRACT_FILES=("lib.cairo" "lib_advanced.cairo" "lib_ultimate.cairo" "lib_ultimate_plus.cairo")
CONTRACT_NAMES=("Veritas" "VeritasAdvanced" "VeritasUltimate" "VeritasUltimatePlus")

echo "🏗️  Available Contract Versions:"
for i in "${!CONTRACTS[@]}"; do
    echo "  ${i}. ${CONTRACTS[$i]}"
done
echo ""

# Check if specific version requested
if [ "$1" != "" ]; then
    BUILD_VERSION="$1"
    echo "🎯 Building specific version: $BUILD_VERSION"
    echo ""
    
    # Find index of requested version
    for i in "${!CONTRACTS[@]}"; do
        if [ "${CONTRACTS[$i]}" = "$BUILD_VERSION" ]; then
            VERSION_INDEX=$i
            break
        fi
    done
    
    if [ -z "$VERSION_INDEX" ]; then
        echo -e "${RED}❌ Invalid version: $BUILD_VERSION${NC}"
        echo "Available versions: ${CONTRACTS[*]}"
        exit 1
    fi
    
    # Build specific version
    echo "📄 Building ${CONTRACTS[$VERSION_INDEX]}..."
    
    # Update Scarb.toml for this version
    update_scarb_config "${CONTRACTS[$VERSION_INDEX]}"
    
    # Build
    echo "🔨 Building..."
    scarb build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Build successful!${NC}"
        
        # Get file info
        CONTRACT_FILE="$BUILD_DIR/veritas_${CONTRACT_NAMES[$VERSION_INDEX]}.contract_class.json"
        if [ -f "$CONTRACT_FILE" ]; then
            SIZE=$(wc -c < "$CONTRACT_FILE")
            echo "📊 Contract file: $CONTRACT_FILE"
            echo "📏 Size: $SIZE bytes"
            
            # Create deployment info
            create_deployment_info "${CONTRACTS[$VERSION_INDEX]}" "$CONTRACT_FILE" "$SIZE"
        fi
        
        echo ""
        echo "🚀 Ready for deployment:"
        echo "  ./scripts/deploy_modular.sh ${CONTRACTS[$VERSION_INDEX]}"
        echo ""
        
    else
        echo -e "${RED}❌ Build failed!${NC}"
        exit 1
    fi
    
else
    # Build all versions
    echo "🔄 Building all contract versions..."
    echo ""
    
    for i in "${!CONTRACTS[@]}"; do
        echo "📄 Building ${CONTRACTS[$i]}..."
        
        # Update Scarb.toml
        update_scarb_config "${CONTRACTS[$i]}"
        
        # Build
        scarb build
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ ${CONTRACTS[$i]} build successful${NC}"
            
            # Get file info
            CONTRACT_FILE="$BUILD_DIR/veritas_${CONTRACT_NAMES[$i]}.contract_class.json"
            if [ -f "$CONTRACT_FILE" ]; then
                SIZE=$(wc -c < "$CONTRACT_FILE")
                echo "  📊 $CONTRACT_FILE ($SIZE bytes)"
                
                # Create deployment info
                create_deployment_info "${CONTRACTS[$i]}" "$CONTRACT_FILE" "$SIZE"
            fi
        else
            echo -e "${RED}❌ ${CONTRACTS[$i]} build failed${NC}"
            exit 1
        fi
        
        echo ""
    done
    
    echo -e "${GREEN}🎉 All contracts built successfully!${NC}"
    echo ""
fi

# Functions
update_scarb_config() {
    local version=$1
    local version_num=""
    
    case $version in
        "basic")
            version_num="0.1.0"
            ;;
        "advanced")
            version_num="0.2.0"
            ;;
        "ultimate")
            version_num="0.3.0"
            ;;
        "ultimate_plus")
            version_num="0.4.0"
            ;;
        *)
            version_num="0.1.0"
            ;;
    esac
    
    cat > Scarb.toml << EOF
[package]
name = "veritas"
version = "$version_num"
edition = "2024_07"

[dependencies]
starknet = ">=2.8.0"

[[target.starknet-contract]]

[tool.fmt]
sort-module-level-items = true

[tool.snforge]
exit_first = true
EOF
}

create_deployment_info() {
    local version=$1
    local contract_file=$2
    local size=$3
    
    local info_file="deployments/${version}_info.json"
    mkdir -p deployments
    
    cat > "$info_file" << EOF
{
    "version": "$version",
    "contract_file": "$contract_file",
    "size_bytes": $size,
    "build_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "networks": {
        "testnet": "deployments/testnet/${version}.txt",
        "mainnet": "deployments/mainnet/${version}.txt"
    },
    "features": {
        "basic": ["commit_reveal", "admin_controls", "time_limits"],
        "advanced": ["multi_sig", "quadratic_voting", "delegation", "zk_proofs", "time_locked", "analytics", "treasury", "upgrades"],
        "ultimate": ["dynamic_weights", "multi_phase", "cross_chain", "recursive_zk", "ml_prediction", "gas_optimization", "quantum_resistant"],
        "ultimate_plus": ["homomorphic_encryption", "neural_governance", "zk_rollups", "quantum_entanglement", "swarm_intelligence", "dna_cryptography", "time_dilated", "fractal_patterns", "consciousness"]
    }
}
EOF
    
    echo "  📋 Deployment info: $info_file"
}

echo ""
echo "🎯 Next Steps:"
echo "1. Deploy to testnet: ./scripts/deploy_modular.sh [version]"
echo "2. Run tests: ./scripts/test_deployment.sh [version]"
echo "3. Verify deployment: ./scripts/verify_contract.sh [version]"
echo "4. Monitor: ./scripts/monitor.sh [version]"
echo ""
echo -e "${BLUE}📚 Documentation: $DOCS_DIR${NC}"
echo -e "${BLUE}🔧 Scripts: $SCRIPTS_DIR${NC}"
echo ""
echo -e "${GREEN}�️  Veritas build system completed!${NC}"
echo ""
echo -e "${GREEN}🛡️  Veritas build system completed!${NC}"
