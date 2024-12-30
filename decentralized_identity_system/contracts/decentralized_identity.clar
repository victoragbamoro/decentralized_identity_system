;; title: decentralized_identity

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-ALREADY-EXISTS (err u2))
(define-constant ERR-NOT-FOUND (err u3))
(define-constant ERR-INVALID-SIGNATURE (err u4))
(define-constant ERR-MAX-CONNECTIONS (err u5))

(define-constant ERR-INSUFFICIENT-REPUTATION (err u6))
(define-constant ERR-CLAIM-ALREADY-EXISTS (err u7))
(define-constant MAX-REPUTATION-SCORE u1000)

;; DID Registry Map
(define-map did-registry 
  { did: principal }
  { 
    did-document: (string-utf8 1000),
    verified: bool,
    creation-timestamp: uint,
    reputation-score: uint,
    social-connections: (list 10 principal)
  }
)

;; Verification Claims Map
(define-map verification-claims
  { 
    did: principal, 
    claim-type: (string-ascii 50) 
  }
  {
    verified: bool,
    issuer: principal,
    timestamp: uint,
    claim-details: (string-utf8 500)
  }
)

;; Update DID Document
(define-public (update-did-document 
  (new-did-doc (string-utf8 1000))
)
  (begin
    (asserts! 
      (is-some (map-get? did-registry { did: tx-sender })) 
      ERR-NOT-FOUND
    )
    (map-set did-registry 
      { did: tx-sender }
      (merge 
        (unwrap! 
          (map-get? did-registry { did: tx-sender }) 
          ERR-NOT-FOUND
        )
        { did-document: new-did-doc }
      )
    )
    (ok true)
  )
)

;; Add Verification Claim
(define-public (add-verification-claim
  (claim-type (string-ascii 50))
  (claim-details (string-utf8 500))
)
  (begin
    (asserts! 
      (is-some (map-get? did-registry { did: tx-sender })) 
      ERR-NOT-FOUND
    )
    (map-set verification-claims
      { 
        did: tx-sender, 
        claim-type: claim-type 
      }
      {
        verified: true,
        issuer: tx-sender,
        timestamp: stacks-block-height,
        claim-details: claim-details
      }
    )
    (ok true)
  )
)

;; Update Reputation Score
(define-public (update-reputation-score
  (points-to-add uint)
)
  (let 
    ((current-did (unwrap! 
      (map-get? did-registry { did: tx-sender }) 
      ERR-NOT-FOUND
    ))
     (new-score (+ 
       (get reputation-score current-did) 
       points-to-add
     ))
    )
    (map-set did-registry 
      { did: tx-sender }
      (merge current-did { reputation-score: new-score })
    )
    (ok new-score)
  )
)

;; Add Social Connection
(define-public (add-social-connection
  (connection-did principal)
)
  (let 
    ((current-did (unwrap! 
      (map-get? did-registry { did: tx-sender }) 
      ERR-NOT-FOUND
    ))
     (current-connections (get social-connections current-did))
     (updated-connections 
       (unwrap! 
         (as-max-len? 
           (append current-connections connection-did) 
           u10
         )
         ERR-MAX-CONNECTIONS
       )
    )
  )
    (map-set did-registry 
      { did: tx-sender }
      (merge current-did { social-connections: updated-connections })
    )
    (ok true)
  )
)


;; Read-only Functions
(define-read-only (get-did-info (did principal))
  (map-get? did-registry { did: did })
)

(define-read-only (get-verification-claim 
  (did principal)
  (claim-type (string-ascii 50))
)
  (map-get? verification-claims 
    { 
      did: did, 
      claim-type: claim-type 
    }
  )
)

;; Validate Bitcoin Signature (Placeholder)
(define-private (validate-bitcoin-signature 
  (signature (buff 256))
)
  (begin
    (asserts! (> (len signature) u0) ERR-INVALID-SIGNATURE)
    (ok true)
  )
)

;; Admin Function to Verify DID
(define-public (admin-verify-did
  (did principal)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (map-set did-registry 
      { did: did }
      (merge 
        (unwrap! 
          (map-get? did-registry { did: did }) 
          ERR-NOT-FOUND
        )
        { verified: true }
      )
    )
    (ok true)
  )
)

(define-map did-badges
  { 
    did: principal, 
    badge-type: (string-ascii 50) 
  }
  {
    earned-timestamp: uint,
    badge-level: uint
  }
)

(define-map did-achievements
  { 
    did: principal 
  }
  {
    total-achievements: uint,
    achievement-points: uint
  }
)

;; Badge System
(define-public (earn-badge
  (badge-type (string-ascii 50))
  (badge-level uint)
)
  (let 
    ((current-did (unwrap! 
      (map-get? did-registry { did: tx-sender }) 
      ERR-NOT-FOUND
    ))
     (current-reputation (get reputation-score current-did))
    )
    (asserts! (>= current-reputation (* badge-level u10)) ERR-INSUFFICIENT-REPUTATION)
    
    (map-set did-badges
      { 
        did: tx-sender, 
        badge-type: badge-type 
      }
      {
        earned-timestamp: stacks-block-height,
        badge-level: badge-level
      }
    )
    (ok true)
  )
)


;; Achievement Tracking
(define-public (log-achievement
  (achievement-points uint)
)
  (let 
    ((current-achievements 
      (default-to 
        { total-achievements: u0, achievement-points: u0 }
        (map-get? did-achievements { did: tx-sender })
      ))
     (updated-achievements 
      {
        total-achievements: (+ (get total-achievements current-achievements) u1),
        achievement-points: (+ (get achievement-points current-achievements) achievement-points)
      }
    ))
    (map-set did-achievements 
      { did: tx-sender }
      updated-achievements
    )
    (try! (update-reputation-score achievement-points))
    (ok true)
  )
)

;; Reputation Decay Mechanism
(define-public (apply-reputation-decay)
  (let 
    ((current-did (unwrap! 
      (map-get? did-registry { did: tx-sender }) 
      ERR-NOT-FOUND
    ))
     (current-score (get reputation-score current-did))
     (decayed-score 
       (if (> current-score u10) 
           (- current-score u10) 
           u0
       )
    )
  )
    (map-set did-registry 
      { did: tx-sender }
      (merge current-did { reputation-score: decayed-score })
    )
    (ok decayed-score)
  )
)

;; Read-only Functions
(define-read-only (get-did-badges 
  (did principal)
  (badge-type (string-ascii 50))
)
  (map-get? did-badges 
    { 
      did: did, 
      badge-type: badge-type 
    }
  )
)

(define-read-only (get-did-achievements (did principal))
  (map-get? did-achievements { did: did })
)

;; New Admin Function: Revoke Badge
(define-public (admin-revoke-badge
  (did principal)
  (badge-type (string-ascii 50))
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (map-delete did-badges 
      { 
        did: did, 
        badge-type: badge-type 
      }
    )
    (ok true)
  )
)
