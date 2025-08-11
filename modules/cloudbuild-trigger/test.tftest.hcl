mock_provider "google" {
  # Mocking disables real API calls and avoids credential requirements
}

variables {
  repo_name    = "my-app-repo"
  repo_owner   = "my-org"
  branch       = "my-branch" # Testing a 'my-branch' branch trigger
  tag          = null        # Not a tag trigger
  invert_regex = false

  registry_artifact = "my-docker-registry"
  infra_project     = "mock-infra-project"
  registry_location = "us-central1"
  trigger_location  = "us-central1"
}

run "basic_trigger_creation_plan" {
  command = plan

  assert {
    condition     = google_cloudbuild_trigger.trigger.name == "my-app-repo-my-branch"
    error_message = "Expected trigger name to be 'my-app-repo-my-branch'."
  }
}