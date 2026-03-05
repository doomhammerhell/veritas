# 📋 Deploy Guide - Veritas Voting System

## 🎯 Overview

Este guia cobre o processo completo de deploy do sistema Veritas em diferentes ambientes, desde desenvolvimento até produção.

## 🏗️ Pré-requisitos

### **Ambiente de Desenvolvimento**
```bash
# Instalar Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Instalar Scarb
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh

# Instalar Starkli (macOS)
brew install starknet

# Instalar Node.js (para frontend)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### **Configuração de Wallet**
- **Argent X**: [Download](https://www.argent.xyz/)
- **Braavos**: [Download](https://www.braavos.app/)
- **MetaMask com Starknet**: [Setup](https://docs.starknet.io/tools/metamask)

## 📁 Estrutura de Deploy

```
veritas/
├── scripts/
│   ├── build.sh                    # Build básico
│   ├── build_advanced.sh           # Build avançado
│   ├── build_ultimate.sh           # Build ultimate
│   ├── build_ultimate_plus.sh      # Build ultimate++
│   ├── deploy_testnet.sh           # Deploy testnet
│   ├── deploy_mainnet.sh           # Deploy mainnet
│   ├── deploy_local.sh             # Deploy local
│   ├── test_deployment.sh          # Testes pós-deploy
│   ├── verify_contract.sh          # Verificação
│   └── rollback.sh                 # Rollback
├── configs/
│   ├── testnet.json               # Config testnet
│   ├── mainnet.json               # Config mainnet
│   ├── local.json                 # Config local
│   └── staging.json               # Config staging
└── deployments/
    ├── testnet/                   # Endereços testnet
    ├── mainnet/                   # Endereços mainnet
    └── local/                     # Endereços local
```

## 🚀 Processo de Deploy

### **1. Preparação do Ambiente**

```bash
# Clonar repositório
git clone https://github.com/your-org/veritas.git
cd veritas

# Instalar dependências
scarb build

# Configurar variáveis de ambiente
export STARKNET_NETWORK=testnet
export STARKNET_ACCOUNT_ADDRESS=0x...
export STARKNET_PRIVATE_KEY=0x...
export RPC_URL="https://starknet-testnet.public.blastapi.io"
```

### **2. Build dos Contratos**

```bash
# Build básico
./scripts/build.sh

# Build avançado
./scripts/build_advanced.sh

# Build ultimate
./scripts/build_ultimate.sh

# Build ultimate++
./scripts/build_ultimate_plus.sh
```

### **3. Deploy na Testnet**

```bash
# Deploy básico na testnet
./scripts/deploy_testnet.sh basic

# Deploy avançado na testnet
./scripts/deploy_testnet.sh advanced

# Deploy ultimate na testnet
./scripts/deploy_testnet.sh ultimate

# Deploy ultimate++ na testnet
./scripts/deploy_testnet.sh ultimate_plus
```

### **4. Testes Pós-Deploy**

```bash
# Testes básicos
./scripts/test_deployment.sh <CONTRACT_ADDRESS> basic

# Testes avançados
./scripts/test_deployment.sh <CONTRACT_ADDRESS> advanced

# Testes ultimate
./scripts/test_deployment.sh <CONTRACT_ADDRESS> ultimate

# Testes ultimate++
./scripts/test_deployment.sh <CONTRACT_ADDRESS> ultimate_plus
```

### **5. Deploy na Mainnet**

```bash
# Deploy na mainnet (após testes completos)
./scripts/deploy_mainnet.sh ultimate_plus
```

## 🔧 Scripts de Deploy

### **build.sh**
```bash
#!/bin/bash
# Build básico do Veritas

echo "🔨 Building Veritas Basic Contract"
echo "================================="

# Verificar dependências
if ! command -v scarb &> /dev/null; then
    echo "❌ Scarb not found. Please install Scarb."
    exit 1
fi

# Build do contrato
scarb build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📄 Contract file: target/dev/veritas_Veritas.contract_class.json"
    echo "📊 Contract size: $(wc -c < target/dev/veritas_Veritas.contract_class.json) bytes"
else
    echo "❌ Build failed!"
    exit 1
fi
```

### **deploy_testnet.sh**
```bash
#!/bin/bash
# Deploy na testnet

CONTRACT_TYPE=$1
NETWORK="testnet"

if [ -z "$CONTRACT_TYPE" ]; then
    echo "❌ Usage: ./deploy_testnet.sh <basic|advanced|ultimate|ultimate_plus>"
    exit 1
