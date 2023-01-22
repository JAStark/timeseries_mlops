# Set up PubSub for Cloud Schedular
resource "google_pubsub_topic" "historical_weather_topic" {
  name = "historical-weather-topic-prod"
}

# Set uo Cloud Schedular to trigger Cloud Function once per day
resource "google_cloud_scheduler_job" "historical_weather_schedular" {
  name        = "historical-weather-schedular-prod"
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
  name     = "timeseries-mlops-cloud-functions-prod"
  location = var.region
  project  = var.project_id
}

# Set up Cloud Storage Bucket for API Data outputs
resource "google_storage_bucket" "timeseries_mlops_weather_api_data" {
  name     = "timeseries-mlops-weather-api-data-prod"
  location = var.region
  project  = var.project_id
}

# Enable the CF to write data to the bucket
resource "google_storage_bucket_acl" "timeseries_mlops_weather_api_data_acl" {
  bucket = google_storage_bucket.timeseries_mlops_weather_api_data.name

  role_entity = [
    "WRITER:user-weather-cloud-functions@silver-antonym-326607.iam.gserviceaccount.com",
  ]
}

# Set up path to zip file containing code for this Cloud Function
resource "google_storage_bucket_object" "prod_historical_weather_cloud_function" {
  name           = "prod-historical-weather.zip"
  bucket         = google_storage_bucket.timeseries_mlops_cloud_functions.name
  source         = "/workspace/cloud_functions/historical_weather.zip"
  detect_md5hash = true
}

# Set up the Secret Manager which will contain the API_KEY
resource "google_secret_manager_secret" "weather_api_key_prod" {
  secret_id = "weather_api_key_prod"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

# # Update IAM policy to grant a role to a new member.
# # Other members for the role for the secret are preserved.
# resource "google_secret_manager_secret_iam_member" "member" {
#   project   = var.project_id
#   secret_id = google_secret_manager_secret.weather_api_key_prod.secret_id
#   role      = "roles/secretmanager.secretAccessor"
#   member    = "user:weather-cloud-functions@silver-antonym-326607.iam.gserviceaccount.com"
# }

# Get the secret version itself. The version (actual secret) will be set up manually
# in the Console.
data "google_secret_manager_secret_version" "weather_api_key_version_prod" {
  secret = google_secret_manager_secret.weather_api_key_prod.secret_id
  depends_on = [
    google_secret_manager_secret.weather_api_key_prod,
    # google_secret_manager_secret_iam_member.member
  ]
}

# Set up the Cloud Function itself
resource "google_cloudfunctions_function" "prod-collect_historical_weather" {
  name                  = "timeseries-mlops-collect-historical-weather-prod"
  description           = "Function to collect yesterday's hourly weather data"
  runtime               = "python310"
  available_memory_mb   = 128
  timeout               = 120
  source_archive_bucket = google_storage_bucket.timeseries_mlops_cloud_functions.name
  source_archive_object = google_storage_bucket_object.prod_historical_weather_cloud_function.name
  entry_point           = "hello_fetch_historical_data"
  ingress_settings      = "ALLOW_INTERNAL_ONLY"
  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource   = google_pubsub_topic.historical_weather_topic.id
    failure_policy {
      retry = false
    }
  }
  environment_variables = {
    PROJECT_ID  = var.project_id
    BUCKET_NAME = google_storage_bucket.timeseries_mlops_weather_api_data.name
  }
  secret_environment_variables {
    key        = "API_KEY"
    project_id = var.project_number
    secret     = google_secret_manager_secret.weather_api_key_prod.secret_id
    version    = "1"
  }
}
