;; Define SIP-009 NFT Trait
(define-trait digital-asset-trait
    (
        ;; Transfer token to a specified principal
        (transfer (uint principal principal) (response bool uint))

        ;; Get the owner of the specified token ID
        (get-owner (uint) (response (optional principal) uint))

        ;; Get the last token ID
        (get-last-token-id () (response uint uint))

        ;; Get the token URI
        (get-token-uri (uint) (response (optional (string-utf8 256)) uint))
    )
)

;; Constants
(define-constant protocol-admin tx-sender)
(define-constant err-admin-only (err u100))
(define-constant err-not-asset-owner (err u101))
(define-constant err-asset-not-found (err u102))
(define-constant err-sale-not-found (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-exchange-paused (err u106))

;; Data Variables
(define-data-var asset-counter uint u0)
(define-data-var exchange-paused bool false)
(define-data-var exchange-fee uint u250) ;; 2.5% fee (basis points)

;; Define the NFT
(define-non-fungible-token premium-asset uint)

;; Data Maps
(define-map asset-metadata 
    uint 
    {
        owner: principal,
        metadata-url: (string-utf8 256),
        creator: principal
    }
)

(define-map asset-sales 
    uint 
    {
        price: uint,
        seller: principal,
        expiry: uint
    }
)

;; Private Functions
(define-private (is-owner (asset-id uint))
    (match (map-get? asset-metadata asset-id)
        asset-info (is-eq tx-sender (get owner asset-info))
        false
    )    
)

(define-private (transfer-asset (asset-id uint) (sender principal) (recipient principal))
    (let (
        (asset-data (map-get? asset-metadata asset-id))
    )
        (asserts! (is-some asset-data) err-asset-not-found)
        (try! (nft-transfer? premium-asset asset-id sender recipient))
        (map-set asset-metadata asset-id 
            (merge (unwrap-panic asset-data)
                   {owner: recipient}))
        (ok true)
    )
)

(define-private (calculate-fee (amount uint))
    (/ (* amount (var-get exchange-fee)) u10000)
)

;; Public Functions

;; SIP009: Transfer token
(define-public (transfer (asset-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (not (var-get exchange-paused)) err-exchange-paused)
        (asserts! (is-eq tx-sender sender) err-not-asset-owner)
        (asserts! (is-owner asset-id) err-not-asset-owner)
        ;; Ensure the recipient is not the contract owner (optional safety check)
        (asserts! (not (is-eq recipient protocol-admin)) (err u999)) ;; Custom error for invalid recipient
        (transfer-asset asset-id sender recipient)
    )
)

;; NFT Core Functions
(define-public (mint (metadata-url (string-utf8 256)))
    (let
        ((asset-id (+ (var-get asset-counter) u1)))
        (asserts! (not (var-get exchange-paused)) err-exchange-paused)
        ;; Ensure metadata-url is not empty
        (asserts! (> (len metadata-url) u0) (err u998)) ;; Add custom error for empty metadata-url
        (try! (nft-mint? premium-asset asset-id tx-sender))
        (map-set asset-metadata asset-id 
            {
                owner: tx-sender,
                metadata-url: metadata-url,
                creator: tx-sender
            })
        (var-set asset-counter asset-id)
        (ok asset-id))
)

;; Marketplace Functions
(define-public (list-asset (asset-id uint) (price uint) (expiry uint))
    (begin
        (asserts! (not (var-get exchange-paused)) err-exchange-paused)
        (asserts! (> price u0) err-invalid-amount)
        (asserts! (is-owner asset-id) err-not-asset-owner)
        ;; Ensure expiry is a future block height
        (asserts! (> expiry u0) (err u997)) ;; Add custom error for invalid expiry
        (map-set asset-sales asset-id 
            {
                price: price,
                seller: tx-sender,
                expiry: (+ block-height expiry)
            })
        (ok true))
)

(define-public (unlist-asset (asset-id uint))
    (begin
        (asserts! (not (var-get exchange-paused)) err-exchange-paused)
        (asserts! (is-owner asset-id) err-not-asset-owner)
        (map-delete asset-sales asset-id)
        (ok true))
)

(define-public (buy-asset (asset-id uint))
    (let
        (
            (sale (unwrap! (map-get? asset-sales asset-id) err-sale-not-found))
            (price (get price sale))
            (seller (get seller sale))
            (expiry (get expiry sale))
        )
        (asserts! (not (var-get exchange-paused)) err-exchange-paused)
        (asserts! (<= block-height expiry) err-sale-not-found)
        (asserts! (>= (stx-get-balance tx-sender) price) err-insufficient-balance)
        (let
            (
                (fee (calculate-fee price))
                (seller-amount (- price fee))
            )
            (try! (stx-transfer? seller-amount tx-sender seller))
            (try! (stx-transfer? fee tx-sender protocol-admin))
            (try! (transfer-asset asset-id seller tx-sender))
            (map-delete asset-sales asset-id)
            (ok true)))
)

;; Read-only Functions
(define-read-only (get-asset-metadata (asset-id uint))
    (map-get? asset-metadata asset-id)
)

(define-read-only (get-asset-sale (asset-id uint))
    (map-get? asset-sales asset-id)
)

;; SIP009: Get the owner of the specified token ID
(define-read-only (get-owner (asset-id uint))
    (match (map-get? asset-metadata asset-id)
        asset-data (ok (some (get owner asset-data)))
        (ok none)
    )
)

;; SIP009: Get the last token ID
(define-read-only (get-last-token-id)
    (ok (var-get asset-counter))
)

;; SIP009: Get the token URI
(define-read-only (get-token-uri (asset-id uint))
    (match (map-get? asset-metadata asset-id)
        asset-data (ok (some (get metadata-url asset-data)))
        (ok none)
    )
)

;; Admin Functions
(define-public (set-exchange-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender protocol-admin) err-admin-only)
        (asserts! (<= new-fee u1000) err-invalid-amount) ;; Max 10% fee
        (var-set exchange-fee new-fee)
        (ok true))
)

(define-public (toggle-exchange-pause)
    (begin
        (asserts! (is-eq tx-sender protocol-admin) err-admin-only)
        (var-set exchange-paused (not (var-get exchange-paused)))
        (ok true))
)

(define-public (update-expiry (asset-id uint) (new-expiry uint))
    (let
        ((sale (unwrap! (map-get? asset-sales asset-id) err-sale-not-found)))
        (asserts! (is-eq tx-sender (get seller sale)) err-not-asset-owner)
        (map-set asset-sales asset-id 
            (merge sale {expiry: (+ block-height new-expiry)}))
        (ok true))
)