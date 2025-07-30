<h1 align="center" style="border-bottom: none;"> gfw-terraform-modules </h1>

<p align="center">
  <a href="https://github.com/GlobalFishingWatch/gfw-terraform-modules/actions/workflows/ci.yaml" >
    <img src="https://github.com/GlobalFishingWatch/gfw-terraform-modules/actions/workflows/ci.yaml/badge.svg"/>
  </a>
  <a href="https://codecov.io/gh/GlobalFishingWatch/gfw-terraform-modules" >
    <img src="https://codecov.io/gh/GlobalFishingWatch/gfw-terraform-modules/graph/badge.svg?token=bpFiU6qtrd"/>
  </a>
  <a>
    <img alt="Terraform Version" src="https://img.shields.io/badge/Terraform-1.8-blue">
  </a>
  <a>
    <img alt="Last release" src="https://img.shields.io/github/v/release/GlobalFishingWatch/gfw-terraform-modules">
  </a>
</p>

This repository serves as the central hub for shared, reusable Terraform modules used across Global Fishing Watch's infrastructure on Google Cloud Platform.

## 🚀 Purpose

Our goal is to foster **Infrastructure as Code (IaC)** best practices by providing:

* **Consistency:** Standardized, opinionated ways to provision common infrastructure components.
* **Reusability:** Avoid duplicating code across different projects and teams, leading to faster development cycles.
* **Maintainability:** Easier to manage and update infrastructure definitions from a single, trusted source.
* **Reliability:** Modules are designed with best practices, tested, and validated for consistent behavior.

Each module within this repository is a self-contained, well-documented building block, promoting a modular approach to infrastructure management.

## 📦 Repository Structure

The core of this repository is the `modules/` directory, which contains individual, independent Terraform modules.

## 🛠️ How to Use These Modules

To incorporate a module from this repository into your Terraform configuration, reference it using its Git URL. It is **highly recommended** to pin modules to a specific Git tag (version) to ensure consistent and reproducible deployments.

**Example Usage:**

```terraform
module "cloudbuild_trigger_main_branch" {
  # --- Module Source: Reference your shared repository and the specific module path ---
  source  = "git::https://github.com/GlobalFishingWatch/gfw-terraform-modules.git//modules/cloudbuild-trigger?ref=v0.1.0"

  # --- Required Variables (no default in modules/cloudbuild-trigger/variables.tf) ---
  repo_name         = "my-awesome-app"
  registry_artifact = "docker-images-repo"

  # --- Optional Variables (have defaults in modules/cloudbuild-trigger/variables.tf) ---
  # If you don't specify these, the module's default values will be used.
  repo_owner        = "GlobalFishingWatch"
  infra_project     = "gfw-int-infrastructure"
  registry_location = "us-central1"
  trigger_location  = "us-central1"

  # --- Trigger-specific Settings ---
  # This instance is configured for a branch trigger:
  branch       = "^main$"
  tag          = null
  invert_regex = false

  # Optional: Custom trigger description (if not set, a dynamic description will be generated)
  # trigger_description = "Builds Docker image on 'main' branch pushes."
}

# Example of an output to get the ID of the created trigger (optional)
output "main_branch_trigger_id" {
  description = "The ID of the Cloud Build trigger for the main branch."
  value       = module.cloudbuild_trigger_main_branch.trigger_id
}
```

## 🤖 Makefile Commands

This repository includes a `Makefile` to simplify common Terraform development and maintenance tasks.

### Displaying Available Commands

To see a list of all available commands and their descriptions, run:

```bash
[...]$ make help
check               Check terraform format recursively.
format              Auto-format terraform files recursively.
help                Display this message
```
