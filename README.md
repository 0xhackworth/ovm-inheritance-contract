# VITE: Validator Inheritance & Trust Executor

## Obol Builder Blitz Submission

**Developer:** hackworth.eth ([@0xhackworth](https://github.com/0xhackworth))

**UNAUDITED AND MINIMALLY TESTED**
**DO NOT USE ON MAINNET**
---

### **TL;DR: What This Is**

VITE (Validator Inheritance & Trust Executor) is a smart contract system that uses the Obol Validator Manager (OVM) to create an on-chain inheritance plan for a staking validator. It solves the real-world problem of what happens to a solo staker's assets when they're no longer around to manage them.

The system works by making a simple, time-locked "dead man's switch" contract (`VITE`) the legal owner of the OVM. As the beneficial owner, I retain day-to-day operational control. However, if I fail to send a routine `checkIn()` transaction within a set period, a designated heir is automatically empowered to take full and final ownership of the validator—not just the rewards, but all administrative rights. This prevents the validator from becoming a "zombie" asset, bleeding value on the network.

### **The Problem I'm Solving**

The current methods for passing on crypto assets are a mess of legal ambiguity and security risks, relying on trusting someone with your private keys after you're gone. For a productive asset like a validator, this is a critical failure point. An unmanaged validator doesn't just sit idle; it gets penalized and can be a total loss.

The OVM's programmability offers a chance to replace fragile, off-chain promises with on-chain, cryptographic certainty. My goal was to build a practical tool that does exactly that.

### **The Architecture: How It Works**

Getting this to work required some significant debugging, particularly in understanding the specific OVM version deployed on the testnet. The final, working architecture is a deliberate sequence of on-chain actions:

1.  **Deploy the OVM:** First, I deploy the OVM. This contract becomes the central hub for all validator management.

2.  **Deploy the VITE Custodian:** Next, I deploy my `VITE` contract. It's initialized with my address as the `beneficialOwner` and my designated `heir`'s address.

3.  **The Ownership Handover:** I call `transferOwnership` on the OVM to nominate the VITE contract as the new owner. Then, I call a function on the VITE contract (`acceptOVMOwnership`) which makes it accept the nomination. At this point, the VITE contract is the OVM's legal owner.

4.  **Grant Myself Operational Roles:** With VITE as the owner, my personal wallet is now powerless to administer the validator, make withdrawals, etc. To fix this, I call `grantAllRolesToSelf()` on the VITE contract. This commands the VITE contract to use its ownership power to grant my personal wallet all necessary operational roles (withdrawal, consolidation, etc.). This cleanly separates ultimate ownership (held by the automated VITE contract) from day-to-day management (held by me).

5.  **The Succession Logic:**
    * I must call `checkIn()` on the VITE contract periodically to prove I'm still active.
    * If I stop checking in, a time-lock begins. Once it expires, the `heir` can call `initiateSuccession()`.
    * This triggers the VITE contract to transfer its ownership of the OVM to the `heir`. 

### **OVM Functions & Roles Used**

* **`transferOwnership()` :** Secure transfer of control from my wallet to the VITE contract, and later to the heir.
* **`grantRoles(address user, uint256 roles)`:** This function allows the VITE contract to grant a combined integer value representing all management roles to me in a single transaction.

### **Project Links & Hashes**

* **GitHub Repository:** `https://github.com/0xhackworth/ovm-inheritance-contract`
* **Loom Video Showcase:** [LINK](https://www.loom.com/share/1d800ac9f19147079764e86ed832c669?sid=d6ab193b-a5ed-428b-aa35-7d9c62dec9e1)
* **Hoodi Testnet Addresses & Hashes:**
    ```
    Deployed OVM Address:   0x530081569962D3035965e1ED37A8812F03bf68D7
    Deployed VITE Address:  0xc5b18f73CDE8E1f9EFf8847a8d3031FCa516FAC0

    OVM Creation TX Hash:   0x89ed75bc03802ab8cbe809d9191518209491e7e7e1a1cf5ef23aef40a83bbdac
    VITE Deployment TX Hash:  0xddd977fdd94866dde5bf24921b6a89091b21fec05d612c08858a8b5022489948
    Final Succession TX Hash: 0x6459824ac0af19470eebe209c78fe61f0f64420e8cbbded96de0b1ae1bd5c00c
    ```

### **License**

This project is licensed under the MIT License. See the [LICENSE](LICENSE.md) file for details.
