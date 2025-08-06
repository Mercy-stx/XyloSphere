# XyloSphere 🌐

> A decentralized platform for securely managing digital assets and NFT collections through flexible smart contracts on the Stacks blockchain.

## Overview

XyloSphere empowers users to create sophisticated, conditional asset management systems with multi-layered security protocols. Built on Stacks with Clarity smart contracts, it provides a trustless environment for managing both fungible tokens and NFT collections with complex access controls, time-based conditions, and emergency recovery mechanisms.

## ✨ Key Features

### 🔐 **Conditional Asset Management**
- Create vaults with customizable conditions and timelock mechanisms
- Set multiple authorized withdrawers with granular permissions
- Implement complex business logic for asset access control

### 🎨 **NFT Collection Management**
- Store and manage NFT collections securely within vaults
- Support for any Stacks-compatible NFT contract
- Individual NFT deposit and withdrawal with proper access controls
- NFT location tracking and vault association

### 🛡️ **Multi-Layer Security**
- Permission-based withdrawal systems for both tokens and NFTs
- Emergency recovery protocols with separate timelock mechanisms
- Owner-controlled vault activation/deactivation

### ⚡ **Smart Contract Automation**
- Automated condition checking for withdrawals
- Time-based access controls using Stacks block height
- Comprehensive parameter validation and error handling
- NFT transfer validation and state management

### 🎯 **User-Centric Design**
- Intuitive vault creation and management
- Real-time vault status monitoring with NFT inventory
- Flexible permission management system for all asset types

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://docs.hiro.so/clarinet) installed
- Basic understanding of Clarity smart contracts
- Stacks wallet for testing
- NFT contracts for testing NFT functionality

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

2. **Deposit NFT to Vault**
   ```clarity
   (contract-call? .xylosphere deposit-nft 
     u1 ;; vault-id
     .my-nft-contract ;; NFT contract
     u42 ;; NFT ID
   )
   ```

3. **Withdraw NFT from Vault**
   ```clarity
   (contract-call? .xylosphere withdraw-nft 
     u1 ;; vault-id
     u0 ;; nft-index in vault
   )
   ;; Returns: {nft-contract: principal, nft-id: uint, recipient: principal}
   ;; User must then call the NFT contract directly to complete transfer
   ```

4. **Withdraw Tokens from Vault**
   ```clarity
   (contract-call? .xylosphere withdraw-from-vault 
     u1 ;; vault-id
     u500000 ;; amount
   )
   ```

5. **Set Emergency Recovery**
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
- `deposit-nft` - Deposit NFT into vault with validation
- `withdraw-nft` - Withdraw specific NFT from vault
- `withdraw-from-vault` - Withdraw fungible assets with condition checking
- `set-emergency-recovery` - Configure emergency recovery
- `emergency-recover` - Execute emergency recovery
- `update-vault-conditions` - Modify vault conditions
- `toggle-vault-status` - Activate/deactivate vault

### Read-Only Functions
- `get-vault-info` - Retrieve vault details including NFT count
- `get-vault-nft` - Get specific NFT information in vault
- `get-nft-vault-location` - Find which vault contains an NFT
- `get-user-vault-count` - Get user's vault count
- `can-withdraw` - Check withdrawal eligibility
- `get-vault-permissions` - View user permissions

## 🎨 NFT Integration Features

### Supported Operations
- **Deposit**: Securely transfer NFTs into vault custody
- **Withdraw**: Retrieve NFTs with proper authorization
- **Tracking**: Monitor NFT locations and vault associations
- **Permissions**: Same access control system as fungible tokens

### NFT Storage Structure
- Each vault tracks its NFT count and status
- Individual NFT metadata stored with deposit information
- Bidirectional lookup between NFTs and their vault locations
- Support for any Stacks NFT contract implementing the standard trait

### Security Features
- Prevents double-deposit of the same NFT
- Validates NFT ownership before deposit
- Ensures proper transfer execution with error handling
- Maintains consistent state across all operations

## 🧪 Testing

Run the test suite to ensure contract functionality:

```bash
clarinet test
```

Test coverage includes:
- Basic vault operations
- NFT deposit and withdrawal flows
- Permission management
- Error conditions and edge cases
- Emergency recovery scenarios

## 🔧 Configuration

### Platform Settings
- **Platform Fee**: 2.5% (250 basis points)
- **Max Authorized Withdrawers**: 5 per vault
- **Condition String Length**: 256 characters max
- **Max NFTs per Vault**: Unlimited (gas-limited)

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
- `u109` - Invalid vault ID
- `u110` - Invalid address
- `u111` - NFT not found
- `u112` - NFT already exists in vault
- `u113` - Invalid NFT ID
- `u114` - NFT transfer failed

## 🏗️ Architecture

### Core Components
1. **Vault Management**: Create and manage conditional vaults
2. **Asset Storage**: Handle both fungible tokens and NFTs
3. **Permission System**: Control access to vault operations
4. **Emergency Recovery**: Backup access mechanisms
5. **NFT Integration**: Full NFT lifecycle management

### Data Structures
- `vaults`: Core vault information with NFT tracking
- `vault-nfts`: Individual NFT storage and metadata
- `nft-vault-lookup`: Bidirectional NFT-to-vault mapping
- `vault-permissions`: User access control
- `emergency-recovery`: Backup recovery settings

## 🤝 Contributing

We welcome contributions! Please read our contributing guidelines and submit pull requests for any improvements.

Areas for contribution:
- Additional NFT standards support
- Advanced condition types
- UI/UX improvements
- Security enhancements
- Gas optimization

## 🌟 Support

For support, questions, or feature requests:
- Open an issue on GitHub
- Join our community discussions
- Follow us for updates

**XyloSphere** - Secure, flexible, and comprehensive digital asset management on Stacks blockchain.