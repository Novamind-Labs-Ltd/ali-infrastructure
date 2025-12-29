# bootstrap-1-cloudsso

> Goal: Use Alibaba Cloud **CloudSSO (Cloud SSO)** to enable **fast local CLI sign-in** and obtain **temporary STS credentials** that can be reused by Terraform and ops tooling.
> Principle: **Humans (local workstations) use CloudSSO**; **machines (CI/CD) use OIDC + RAM Role** (not covered here).

---

## 1. Background & Key Concepts

### 1.1 Why CloudSSO (instead of RAM User + AccessKey)

* Avoid long-lived AccessKey leakage risk (CloudSSO issues **temporary STS credentials**)
* Centralized permission management and better auditability
* Similar intent to AWS SSO / IAM Identity Center (naming and UX differ)

### 1.2 Three Alibaba Cloud “SSO” areas that are easy to confuse

* **CloudSSO (Cloud SSO / Multi-account identity & permission)**: *account-level SSO* (used in this guide)
* **SSO Management / OAuth Applications (beta)**: *application-level login/authorization* (usually **not** for infra ops sign-in)
* **RAM (users/groups/roles)**: traditional IAM (commonly used for CI/OIDC; avoid RAM users for humans if possible)

### 1.3 What you see in the CloudSSO Portal

* The portal typically shows **Access Configurations** (e.g., `terraform-local`)
* Access Configuration is a CloudSSO-side “permission bundle” (system policies / custom policies)
* When signing into Console/CLI, CloudSSO issues STS credentials based on the chosen access configuration

---

## 2. Console Setup (one-time bootstrap)

> Goal: CloudSSO users can see an access configuration (e.g., `terraform-local`) and can sign into Console/CLI to obtain temporary credentials.

### 2.1 Create a CloudSSO Directory

Path: **CloudSSO → Initialize / Create Directory**

* Directory ≈ CloudSSO “tenant / identity space”
* It’s normal that **Singapore may not be available** in the region selector
  The directory region affects where identity data is stored, **not** where you can deploy resources.

A service role will be created automatically:

* `AliyunServiceRoleForCloudSSO`
  ✅ Required; do not delete.

### 2.2 Create CloudSSO Users

Path: **CloudSSO → People/Users → Create User**

* Create a user (e.g., `kun.wang`)
* Set an initial password (MFA/password policies can be enabled later)

### 2.3 Create an Access Configuration

Path: **CloudSSO → Access Configurations → Create**
Recommended:

* Name: `terraform-local` (or more explicit like `terraform-dev`)
* Initial landing page: **leave empty (recommended)** to default to the Console home page

Attach system policies needed for your bootstrap activities (example):

* `AliyunVPCFullAccess`
* `AliyunECSFullAccess`
* `AliyunOSSFullAccess`
  (You can later tighten to least-privilege custom policies.)

### 2.4 Assign the Access Configuration to a User/Group

Path: **CloudSSO → Multi-account Permission Management (RD) → Root → Configure Permissions**

* Select the target account (UID)
* Choose principal: user or group (recommended: create a `devops` group and assign once)
* Select access configuration: `terraform-local`
* Save

### 2.5 CloudSSO Login URL (important)

CloudSSO portal entry is shown on: **CloudSSO → Overview** (right-side panel)

* Copy the **User Login URL** for browser sign-in

---

## 3. Local CLI Setup (key steps)

### 3.1 Prerequisites

* `aliyun` CLI version must be **3.0.271+**
* Verified working version: `aliyun version` → 3.2.2 ✅

### 3.2 Create a CloudSSO CLI Profile (interactive)

Create a profile (example: `SSOProfile`):

```bash
aliyun configure --profile SSOProfile --mode CloudSSO
```

Fill in the prompted fields:

* **SignIn URL**: use the CloudSSO **device login** endpoint
  Typically: `https://<signin-domain>/device/login` (not the regular `/.../login` portal URL)
* Select the target RD account
* Select access configuration: `terraform-local`
* Set the default region (e.g., `cn-hongkong` / `cn-hangzhou`)

The CLI will open a browser for authorization (or print a device code flow).

### 3.3 Validate credentials

```bash
aliyun sts GetCallerIdentity --profile SSOProfile
```

If you get `AccountId` / `Arn`, CloudSSO auth is working and temporary STS credentials are active.

---

## 4. Lessons Learned / Common Pitfalls

1. **CloudSSO directory region ≠ resource region**
   Not seeing Singapore in directory creation does not prevent deploying to ap-southeast-1.

2. **Don’t confuse RAM settings with CloudSSO login**
   RAM “username/password login” and “SAML settings” are not the CloudSSO user portal.
   The CloudSSO login URL is on **CloudSSO → Overview**.

3. **Portal shows Access Configurations**
   This is normal product behavior. The access configuration is what you select in the portal/CLI.

4. **Correct CLI approach on 3.x**
   Use: `aliyun configure --profile <name> --mode CloudSSO`

---

## 5. Done Criteria

* [x] CloudSSO user can sign in via the CloudSSO User Login URL and reach the Console
* [x] CloudSSO portal shows and allows selecting `terraform-local`
* [x] Local command `aliyun sts GetCallerIdentity --profile SSOProfile` succeeds
* [x] Local workstation can use temporary STS credentials for Terraform/ops

---

## 6. Next Step

Proceed to **bootstrap-2-remote-state** to use this CloudSSO-based local profile to bootstrap Terraform remote state resources:

* Create an **OSS bucket** for Terraform state
* Create a **Tablestore (OTS) lock table** for Terraform state locking
