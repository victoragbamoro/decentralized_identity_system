;; title: decentralized_identity

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-ALREADY-EXISTS (err u2))
(define-constant ERR-NOT-FOUND (err u3))
(define-constant ERR-INVALID-SIGNATURE (err u4))
(define-constant ERR-MAX-CONNECTIONS (err u5))

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
