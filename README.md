# Zitadel Admin Script

Simple bash script to perform some Zitadel API-only admin actions.

While ZITADEL offers a robust Management Console UI, certain backend administrative tasks or branding adjustments are currently accessible exclusively via their API. This script provides an interactive, menu-driven CLI tool to quickly perform these actions without needing to manually construct API requests or manually look up internal User IDs.

## Features

* **Interactive Menu:** Simple numbered interface for selecting actions.
* **Automatic ID Resolution:** You can input a user's Email, Username, or raw `user_id`. The script will automatically query the ZITADEL API to resolve the underlying ID.
* **Generate Recovery Codes:** Quickly generate a specified number of recovery codes (1-50) for a user.
* **Trigger Password Resets:** Initiate the default password reset email flow for a target user.
* **Change Instance Name:** Update the global Instance Name of your ZITADEL installation.
* **Flexible Configuration:** Pass credentials interactively, via script variables, or securely via environment variables.

---

## Prerequisites

To run this script, you will need the following available in your terminal environment:

* `curl` (Required for API requests)
* `jq` (Highly recommended: Used to parse the user ID search and cleanly format the JSON output)
* **A Personal Access Token (PAT):** Generated from a machine user or your own profile inside ZITADEL.

### Required ZITADEL Permissions

Depending on the action you intend to run, the PAT must belong to an account with the following roles:

* **Recovery Codes / Password Reset:** `IAM_USER_MANAGER` or `ORG_USER_MANAGER`
* **Change Instance Name:** `IAM_OWNER` or `system.instance.write`

---

## Usage

**1. Make the script executable**

```bash
chmod +x zitadel-admin.sh
```

**2. Provide Configuration**
You can provide your ZITADEL Domain and Personal Access Token (PAT) in three different ways. The script applies the following order of precedence:

* **Option A: Environment Variables (Recommended for CI/CD or security)**
  Pass the credentials directly in the terminal execution line.

```bash
ZITADEL_DOMAIN="your-instance.zitadel.cloud" ZITADEL_PAT="your_secret_token" ./zitadel-admin.sh
```

* **Option B: Hardcoded Script Variables**
  Open `zitadel-admin.sh` in a text editor and populate the `SCRIPT_DOMAIN` and `SCRIPT_PAT` variables at the top of the file.
* **Option C: Interactive Prompts (Default)**
  Simply run the script. If the domain and token are not found in the environment or the script variables, it will prompt you to enter them securely.

```bash
./zitadel-admin.sh
```

---

## Available Actions

### 1. Generate Recovery Codes

Generates an array of fallback recovery codes for a user who has lost access to their standard MFA methods.

* **Input:** Username, Email, or User ID.
* **Options:** Choose how many codes to generate (between 1 and 50, default is 10).
* **Output:** A JSON array containing the plain-text codes.

### 2. Trigger Password Reset

Triggers the ZITADEL backend to send a standard password reset email to the target user.

* **Input:** Username, Email, or User ID.
* **Output:** Success confirmation or error details.

### 3. Change Instance Name

Updates the top-level identifier of your ZITADEL instance.

* **Input:** The new instance name string.
* **Note:** Changing the instance name will alter the branding in standard emails, but does not retroactively alter the "Issuer" label for previously generated TOTP apps.

---

## AI Use Disclosure

This project was made with the assistance of Gemini to accelerate coding and documentation. All generated code has been manually reviewed and thoroughly tested to ensure functionality and security.

## License

This script is open-source and available under the [GNU Affero General Public License v3.0 (AGPLv3)](https://www.gnu.org/licenses/agpl-3.0.html). Feel free to modify, distribute, or integrate it into your workflows.