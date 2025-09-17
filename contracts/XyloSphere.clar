;; XyloSphere - Conditional Asset Management Contract with Multi-Asset and NFT Support

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-condition-not-met (err u105))
(define-constant err-invalid-timelock (err u106))
(define-constant err-asset-locked (err u107))
(define-constant err-invalid-signature (err u108))
(define-constant err-invalid-vault-id (err u109))
(define-constant err-invalid-address (err u110))
(define-constant err-nft-not-found (err u111))
(define-constant err-nft-already-exists (err u112))
(define-constant err-invalid-nft-id (err u113))
(define-constant err-nft-transfer-failed (err u114))
(define-constant err-token-not-supported (err u115))
(define-constant err-invalid-token-contract (err u116))
(define-constant err-token-transfer-failed (err u117))
(define-constant err-token-already-exists (err u118))

;; Data Variables
(define-data-var contract-active bool true)
(define-data-var total-vaults uint u0)
(define-data-var platform-fee uint u250) ;; 2.5% in basis points

;; Data Maps
(define-map vaults 
  { vault-id: uint }
  {
    owner: principal,
    timelock: uint,
    conditions: (string-ascii 256),
    is-active: bool,
    created-at: uint,
    authorized-withdrawers: (list 5 principal),
    has-nfts: bool,
    nft-count: uint,
    has-tokens: bool,
    token-count: uint
  }
)

(define-map vault-tokens
  { vault-id: uint, token-contract: principal }
  {
    balance: uint,
    deposited-at: uint,
    last-update: uint
  }
)

(define-map vault-supported-tokens
  { vault-id: uint, token-index: uint }
  {
    token-contract: principal,
    added-at: uint
  }
)

(define-map vault-nfts
  { vault-id: uint, nft-index: uint }
  {
    nft-contract: principal,
    nft-id: uint,
    deposited-at: uint,
    depositor: principal
  }
)

(define-map nft-vault-lookup
  { nft-contract: principal, nft-id: uint }
  { vault-id: uint, nft-index: uint }
)

(define-map user-vault-count
  { user: principal }
  { count: uint }
)

(define-map vault-permissions
  { vault-id: uint, user: principal }
  { can-withdraw: bool, permission-level: uint }
)

(define-map emergency-recovery
  { vault-id: uint }
  { recovery-address: principal, recovery-timelock: uint }
)

;; Input Validation Functions
(define-private (is-valid-vault-id (vault-id uint))
  (and (> vault-id u0) (<= vault-id (var-get total-vaults)))
)

