;; XyloSphere - Conditional Asset Management Contract

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

;; Data Variables
(define-data-var contract-active bool true)
(define-data-var total-vaults uint u0)
(define-data-var platform-fee uint u250) ;; 2.5% in basis points

;; Data Maps
(define-map vaults 
  { vault-id: uint }
  {
    owner: principal,
    asset-amount: uint,
    timelock: uint,
    conditions: (string-ascii 256),
    is-active: bool,
    created-at: uint,
    authorized-withdrawers: (list 5 principal)
  }
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

;; Public Functions

(define-public (create-vault (asset-amount uint) (timelock uint) (conditions (string-ascii 256)) (authorized-withdrawers (list 5 principal)))
  (let
    (
      (vault-id (+ (var-get total-vaults) u1))
      (current-height stacks-block-height)
      (user-count (default-to u0 (get count (map-get? user-vault-count { user: tx-sender }))))
    )
    (asserts! (var-get contract-active) err-unauthorized)
    (asserts! (> asset-amount u0) err-invalid-amount)
    (asserts! (> timelock current-height) err-invalid-timelock)
    (asserts! (<= (len authorized-withdrawers) u5) err-unauthorized)

    (map-set vaults
      { vault-id: vault-id }
      {
        owner: tx-sender,
        asset-amount: asset-amount,
        timelock: timelock,
        conditions: conditions,
        is-active: true,
        created-at: current-height,
        authorized-withdrawers: authorized-withdrawers
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

(define-public (withdraw-from-vault (vault-id uint) (amount uint))
  (let
    (
      (vault (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found))
      (current-height stacks-block-height)
      (user-permission (map-get? vault-permissions { vault-id: vault-id, user: tx-sender }))
    )
    (begin
      (asserts! (var-get contract-active) err-unauthorized)
      (asserts! (get is-active vault) err-asset-locked)
      (asserts! (>= current-height (get timelock vault)) err-condition-not-met)
      (asserts! (> amount u0) err-invalid-amount)
      (asserts! (<= amount (get asset-amount vault)) err-insufficient-balance)
      (asserts! (or (is-eq tx-sender (get owner vault)) (is-some user-permission)) err-unauthorized)

      (map-set vaults
        { vault-id: vault-id }
        (merge vault { asset-amount: (- (get asset-amount vault) amount) })
      )
      (ok amount)
    )
  )
)

(define-public (set-emergency-recovery (vault-id uint) (recovery-address principal) (recovery-timelock uint))
  (let
    (
      (vault (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found))
      (current-height stacks-block-height)
    )
    (begin
      (asserts! (is-eq tx-sender (get owner vault)) err-unauthorized)
      (asserts! (> recovery-timelock current-height) err-invalid-timelock)

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
      (vault (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found))
      (recovery-info (unwrap! (map-get? emergency-recovery { vault-id: vault-id }) err-not-found))
      (current-height stacks-block-height)
    )
    (begin
      (asserts! (is-eq tx-sender (get recovery-address recovery-info)) err-unauthorized)
      (asserts! (>= current-height (get recovery-timelock recovery-info)) err-condition-not-met)

      (map-set vaults
        { vault-id: vault-id }
        (merge vault { owner: (get recovery-address recovery-info) })
      )
      (ok true)
    )
  )
)

(define-public (update-vault-conditions (vault-id uint) (new-conditions (string-ascii 256)))
  (let
    (
      (vault (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found))
    )
    (begin
      (asserts! (is-eq tx-sender (get owner vault)) err-unauthorized)
      (asserts! (get is-active vault) err-asset-locked)

      (map-set vaults
        { vault-id: vault-id }
        (merge vault { conditions: new-conditions })
      )
      (ok true)
    )
  )
)

(define-public (toggle-vault-status (vault-id uint))
  (let
    (
      (vault (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found))
    )
    (begin
      (asserts! (is-eq tx-sender (get owner vault)) err-unauthorized)

      (map-set vaults
        { vault-id: vault-id }
        (merge vault { is-active: (not (get is-active vault)) })
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

(define-private (set-single-permission-fold (withdrawer principal) (vault-id uint))
  (begin
    (map-set vault-permissions
      { vault-id: vault-id, user: withdrawer }
      { can-withdraw: true, permission-level: u1 }
    )
    vault-id
  )
)

(define-private (set-single-permission (withdrawer principal) (vault-id uint))
  (begin
    (map-set vault-permissions
      { vault-id: vault-id, user: withdrawer }
      { can-withdraw: true, permission-level: u1 }
    )
    true
  )
)

;; Read-only Functions

(define-read-only (get-vault-info (vault-id uint))
  (map-get? vaults { vault-id: vault-id })
)

(define-read-only (get-user-vault-count (user principal))
  (default-to u0 (get count (map-get? user-vault-count { user: user })))
)

(define-read-only (get-vault-permissions (vault-id uint) (user principal))
  (map-get? vault-permissions { vault-id: vault-id, user: user })
)

(define-read-only (get-emergency-recovery (vault-id uint))
  (map-get? emergency-recovery { vault-id: vault-id })
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
      (vault (map-get? vaults { vault-id: vault-id }))
      (user-permission (map-get? vault-permissions { vault-id: vault-id, user: user }))
      (current-height stacks-block-height)
    )
    (match vault
      vault-data
      (and
        (get is-active vault-data)
        (>= current-height (get timelock vault-data))
        (or
          (is-eq user (get owner vault-data))
          (is-some user-permission)
        )
      )
      false
    )
  )
)
