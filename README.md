# Thesis Bundles — Reusable Infrastructure-as-Code for SMEs

This repository contains three Terraform bundles developed as part of a Master's thesis at Åbo Akademi University.

**Thesis title:** Design and Evaluation of Reusable Infrastructure-as-Code Bundles for Small and Medium Enterprises

**Author:** Zakaria Bouzada

---

## Overview

Each bundle deploys a complete, production-ready infrastructure pattern on Microsoft Azure. The bundles are designed for SME developers with basic cloud familiarity but without specialised DevOps expertise.

| Bundle | Use Case | Resources | Parameters |
|--------|----------|-----------|------------|
| **Bundle A** | Web application stack (containerised) | ~30 | 10 |
| **Bundle B** | Serverless API backend | ~24 | 7 |
| **Bundle C** | Static website with CDN | ~9 | 5 |

Only `app_name` is required. All other parameters have sensible defaults.

---

## Prerequisites

| Tool | Version | Installation |
|------|---------|--------------|
| Terraform | >= 1.5.0 | [terraform.io/downloads](https://www.terraform.io/downloads) |
| Azure CLI | >= 2.50.0 | [aka.ms/install-azure-cli](https://aka.ms/install-azure-cli) |
| Azure subscription | Free credits available | [azure.microsoft.com/free](https://azure.microsoft.com/free) |

> ⚠️ **Cost Warning:** Azure requires a credit card for verification. You receive €200 free credits for 30 days. **Always run `terraform destroy` after testing** to avoid unexpected charges.

## Authentication

### Option 1: Quick Test (Recommended for first-time users)

Log in with your personal Azure account. Terraform will use these credentials automatically.

```bash
az login
az account show --query id -o tsv
```

### Option 2: Service Principal for Terraform (For CI/CD pipelines or team use)

```bash
az ad sp create-for-rbac --name "terraform-bundles" --role Contributor --scopes /subscriptions/<SUBSCRIPTION_ID>
```
Save the JSON output (appId, password, tenant). Then set the following environment variables before running Terraform:

```bash
# Linux / Mac / Git Bash:
export ARM_CLIENT_ID=<appId>
export ARM_CLIENT_SECRET=<password>
export ARM_TENANT_ID=<tenant>
export ARM_SUBSCRIPTION_ID=<subscription_id>

# Windows Command Prompt:
set ARM_CLIENT_ID=<appId>
...
```
  
## Quick Start
Clone the Repository
```bash
git clone https://github.com/ZakariaBouzada/thesis_bundles.git
cd thesis_bundles
```
## Deploy Bundle A (Web Application)
```bash
cd bundle-a-web-app
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set app_name only, to your choosing (e.g. "my-test-site")
terraform init
terraform plan
terraform apply
# Type 'yes' when prompted
```

## Deploy Bundle B (Serverless API)
```bash
cd bundle-b-serverless-api
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set app_name only, to your choosing (e.g. "my-test-site")
terraform init
terraform plan
terraform apply
# Type 'yes' when prompted
```
## Deploy Bundle C (Static Website) (Recommended for testing)
```bash
cd bundle-c-static-web
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set app_name only, to your choosing (e.g. "my-test-site")
terraform init
terraform plan
terraform apply
# Type 'yes' when prompted
```
## Output
After deployment completes, Terraform outputs the application URL. Open it in a browser.
Or, 
```bash
terraform output
terraform output app_url        # Bundle A and B
terraform output site_url       # Bundle C
```

## **Destroy your resources**
```bash
# After testing, destroy resources from the same bundle directory:
cd bundle-c-static-web   # or bundle-a-web-app, bundle-b-serverless-api
terraform destroy
```

## Repository Structure
```bash
thesis_bundles/
├── bundle-a-web-app/           # Containerised web application
│   ├── main.tf                 # Root module
│   ├── variables.tf            # User parameters
│   ├── outputs.tf              # Deployment outputs
│   ├── versions.tf             # Provider versions
│   ├── terraform.tfvars.example # Example configuration
│   └── modules/                # Child modules (networking, security, database, compute, etc.)
├── bundle-b-serverless-api/    # Serverless API backend
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── terraform.tfvars.example
│   └── modules/                # Networking, security, cosmosdb, functions, apim, monitoring
├── bundle-c-static-web/        # Static website with CDN
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── terraform.tfvars.example
│   └── modules/                # Hosting, security, monitoring
└── README.md                   # This file

```
## Cost Estimates
Approximate monthly costs for eu-north-1 / swedencentral region:

| Bundle | Dev/Staging | Production (single NAT) | Production (HA) |
|--------|-------------|------------------------|-----------------|
| **Bundle A** (Web App) | ~€25 | ~€60 | ~€95 |
| **Bundle B** (Serverless API) | ~€0 (pay-per-execution) | ~€0 (pay-per-execution) | ~€0 (pay-per-execution) |
| **Bundle C** (Static Web) | Free tier available | Free tier available | Free tier available |

## Documentation
Each bundle includes a detailed README with:

- Architecture diagram

- Step-by-step deployment instructions

- Complete parameter reference

- Output descriptions

- Cost estimates

- Design decisions and trade-offs

- Troubleshooting guide

## Key Design Decisions
All bundles follow three design principles grounded in the thesis research questions:

- Modularisation: Each module has a single responsibility. The security module is reused across all three bundles without modification.

- Parameterisation: Only 5–10 parameters are exposed. The rest are opinionated defaults based on SME constraints.

- Abstraction: Users interact with high-level concepts (instance size, environment). Cloud-provider details (VNet CIDR, subnet masks, IAM policies) are hidden.

## Limitations
| Limitation | Bundle | Workaround |
|------------|--------|------------|
| Static Web Apps not available in `swedencentral` | C | Use `westeurope` |
| API Management first deployment takes 30–45 min | B | Documented in README; subsequent updates fast |
| HTTPS/SSL termination not automated | A | Configure manually after deployment |
| Function code not included | B | Deploy separately via `func azure functionapp publish` |

### Academic Context
This repository is an artefact produced for the Master's thesis:

***Design and Evaluation of Reusable Infrastructure-as-Code Bundles for Small and Medium Enterprises***

Åbo Akademi University, Faculty of Science and Engineering, Information Technologies, 2026

The thesis examines:

- RQ1: How to structure IaC into reusable deployment bundles for SMEs

- RQ2: How modularisation, parameterisation, and abstraction affect reusability and maintainability

- RQ3: Quantified reduction in deployment time and configuration effort vs manual methods

### License
MIT License — see each bundle folder for details.

### Contributing
This repository is a research artefact. Issues and suggestions are welcome via GitHub Issues.

### Contact
Zakaria Bouzada — GitHub Profile
