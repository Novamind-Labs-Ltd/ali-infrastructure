# Alicloud Account & Access Guideline

Guideline for onboarding additional identities into the existing Alicloud tenant so that (a) two DevOps engineers can sign in to manage infrastructure when needed, and (b) GitHub Actions can deploy to Alicloud services via OIDC without long‑lived access keys. Applies to the already activated main/master account that is currently accessed via Google sign-in.

---

## 1. Concepts & Roles

- **Main account (root)** – break-glass owner with Google login; should only be used for governance and billing.
- **RAM Users** – named users with console access, MFA, and granular permissions; used for DevOps engineers.
- **RAM Groups/Policies** – reusable bundles of permissions (e.g., `DevOpsAdmin`, `ReadOnly`), assigned to RAM users.
- **RAM Roles + OIDC IdP** – short-lived credentials for automations; GitHub Actions assumes this role through an identity provider bound to GitHub’s OIDC tokens.

---

## 2. Prerequisites

1. Confirm you can reach the RAM console with the main account.
2. Collect primary email, full name, and phone (optional) for each DevOps engineer.
3. List the Alicloud services that GitHub Actions must touch (Container Service ACK, VPC, Log Service, etc.) to scope policies.
4. Decide on a naming convention, e.g., `ram-user.<firstname>` and `ram-role.github-actions.<env>`.

---

## 3. Personal DevOps Accounts (Console Access)

1. **Create RAM group & policy**
   - RAM Console → `Groups` → `Create Group` named `DevOpsAdmin`.
   - Attach system policies: `AliyunCSFullAccess`, `AliyunECSFullAccess`, `AliyunVPCFullAccess`, `AliyunLogFullAccess` (trim as required). Prefer custom policies using `Action`, `Resource`, and `Condition` to limit blast radius.
2. **Add RAM users**
   - RAM Console → `Users` → `Create User`.
   - Enable `Console Logon`, set `LoginName` (e.g., `devops.jane`), use their corporate email, and auto-generate password (force reset on first login).
   - Disable AccessKey creation for human-only users unless CLI access is required; if needed, generate AccessKey, store in Vault, and enforce rotation every 90 days.
3. **Security hardening**
   - Require MFA: RAM Console → `Security Settings` → `MFA` → bind virtual MFA (Google Authenticator) during the user’s first login.
   - Enforce strong password policy (min 12 chars, rotation 90 days).
   - If Google Workspace is the corporate IdP, configure CloudSSO + Google federation, map users to RAM roles, and let DevOps sign in via Google instead of password+MFA (keeps parity with main-account access).
4. **Group assignment & verification**
   - Add each user to `DevOpsAdmin`.
   - Ask them to log in, reset password, bind MFA, and confirm they can open ACK/Container Service.

---

## 4. GitHub Actions Deployment Role (OIDC, no secrets)

### 4.1 Create OIDC Identity Provider in RAM

1. RAM Console → `Identity Providers` → `Create Provider` → choose `OIDC`.
2. Name: `github-actions`.
3. Provider URL: `https://token.actions.githubusercontent.com`.
4. Obtain the OIDC metadata JSON from `https://token.actions.githubusercontent.com/.well-known/openid-configuration` and upload/paste it.
5. Set `Client ID` (audience) to `sts.aliyuncs.com`.
6. (Optional) Limit `Subject` format using `repo:<org>/<repo>:ref:refs/heads/<branch>` so only specific repositories/branches can assume roles.

### 4.2 Create RAM Role for GitHub Actions

1. RAM Console → `Roles` → `Create Role` → `Web Identity / OIDC`.
2. Role name: `GitHubActionsDeploy`.
3. Select the `github-actions` IdP created above.
4. Trust policy condition example (adjust repo/branch):

   ```json
   {
     "Version": "1",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": { "Federated": "acs:ram::<account-id>:oidc-provider/github-actions" },
         "Action": "sts:AssumeRoleWithOIDC",
         "Condition": {
           "StringEquals": {
             "oidc:aud": "sts.aliyuncs.com",
             "oidc:sub": "repo:novamind/ali-infrastructure:ref:refs/heads/main"
           }
         }
       }
     ]
   }
   ```

5. Attach least-privilege policies (custom if possible) permitting the exact resources to manage, e.g., ACK deployments: `AliyunCSFullAccess`, `AliyunECRFullAccess`, `AliyunLogFullAccess`, `AliyunVPCReadOnlyAccess`.

### 4.3 Wire to GitHub Actions

1. In the repo, define a reusable Action step that calls `aliyun sts AssumeRoleWithOIDC` (SDK/CLI) using GitHub’s native OIDC token:

   ```yaml
   permissions:
     id-token: write
     contents: read

   jobs:
     deploy:
       environment: production
       runs-on: ubuntu-latest
       steps:
         - name: Configure Alicloud credentials
           uses: aliyun/credentials-action@v1
           with:
             role_arn: acs:ram::<account-id>:role/GitHubActionsDeploy
             oidc_provider_arn: acs:ram::<account-id>:oidc-provider/github-actions
         - name: Deploy to ACK
           run: |
             aliyun cs UpdateKubernetesManifest --region <region> --body file://deployment.yaml
   ```

2. No long-lived secrets are stored; the action exchanges the GitHub OIDC token for temporary STS credentials.
3. Optionally gate with GitHub environments requiring approvals to align with Alibaba Cloud Change Management.

---

## 5. Operational Guardrails

1. **Logging & Monitoring** – Enable ActionTrail and Cloud Config for RAM events (user creation, role assumption) so you can audit changes.
2. **Periodic Access Reviews** – Quarterly verify RAM users and roles; disable or delete unused accounts.
3. **Least Privilege** – Continuously refine policies; prefer custom policies referencing resource ARNs (ACK clusters, VPCs) rather than `*`.
4. **Break-glass Flow** – Keep main account credentials vaulted; only the infra lead can access them, and every use is logged.
5. **Documentation** – Store this guideline plus any future updates under `docs/guideline/` and record every created user/role in your IAM registry.

---

## 6. Checklist

- [ ] `DevOpsAdmin` group created and scoped.
- [ ] DevOps RAM users provisioned, MFA enforced, login verified.
- [ ] OIDC IdP `github-actions` created.
- [ ] `GitHubActionsDeploy` role created + least-privilege policies attached.
- [ ] GitHub Actions workflow updated to request OIDC credentials.
- [ ] Logging/auditing enabled; review cadence defined.

