"""Cloud Function runs once per hour to fectch the realtime weather into one json file.

API: https://www.weatherapi.com/docs/
realtime weather or realtime weather API method allows a user to get up to date
realtime weather information in json and xml. The data is returned as a realtime Object.
realtime object contains realtime or realtime weather information for a given city.

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

logging.basicConfig(level=logging.DEBUG)

API_KEY = os.environ["API_KEY"]
PROJECT_ID = os.environ["PROJECT_ID"]
STORAGE_CLIENT = storage.Client("PROJECT_ID")
BUCKET_NAME = os.environ["BUCKET_NAME"]


def write_to_storage(json_data: dict, realtime: tuple) -> None:
    """Funtion to write json data to file in GCS.
    File name: realtime_weather_<YYYY-MM-DD_HH>
    """

    filename = f"realtime_weather/manchester_weather_{realtime[1]}_{str(realtime[0])}.json"
    try:
        bucket = STORAGE_CLIENT.get_bucket(BUCKET_NAME)
        blob = bucket.blob(filename)
        blob.upload_from_string(data=json_data, content_type="application/json")
        logging.info(f"File {filename} uploaded to {BUCKET_NAME}.")
    except exceptions.NotFound as e:
        logging.error(f"Bucket: {BUCKET_NAME} does not exist. Error: {e}")
    except Exception as e:
        logging.info(f"Something went wrong. Check the logs {e}")


def fetch_realtime_data(realtime: tuple) -> dict:
    """Function to call API and fetch realtime weather data"""

    url = f"https://api.weatherapi.com/v1/current.json?key={API_KEY}&q=manchester&aqi=yes"
    response = requests.request("GET", url)
    json_data = response.text
    logging.info(f"TYPE RESPONSE: {type(json_data)}")
    logging.info(f"Data collected for day {realtime[1]}, and hour {realtime[0]}: \n{json_data}")
    return json_data


def get_realtime() -> str:
    """Function to get the date and hour for realtime as a string: `YYYY-MM-DD_HH`"""

    today = datetime.today()
    realtime_hour = today.time().hour
    realtime_date = today.date().isoformat()
    logging.info(f"TYPE realtime hour: {realtime_hour} for {realtime_date}")
    return realtime_hour, realtime_date


def main():
    """Function that calls other Functions"""

    logging.info("Starting main for realtime weather data collection")
    realtime = get_realtime()
    logging.info(f"\nrealtime: {realtime}")
    json_data = fetch_realtime_data(realtime)
    logging.info("\nWRITING DATA TO STORAGE…")
    # write_to_storage(json_data, realtime)


def hello_fetch_realtime_data(event, context=None) -> None:
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

        if data == "Realtime Weather Begin!":
            main()
        else:
            raise Exception(
                f'Expected Message: "Realtime Weather Begin!"\nActual Message: "{data}"'
            )
    else:
        raise Exception(f"No data received in pubsub event. Event: {event}")


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    json_data = fetch_realtime_data(sys.argv[1])
    write_to_storage(json_data, sys.argv[1])
