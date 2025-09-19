;; licensing-royalties
;; Automated royalty distribution for licensed IP usage

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_INVALID_LICENSE (err u201))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u202))

;; data vars
(define-data-var next-license-id uint u1)
(define-data-var total-licenses uint u0)
(define-data-var platform-fee uint u250)

;; data maps
(define-map licenses
    { license-id: uint }
    {
        ip-id: uint,
        licensee: principal,
        licensor: principal,
        royalty-rate: uint,
        license-fee: uint,
        created-at: uint,
        expires-at: uint,
        is-active: bool
    }
)

(define-map royalty-payments
    { payment-id: uint }
    {
        license-id: uint,
        amount: uint,
        timestamp: uint,
        payer: principal
    }
)

(define-data-var next-payment-id uint u1)

;; public functions

;; Create IP license
(define-public (create-license
    (ip-id uint)
    (licensee principal)
    (royalty-rate uint)
    (license-fee uint)
    (duration-blocks uint)
)
    (let (
        (license-id (var-get next-license-id))
        (current-block u1)
        (expires-at (+ current-block duration-blocks))
    )
        (asserts! (> royalty-rate u0) ERR_INVALID_LICENSE)
        (asserts! (> duration-blocks u0) ERR_INVALID_LICENSE)
        
        (map-set licenses { license-id: license-id }
            {
                ip-id: ip-id,
                licensee: licensee,
                licensor: tx-sender,
                royalty-rate: royalty-rate,
                license-fee: license-fee,
                created-at: current-block,
                expires-at: expires-at,
                is-active: true
            }
        )
        
        (var-set next-license-id (+ license-id u1))
        (var-set total-licenses (+ (var-get total-licenses) u1))
        
        (ok license-id)
    )
)

;; Pay royalties
(define-public (pay-royalties (license-id uint) (amount uint))
    (let (
        (payment-id (var-get next-payment-id))
        (license-data (unwrap! (map-get? licenses { license-id: license-id }) ERR_INVALID_LICENSE))
    )
        (asserts! (get is-active license-data) ERR_INVALID_LICENSE)
        (asserts! (> amount u0) ERR_INSUFFICIENT_PAYMENT)
        
        (map-set royalty-payments { payment-id: payment-id }
            {
                license-id: license-id,
                amount: amount,
                timestamp: u1,
                payer: tx-sender
            }
        )
        
        (var-set next-payment-id (+ payment-id u1))
        
        (ok payment-id)
    )
)

;; Get license information
(define-read-only (get-license-info (license-id uint))
    (map-get? licenses { license-id: license-id })
)

;; Get payment information
(define-read-only (get-payment-info (payment-id uint))
    (map-get? royalty-payments { payment-id: payment-id })
)

;; Get platform statistics
(define-read-only (get-licensing-stats)
    {
        total-licenses: (var-get total-licenses),
        next-license-id: (var-get next-license-id),
        platform-fee: (var-get platform-fee)
    }
)
