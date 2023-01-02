#!/bin/#!/usr/bin/env bash

# script to go into the Cloud Functions Directory, and recursively
# zip each cloud function code.

echo "$BRANCH_NAME"
pwd
ls
cd cloud_functions
pwd
ls
for i in */; do zip -r "${i%/}.zip" "$i"; done
