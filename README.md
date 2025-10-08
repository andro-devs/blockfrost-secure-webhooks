# Inspiration

https://blockfrost.dev/start-building/webhooks/webhooks-signatures#using-sdk
https://github.com/blockfrost/blockfrost.dev/issues?q=is%3Aopen+is%3Aissue+label%3ABounty%21
https://github.com/blockfrost/blockfrost.dev/issues/8
https://github.com/blockfrost/blockfrost-js/blob/master/src/utils/helpers.ts

# Generate a valid signature for env variable BLOCKFROST_TOKEN='WEBHOOK-AUTH-TOKEN'
```
dart run bin/generate_test_signature.dart
```

# Run server on 8080
```
BLOCKFROST_TOKEN='WEBHOOK-AUTH-TOKEN' dart run bin/server.dart
```

# Status endpoint (GET)
```
curl -X GET http://localhost:8080/status
```

# Webhook endpoint (POST)
## Note: generate the header value (t=,v1=) by using "dart run bin/generate_test_signature.dart"
```
curl --location 'http://localhost:8080/webhook' \
--header 'blockfrost-signature: YOUR_GENERATED_SIGNATE' \
--header 'Content-Type: application/json' \
--data '{"event":"test_event","id":1001}'
```

# Hosting
### Install Google Cloud SDK with brew on MacOS
```
brew install --cask google-cloud-sdk
```

### Authenticate Your User Account
```
gcloud auth login
```

### Set current project id (not the project number), e.g. blockfrost-webhook
```
gcloud config set project [YOUR_PROJECT_ID]
e.g.: gcloud config set project blockfrost-webhook
```

### Verify auth and config settings
```
gcloud auth list
gcloud config list
```

# Build docker image
```
# This command builds the image locally and tags it for pushing to Google's registry (GCR).
# Important: Attach the "--platform linux/amd64" if built on arm (MacOS) architecture!

docker build --platform linux/amd64 -t
us-central1-docker.pkg.dev/blockfrost-webhook/dart-webhooks/blockfrost-secure-webhook:latest .
--no-cache

### Note: if error comes up clean the dart tool and run docker build again
# Delete the local configuration cache
rm -rf .dart_tool
```

### Start docker container on your local machine
```
docker run -d \
-p 8080:8080 \
--name blockfrost-secure-webhook-test \
-e BLOCKFROST_TOKEN='WEBHOOK-AUTH-TOKEN' \
us-central1-docker.pkg.dev/blockfrost-webhook/dart-webhooks/blockfrost-secure-webhook:latest
```

### Check docker container log file
```
docker logs blockfrost-secure-webhook-test
```

# ------------------------ Cloud deployment --------------------------------------------------------

### Enable the Artifact Registry API (if not already enabled):

```
gcloud services enable artifactregistry.googleapis.com
```

### Create a Repository: We'll create a repository in the same region we plan to deploy (e.g., us-central1).

```
gcloud artifacts repositories create dart-webhooks \
--repository-format=docker \
--location=us-central1 \
--project=blockfrost-webhook \
--description="Docker images for Blockfrost secure webhooks"
```

### Configure Docker for Artifact Registry
 This command tells Docker how to authenticate with the new Artifact Registry service.
```
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### Provide permission to the user to write the Artifact Registry
```
Open the Google Cloud Console.
Navigate to IAM & Admin > IAM.
Click + Grant Access at the top or edit already existing user.
In the New principals field, enter your Google account email address (e.g., YOUR_EMAIL).
In the Role dropdown, search for and select:
Artifact Registry Writer (If you only want permission to push images).
Click Save.
```

### Push the image to Google Container Registry (GCR):
 This uploads the image so Cloud Run can access it.
```
docker push us-central1-docker.pkg.dev/blockfrost-webhook/dart-webhooks/blockfrost-secure-webhook:
latest
```

# Deploy to Google Cloud Run
### Deploy the service:
 Choose a region close to you or your users (e.g., us-central1).
 Note: replace the 'WEBHOOK-AUTH-TOKEN' with the auth-token from blockfrost webhook settings page

```
gcloud run deploy blockfrost-webhook \
--image us-central1-docker.pkg.dev/blockfrost-webhook/dart-webhooks/blockfrost-secure-webhook:
latest \
--platform managed \
--region us-central1 \
--allow-unauthenticated \
--port 8080 \
--set-env-vars BLOCKFROST_TOKEN='WEBHOOK-AUTH-TOKEN' \
--project blockfrost-webhook
```

### Output the service URL
```
# Example:
Service URL: https://blockfrost-webhook-123456789.us-central1.run.app/webhook
```

### TODO: how to create a github pipeline to push the image to google artifact registry?
see this URL:
https://stackoverflow.com/questions/75840164/permission-artifactregistry-repositories-uploadartifacts-denied-on-resource-usin
i probably need a service account which creds stored in github actions secrets

