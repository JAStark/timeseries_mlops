# Set up PubSub for Cloud Schedular
resource "google_pubsub_topic" "historical_weather_topic" {
  name = "historical-weather-topic-dev"
}

# Set uo Cloud Schedular to trigger Cloud Function once per day
resource "google_cloud_scheduler_job" "historical_weather_schedular" {
  name        = "historical-weather-schedular-dev"
  description = "Cron Job to start the collection of Historical Weather"
  schedule    = "0 7 * * *" # Run at 7am
  time_zone   = "Europe/London"
  region      = var.region
  pubsub_target {
    topic_name = google_pubsub_topic.historical_weather_topic.id
    data       = base64encode("Historical Weather Begin!")
  }
}

# Set up Cloud Storage Bucket for Cloud Function to read code from
resource "google_storage_bucket" "timeseries_mlops_cloud_functions" {
  name     = "timeseries-mlops-cloud-functions-dev"
  location = var.region
}

# Set up Cloud Storage Bucket for API Data outputs
resource "google_storage_bucket" "timeseries_mlops_weather_api_data" {
  name     = "timeseries-mlops-weather-api-data-dev"
  location = var.region
}

# set up trigger so that cloud build deploys CF upon code change in CF
# resource "google_cloudbuild_trigger" "dev_historical_weather_cf_trigger" {
#   name        = "dev-historical-weather-cf-deploy-trigger"
#   description = "DEV Cloud Build trigger to deploy fetch_historical_data.py CF if changed."
#   location    = var.region
#
#   github {
#     owner = "JAStark"
#     name  = "timeseries_mlops"
#     push {
#       branch = "^dev$"
#     }
#   }
#
#   included_files = ["cloud_functions/historical_weather/*"]
#   filename       = "cloud_functions/historical_weather/cloudbuild.yaml"
# }

# Set up path to zip file containing code for this Cloud Function
resource "google_storage_bucket_object" "dev_historical_weather_cloud_function" {
  name   = "dev-historical-weather.zip"
  bucket = google_storage_bucket.timeseries_mlops_cloud_functions.name
  source = "./workspace/cloud_functions/historical_weather.zip"
}

# Set up the Secret Manager which will contain the API_KEY
resource "google_secret_manager_secret" "weather_api_key_dev" {
  secret_id = "weather_api_key_dev"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

# Set IAM Policy so CF can access secrets
data "google_iam_policy" "admin" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      "user:silver-antonym-326607@appspot.gserviceaccount.com",
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  project = var.project_id
  secret_id = google_secret_manager_secret.weather_api_key_dev.secret_id
  policy_data = data.google_iam_policy.admin.policy_data
}

# Get the secret version itself. The version (actual secret) will be set up manually
# in the Console.
data "google_secret_manager_secret_version" "weather_api_key_version_dev" {
  secret = "weather_api_key_dev"
  depends_on = [
    google_secret_manager_secret_iam_policy.policy
    ]
}

# Set up the Cloud Function itself
# resource "google_cloudfunctions_function" "dev_collect_historical_weather" {
#   name                  = "timeseries-mlops-collect-historical-weather-dev"
#   description           = "Function to collect yesterday's hourly weather data"
#   runtime               = "python310"
#   available_memory_mb   = 128
#   timeout               = 120
#   source_archive_bucket = google_storage_bucket.timeseries_mlops_cloud_functions.name
#   source_archive_object = google_storage_bucket_object.dev_historical_weather_cloud_function.name
#   entry_point           = "hello_fetch_historical_data"
#   ingress_settings      = "ALLOW_INTERNAL_ONLY"
#   event_trigger {
#     event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
#     resource   = google_pubsub_topic.historical_weather_topic.id
#     failure_policy {
#       retry = false
#     }
#   }
#   environment_variables = {
#     PROJECT_ID  = var.project_id
#     BUCKET_NAME = google_storage_bucket.timeseries_mlops_weather_api_data.name
#     API_KEY     = data.google_secret_manager_secret_version.weather_api_key_version_dev.name
#   }
#
#   depends_on = [
#   google_secret_manager_secret_iam_policy.policy
#   ]
# }
