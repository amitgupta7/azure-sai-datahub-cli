#!/bin/bash
while getopts h:k:s:t: flag
do
    case "${flag}" in
        h) host=${OPTARG};;
        k) apikey=${OPTARG};;
        s) apisecret=${OPTARG};;
        t) apitenant=${OPTARG};;        
    esac
done
sudo snap install jq
sudo apt-get update 
sudo apt-get install -y python3-pip
echo "Installing DataHub cli"
python3 -m pip install --upgrade pip wheel setuptools
python3 -m pip install --upgrade acryl-datahub
python3 -m pip install acryl-datahub-actions
curl -s -X 'GET' \
  'https://app.securiti.ai/privaci/v1/admin/data_catalog/api/generate_session_token' \
  -H 'accept: application/json' \
  -H 'X-API-Secret:  '$apisecret \
  -H 'X-API-Key:  '$apikey \
  -H 'X-TIDENT:  '$apitenant | jq -r '.accessToken' > datahub_session_token

cat << EOF > .datahubenv
gms:
  server: $host
  token: $(cat datahub_session_token)
EOF
echo "testing Datahub Installation by connecting to $host"
~/.local/bin/datahub get --urn "urn:li:dataset:(urn:li:dataPlatform:mysql,mysql-1,PROD)"
~/.local/bin/datahub ingest -c csv-enricher.dhub.yaml



