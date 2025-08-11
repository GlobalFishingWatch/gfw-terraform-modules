# Cloud Build Trigger Module

This Terraform module creates a Google Cloud Build trigger linked to a GitHub repository,
capable of building and pushing Docker images to Artifact Registry based on Git branch pushes or tag creations.

It is designed to be instantiated multiple times in your root module to cover different triggering scenarios
(e.g., one instance for branch pushes, another for tag creations).

## Features

* **Dynamic Image Tagging**: Automatically tags Docker images with the Git tag name (for tag builds) or the branch name (for branch builds).
* **Artifact Registry Integration**: Builds and pushes images to a specified Artifact Registry repository.
* **Flexible Triggering**: Configurable for specific branches and/or Git tags using regex.
* **Customizable Descriptions**: Allows for default or custom trigger descriptions.
* **Clean Naming**: Generates trigger names based on repository name and trigger type (e.g., `my-app-main`, `my-app-tag`).

## Usage Example

This module is typically used by instantiating it in your root Terraform configuration (`main.tf`).
Below is an example for creating a trigger that builds and pushes an image on pushes to the `main` branch.

**For a complete CI/CD setup for Docker images, you would usually instantiate this module twice:**
1.  One instance for **branch-based builds** (like the example below, for `main` branch pushes).
2.  Another separate instance specifically for **tag-based builds** (e.g., for `v1.0.0` tags),
where you would set `branch = null` and `tag = ".*"` or a more specific tag regex.

```terraform
# main.tf (in your root Terraform configuration)

# This module creates a Cloud Build trigger for pushes to the 'main' branch.
module "cloudbuild_trigger_main_branch" {
  source = "./modules/cloudbuild-trigger" # Path to your module directory

  # --- Required Variables (variables without 'default' in modules/cloudbuild-trigger/variables.tf) ---
  repo_name         = "my-awesome-app"           # Your GitHub repository name (e.g., "my-application")
  registry_artifact = "docker-images-repo"       # Name of your Artifact Registry repository (e.g., "my-app-images")

  # --- Optional Variables (variables with 'default' in modules/cloudbuild-trigger/variables.tf) ---
  # If you don't specify these, the module's default values will be used.
  repo_owner        = "GlobalFishingWatch"       # Defaults to "GlobalFishingWatch"
  infra_project     = "gfw-int-infrastructure"   # Defaults to "gfw-int-infrastructure"
  registry_location = "us-central1"              # Defaults to "us-central1"
  trigger_location  = "us-central1"              # Defaults to "us-central1"

  # --- Trigger-specific Settings ---
  # This instance is configured for a branch trigger:
  branch       = "^main$"                        # Regex for the branch to trigger on (e.g., "^main$" for the main branch)
  tag          = null                            # Set to null for branch-based triggers
  invert_regex = false                           # Optional: true to invert the branch/tag regex match (defaults to false)

  # Optional: Custom trigger description (if not set, a dynamic description will be generated)
  # trigger_description = "Builds Docker image on 'main' branch pushes."
}

# Example of an output to get the ID of the created trigger (optional)
output "main_branch_trigger_id" {
  description = "The ID of the Cloud Build trigger for the main branch."
  value       = module.cloudbuild_trigger_main_branch.trigger_id
}