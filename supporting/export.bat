rem Set the environment variables command prompt
set AWS_ACCESS_KEY_ID=<your-access-key-id>
set AWS_SECRET_ACCESS_KEY=<your-secret-access-key>
set AWS_REGION=us-east-1


rem Get api credentials and urls from terraform
terraform output api_key
terraform output state_endpoint
terraform output api_endpoint