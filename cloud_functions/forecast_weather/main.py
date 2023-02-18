"""This cloud function runs once per hour to fetch the for the next 3 days,
including the current day.
API call returns a JSON file containing:
- current day, current weather
- current day, forecast for each hour
- next day, forecast for each hour
- day after that, forecast for each hour

Unclear whether these hourly forecast epochs change when queriying over the course
of a day. Eg, if I query once per day, are those hourly forecasts static for the
whole day? or do they get updated?

I'm going to assume (hope) they get updated over the course of the day, therefore
I will collect data once per hour.

API: https://www.weatherapi.com/docs/

"""

import os
import sys
import json
import logging
import requests
from datetime import datetime
import base64

from google.cloud import storage
from google.api_core import exceptions

logging.basicConfig(level=logging.INFO)

API_KEY = os.environ["API_KEY"]
PROJECT_ID = os.environ["PROJECT_ID"]
STORAGE_CLIENT = storage.Client("PROJECT_ID")
BUCKET_NAME = os.environ["BUCKET_NAME"]


def write_to_storage(json_data: dict, forecast: tuple) -> None:
    """Funtion to write json data to file in GCS.
    File name: forecast_weather_<YYYY-MM-DD_HH>
    """

    filename = (
        f"forecast_weather/manchester_weather_{forecast[1]}_{str(forecast[0])}.json"
    )
    try:
        bucket = STORAGE_CLIENT.get_bucket(BUCKET_NAME)
        blob = bucket.blob(filename)
        blob.upload_from_string(data=json_data, content_type="application/json")
        logging.info(f"File {filename} uploaded to {BUCKET_NAME}.")
    except exceptions.NotFound as e:
        logging.error(f"Bucket: {BUCKET_NAME} does not exist. Error: {e}")
    except Exception as e:
        logging.info(f"Something went wrong. Check the logs {e}")


def fetch_forecast_data(forecast: tuple) -> dict:
    """Function to call API and fetch forecast weather data"""

    url = f"https://api.weatherapi.com/v1/forecast.json?key={API_KEY}&q=Manchester&days=3&aqi=yes&alerts=no"
    response = requests.request("GET", url)
    json_data = response.text
    logging.info(f"TYPE RESPONSE: {type(json_data)}")
    logging.info(
        f"Data collected for day {forecast[1]}, and hour {forecast[0]}: \n{json_data}"
    )
    return json_data


def get_forecast() -> str:
    """Function to get the date and hour for forecast as a string: `YYYY-MM-DD_HH`"""

    today = datetime.today()
    forecast_hour = today.time().hour
    forecast_date = today.date().isoformat()
    logging.info(f"Forecast hour: {forecast_hour} for {forecast_date}")
    return forecast_hour, forecast_date


def main():
    """Function that calls other Functions"""

    logging.info("Starting main for forecast weather data collection")
    forecast = get_forecast()
    logging.info(f"\nforecast: {forecast}")
    json_data = fetch_forecast_data(forecast)
    logging.info("\nWRITING DATA TO STORAGE…")
    write_to_storage(json_data, forecast)


def hello_fetch_forecast_data(event, context=None) -> None:
    """Entry point for the Cloud Function.
    Args:
        event (dict): Event payload from the Cloud Scheduler
        context (google.cloud.functions.Context): Metadata for the event.
    """

    if context:
        logging.info(f"CONTEXT: {context}")
        logging.info(
            f"Function triggered by messageId {context.event_id} published at {context.timestamp}"
        )

    if "data" in event:
        logging.info(f"EVENT: {event}")
        data = base64.b64decode(event["data"]).decode("utf-8")

        if data == "Forecast Weather Begin!":
            main()
        else:
            raise Exception(
                f'Expected Message: "Forecast Weather Begin!"\nActual Message: "{data}"'
            )
    else:
        raise Exception(f"No data received in pubsub event. Event: {event}")


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    json_data = fetch_forecast_data(sys.argv[1])
    write_to_storage(json_data, sys.argv[1])