fi

echo "🚀 Deploying Veritas $CONTRACT_TYPE to $NETWORK"
echo "=========================================="

# Verificar variáveis de ambiente
if [ -z "$STARKNET_ACCOUNT_ADDRESS" ] || [ -z "$STARKNET_PRIVATE_KEY" ]; then
    echo "❌ Please set STARKNET_ACCOUNT_ADDRESS and STARKNET_PRIVATE_KEY"
    exit 1
fi

# Selecionar arquivo do contrato
case $CONTRACT_TYPE in
    "basic")
        CONTRACT_FILE="target/dev/veritas_Veritas.contract_class.json"
        ;;
    "advanced")
        CONTRACT_FILE="target/dev/veritas_VeritasAdvanced.contract_class.json"
        ;;
    "ultimate")
        CONTRACT_FILE="target/dev/veritas_VeritasUltimate.contract_class.json"
        ;;
    "ultimate_plus")
        CONTRACT_FILE="target/dev/veritas_VeritasUltimatePlus.contract_class.json"
        ;;
    *)
        echo "❌ Invalid contract type: $CONTRACT_TYPE"
        exit 1
        ;;
esac

# Verificar se o arquivo existe
if [ ! -f "$CONTRACT_FILE" ]; then
    echo "❌ Contract file not found: $CONTRACT_FILE"
    echo "Please run ./scripts/build_$CONTRACT_TYPE.sh first"
    exit 1
fi

# Deploy do contrato
echo "📄 Deploying contract: $CONTRACT_FILE"
echo "🌐 Network: $NETWORK"
echo "👤 Account: $STARKNET_ACCOUNT_ADDRESS"

# Usar starkli para deploy
if command -v starkli &> /dev/null; then
    # Deploy com starkli
    CLASS_HASH=$(starkli declare "$CONTRACT_FILE" --network $NETWORK --account $STARKNET_ACCOUNT_ADDRESS --private-key $STARKNET_PRIVATE_KEY)
    
    if [ $? -eq 0 ]; then
        echo "✅ Class hash: $CLASS_HASH"
        
        # Deploy do contrato
        CONTRACT_ADDRESS=$(starkli deploy "$CLASS_HASH" --network $NETWORK --account $STARKNET_ACCOUNT_ADDRESS --private-key $STARKNET_PRIVATE_KEY)
        
        if [ $? -eq 0 ]; then
            echo "✅ Contract deployed: $CONTRACT_ADDRESS"
            
            # Salvar endereço
            mkdir -p deployments/testnet
            echo "$CONTRACT_ADDRESS" > deployments/testnet/veritas_$CONTRACT_TYPE.txt
            echo "$CLASS_HASH" > deployments/testnet/veritas_$CONTRACT_TYPE.class_hash.txt
            
            echo "🎉 Deploy successful!"
            echo "📋 Contract address saved to: deployments/testnet/veritas_$CONTRACT_TYPE.txt"
            echo "🔗 Explorer: https://testnet.starkscan.co/contract/$CONTRACT_ADDRESS"
        else
            echo "❌ Contract deployment failed!"
            exit 1
        fi
    else
        echo "❌ Class declaration failed!"
        exit 1
    fi
else
    echo "❌ Starkli not found. Please install Starkli or use web deployer."
    echo "📖 Web deployer: https://starknet.js.org/deploy"
    exit 1
fi
```

### **test_deployment.sh**
```bash
#!/bin/bash
# Testes pós-deploy

CONTRACT_ADDRESS=$1
CONTRACT_TYPE=$2

if [ -z "$CONTRACT_ADDRESS" ] || [ -z "$CONTRACT_TYPE" ]; then
    echo "❌ Usage: ./test_deployment.sh <CONTRACT_ADDRESS> <basic|advanced|ultimate|ultimate_plus>"
    exit 1
fi

echo "🧪 Testing Veritas $CONTRACT_TYPE Deployment"
echo "=========================================="
echo "📄 Contract: $CONTRACT_ADDRESS"
echo "🌐 Network: $STARKNET_NETWORK"

# Testes básicos (comuns a todas as versões)
echo "🔍 Running basic tests..."

# Test 1: Verificar se o contrato existe
echo "1. Verifying contract existence..."
if starkli call "$CONTRACT_ADDRESS" get_admin --network $STARKNET_NETWORK &> /dev/null; then
    echo "✅ Contract exists and is responsive"
