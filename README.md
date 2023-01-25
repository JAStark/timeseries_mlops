# Project to experiment with MLOps using GCP
Powered by <a href="https://www.weatherapi.com/" title="Free Weather API">WeatherAPI.com</a>


## Ingredients
**An ML problem**
It's important – and difficult – to not get too carried away on the ML problem itself.
Therefore I am going to use the Keras example for weather timeseries. This provides me
with something that can be predicted, with rapid feedback regarding the accuracy or
correctness of the prediction (eg the next day or the next hour). There are several
APIs for weather, and I want to make this more personal, so instead of the dataset provided
in the Keras example I will be using data from another API.

Weather API
- https://www.weatherapi.com which is free for
  - 1,000,000 calls per month
  - history for only 7 days
  - Time range: Historical data for 7 days back, current weather and forecasts up to 10 days.

Powered by <a href="https://www.weatherapi.com/" title="Weather API">WeatherAPI.com</a>
<a href="https://www.weatherapi.com/" title="Free Weather API"><img src='//cdn.weatherapi.com/v4/images/weatherapi_logo.png' alt="Weather data by WeatherAPI.com" border="0"></a>


## Infrastructure
- IaC using Terraform with the Google Provider
- Cloud Functions to call the weather API
- JSON file outputs to go to Google Cloud Storage
- Cloud Schedular to trigger the Cloud Function every hour or 30 minutes or something to collect data. Frequency will depend on the endpoint.
- Google Secrets Manager for the API key

## Dealing with secrets
I used terraform to create the secret manager for the API Key secret. Then, I went into the newly created resource in the Console and added a `version`, where I pasted in the API Key. Another option is to give it a file path, but the key is tiny, so I just pasted it in.

Now, the secret is applied in the terraform cloud function resource definition, which will then make the API key available to the cloud function as an environment variable.

## Data Collection
- **historical weather data** is currently running once per day, fetching yesterday's data. Yesterday's data has weather data for each hour of the day.
- **current weather data** is in progress. It will run once per hour each day to collect the weather for _right now_. The API appears to update the weather every 15 minutes. This means if I query the data at 10:10, I will receive the current weather as of 10:00. If I query again at 10:17, I will receive the weather as of 10:15.
- 14 day forecast
  Having both current and forecast data could be really interesting as I can compare my predictions with the API's predictions _and_ the real outcome.
  I can also use their predictions _and/or_ the current values (truth) to track my algorithm performance against, and use to determine when to retrain my algorithm.
- Collect at the highest frequency on my plan: 25 calls per day, or once every hour.

## Repo configuration notes:
- GitOps as described [here](https://cloud.google.com/architecture/managing-infrastructure-as-code) where we have:
- a `dev` branch and a `prod` branch
- cloud build app configured in GitHub and a Cloud Build trigger configured in GCP so that when I push to GitHub, it triggers a build.
- `dev` and `prod` branches protected, in that only when the feature branch cloud build passes, can `dev` be merged into, and likewise for `dev` into `prod`.  
