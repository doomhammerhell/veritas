#!/bin/bash

# Veritas Modular Deploy System
# Deploy script for all contract versions

set -e

echo "🚀 Veritas Modular Deploy System"
echo "==============================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
NETWORK=${STARKNET_NETWORK:-"testnet"}
BUILD_DIR="target/dev"
DEPLOYMENTS_DIR="deployments"
CONFIGS_DIR="configs"

# Contract versions
CONTRACTS=("basic" "advanced" "ultimate" "ultimate_plus")
CONTRACT_NAMES=("Veritas" "VeritasAdvanced" "VeritasUltimate" "VeritasUltimatePlus")

echo "🌐 Network: $NETWORK"
echo "📁 Build directory: $BUILD_DIR"
echo "📋 Deployments directory: $DEPLOYMENTS_DIR"
echo ""

# Check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check starkli
    if ! command -v starkli &> /dev/null; then
        echo -e "${RED}❌ Starkli not found. Please install Starkli.${NC}"
        echo "📖 Installation: https://github.com/0xSpaceShard/starkli"
        exit 1
    fi
    
    # Check environment variables
    if [ -z "$STARKNET_ACCOUNT_ADDRESS" ] || [ -z "$STARKNET_PRIVATE_KEY" ]; then
        echo -e "${RED}❌ Please set STARKNET_ACCOUNT_ADDRESS and STARKNET_PRIVATE_KEY${NC}"
        echo "💡 Example:"
        echo "   export STARKNET_ACCOUNT_ADDRESS=0x..."
        echo "   export STARKNET_PRIVATE_KEY=0x..."
        exit 1
    fi
    
    # Check network
    case $NETWORK in
        "testnet"|"mainnet"|"devnet")
            echo -e "${GREEN}✅ Network: $NETWORK${NC}"
            ;;
        *)
            echo -e "${RED}❌ Invalid network: $NETWORK${NC}"
            echo "💡 Valid networks: testnet, mainnet, devnet"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
    echo ""
}

