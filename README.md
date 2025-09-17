# XyloSphere 🌐

> A decentralized platform for securely managing digital assets and NFT collections through flexible smart contracts on the Stacks blockchain.

## Overview

XyloSphere empowers users to create sophisticated, conditional asset management systems with multi-layered security protocols. Built on Stacks with Clarity smart contracts, it provides a trustless environment for managing multiple fungible tokens and NFT collections with complex access controls, time-based conditions, and emergency recovery mechanisms.

## ✨ Key Features

### 🔐 **Conditional Asset Management**
- Create vaults with customizable conditions and timelock mechanisms
- Set multiple authorized withdrawers with granular permissions
- Implement complex business logic for asset access control

### 💰 **Multi-Asset Token Support**
- Store and manage multiple fungible token types within a single vault
- Support for any SIP-010 compliant token contract
- Independent balance tracking for each token type
- Flexible deposit and withdrawal for different assets

### 🎨 **NFT Collection Management**
- Store and manage NFT collections securely within vaults
- Support for any Stacks-compatible NFT contract
- Individual NFT deposit and withdrawal with proper access controls
- NFT location tracking and vault association

### 🛡️ **Multi-Layer Security**
- Permission-based withdrawal systems for all asset types
- Emergency recovery protocols with separate timelock mechanisms
- Owner-controlled vault activation/deactivation
- Comprehensive input validation and error handling

### ⚡ **Smart Contract Automation**
- Automated condition checking for withdrawals
- Time-based access controls using Stacks block height
- Comprehensive parameter validation and error handling
- Multi-asset transfer validation and state management

### 🎯 **User-Centric Design**
- Intuitive vault creation and management
- Real-time vault status monitoring with complete asset inventory
- Flexible permission management system for all asset types
- Multi-token balance tracking and reporting

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://docs.hiro.so/clarinet) installed
- Basic understanding of Clarity smart contracts
- Stacks wallet for testing
- SIP-010 compliant token contracts for testing
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
     u144 ;; timelock (blocks)
     "Multi-asset vault conditions" ;; conditions
     (list 'SP1ABC...DEF 'SP2GHI...JKL) ;; authorized withdrawers
   )
   ```

2. **Deposit Fungible Tokens**
   ```clarity
   (contract-call? .xylosphere deposit-token 
     u1 ;; vault-id
     .my-token-contract ;; token contract
     u1000000 ;; amount
   )
   ```

3. **Deposit NFT to Vault**
   ```clarity
   (contract-call? .xylosphere deposit-nft 
     u1 ;; vault-id
     .my-nft-contract ;; NFT contract
     u42 ;; NFT ID
   )
   ```

4. **Withdraw Tokens from Vault**
   ```clarity
   (contract-call? .xylosphere withdraw-token
     u1 ;; vault-id
     .my-token-contract ;; token contract
     u500000 ;; amount
   )
   ```

5. **Withdraw NFT from Vault**
   ```clarity
   (contract-call? .xylosphere withdraw-nft 
     u1 ;; vault-id
     u0 ;; nft-index in vault
   )
   ;; Returns: {nft-contract: principal, nft-id: uint, recipient: principal}
   ;; User must then call the NFT contract directly to complete transfer
   ```

6. **Set Emergency Recovery**
   ```clarity
   (contract-call? .xylosphere set-emergency-recovery
     u1 ;; vault-id
     'SP3RECOVERY...ADDRESS ;; recovery address
     u1008 ;; recovery timelock
   )
   ```

## 📋 Contract Functions

### Public Functions
- `create-vault` - Create a new conditional vault (multi-asset ready)
- `deposit-token` - Deposit fungible tokens into vault
- `deposit-nft` - Deposit NFT into vault with validation
- `withdraw-token` - Withdraw specific fungible tokens from vault
- `withdraw-nft` - Withdraw specific NFT from vault
- `set-emergency-recovery` - Configure emergency recovery
- `emergency-recover` - Execute emergency recovery
- `update-vault-conditions` - Modify vault conditions
- `toggle-vault-status` - Activate/deactivate vault

### Read-Only Functions
- `get-vault-info` - Retrieve vault details including asset counts
- `get-vault-token-balance` - Get specific token balance in vault
- `get-vault-supported-tokens` - List all token types in vault
- `get-vault-nft` - Get specific NFT information in vault
- `get-nft-vault-location` - Find which vault contains an NFT
- `get-user-vault-count` - Get user's vault count
- `can-withdraw` - Check withdrawal eligibility
- `get-vault-permissions` - View user permissions

## 💰 Multi-Asset Token Features

### Supported Operations
- **Deposit**: Transfer multiple token types into vault custody
- **Withdraw**: Retrieve specific token amounts with proper authorization
- **Balance Tracking**: Monitor individual token balances per vault
- **Token Discovery**: List all supported token types within a vault

### Token Storage Structure
- Each vault tracks supported token contracts and balances
- Independent balance management for each token type
- Comprehensive token validation and transfer handling
- Support for any SIP-010 compliant token contract

### Security Features
- Validates token contract compliance before deposit
- Prevents invalid token operations
- Ensures proper transfer execution with comprehensive error handling
- Maintains consistent state across all multi-asset operations

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
- Multi-asset vault operations
- Token deposit and withdrawal flows
- NFT deposit and withdrawal flows
- Permission management
- Error conditions and edge cases
- Emergency recovery scenarios

## 🔧 Configuration

### Platform Settings
- **Platform Fee**: 2.5% (250 basis points)
- **Max Authorized Withdrawers**: 5 per vault
- **Condition String Length**: 256 characters max
- **Max Tokens per Vault**: Unlimited (gas-limited)
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
- `u115` - Token not supported
- `u116` - Invalid token contract
- `u117` - Token transfer failed
- `u118` - Token already exists in vault

## 🏗️ Architecture

### Core Components
1. **Vault Management**: Create and manage conditional multi-asset vaults
2. **Token Storage**: Handle multiple fungible token types with independent tracking
3. **NFT Storage**: Full NFT lifecycle management
4. **Permission System**: Control access to all vault operations
5. **Emergency Recovery**: Backup access mechanisms
6. **Multi-Asset Integration**: Comprehensive multi-token and NFT management

### Data Structures
- `vaults`: Core vault information with asset tracking
- `vault-tokens`: Individual token balance tracking
- `vault-supported-tokens`: Token type registry per vault
- `vault-nfts`: Individual NFT storage and metadata
- `nft-vault-lookup`: Bidirectional NFT-to-vault mapping
- `vault-permissions`: User access control
- `emergency-recovery`: Backup recovery settings

## 🤝 Contributing

We welcome contributions! Please read our contributing guidelines and submit pull requests for any improvements.

Areas for contribution:
- Additional token standards support
- Advanced condition types
- UI/UX improvements
- Security enhancements
- Gas optimization
- Multi-asset analytics

## 🌟 Support

For support, questions, or feature requests:
- Open an issue on GitHub
- Join our community discussions
- Follow us for updates

**XyloSphere** - Secure, flexible, and comprehensive multi-asset digital asset management on Stacks blockchain.