locals {
  trigger_description_tag     = "Publishes a Docker image for tags matching the specified pattern."
  trigger_description_branch  = "Publishes a Docker image for branches matching the specified pattern."
  trigger_description_default = var.tag != null ? local.trigger_description_tag : local.trigger_description_branch
  trigger_description         = var.trigger_description != null ? var.trigger_description : local.trigger_description_default
  trigger_suffix              = var.gke_deploy_enabled ? "tag-deploy" : "${var.tag != null ? "tag" : var.branch}"
  service_account             = "projects/${var.infra_project}/serviceAccounts/cloudbuild@${var.infra_project}.iam.gserviceaccount.com"
  image_name                  = "${var.registry_location}-docker.pkg.dev/${var.infra_project}/${var.registry_artifact}/${var.repo_name}"
  tag_name                    = var.tag != null ? "$TAG_NAME" : "$BRANCH_NAME"
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
  }

  # Note: This Cloud Build trigger is configured to activate only for pushes
  # to branches matching 'var.branch' (e.g., 'main') and for new Git tags
  # matching 'var.tag'.

  build {
    step {
      id   = "docker build"
      name = "gcr.io/cloud-builders/docker"
      args = [
        "build",
        "-t", "$_IMAGE_NAME:$_TAG_NAME",
        "--target", "prod",
        "."
      ]
    }
    step {
      id   = "docker push tag"
      name = "gcr.io/cloud-builders/docker"
      args = [
        "push",
        "$_IMAGE_NAME:$_TAG_NAME"
      ]
    }

    dynamic "step" {
      for_each = var.gke_deploy_enabled ? [1] : []
      content {
        id   = "deploy"
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


    timeout = "600s"

    options {
      logging               = "CLOUD_LOGGING_ONLY"
      dynamic_substitutions = true
    }
  }
}