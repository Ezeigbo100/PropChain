PropChain
=========

A comprehensive smart contract for managing a **Blockchain-Based Land Registry and Title Management System**, built on the **Clarity** smart contract language. This system provides a secure, transparent, and immutable record of property ownership, transfers, and administrative actions, featuring robust access controls and comprehensive audit trails.

* * * * *

📖 Table of Contents
--------------------

-   Features

-   Getting Started

-   Smart Contract Details

-   Private Functions

-   Key Functions

-   Error Codes

-   Administrative Roles

-   Usage Example

-   License

-   Contributing

* * * * *

✨ Features
----------

-   **Immutable Land Registry:** Securely register and track property ownership on the blockchain.

-   **Role-Based Access Control:** Differentiates between `CONTRACT_OWNER`, `REGISTRAR`, and `NOTARY` roles for secure administrative management.

-   **Comprehensive Metadata:** Stores detailed legal descriptions, property types, zoning, and tax IDs.

-   **Transfer History:** Maintains a complete audit trail of all property transfers for transparency and compliance.

-   **Property Status Management:** Uses status flags (`ACTIVE`, `PENDING`, `DISPUTED`, `FROZEN`) to manage the state of properties.

-   **Secure Validation:** Validates property coordinates, ownership, and administrative privileges before executing transactions.

-   **Administrative Controls:** The contract owner can add new administrators and pause the contract in case of an emergency.

* * * * *

🚀 Getting Started
------------------

To interact with this smart contract, you'll need a Stacks-compatible wallet and a development environment for Clarity, such as the Clarity Visual Studio Code extension or a local `clarity-cli` setup.

1.  **Deploy:** Deploy the `PropChain` contract to the Stacks blockchain.

2.  **Initialize:** Call the `initialize-contract` public function from the contract deployer's address to set up the initial `CONTRACT_OWNER` and `REGISTRAR` role.

3.  **Interact:** Begin using the public functions to register properties, manage transfers, and perform administrative actions.

* * * * *

🧠 Smart Contract Details
-------------------------

### Data Maps

-   `Properties`: A map storing core property information, including owner, registration block, status, value, coordinates, and area.

-   `PropertyMetadata`: Stores non-critical, descriptive information like legal descriptions and zoning.

-   `TransferHistory`: Logs every transfer, including `from`, `to`, `block`, and `notarized` status.

-   `Administrators`: Manages administrative roles and their active status.

### Data Variables

-   `next-property-id`: Tracks the next available unique ID for a new property.

-   `total-properties`: A count of all properties registered in the system.

-   `contract-paused`: A boolean flag to pause all public functions in an emergency.

* * * * *

🕵️ Private Functions
---------------------

Private functions are internal helper functions that cannot be called directly by users. They are used to perform validations and internal logic to ensure the integrity and security of the contract.

-   `is-valid-coordinates(lat, lng)`: A crucial validation function that checks if the provided latitude and longitude values are within a globally accepted range. This prevents the registration of properties with nonsensical or malicious location data.

-   `is-administrator(caller, required-role)`: Verifies if the calling address has the necessary administrative role to execute a specific function. This function enforces the contract's role-based access control.

-   `property-exists(property-id)`: A simple check to confirm if a property ID is already registered in the `Properties` map. This prevents the creation of duplicate properties and ensures data consistency.

* * * * *

🛠️ Key Functions
-----------------

### Public Functions

-   `initialize-contract()`: Sets up the initial administrator role for the contract deployer. Must be called once after deployment.

-   `register-property(...)`: Registers a new property with detailed metadata and assigns ownership to the caller. Requires the caller to have the `REGISTRAR` role.

-   `transfer-property(property-id, recipient)`: Transfers ownership of a property. Only the current owner can initiate a transfer.

-   `add-administrator(new-admin, role)`: Grants an administrative role (`REGISTRAR` or `NOTARY`) to a new principal. Can only be called by the `CONTRACT_OWNER`.

-   `comprehensive-property-audit(...)`: A comprehensive function for `REGISTRAR` and `NOTARY` roles to audit and verify a property, updating its value and creating a notarized audit trail.

### Read-Only Functions

-   `get-property-info(property-id)`: Retrieves core details for a given property ID.

-   `get-property-metadata(property-id)`: Retrieves descriptive metadata for a given property ID.

-   `verify-ownership(property-id, alleged-owner)`: Checks if a given principal is the current owner of a property.

* * * * *

🚫 Error Codes
--------------

-   `u100`: `ERR_UNAUTHORIZED` - Caller lacks the necessary permissions.

-   `u101`: `ERR_PROPERTY_EXISTS` - A property with this ID already exists (not used in current version).

-   `u102`: `ERR_PROPERTY_NOT_FOUND` - The specified property ID does not exist.

-   `u103`: `ERR_NOT_OWNER` - The caller is not the owner of the property.

-   `u104`: `ERR_INVALID_RECIPIENT` - The transfer recipient is invalid.

-   `u105`: `ERR_TRANSFER_RESTRICTED` - The property is not in an `ACTIVE` state and cannot be transferred.

-   `u106`: `ERR_INVALID_COORDINATES` - The latitude or longitude is outside the valid range.

-   `u107`: `ERR_INSUFFICIENT_PAYMENT` - The payment for a service (e.g., audit) is zero.

* * * * *

🧑‍💼 Administrative Roles
--------------------------

-   `CONTRACT_OWNER`: The deployer of the contract, who has ultimate control. Can add new administrators.

-   `REGISTRAR_ROLE` (`u1`): Can register new properties and perform comprehensive property audits.

-   `NOTARY_ROLE` (`u2`): A specific role that can participate in the `comprehensive-property-audit` function to provide verification.

* * * * *

💡 Usage Example
----------------

1.  **Initialize:** The contract deployer calls `(initialize-contract)`.

2.  **Add a Registrar:** The contract owner calls `(add-administrator 'ST2ZKEQ12X45... u1)` to add a new registrar.

3.  **Register a Property:** The new registrar calls `(register-property 40000000 74000000 5000 1500000000 "Legal description..." "Residential" "R-1" "1234567")`.

4.  **Transfer Ownership:** The registrar, who is also the owner of the new property, calls `(transfer-property u1 'ST1J2X45... )` to sell it to someone else.

* * * * *

📄 License
----------

This smart contract is licensed under the **MIT License**. See the `LICENSE` file for more details.

* * * * *

🤝 Contributing
---------------

Contributions are welcome! Please feel free to open an issue or submit a pull request if you find a bug or have a suggestion for an improvement.
