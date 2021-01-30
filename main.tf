provider "google" {
  project = "member-gentei"
}

resource "google_service_account" "api" {
  account_id   = "gentei-api"
  display_name = "gentei-api"
}

resource "google_service_account" "member-check" {
  account_id   = "gentei-member-check"
  display_name = "gentei-member-check"
  description  = "Performs membership checks (via systemd.timer)"
}

resource "google_service_account" "refresh-data" {
  account_id   = "gentei-refresh-data"
  display_name = "gentei-refresh-data"
}

resource "google_service_account" "bot" {
  account_id   = "gentei-bot"
  display_name = "gentei-bot"
}

resource "google_project_iam_member" "logging_logWriter" {
  for_each = toset([for sa in [
    google_service_account.bot,
    google_service_account.member-check,
    google_service_account.refresh-data,
  ] : sa.email])
  role   = "roles/logging.logWriter"
  member = "serviceAccount:${each.key}"
}

resource "google_project_iam_member" "monitoring_metricWriter" {
  for_each = toset([for sa in [
    google_service_account.bot,
  ] : sa.email])
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:${each.key}"
}

resource "google_project_iam_member" "datastore_user" {
  for_each = toset([for sa in [
    google_service_account.api,
    google_service_account.bot,
    google_service_account.member-check,
    google_service_account.refresh-data,
  ] : sa.email])
  role   = "roles/datastore.user"
  member = "serviceAccount:${each.key}"
}
