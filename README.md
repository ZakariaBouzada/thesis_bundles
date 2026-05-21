# Thesis Bundles — Reusable Infrastructure-as-Code for SMEs

This repository contains three Terraform bundles developed as part of a Master's thesis at Åbo Akademi University.

**Thesis title:** Design and Evaluation of Reusable Infrastructure-as-Code Bundles for Small and Medium Enterprises

**Author:** Zakaria Bouzada

**Supervisor:** Adnan Ashraf

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

### Azure Authentication

```bash
az login
az account show --query id -o tsv
