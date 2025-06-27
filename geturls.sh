#!/bin/bash

jq -r '.[].url' downloads.json > downloads.txt