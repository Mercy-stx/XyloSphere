# XyloSphere 🌐

> A decentralized platform for securely managing digital assets through flexible smart contracts on the Stacks blockchain.

## Overview

XyloSphere empowers users to create sophisticated, conditional asset management systems with multi-layered security protocols. Built on Stacks with Clarity smart contracts, it provides a trustless environment for managing digital assets with complex access controls, time-based conditions, and emergency recovery mechanisms.

## ✨ Key Features

### 🔐 **Conditional Asset Management**
- Create vaults with customizable conditions and timelock mechanisms
- Set multiple authorized withdrawers with granular permissions
- Implement complex business logic for asset access control

### 🛡️ **Multi-Layer Security**
- Permission-based withdrawal systems
- Emergency recovery protocols with separate timelock mechanisms
- Owner-controlled vault activation/deactivation

### ⚡ **Smart Contract Automation**
- Automated condition checking for withdrawals
- Time-based access controls using Stacks block height
- Comprehensive parameter validation and error handling

### 🎯 **User-Centric Design**
- Intuitive vault creation and management
- Real-time vault status monitoring
- Flexible permission management system

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://docs.hiro.so/clarinet) installed
- Basic understanding of Clarity smart contracts
- Stacks wallet for testing

### Installation

```bash
git clone https://github.com/yourusername/xylosphere.git
cd xylosphere
clarinet check
```

### Basic Usage

1. **Create a Vault**
   ```clarity
   (contract-call? .xylosphere create-vault 
     u1000000 ;; asset amount
     u144 ;; timelock (blocks)
     "Standard access conditions" ;; conditions
     (list 'SP1ABC...DEF 'SP2GHI...JKL) ;; authorized withdrawers
   )
   ```

2. **Withdraw from Vault**
   ```clarity
   (contract-call? .xylosphere withdraw-from-vault 
     u1 ;; vault-id
     u500000 ;; amount
   )
   ```

3. **Set Emergency Recovery**
   ```clarity
   (contract-call? .xylosphere set-emergency-recovery
     u1 ;; vault-id
     'SP3RECOVERY...ADDRESS ;; recovery address
     u1008 ;; recovery timelock
   )
   ```

## 📋 Contract Functions

### Public Functions
- `create-vault` - Create a new conditional vault
- `withdraw-from-vault` - Withdraw assets with condition checking
- `set-emergency-recovery` - Configure emergency recovery
- `emergency-recover` - Execute emergency recovery
- `update-vault-conditions` - Modify vault conditions
- `toggle-vault-status` - Activate/deactivate vault

### Read-Only Functions
- `get-vault-info` - Retrieve vault details
- `get-user-vault-count` - Get user's vault count
- `can-withdraw` - Check withdrawal eligibility
- `get-vault-permissions` - View user permissions

## 🧪 Testing

Run the test suite to ensure contract functionality:

```bash
clarinet test
```

## 🔧 Configuration

### Platform Settings
- **Platform Fee**: 2.5% (250 basis points)
- **Max Authorized Withdrawers**: 5 per vault
- **Condition String Length**: 256 characters max

### Error Codes
- `u100` - Owner only operation
- `u101` - Vault not found
- `u102` - Unauthorized access
- `u103` - Invalid amount
- `u104` - Insufficient balance
- `u105` - Condition not met
- `u106` - Invalid timelock
- `u107` - Asset locked
- `u108` - Invalid signature

## 🤝 Contributing

We welcome contributions! Please read our contributing guidelines and submit pull requests for any improvements.

## 🌟 Support

For support, questions, or feature requests:
- Open an issue on GitHub
- Join our community discussions
- Follow us for updates

