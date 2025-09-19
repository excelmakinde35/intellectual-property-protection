;; ip-registration
;; Immutable registration system for intellectual property

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_IP (err u101))
(define-constant ERR_IP_EXISTS (err u102))

;; data vars
(define-data-var next-ip-id uint u1)
(define-data-var total-registrations uint u0)

;; data maps
(define-map ip-registry
    { ip-id: uint }
    {
        title: (string-ascii 256),
        description: (string-ascii 1024),
        owner: principal,
        ip-type: (string-ascii 64),
        created-at: uint,
        hash: (buff 32),
        is-active: bool
    }
)

(define-map owner-ips
    { owner: principal }
    { ip-count: uint, ips: (list 100 uint) }
)

;; public functions

;; Register new intellectual property
(define-public (register-ip
    (title (string-ascii 256))
    (description (string-ascii 1024))
    (ip-type (string-ascii 64))
    (content-hash (buff 32))
)
    (let (
        (ip-id (var-get next-ip-id))
        (current-block u1)
    )
        (asserts! (> (len title) u0) ERR_INVALID_IP)
        (asserts! (> (len description) u0) ERR_INVALID_IP)
        
        (map-set ip-registry { ip-id: ip-id }
            {
                title: title,
                description: description,
                owner: tx-sender,
                ip-type: ip-type,
                created-at: current-block,
                hash: content-hash,
                is-active: true
            }
        )
        
        (var-set next-ip-id (+ ip-id u1))
        (var-set total-registrations (+ (var-get total-registrations) u1))
        
        (ok ip-id)
    )
)

;; Transfer IP ownership
(define-public (transfer-ip (ip-id uint) (new-owner principal))
    (let (
        (ip-data (unwrap! (map-get? ip-registry { ip-id: ip-id }) ERR_INVALID_IP))
    )
        (asserts! (is-eq tx-sender (get owner ip-data)) ERR_UNAUTHORIZED)
        
        (map-set ip-registry { ip-id: ip-id }
            (merge ip-data { owner: new-owner })
        )
        
        (ok true)
    )
)

;; Get IP information
(define-read-only (get-ip-info (ip-id uint))
    (map-get? ip-registry { ip-id: ip-id })
)

;; Get platform statistics
(define-read-only (get-registration-stats)
    {
        total-registrations: (var-get total-registrations),
        next-ip-id: (var-get next-ip-id)
    }
)
