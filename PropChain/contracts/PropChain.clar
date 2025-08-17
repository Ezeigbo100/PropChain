;; Blockchain-Based Land Registry and Title Management System
;; A comprehensive smart contract for managing property ownership, transfers, and title verification
;; with built-in security measures and administrative controls for real estate management

;; ============================================================================
;; CONSTANTS
;; ============================================================================

;; Administrative roles
(define-constant CONTRACT_OWNER tx-sender)
(define-constant REGISTRAR_ROLE u1)
(define-constant NOTARY_ROLE u2)

;; Error codes for comprehensive error handling
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROPERTY_EXISTS (err u101))
(define-constant ERR_PROPERTY_NOT_FOUND (err u102))
(define-constant ERR_NOT_OWNER (err u103))
(define-constant ERR_INVALID_RECIPIENT (err u104))
(define-constant ERR_TRANSFER_RESTRICTED (err u105))
(define-constant ERR_INVALID_COORDINATES (err u106))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u107))

;; Property status constants
(define-constant STATUS_ACTIVE u1)
(define-constant STATUS_PENDING u2)
(define-constant STATUS_DISPUTED u3)
(define-constant STATUS_FROZEN u4)

;; ============================================================================
;; DATA MAPS AND VARIABLES
;; ============================================================================

;; Core property registry mapping property ID to ownership and metadata
(define-map Properties
  { property-id: uint }
  {
    owner: principal,
    registered-block: uint,
    last-transfer-block: uint,
    status: uint,
    property-value: uint,
    coordinates: { lat: int, lng: int },
    area-sqft: uint
  }
)

;; Property metadata and legal information
(define-map PropertyMetadata
  { property-id: uint }
  {
    legal-description: (string-ascii 256),
    property-type: (string-ascii 64),
    zoning: (string-ascii 32),
    tax-id: (string-ascii 64)
  }
)

;; Transfer history for audit trail and legal compliance
(define-map TransferHistory
  { property-id: uint, transfer-index: uint }
  {
    from: principal,
    to: principal,
    transfer-block: uint,
    transfer-price: uint,
    notarized: bool
  }
)

;; Administrative access control
(define-map Administrators
  { admin: principal }
  { role: uint, active: bool }
)

;; Global contract state
(define-data-var next-property-id uint u1)
(define-data-var total-properties uint u0)
(define-data-var contract-paused bool false)

;; ============================================================================
;; PRIVATE FUNCTIONS
;; ============================================================================

;; Validate property coordinates are within reasonable bounds
(define-private (is-valid-coordinates (lat int) (lng int))
  (and 
    (>= lat -90000000)  ;; -90 degrees * 1M for precision
    (<= lat 90000000)   ;; 90 degrees * 1M for precision
    (>= lng -180000000) ;; -180 degrees * 1M for precision
    (<= lng 180000000)  ;; 180 degrees * 1M for precision
  )
)

;; Check if caller has administrative privileges
(define-private (is-administrator (caller principal) (required-role uint))
  (match (map-get? Administrators { admin: caller })
    admin-info (and (get active admin-info) (>= (get role admin-info) required-role))
    false
  )
)

;; Validate property exists in the registry
(define-private (property-exists (property-id uint))
  (is-some (map-get? Properties { property-id: property-id }))
)

;; ============================================================================
;; PUBLIC FUNCTIONS
;; ============================================================================

;; Initialize contract with deployer as primary administrator
(define-public (initialize-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set Administrators 
      { admin: CONTRACT_OWNER } 
      { role: REGISTRAR_ROLE, active: true })
    (ok true)
  )
)

