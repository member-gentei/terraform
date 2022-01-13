provider "google" {
  project = "member-gentei"
}

resource "google_service_account" "gentei" {
  account_id   = "gentei"
  display_name = "gentei"
  description  = "API server, queue worker, and pretty much everything else that doesn't use Discord."
}

resource "google_service_account" "bot" {
  account_id   = "discord-bot"
  display_name = "discord-bot"
  description  = "Discord bot and messaging worker"
}

resource "google_project_iam_member" "logging_logWriter" {
  for_each = toset([for sa in [
    google_service_account.bot,
    google_service_account.gentei,
  ] : sa.email])
  project = "member-gentei"
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${each.key}"
}

resource "google_project_iam_member" "monitoring_metricWriter" {
  for_each = toset([for sa in [
    google_service_account.bot,
    google_service_account.gentei,
  ] : sa.email])
  project = "member-gentei"
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${each.key}"
}
