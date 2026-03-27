locals {
  trigger_description_tag     = "Publishes a Docker image for tags matching the specified pattern."
  trigger_description_branch  = "Publishes a Docker image for branches matching the specified pattern."
  trigger_description_default = var.tag != null ? local.trigger_description_tag : local.trigger_description_branch
  trigger_description         = var.trigger_description != null ? var.trigger_description : local.trigger_description_default
  trigger_suffix              = var.gke_deploy_enabled ? "tag-deploy" : "${var.tag != null ? "tag" : var.branch}"
  service_account             = "projects/${var.infra_project}/serviceAccounts/cloudbuild@${var.infra_project}.iam.gserviceaccount.com"
  image_name                  = "${var.registry_location}-docker.pkg.dev/${var.infra_project}/${var.registry_artifact}/${var.repo_name}${var.image_name_suffix}"
  tag_name                    = var.tag != null ? "$TAG_NAME" : "$BRANCH_NAME"
  dataflow_template_gcs_path  = "${var.dataflow_template_gcs_prefix}/${var.repo_name}/$TAG_NAME.json"
}

output "trigger_id" {
  description = "Cloud Build trigger id"
  value       = google_cloudbuild_trigger.trigger.id
}

resource "google_cloudbuild_trigger" "trigger" {
  name        = "${var.repo_name}-${local.trigger_suffix}"
  description = local.trigger_description
  location    = var.trigger_location
  project     = var.infra_project

  github {
    name  = var.repo_name
    owner = var.repo_owner

    push {
      branch       = var.branch
      tag          = var.tag
      invert_regex = var.invert_regex
    }
  }

  service_account = local.service_account

  substitutions = {
    _IMAGE_NAME = local.image_name
    _TAG_NAME   = local.tag_name
    _PLATFORM   = var.platform

  }

  # Note: This Cloud Build trigger is configured to activate only for pushes
  # to branches matching 'var.branch' (e.g., 'main') and for new Git tags
  # matching 'var.tag'.

  build { # Use buildx so we can create multiarchitecture images
    # 1. Enable ARM emulation (QEMU)
    step {
      id   = "init-qemu"
      name = "gcr.io/cloud-builders/docker"
      args = [
        "run",
        "--privileged",
        "--rm",
        "tonistiigi/binfmt",
        "--install",
        "all"
      ]
    }

    # 2. Create and use buildx builder
    step {
      id   = "create-builder"
      name = "gcr.io/cloud-builders/docker"
      args = ["buildx", "create", "--name", "mybuilder", "--use"]
    }

    # 3. Bootstrap builder (IMPORTANT: enables arm64)
    step {
      id   = "bootstrap-builder"
      name = "gcr.io/cloud-builders/docker"
      args = ["buildx", "inspect", "--bootstrap"]
    }

    # 4. Build + push image
    step {
      id   = "build-image"
      name = "gcr.io/cloud-builders/docker"
      args = [
        "buildx", "build",
        "--platform", "$_PLATFORM",
        "-t", "$_IMAGE_NAME:$_TAG_NAME",
        "--target", "prod",
        "--push",
        "."
      ]
    }

    dynamic "step" {
      for_each = (var.gke_deploy_enabled && var.gke_compile_command != null) ? [1] : []
      content {
        id         = "gke-compile-manifest"
        name       = var.gke_compile_image
        entrypoint = "bash"

        args = [
          "-c",
          var.gke_compile_command
        ]
      }
    }

    dynamic "step" {
      for_each = var.gke_deploy_enabled ? [1] : []
      content {
        id   = "gke-deploy"
        name = "gcr.io/cloud-builders/gke-deploy"
        args = [
          "run",
          "--image", "$_IMAGE_NAME:$_TAG_NAME",
          "--filename=${var.gke_manifest}",
          "--location=${var.gke_location}",
          "--cluster=${var.gke_cluster}",
          "--project=${var.gke_project}",
        ]
      }
    }

    timeout = var.timeout

    options {
      logging               = "CLOUD_LOGGING_ONLY"
      dynamic_substitutions = true
      machine_type          = var.machine_type
    }
  }
}

resource "google_cloudbuild_trigger" "deploy_dataflow" {
  name        = "${var.repo_name}-dataflow-deploy"
  description = "Manual Dataflow deployment"
  location    = var.trigger_location
  project     = var.infra_project

  service_account = local.service_account

  source_to_build {
    uri       = "https://github.com/${var.repo_owner}/${var.repo_name}.git"
    ref       = "refs/tags/$TAG_NAME"
    repo_type = "GITHUB"
  }

  substitutions = {
    _IMAGE_NAME = local.image_name
  }

  build {
    step {
      id         = "validate-tag"
      name       = "gcr.io/cloud-builders/bash"
      entrypoint = "bash"
      args = ["-c", <<-EOT
        if [[ -z "$TAG_NAME" ]]; then
          echo "ERROR: TAG_NAME must be provided"
          exit 1
        fi
      EOT
      ]
    }

    step {
      id         = "check-image"
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "bash"
      args = ["-c", <<-EOT
        gcloud artifacts docker images describe "$_IMAGE_NAME:$TAG_NAME" || {
          echo "ERROR: Image does not exist"
          exit 1
        }
      EOT
      ]
    }

    step {
      id         = "dataflow-drain"
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "bash"
      args = [
        var.dataflow_drain_script,
        var.dataflow_project,
        var.dataflow_region,
        var.dataflow_job_name,
      ]
    }

    step {
      id         = "dataflow-build-template"
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "gcloud"

      args = [
        "dataflow", "flex-template", "build", local.dataflow_template_gcs_path,
        "--image", "$_IMAGE_NAME:$TAG_NAME",
        "--sdk-language", "PYTHON",
        "--metadata-file", var.dataflow_metadata_file,
      ]
    }

    step {
      id         = "dataflow-deploy"
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "gcloud"

      args = compact([
        "dataflow", "flex-template",
        "run", var.dataflow_job_name,
        "--region=${var.dataflow_region}",
        "--service-account-email=${var.dataflow_service_account}",
        "--project=${var.dataflow_project}",
        "--template-file-gcs-location", local.dataflow_template_gcs_path,
        "--temp-location=${var.dataflow_temp_location}/${var.repo_name}",
        "--staging-location=${var.dataflow_staging_location}/${var.repo_name}",
        var.dataflow_config_file != null ? "--parameters=config-file=${var.dataflow_config_file}" : null,
        "--parameters=sdk_container_image=$_IMAGE_NAME:$TAG_NAME",
      ])
    }

    timeout = var.timeout

    options {
      logging               = "CLOUD_LOGGING_ONLY"
      dynamic_substitutions = true
      machine_type          = var.machine_type
    }
  }
}
