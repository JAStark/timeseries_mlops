# Set up Cloud Storage Bucket for Cloud Function to read code from
resource "google_storage_bucket" "timeseries_mlops_cloud_functions" {
  name     = "timeseries-mlops-cloud-functions-dev"
  location = var.region
  project  = var.project_id
}

# Set up Cloud Storage Bucket for API Data outputs
resource "google_storage_bucket" "timeseries_mlops_weather_api_data" {
  name     = "timeseries-mlops-weather-api-data-dev"
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
