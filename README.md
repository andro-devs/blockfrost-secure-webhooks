## blockfrost-secure-webhooks

[![Dart Unit Tests](https://github.com/andro-devs/blockfrost-secure-webhooks/actions/workflows/dart.yml/badge.svg)](https://github.com/andro-devs/blockfrost-secure-webhooks/actions/workflows/dart.yml/badge.svg)  [![GitHub license](https://img.shields.io/github/license/andro-devs/blockfrost-secure-webhooks)](https://github.com/andro-devs/blockfrost-secure-webhooks/blob/main/LICENSE) [![Code Coverage](https://codecov.io/gh/andro-devs/blockfrost-secure-webhooks/branch/main/graph/badge.svg)](https://codecov.io/gh/andro-devs/blockfrost-secure-webhooks)

##### @formatter:off

### Run server on 8080
```
BLOCKFROST_TOKEN='WEBHOOK-AUTH-TOKEN' dart run bin/server.dart
```

### Status Endpoint (GET)
```
curl -X GET http://localhost:8080/status
```

### Webhook Endpoint (POST)
#### Note: generate the header value (t=,v1=) by using "dart run bin/generate_test_signature.dart"
```
curl --location 'http://localhost:8080/webhook' \
--header 'blockfrost-signature: YOUR_GENERATED_SIGNATURE' \
--header 'Content-Type: application/json' \
--data '{"type": "block", "payload": {"hash": "0a26dd2b2c2cd32e66029215d22cd9f1572e41bd6549c75cf2479fb9b771487a"}}'
```

### Build Docker Image
```
# This command builds the image locally and tags it for pushing to Google's registry (GCR).
# Important: Attach the "--platform linux/amd64" when you built it on arm (MacOS) architecture!

docker build --platform linux/amd64 -t us-central1-docker.pkg.dev/blockfrost-webhook/dart-webhooks/blockfrost-secure-webhook:latest . --no-cache

### Note: if error comes up clean the dart tool and run docker build again
# Delete the local configuration cache
rm -rf .dart_tool
```

### Start Docker Container
```
docker run -d \
-p 8080:8080 \
--name blockfrost-secure-webhook-test \
-e BLOCKFROST_TOKEN='WEBHOOK-AUTH-TOKEN' \
us-central1-docker.pkg.dev/blockfrost-webhook/dart-webhooks/blockfrost-secure-webhook:latest
```

### Check Docker Container Log File
```
docker logs -f blockfrost-secure-webhook-test
```

### Test call to Docker Container
Generate the signature using the generate_test_signature.dart and paste it into the header
```
curl --location 'http://localhost:8080/webhook' \
--header 'blockfrost-signature:
ADD_SIGNATURE_HERE' \
--header 'Content-Type: application/json' \
--data '{"type": "block", "payload": {"hash": "0a26dd2b2c2cd32e66029215d22cd9f1572e41bd6549c75cf2479fb9b771487a"}}'
```

### Cloud Deployment

#### Install Google Cloud SDK with brew on MacOS
```
brew install --cask google-cloud-sdk
```

#### Authenticate Your User Account
```
gcloud auth login
```

#### Set Current Project Id
```
# Example: blockfrost-webhook

gcloud config set project [YOUR_PROJECT_ID]
e.g.: gcloud config set project blockfrost-webhook
```

#### Verify Auth and Config Settings
```
gcloud auth list
gcloud config list
```

#### Enable the Artifact Registry API (if not already enabled):

```
gcloud services enable artifactregistry.googleapis.com
```

#### Create an Artifacts Repository

```
gcloud artifacts repositories create dart-webhooks \
--repository-format=docker \
--location=us-central1 \
--project=blockfrost-webhook \
--description="Docker images for Blockfrost secure webhooks"
```

#### Configure Docker for Artifact Registry
This command tells Docker how to authenticate with the new Artifact Registry service.
```
gcloud auth configure-docker us-central1-docker.pkg.dev
```

#### Provide permission to the user to write the Artifact Registry
```
Open the Google Cloud Console.
Navigate to IAM & Admin > IAM.
Click + Grant Access at the top or edit already existing user.
In the New principals field, enter your Google account email address (e.g., YOUR_EMAIL).
In the Role dropdown, search for and select:
Artifact Registry Writer (If you only want permission to push images).
Click Save.
```

#### Push the image to Google Container Registry (GCR):
This uploads the image so Cloud Run can access it.
```
docker push us-central1-docker.pkg.dev/blockfrost-webhook/dart-webhooks/blockfrost-secure-webhook:latest
```

#### Deploy the service to Cloud Run
Choose a region close to you or your users (e.g., us-central1).
Note: replace the 'WEBHOOK-AUTH-TOKEN' with the auth-token from blockfrost webhook settings page

```
gcloud run deploy blockfrost-webhook \
--image us-central1-docker.pkg.dev/blockfrost-webhook/dart-webhooks/blockfrost-secure-webhook:latest \
--platform managed \
--region us-central1 \
--allow-unauthenticated \
--port 8080 \
--set-env-vars BLOCKFROST_TOKEN='56b2d3af-aaf0-433b-a8f5-ebb031402c2f' \
--project blockfrost-webhook
```

#### Output the service URL
```
# Example:
Service URL: https://blockfrost-webhook-PROJECT_NUMBER.us-central1.run.app/webhook
```