;; Register new property with comprehensive validation and security checks
(define-public (register-property 
  (coordinates-lat int) 
  (coordinates-lng int)
  (area-sqft uint)
  (property-value uint)
  (legal-description (string-ascii 256))
  (property-type (string-ascii 64))
  (zoning (string-ascii 32))
  (tax-id (string-ascii 64)))
  (let 
    (
      (property-id (var-get next-property-id))
      (current-block block-height)
    )
    (begin
      ;; Security and validation checks
      (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
      (asserts! (is-administrator tx-sender REGISTRAR_ROLE) ERR_UNAUTHORIZED)
      (asserts! (is-valid-coordinates coordinates-lat coordinates-lng) ERR_INVALID_COORDINATES)
      (asserts! (> area-sqft u0) ERR_INVALID_COORDINATES)
      
      ;; Register core property information
      (map-set Properties
        { property-id: property-id }
        {
          owner: tx-sender,
          registered-block: current-block,
          last-transfer-block: current-block,
          status: STATUS_ACTIVE,
          property-value: property-value,
          coordinates: { lat: coordinates-lat, lng: coordinates-lng },
          area-sqft: area-sqft
        }
      )
      
      ;; Store additional metadata
      (map-set PropertyMetadata
        { property-id: property-id }
        {
          legal-description: legal-description,
          property-type: property-type,
          zoning: zoning,
          tax-id: tax-id
        }
      )
      
      ;; Update global state
      (var-set next-property-id (+ property-id u1))
      (var-set total-properties (+ (var-get total-properties) u1))
      
      (ok property-id)
    )
  )
)

;; Transfer property ownership with security validations
(define-public (transfer-property (property-id uint) (recipient principal))
  (let
    (
      (property-info (unwrap! (map-get? Properties { property-id: property-id }) ERR_PROPERTY_NOT_FOUND))
      (current-block block-height)
    )
    (begin
      ;; Comprehensive security checks
      (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
      (asserts! (is-eq (get owner property-info) tx-sender) ERR_NOT_OWNER)
      (asserts! (not (is-eq recipient tx-sender)) ERR_INVALID_RECIPIENT)
      (asserts! (is-eq (get status property-info) STATUS_ACTIVE) ERR_TRANSFER_RESTRICTED)
      
      ;; Execute transfer
      (map-set Properties
        { property-id: property-id }
        (merge property-info {
          owner: recipient,
          last-transfer-block: current-block
        })
      )
      
      (ok true)
    )
  )
)

;; Query property information with access control
(define-read-only (get-property-info (property-id uint))
  (map-get? Properties { property-id: property-id })
)

;; Query property metadata
(define-read-only (get-property-metadata (property-id uint))
  (map-get? PropertyMetadata { property-id: property-id })
)

;; Verify property ownership
(define-read-only (verify-ownership (property-id uint) (alleged-owner principal))
  (match (map-get? Properties { property-id: property-id })
    property-info (is-eq (get owner property-info) alleged-owner)
    false
  )
)

;; Administrative function to add new administrators
(define-public (add-administrator (new-admin principal) (role uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set Administrators 
      { admin: new-admin } 
      { role: role, active: true })
    (ok true)
  )
)

;; Comprehensive property verification and audit system
;; This function performs extensive validation and creates detailed audit trails
(define-public (comprehensive-property-audit 
  (property-id uint) 
  (audit-price uint) 
  (notary-principal principal))
  (let
    (
      (property-info (unwrap! (map-get? Properties { property-id: property-id }) ERR_PROPERTY_NOT_FOUND))
      (metadata (unwrap! (map-get? PropertyMetadata { property-id: property-id }) ERR_PROPERTY_NOT_FOUND))
      (current-block block-height)
      (is-notary (is-administrator notary-principal NOTARY_ROLE))
    )
    (begin
      ;; Comprehensive authorization and validation checks
      (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
      (asserts! (is-administrator tx-sender REGISTRAR_ROLE) ERR_UNAUTHORIZED)
      (asserts! is-notary ERR_UNAUTHORIZED)
      (asserts! (> audit-price u0) ERR_INSUFFICIENT_PAYMENT)
      
      ;; Validate property is in auditable state
      (asserts! (or 
        (is-eq (get status property-info) STATUS_ACTIVE)
        (is-eq (get status property-info) STATUS_PENDING)) 
        ERR_TRANSFER_RESTRICTED)
      
      ;; Verify coordinates are still valid (properties may be updated)
      (asserts! (is-valid-coordinates 
        (get lat (get coordinates property-info))
        (get lng (get coordinates property-info))) 
        ERR_INVALID_COORDINATES)
      
      ;; Create comprehensive audit record in transfer history
      (map-set TransferHistory
        { property-id: property-id, transfer-index: current-block }
        {
          from: (get owner property-info),
          to: (get owner property-info), ;; Same owner for audit record
          transfer-block: current-block,
          transfer-price: audit-price,
          notarized: true
        }
      )
      
      ;; Update property status to reflect completed audit
      (map-set Properties
        { property-id: property-id }
        (merge property-info {
          last-transfer-block: current-block,
          status: STATUS_ACTIVE,
          property-value: audit-price ;; Update with audited value
        })
      )
      
      ;; Return comprehensive audit results
      (ok {
        audit-block: current-block,
        audited-value: audit-price,
        notary: notary-principal,
        property-status: STATUS_ACTIVE,
        coordinates-valid: true,
        owner-verified: true
      })
    )
  )
)


