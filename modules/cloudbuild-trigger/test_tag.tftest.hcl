mock_provider "google" {
  # Mocking disables real API calls and avoids credential requirements
}

variables {
  repo_name    = "my-app-repo"
  repo_owner   = "my-org"
  branch       = null
  tag          = "my-app-repo-package@1.0.0"
  invert_regex = false

  registry_artifact = "my-docker-registry"
  infra_project     = "mock-infra-project"
  registry_location = "us-central1"
  trigger_location  = "us-central1"
  dockerfile_path   = "path/to/test.Dockerfile"
}

run "basic_tag_trigger_creation_plan" {
  command = plan

  assert {
    condition     = google_cloudbuild_trigger.trigger.name == "my-app-repo-package-tag"
    error_message = "Expected trigger name to be 'my-app-repo-package-tag'."
  }
}
