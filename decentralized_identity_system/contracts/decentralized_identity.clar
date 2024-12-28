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