# Deploy single contract
deploy_contract() {
    local version=$1
    local contract_name=$2
    
    echo "🚀 Deploying $version contract to $NETWORK"
    echo "=========================================="
    
    # Check if contract file exists
    local contract_file="$BUILD_DIR/veritas_${contract_name}.contract_class.json"
    if [ ! -f "$contract_file" ]; then
        echo -e "${RED}❌ Contract file not found: $contract_file${NC}"
        echo "💡 Please run: ./scripts/build.sh $version"
        exit 1
    fi
    
    echo "📄 Contract file: $contract_file"
    echo "📏 Size: $(wc -c < $contract_file) bytes"
    echo ""
    
    # Create deployments directory
    mkdir -p "$DEPLOYMENTS_DIR/$NETWORK"
    
    # Declare class
    echo "📝 Declaring contract class..."
    CLASS_HASH=$(starkli declare "$contract_file" \
        --network "$NETWORK" \
        --account "$STARKNET_ACCOUNT_ADDRESS" \
        --private-key "$STARKNET_PRIVATE_KEY" \
        --json 2>/dev/null | jq -r '.class_hash' 2>/dev/null || echo "")
    
    if [ -z "$CLASS_HASH" ] || [ "$CLASS_HASH" = "null" ]; then
        echo -e "${RED}❌ Class declaration failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Class hash: $CLASS_HASH${NC}"
    
    # Deploy contract
    echo "🔨 Deploying contract..."
    
    # Constructor parameters (example values)
    VOTING_DURATION=3600  # 1 hour
    MAX_OPTIONS=5
    ADMIN_THRESHOLD=2
    
    CONTRACT_ADDRESS=$(starkli deploy "$CLASS_HASH" \
        "$VOTING_DURATION" "$MAX_OPTIONS" "$ADMIN_THRESHOLD" \
        --network "$NETWORK" \
        --account "$STARKNET_ACCOUNT_ADDRESS" \
        --private-key "$STARKNET_PRIVATE_KEY" \
        --json 2>/dev/null | jq -r '.contract_address' 2>/dev/null || echo "")
    
    if [ -z "$CONTRACT_ADDRESS" ] || [ "$CONTRACT_ADDRESS" = "null" ]; then
        echo -e "${RED}❌ Contract deployment failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Contract address: $CONTRACT_ADDRESS${NC}"
    
    # Save deployment info
    echo "$CONTRACT_ADDRESS" > "$DEPLOYMENTS_DIR/$NETWORK/veritas_$version.txt"
    echo "$CLASS_HASH" > "$DEPLOYMENTS_DIR/$NETWORK/veritas_$version.class_hash.txt"
    
    # Create deployment record
    cat > "$DEPLOYMENTS_DIR/$NETWORK/${version}_deployment.json" << EOF
{
    "version": "$version",
    "contract_name": "$contract_name",
    "network": "$NETWORK",
    "class_hash": "$CLASS_HASH",
    "contract_address": "$CONTRACT_ADDRESS",
    "deploy_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "deployer": "$STARKNET_ACCOUNT_ADDRESS",
    "constructor_args": [$VOTING_DURATION, $MAX_OPTIONS, $ADMIN_THRESHOLD],
    "contract_file": "$contract_file",
    "contract_size": $(wc -c < "$contract_file)
}
EOF
    
    echo "📋 Deployment info saved to: $DEPLOYMENTS_DIR/$NETWORK/${version}_deployment.json"
    
    # Verify deployment
    echo "🔍 Verifying deployment..."
    
    # Check if contract is responsive
    ADMIN_CHECK=$(starkli call "$CONTRACT_ADDRESS" get_admin \
        --network "$NETWORK" 2>/dev/null || echo "")
    
    if [ -n "$ADMIN_CHECK" ]; then
        echo -e "${GREEN}✅ Contract is responsive${NC}"
        echo "👤 Admin: $ADMIN_CHECK"
    else
        echo -e "${YELLOW}⚠️  Contract not responsive (may need time to initialize)${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 $version deployment successful!${NC}"
    echo "🔗 Explorer: https://$NETWORK.starkscan.co/contract/$CONTRACT_ADDRESS"
    echo ""
}

# Deploy all contracts
deploy_all() {
    echo "🔄 Deploying all contract versions to $NETWORK"
    echo "=========================================="
    echo ""
    
    for i in "${!CONTRACTS[@]}"; do
        echo "📄 Deploying ${CONTRACTS[$i]}..."
        deploy_contract "${CONTRACTS[$i]}" "${CONTRACT_NAMES[$i]}"
        echo ""
    done
    
    echo -e "${GREEN}🎉 All contracts deployed successfully!${NC}"
    echo ""
}

# Main execution
main() {
    local version=$1
    
    check_prerequisites
    
    if [ -n "$version" ]; then
        # Deploy specific version
        for i in "${!CONTRACTS[@]}"; do
            if [ "${CONTRACTS[$i]}" = "$version" ]; then
                deploy_contract "$version" "${CONTRACT_NAMES[$i]}"
                exit 0
            fi
        done
        
        echo -e "${RED}❌ Invalid version: $version${NC}"
        echo "💡 Available versions: ${CONTRACTS[*]}"
        exit 1
    else
        # Deploy all versions
        deploy_all
    fi
}

# Show usage
usage() {
    echo "Usage: $0 [version]"
    echo ""
    echo "Versions:"
    for i in "${!CONTRACTS[@]}"; do
        echo "  ${CONTRACTS[$i]}"
    done
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy all versions"
    echo "  $0 basic              # Deploy basic version only"
    echo "  $0 ultimate_plus      # Deploy ultimate_plus version only"
    echo ""
    echo "Environment variables:"
    echo "  STARKNET_NETWORK      # Network (testnet|mainnet|devnet)"
    echo "  STARKNET_ACCOUNT_ADDRESS  # Account address"
    echo "  STARKNET_PRIVATE_KEY  # Private key"
    echo ""
}

# Check for help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    usage
    exit 0
fi

# Run main function
main "$1"

echo ""
echo "📋 Deployment Summary:"
echo "=================="
echo "🌐 Network: $NETWORK"
echo "📁 Deployments: $DEPLOYMENTS_DIR/$NETWORK"
echo ""
echo "Deployed contracts:"
for i in "${!CONTRACTS[@]}"; do
    if [ -f "$DEPLOYMENTS_DIR/$NETWORK/veritas_${CONTRACTS[$i]}.txt" ]; then
        ADDRESS=$(cat "$DEPLOYMENTS_DIR/$NETWORK/veritas_${CONTRACTS[$i]}.txt")
        echo "  ✅ ${CONTRACTS[$i]}: $ADDRESS"
    else
        echo "  ❌ ${CONTRACTS[$i]}: Not deployed"
    fi
done
echo ""
echo "🎯 Next Steps:"
echo "1. Test deployment: ./scripts/test.sh [version]"
echo "2. Verify contracts: ./scripts/verify.sh [version]"
echo "3. Monitor contracts: ./scripts/monitor.sh [version]"
echo ""
echo -e "${BLUE}📚 Documentation: docs/DEPLOY.md${NC}"
echo -e "${BLUE}🔧 Build scripts: scripts/build.sh${NC}"
echo ""
echo -e "${GREEN}🛡️  Veritas deployment system completed!${NC}"