else
    echo "❌ Contract not found or not responsive"
    exit 1
fi

# Test 2: Verificar estado inicial
echo "2. Checking initial state..."
VOTING_END=$(starkli call "$CONTRACT_ADDRESS" get_voting_end --network $STARKNET_NETWORK)
ADMIN=$(starkli call "$CONTRACT_ADDRESS" get_admin --network $STARKNET_NETWORK)
MAX_OPTIONS=$(starkli call "$CONTRACT_ADDRESS" get_max_options --network $STARKNET_NETWORK)

echo "📊 Initial state:"
echo "  - Voting end: $VOTING_END"
echo "  - Admin: $ADMIN"
echo "  - Max options: $MAX_OPTIONS"

# Test 3: Verificar se a votação está aberta
echo "3. Checking voting status..."
IS_CLOSED=$(starkli call "$CONTRACT_ADDRESS" is_voting_closed --network $STARKNET_NETWORK)

if [ "$IS_CLOSED" = "false" ]; then
    echo "✅ Voting is open"
else
    echo "❌ Voting is closed"
    exit 1
fi

# Testes específicos por versão
case $CONTRACT_TYPE in
    "basic")
        echo "🔍 Running basic-specific tests..."
        # Test 4: Commit vote
        echo "4. Testing commit_vote..."
        COMMITMENT="0x1234567890abcdef"
        starkli invoke "$CONTRACT_ADDRESS" commit_vote "$COMMITMENT" --network $STARKNET_NETWORK --account $STARKNET_ACCOUNT_ADDRESS --private-key $STARKNET_PRIVATE_KEY
        
        if [ $? -eq 0 ]; then
            echo "✅ commit_vote works"
        else
            echo "❌ commit_vote failed"
            exit 1
        fi
        ;;
    
    "advanced")
        echo "🔍 Running advanced-specific tests..."
        # Test 4: Quadratic voting
        echo "4. Testing commit_quadratic_vote..."
        starkli invoke "$CONTRACT_ADDRESS" commit_quadratic_vote "0x1234567890abcdef" "1000" --network $STARKNET_NETWORK --account $STARKNET_ACCOUNT_ADDRESS --private-key $STARKNET_PRIVATE_KEY
        
        if [ $? -eq 0 ]; then
            echo "✅ commit_quadratic_vote works"
        else
            echo "❌ commit_quadratic_vote failed"
            exit 1
        fi
        ;;
    
    "ultimate")
        echo "🔍 Running ultimate-specific tests..."
        # Test 4: Dynamic voting weights
        echo "4. Testing calculate_dynamic_weight..."
        starkli call "$CONTRACT_ADDRESS" calculate_dynamic_weight "$STARKNET_ACCOUNT_ADDRESS" "1" --network $STARKNET_NETWORK
        
        if [ $? -eq 0 ]; then
            echo "✅ calculate_dynamic_weight works"
        else
            echo "❌ calculate_dynamic_weight failed"
            exit 1
        fi
        ;;
    
    "ultimate_plus")
        echo "🔍 Running ultimate_plus-specific tests..."
        # Test 4: Homomorphic encryption
        echo "4. Testing encrypt_vote_homomorphic..."
        starkli call "$CONTRACT_ADDRESS" encrypt_vote_homomorphic "1" "0x1234567890abcdef" --network $STARKNET_NETWORK
        
        if [ $? -eq 0 ]; then
            echo "✅ encrypt_vote_homomorphic works"
        else
            echo "❌ encrypt_vote_homomorphic failed"
            exit 1
        fi
        ;;
esac