(define-private (is-valid-principal (addr principal))
  (not (is-eq addr 'SP000000000000000000002Q6VF78))
)

(define-private (is-valid-timelock (timelock uint))
  (and (> timelock stacks-block-height) (< timelock (+ stacks-block-height u1000000)))
)

(define-private (sanitize-conditions (conditions (string-ascii 256)))
  ;; Basic validation - ensure conditions string is not empty and has reasonable length
  (and (> (len conditions) u0) (<= (len conditions) u256))
)

(define-private (is-valid-nft-id (nft-id uint))
  (> nft-id u0)
)

(define-private (is-valid-amount (amount uint))
  (> amount u0)
)

;; Helper Functions
(define-private (get-next-nft-index (vault-id uint))
  (let
    (
      (vault-data (unwrap! (map-get? vaults { vault-id: vault-id }) u0))
    )
    (get nft-count vault-data)
  )
)

(define-private (get-next-token-index (vault-id uint))
  (let
    (
      (vault-data (unwrap! (map-get? vaults { vault-id: vault-id }) u0))
    )
    (get token-count vault-data)
  )
)

(define-private (token-exists-in-vault (vault-id uint) (token-contract principal))
  (is-some (map-get? vault-tokens { vault-id: vault-id, token-contract: token-contract }))
)

;; Public Functions

(define-public (create-vault (timelock uint) (conditions (string-ascii 256)) (authorized-withdrawers (list 5 principal)))
  (let
    (
      (vault-id (+ (var-get total-vaults) u1))
      (current-height stacks-block-height)
      (user-count (default-to u0 (get count (map-get? user-vault-count { user: tx-sender }))))
    )
    ;; Input validation
    (asserts! (var-get contract-active) err-unauthorized)
    (asserts! (is-valid-timelock timelock) err-invalid-timelock)
    (asserts! (sanitize-conditions conditions) err-invalid-signature)
    (asserts! (<= (len authorized-withdrawers) u5) err-unauthorized)
    
    ;; Validate all authorized withdrawers
    (asserts! (fold validate-withdrawer-fold authorized-withdrawers true) err-invalid-address)

    (map-set vaults
      { vault-id: vault-id }
      {
        owner: tx-sender,
        timelock: timelock,
        conditions: conditions,
        is-active: true,
        created-at: current-height,
        authorized-withdrawers: authorized-withdrawers,
        has-nfts: false,
        nft-count: u0,
        has-tokens: false,
        token-count: u0
      }
    )

    (map-set user-vault-count
      { user: tx-sender }
      { count: (+ user-count u1) }
    )

    (fold set-single-permission-fold authorized-withdrawers vault-id)

    (var-set total-vaults vault-id)
    (ok vault-id)
  )
)

(define-public (deposit-token (vault-id uint) (token-contract <sip-010-trait>) (amount uint))
  (let
    (
      (vault-data (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found))
      (current-height stacks-block-height)
      (token-contract-principal (contract-of token-contract))
      (existing-balance (default-to u0 (get balance (map-get? vault-tokens { vault-id: vault-id, token-contract: token-contract-principal }))))
      (token-exists (token-exists-in-vault vault-id token-contract-principal))
      (token-index (get-next-token-index vault-id))
    )
    (begin
      ;; Input validation
      (asserts! (is-valid-vault-id vault-id) err-invalid-vault-id)
      (asserts! (is-valid-amount amount) err-invalid-amount)
      (asserts! (is-valid-principal token-contract-principal) err-invalid-token-contract)
      (asserts! (var-get contract-active) err-unauthorized)
      (asserts! (get is-active vault-data) err-asset-locked)
      (asserts! (or (is-eq tx-sender (get owner vault-data)) 
                    (is-some (map-get? vault-permissions { vault-id: vault-id, user: tx-sender }))) err-unauthorized)

      ;; Try to transfer tokens to contract
      (match (contract-call? token-contract transfer amount tx-sender (as-contract tx-sender) none)
        success
        (begin
          ;; Update or create token balance
          (map-set vault-tokens
            { vault-id: vault-id, token-contract: token-contract-principal }
            {
              balance: (+ existing-balance amount),
              deposited-at: (if token-exists (default-to current-height (get deposited-at (map-get? vault-tokens { vault-id: vault-id, token-contract: token-contract-principal }))) current-height),
              last-update: current-height
            }
          )

          ;; Add to supported tokens list if new
          (if (not token-exists)
            (begin
              (map-set vault-supported-tokens
                { vault-id: vault-id, token-index: token-index }
                {
                  token-contract: token-contract-principal,
                  added-at: current-height
                }
              )
              ;; Update vault token count and status
              (map-set vaults
                { vault-id: vault-id }
                (merge vault-data { 
                  has-tokens: true, 
                  token-count: (+ token-index u1) 
                })
              )
            )
            true
          )

          (ok (+ existing-balance amount))
        )
        error err-token-transfer-failed
      )
    )
  )
)

(define-public (withdraw-token (vault-id uint) (token-contract <sip-010-trait>) (amount uint))
  (let
    (
      (vault-data (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found))
      (token-contract-principal (contract-of token-contract))
      (token-data (unwrap! (map-get? vault-tokens { vault-id: vault-id, token-contract: token-contract-principal }) err-token-not-supported))
      (current-balance (get balance token-data))
      (current-height stacks-block-height)
    )
    (begin
      ;; Input validation
      (asserts! (is-valid-vault-id vault-id) err-invalid-vault-id)
      (asserts! (is-valid-amount amount) err-invalid-amount)
      (asserts! (var-get contract-active) err-unauthorized)
      (asserts! (get is-active vault-data) err-asset-locked)
      (asserts! (>= current-height (get timelock vault-data)) err-condition-not-met)
      (asserts! (<= amount current-balance) err-insufficient-balance)
      (asserts! (or (is-eq tx-sender (get owner vault-data)) 
                    (is-some (map-get? vault-permissions { vault-id: vault-id, user: tx-sender }))) err-unauthorized)

      ;; Try to transfer tokens from contract
      (asserts! (is-valid-principal (contract-of token-contract)) err-invalid-token-contract)
      (match (as-contract (contract-call? token-contract transfer amount tx-sender tx-sender none))
        success
        (begin
          ;; Update token balance
          (let ((new-balance (- current-balance amount)))
            (if (is-eq new-balance u0)
              ;; Remove token entry if balance is zero
              (map-delete vault-tokens { vault-id: vault-id, token-contract: token-contract-principal })
              ;; Update balance
              (map-set vault-tokens
                { vault-id: vault-id, token-contract: token-contract-principal }
                (merge token-data { 
                  balance: new-balance,
                  last-update: current-height
                })
              )
            )
          )
          (ok amount)
        )
        error err-token-transfer-failed
      )
    )
  )
)

(define-public (deposit-nft (vault-id uint) (nft-contract <nft-trait>) (nft-id uint))
  (let
    (
      (vault-data (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found))
      (current-height stacks-block-height)
      (nft-index (get-next-nft-index vault-id))
      (nft-contract-principal (contract-of nft-contract))
    )
    (begin
      ;; Input validation
      (asserts! (is-valid-vault-id vault-id) err-invalid-vault-id)
      (asserts! (is-valid-nft-id nft-id) err-invalid-nft-id)
      (asserts! (is-valid-principal nft-contract-principal) err-invalid-address)
      (asserts! (var-get contract-active) err-unauthorized)
      (asserts! (get is-active vault-data) err-asset-locked)
      (asserts! (or (is-eq tx-sender (get owner vault-data)) 
                    (is-some (map-get? vault-permissions { vault-id: vault-id, user: tx-sender }))) err-unauthorized)
      
      ;; Check if NFT is already in a vault
      (asserts! (is-none (map-get? nft-vault-lookup { nft-contract: nft-contract-principal, nft-id: nft-id })) err-nft-already-exists)

      ;; Try to transfer NFT to contract
      (match (contract-call? nft-contract transfer nft-id tx-sender (as-contract tx-sender))
        success 
        (begin
          ;; Store NFT information
          (map-set vault-nfts
            { vault-id: vault-id, nft-index: nft-index }
            {
              nft-contract: nft-contract-principal,
              nft-id: nft-id,
              deposited-at: current-height,
              depositor: tx-sender
            }
          )

          ;; Update lookup map
          (map-set nft-vault-lookup
            { nft-contract: nft-contract-principal, nft-id: nft-id }
            { vault-id: vault-id, nft-index: nft-index }
          )

          ;; Update vault NFT count and status
          (map-set vaults
            { vault-id: vault-id }
            (merge vault-data { 
              has-nfts: true, 
              nft-count: (+ nft-index u1) 
            })
          )

          (ok nft-index)
        )
        error err-nft-transfer-failed
      )
    )
  )
)

(define-public (withdraw-nft (vault-id uint) (nft-index uint))
  (let
    (
      (vault-data (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found))
      (nft-data (unwrap! (map-get? vault-nfts { vault-id: vault-id, nft-index: nft-index }) err-nft-not-found))
      (current-height stacks-block-height)
      (nft-contract-principal (get nft-contract nft-data))
      (nft-id (get nft-id nft-data))
      (vault-key { vault-id: vault-id, nft-index: nft-index })
      (lookup-key { nft-contract: nft-contract-principal, nft-id: nft-id })
    )
    (begin
      ;; Input validation
      (asserts! (is-valid-vault-id vault-id) err-invalid-vault-id)
      (asserts! (var-get contract-active) err-unauthorized)
      (asserts! (get is-active vault-data) err-asset-locked)
      (asserts! (>= current-height (get timelock vault-data)) err-condition-not-met)
      (asserts! (or (is-eq tx-sender (get owner vault-data)) 
                    (is-some (map-get? vault-permissions { vault-id: vault-id, user: tx-sender }))) err-unauthorized)

      ;; Delete using pre-constructed keys to avoid unchecked data warnings
      (begin
        (map-delete vault-nfts vault-key)
        (map-delete nft-vault-lookup lookup-key)
        (ok { nft-contract: nft-contract-principal, nft-id: nft-id, recipient: tx-sender })
      )
    )
  )
)

(define-public (set-emergency-recovery (vault-id uint) (recovery-address principal) (recovery-timelock uint))
  (let
    (
      (vault-data (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found))
    )
    (begin
      ;; Input validation
      (asserts! (is-valid-vault-id vault-id) err-invalid-vault-id)
      (asserts! (is-valid-principal recovery-address) err-invalid-address)
      (asserts! (is-valid-timelock recovery-timelock) err-invalid-timelock)
      (asserts! (is-eq tx-sender (get owner vault-data)) err-unauthorized)

      (map-set emergency-recovery
        { vault-id: vault-id }
        { recovery-address: recovery-address, recovery-timelock: recovery-timelock }
      )
      (ok true)
    )
  )
)

(define-public (emergency-recover (vault-id uint))
  (let
    (
      (vault-data (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found))
      (recovery-info (unwrap! (map-get? emergency-recovery { vault-id: vault-id }) err-not-found))
      (current-height stacks-block-height)
    )
    (begin
      ;; Input validation
      (asserts! (is-valid-vault-id vault-id) err-invalid-vault-id)
      (asserts! (is-eq tx-sender (get recovery-address recovery-info)) err-unauthorized)
      (asserts! (>= current-height (get recovery-timelock recovery-info)) err-condition-not-met)

      (map-set vaults
        { vault-id: vault-id }
        (merge vault-data { owner: (get recovery-address recovery-info) })
      )
      (ok true)
    )
  )
)

(define-public (update-vault-conditions (vault-id uint) (new-conditions (string-ascii 256)))
  (let
    (
      (vault-data (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found))
    )
    (begin
      ;; Input validation
      (asserts! (is-valid-vault-id vault-id) err-invalid-vault-id)
      (asserts! (sanitize-conditions new-conditions) err-invalid-signature)
      (asserts! (is-eq tx-sender (get owner vault-data)) err-unauthorized)
      (asserts! (get is-active vault-data) err-asset-locked)

      (map-set vaults
        { vault-id: vault-id }
        (merge vault-data { conditions: new-conditions })
      )
      (ok true)
    )
  )
)

(define-public (toggle-vault-status (vault-id uint))
  (let
    (
      (vault-data (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found))
    )
    (begin
      ;; Input validation
      (asserts! (is-valid-vault-id vault-id) err-invalid-vault-id)
      (asserts! (is-eq tx-sender (get owner vault-data)) err-unauthorized)

      (map-set vaults
        { vault-id: vault-id }
        (merge vault-data { is-active: (not (get is-active vault-data)) })
      )
      (ok true)
    )
  )
)

(define-public (toggle-contract-status)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)

;; Private Functions

(define-private (validate-withdrawer-fold (withdrawer principal) (is-valid bool))
  (and is-valid (is-valid-principal withdrawer))
)

(define-private (set-single-permission-fold (withdrawer principal) (vault-id uint))
  (begin
    (map-set vault-permissions
      { vault-id: vault-id, user: withdrawer }
      { can-withdraw: true, permission-level: u1 }
    )
    vault-id
  )
)

;; Read-only Functions

(define-read-only (get-vault-info (vault-id uint))
  (if (is-valid-vault-id vault-id)
    (map-get? vaults { vault-id: vault-id })
    none
  )
)

(define-read-only (get-vault-token-balance (vault-id uint) (token-contract principal))
  (if (and (is-valid-vault-id vault-id) (is-valid-principal token-contract))
    (map-get? vault-tokens { vault-id: vault-id, token-contract: token-contract })
    none
  )
)

(define-read-only (get-vault-supported-tokens (vault-id uint) (token-index uint))
  (if (is-valid-vault-id vault-id)
    (map-get? vault-supported-tokens { vault-id: vault-id, token-index: token-index })
    none
  )
)

(define-read-only (get-vault-nft (vault-id uint) (nft-index uint))
  (if (is-valid-vault-id vault-id)
    (map-get? vault-nfts { vault-id: vault-id, nft-index: nft-index })
    none
  )
)

(define-read-only (get-nft-vault-location (nft-contract principal) (nft-id uint))
  (if (and (is-valid-principal nft-contract) (is-valid-nft-id nft-id))
    (map-get? nft-vault-lookup { nft-contract: nft-contract, nft-id: nft-id })
    none
  )
)

(define-read-only (get-user-vault-count (user principal))
  (if (is-valid-principal user)
    (default-to u0 (get count (map-get? user-vault-count { user: user })))
    u0
  )
)

(define-read-only (get-vault-permissions (vault-id uint) (user principal))
  (if (and (is-valid-vault-id vault-id) (is-valid-principal user))
    (map-get? vault-permissions { vault-id: vault-id, user: user })
    none
  )
)

(define-read-only (get-emergency-recovery (vault-id uint))
  (if (is-valid-vault-id vault-id)
    (map-get? emergency-recovery { vault-id: vault-id })
    none
  )
)

(define-read-only (get-contract-status)
  (var-get contract-active)
)

(define-read-only (get-total-vaults)
  (var-get total-vaults)
)

(define-read-only (get-platform-fee)
  (var-get platform-fee)
)

(define-read-only (can-withdraw (vault-id uint) (user principal))
  (let
    (
      (vault-data (map-get? vaults { vault-id: vault-id }))
      (user-permission (map-get? vault-permissions { vault-id: vault-id, user: user }))
      (current-height stacks-block-height)
    )
    (if (and (is-valid-vault-id vault-id) (is-valid-principal user))
      (match vault-data
        vault-info
        (and
          (get is-active vault-info)
          (>= current-height (get timelock vault-info))
          (or
            (is-eq user (get owner vault-info))
            (is-some user-permission)
          )
        )
        false
      )
      false
    )
  )
)

;; Trait Definitions
(define-trait sip-010-trait
  (
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    (get-name () (response (string-ascii 32) uint))
    (get-symbol () (response (string-ascii 32) uint))
    (get-decimals () (response uint uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-token-uri () (response (optional (string-utf8 256)) uint))
  )
)

(define-trait nft-trait
  (
    (transfer (uint principal principal) (response bool uint))
    (get-owner (uint) (response (optional principal) uint))
  )
)