echo ""
echo "🎉 All tests passed!"
echo "📊 Contract is ready for use"
echo "🔗 Explorer: https://testnet.starkscan.co/contract/$CONTRACT_ADDRESS"
```

## 🌐 Configurações de Ambiente

### **testnet.json**
```json
{
    "network": "testnet",
    "rpc_url": "https://starknet-testnet.public.blastapi.io",
    "account_address": "0x...",
    "private_key": "0x...",
    "max_fee": "0x1000000000000000",
    "gas_price": "0x1000000000",
    "contracts": {
        "basic": "deployments/testnet/veritas_basic.txt",
        "advanced": "deployments/testnet/veritas_advanced.txt",
        "ultimate": "deployments/testnet/veritas_ultimate.txt",
        "ultimate_plus": "deployments/testnet/veritas_ultimate_plus.txt"
    }
}
```

### **mainnet.json**
```json
{
    "network": "mainnet",
    "rpc_url": "https://starknet-mainnet.public.blastapi.io",
    "account_address": "0x...",
    "private_key": "0x...",
    "max_fee": "0x1000000000000000",
    "gas_price": "0x1000000000",
    "contracts": {
        "basic": "deployments/mainnet/veritas_basic.txt",
        "advanced": "deployments/mainnet/veritas_advanced.txt",
        "ultimate": "deployments/mainnet/veritas_ultimate.txt",
        "ultimate_plus": "deployments/mainnet/veritas_ultimate_plus.txt"
    }
}
```

## 🔐 Considerações de Segurança

### **1. Chaves Privadas**
- Nunca commit chaves privadas no repositório
- Use variáveis de ambiente
- Use hardware wallets para produção
- Rotate keys regularmente

### **2. Deploy em Produção**
- Use multi-sig para admin
- Implemente circuit breakers
- Monitore atividades suspeitas
- Tenha plano de rollback

### **3. Testes**
- Teste todas as funções
- Teste casos de erro
- Teste limites de gás
- Teste concorrência

## 📊 Monitoramento Pós-Deploy

### **1. Verificação Básica**
```bash
# Verificar se o contrato está online
starkli call <CONTRACT_ADDRESS> get_admin --network mainnet

# Verificar eventos
starkli call <CONTRACT_ADDRESS> get_voting_end --network mainnet
```

### **2. Monitoramento de Eventos**
```bash
# Monitorar eventos em tempo real
starkli events --from-block latest --address <CONTRACT_ADDRESS> --network mainnet
```

### **3. Analytics**
```bash
# Gerar relatório de analytics
starkli call <CONTRACT_ADDRESS> get_analytics_report --network mainnet
```

## 🔄 Rollback

### **Rollback para Versão Anterior**
```bash
# Desativar contrato atual
starkli invoke <CONTRACT_ADDRESS> emergency_close --network mainnet

# Deploy versão anterior
./scripts/deploy_mainnet.sh ultimate

# Migrar dados se necessário
./scripts/migrate_data.sh <OLD_CONTRACT> <NEW_CONTRACT>
```

## 📋 Checklist de Deploy

### **Pré-Deploy**
- [ ] Código testado e aprovado
- [ ] Security audit completo
- [ ] Configurações de ambiente verificadas
- [ ] Chaves privadas seguras
- [ ] Backup do estado atual

### **Deploy**
- [ ] Build do contrato bem-sucedido
- [ ] Deploy na testnet
- [ ] Testes completos na testnet
- [ ] Deploy na mainnet
- [ ] Verificação pós-deploy

### **Pós-Deploy**
- [ ] Monitoramento ativo
- [ ] Documentação atualizada
- [ ] Comunicar stakeholders
- [ ] Plano de contingência pronto

## 🚨 Troubleshooting

### **Problemas Comuns**

#### **1. Build Falha**
```bash
# Limpar cache
scarb clean

# Rebuild
scarb build

# Verificar dependências
scarb check
```

#### **2. Deploy Falha**
```bash
# Verificar saldo
starkli account balance --network testnet

# Verificar nonce
starkli account nonce --network testnet

# Verificar configuração
starkli account --network testnet
```

#### **3. Testes Falham**
```bash
# Verificar se o contrato existe
starkli call <CONTRACT_ADDRESS> get_admin --network testnet

# Verificar permissões
starkli call <CONTRACT_ADDRESS> is_voting_closed --network testnet

# Verificar gás
starkli estimate_fee --network testnet
```

## 📞 Suporte

### **Canais de Ajuda**
- **Discord**: Comunidade técnica
- **Telegram**: Suporte rápido
- **GitHub Issues**: Report bugs
- **Documentation**: docs.veritas.io

### **Recursos**
- [Starknet Docs](https://docs.starknet.io/)
- [Cairo Book](https://book.cairo-lang.org/)
- [Scarb Docs](https://docs.swmansion.com/scarb/)
- [Starkli Guide](https://github.com/0xSpaceShard/starkli)

---

## 🎉 Conclusão

Este guia cobre o processo completo de deploy do sistema Veritas. Siga os passos cuidadosamente e teste completamente antes de fazer deploy em produção.

**Para suporte adicional, consulte nossa documentação ou entre em contato com nossa equipe técnica.**
