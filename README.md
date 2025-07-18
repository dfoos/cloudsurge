![CloudSurge](/media/cloudsurge-logo.png)


# CloudSurge
[YouTube Presentation for optimizing AWS costs & sustainability for AWS EC2](https://youtu.be/WaRfZgtWw04?si=nTAZCOtfxASBvxlC)

[YouTube demo](https://youtu.be/gxzmq7Qi7pw)

CloudSurge is a proof-of-concept (PoC) platform that allows users to manage the power state of a pod of AWS EC2 instances via a web interface or API. The platform uses a token-based system to control access to starting instances. Users spend tokens as credits to power on their PODs (groups of EC2 instances tagged with environment=ut).

- **User Webpage** (`index.html`): Allows users to start a pod of stopped EC2 instances.
![User Webpage](/media/customer.png)

- **Admin Webpage** (`admin.html`): Enables administrators to start or stop a pod of EC2 instances and assign tokens to customers.
![Admin Webpage](/media/admin.png)

CloudSurge leverages AWS services (EC2, API Gateway, Lambda, Dynamo) and Terraform for infrastructure management, making it an ideal demo for cloud automation.

## Tokens System

The CloudSurge application uses a token-based system to control access to starting EC2 instances. Tokens represent credits that users spend to power on their POD (a group of EC2 instances tagged with `environment=ut`). This section explains how tokens work, how they are managed, and how to interact with the token system.

### Overview

- **Purpose**: Tokens ensure controlled usage of EC2 resources by requiring customers to have sufficient tokens before starting their POD.
- **Storage**: Token counts are stored in a DynamoDB table named `TokenStore`, with each record identified by a unique `id` (e.g., `my-token`) and a `token` attribute storing the count.
- **Display**: Tokens are shown on the customer and admin web pages with a coin emoji (🪙) for a Nintendo-style aesthetic (e.g., `Tokens: 100 🪙`).

### Customer Interaction

- **Viewing Tokens**: On the customer page (`html/index.html`), the current token count is displayed (e.g., `Tokens: 0 🪙`).
- **Starting POD**: Customers can start the POD (EC2 instances) by toggling a switch, but only if:
  - The POD is in a `stopped` state.
  - The customer has at least one token.
- **Token Cost**: Starting the POD subtracts one token from the count, updated via the `POST /tokens/count` endpoint with `action: subtract`.
- **Restriction**: If the token count is zero, the toggle switch is disabled, and a message appears: “No tokens available: Cannot start pod.”

### Admin Interaction

- **Viewing Tokens**: On the admin page (`html/admin.html`), the current token count is displayed similarly to the customer page.
- **Updating Tokens**: Admins can set the token count using a text box and “Update Tokens” button:
  - Enter a non-negative integer (e.g., `100`).
  - Submit to update the count via the `POST /tokens/count` endpoint with `action: set`.
  - Invalid inputs (e.g., negative numbers, non-integers) trigger an error message.
- **No Token Cost**: Admin actions (starting/stopping the POD) do not consume tokens.

### API Endpoints

Tokens are managed through the `/tokens/count` API endpoint, integrated with AWS API Gateway and backed by a Lambda function. The endpoints require an API key for authentication.

- **GET /tokens/count?id=<token_id>**:
  - Retrieves the current token count for the specified `token_id` (e.g., `my-token`).
  - Response: `{"count": <number>}` (e.g., `{"count": 100}`).
  - If no record exists, a new record is created with a count of 0.
- **POST /tokens/count**:
  - Updates the token count based on the request body:
    - **Set Count**: `{"id": "<token_id>", "action": "set", "count": <number>}`
      - Sets the token count to the specified value (must be non-negative).
      - Example: `{"id": "my-token", "action": "set", "count": 100}`
      - Response: `{"count": 100}`
    - **Subtract Token**: `{"id": "<token_id>", "action": "subtract"}`
      - Decrements the token count by 1.
      - Example: `{"id": "my-token", "action": "subtract"}`
      - Response: `{"count": 99}`
  - Errors: Invalid actions or negative counts return a 400 status with an error message.

### Example: Managing Tokens

To set the token count to 100 for testing:

```powershell
$uri = "https://<api-id>.execute-api.<region>.amazonaws.com/prod/tokens/count"
$headers = @{ "x-api-key" = "<API_KEY>"; "Content-Type" = "application/json" }
$body = @{ id = "my-token"; action = "set"; count = 100 } | ConvertTo-Json
Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
```

This updates the token count to 100, visible on both web pages. Customers can then start the POD, consuming one token per start.

### Notes

- **Token ID**: The default `token_id` is `my-token`. To use different IDs, update the `TOKEN_ID` constant in `html/index.html` and `html/admin.html`.
- **Security**: The API key is hardcoded in the HTML files for simplicity. In production, consider using AWS Cognito or a backend proxy to secure API access.
- **DynamoDB**: Ensure the Lambda function has permissions to read/write to the `TokenStore` table.
- **UI Feedback**: The web pages display errors if API calls fail (e.g., invalid API key, network issues).

For more details on the web interface, see the [Customer Page](#customer-page) and [Admin Page](#admin-page) sections. To troubleshoot token-related issues, check the Lambda logs in CloudWatch or the browser’s Developer Tools (F12) Console.

## Prerequisites

- **AWS Account**: Access to an AWS account with administrative privileges.
- **Terraform**: Version 1.5 or later installed.
- **Git**: For cloning the repository.

## Setting Up an AWS Account

1. **Create an AWS Account**:
   - Go to [aws.amazon.com](https://aws.amazon.com) and click "Create an AWS Account".
   - Follow the prompts to set up your account with billing information.
   - Sign in to the AWS Management Console as the root user.

2. **Create an IAM User for Terraform**:
   - In the AWS Console, navigate to **IAM** > **Users** > **Add users**.
   - Name the user (e.g., `terraform-user`) and select **Programmatic access**.
   - Attach the `AdministratorAccess` policy (for simplicity; restrict in production using `custom_permissions.json`).
   - Download the **Access Key ID** and **Secret Access Key** CSV file.

3. **Configure AWS Credentials (Environment Variables)**
  - [Terraform AWS Provider - Authentication and Configuration ](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)

   #### 🔐 Required Environment Variables:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - *(Optional)* `AWS_SESSION_TOKEN` (if using temporary credentials)
   - *(Optional)* `AWS_DEFAULT_REGION`

   ### 📌 For Windows (Command Prompt)
   ```cmd
   set AWS_ACCESS_KEY_ID=your_access_key
   set AWS_SECRET_ACCESS_KEY=your_secret_key
   set AWS_DEFAULT_REGION=us-east-1
   ```
   ### 📌 For Linux / macOS
   ```bash
   export AWS_ACCESS_KEY_ID=your_access_key
   export AWS_SECRET_ACCESS_KEY=your_secret_key
   export AWS_DEFAULT_REGION=us-east-1
   ```

## Setting Up Terraform

1. **Install Terraform**:
   - Download Terraform from [terraform.io](https://www.terraform.io/downloads.html).
   - Extract the binary and add it to your system PATH.
   - Verify:
     ```cmd
     terraform -version
     ```

2. **Clone the Repository**:
     ```cmd
     git clone `https://github.com/dfoos/cloudsurge.git`
     cd cloudsurge
     ```

3. **Directory Structure**:
   ```
    cloudsurge/
    ├── .git/
    ├── .gitignore
    ├── README.md
    ├── main.tf
    ├── outputs.tf
    ├── variables.tf
    ├── html/
    │   ├── admin.htm
    │   └── index.htm
    ├── media/
    │   ├── admin.png
    │   ├── cloudsurge-logo.png
    │   └── customer.png
    ├── modules/
    │   ├── api/
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── dynamo/
    │   │   └── main.tf
    │   ├── ec2/
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── lambda/
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── lambda_function/
    │   │       ├── ec2_control.py
    │   │       └── ec2_control.zip
    │   └── vpc/
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    └── supporting/
        ├── custom_permissions.json
        ├── export.bat
        ├── test-all.ps1
        └── test-api.ps1
   ```

## Deploying CloudSurge with Terraform

1. **Initialize Terraform**:
   ```cmd
   terraform init
   ```

2. **Apply Infrastructure**:
   - Create a key pair for EC2 (e.g., `powergrid-key`) in the AWS Console under **EC2** > **Key Pairs**.
   - Update `main.tf` or `modules/ec2/main.tf` with your `key_name` and region-specific AMI (e.g., `ami-0f3f13f145e66a0a3` for us-east-1).
   - Run:
     ```cmd
     terraform apply
     ```
   - Type `yes` to deploy the EC2 instance, API Gateway, Lambda, and Dynamo.
   - Sometimes API will throw errors due to loading. Run apply again to fix.

3. **Retrieve Outputs**:
   - Get the API key and endpoints:
     ```cmd
     terraform output api_key
     terraform output state_endpoint
     terraform output api_endpoint
     ```
   - Example outputs:
     ```
     api_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
     state_endpoint = "https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/ec2/state"
     api_endpoint = "https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/ec2"
     ```

4. **API Key Permissions**:
   - The API key is created by Terraform in `modules/api/main.tf` with usage restricted to the API Gateway endpoints.
   - The Lambda function (`modules/lambda/main.tf`) has an IAM role with permissions:
     ```json
     {
       "Effect": "Allow",
       "Action": [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
       ],
       "Resource": "*"
     },
     {
       "Effect": "Allow",
       "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
       ],
       "Resource": "*"
     },
        {
       "Effect": "Allow",
       "Action": [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
       ],
       "Resource": "*"
     }

     ```

## Updating API Credentials in HTML Files

1. **Obtain API Values from Terraform**:
   - Run the following commands in the same shell used to run Terraform:
   ```cmd
   terraform output api_key
   terraform output state_endpoint
   terraform output api_endpoint
   ```

2. **Open HTML Files**:
   ```cmd
   notepad index.html
   notepad admin.html
   ```

3. **Update Placeholders**:
   - Replace the following in both files with the Terraform outputs:
    ```javascript
        // Replace with Terraform outputs
        const API_KEY = ''; // Your API Gateway API key (e.g., from aws_api_gateway_api_key.ec2_control_key)
        // STATE_ENDPOINT: URL for checking EC2 instance state
        // Format: https://<api-id>.execute-api.<region>.amazonaws.com/prod/ec2/state
        // Example: https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod/ec2/state
        const STATE_ENDPOINT = 'https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/ec2/state';
        // CONTROL_ENDPOINT: URL for starting/stopping EC2 instances
        // Format: https://<api-id>.execute-api.<region>.amazonaws.com/prod/ec2
        // Example: https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod/ec2
        const CONTROL_ENDPOINT = 'https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/ec2';
        // TOKENS_COUNT_ENDPOINT: URL for getting or updating token count
        // Format: https://<api-id>.execute-api.<region>.amazonaws.com/prod/tokens/count
        // Example: https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod/tokens/count
        const TOKENS_COUNT_ENDPOINT = 'https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/tokens/count';
    ```
   - Save with UTF-8 encoding.


## Calling the API Directly with PowerShell

This section provides PowerShell examples for interacting with the CloudSurge API to manage EC2 instances and tokens. All requests require an API key, obtained from Terraform outputs (`api_key`). Replace `<api-id>`, `<region>`, and `<api_key>` with your actual values.

1. **Get Instance State** (GET `/ec2/state`):
   ```powershell
   $stateEndpoint = "https://<api-id>.execute-api.<region>.amazonaws.com/prod/ec2/state"
   $apiKey = "<api_key>" # e.g., Xyz123Abc4567890
   Invoke-RestMethod -Uri $stateEndpoint -Method Get -Headers @{ "x-api-key" = $apiKey } -ContentType "application/json"
   ```
   - Example response:
     ```json
     { "state": "running" }
     ```
   - Notes: Returns `running`, `stopped`, `pending`, `stopping`, or `mix` if instances tagged `environment=ut` have varied states. `terminated`/`terminating` instances are excluded.

2. **Start or Stop Instances** (POST `/ec2`):
   - Start:
     ```powershell
     $controlEndpoint = "https://<api-id>.execute-api.<region>.amazonaws.com/prod/ec2"
     $apiKey = "<api_key>"
     $body = @{ action = "start" } | ConvertTo-Json
     Invoke-RestMethod -Uri $controlEndpoint -Method Post -Headers @{ "x-api-key" = $apiKey } -Body $body -ContentType "application/json"
     ```
     - Example response:
       ```json
       { "message": "Instances [i-05f03b7840c411034] starting" }
       ```
     - Notes: Only starts instances tagged `environment=ut` in `stopped` state.
   - Stop:
     ```powershell
     $body = @{ action = "stop" } | ConvertTo-Json
     Invoke-RestMethod -Uri $controlEndpoint -Method Post -Headers @{ "x-api-key" = $apiKey } -Body $body -ContentType "application/json"
     ```
     - Example response:
       ```json
       { "message": "Instances [i-05f03b7840c411034] stopping" }
       ```
     - Notes: Stops instances tagged `environment=ut` in `running` state.

3. **Get Token Count** (GET `/tokens/count`):
   ```powershell
   $tokensEndpoint = "https://<api-id>.execute-api.<region>.amazonaws.com/prod/tokens/count?id=my-token"
   $apiKey = "<api_key>"
   Invoke-RestMethod -Uri $tokensEndpoint -Method Get -Headers @{ "x-api-key" = $apiKey } -ContentType "application/json"
   ```
   - Example response:
     ```json
     { "count": 100 }
     ```
   - Notes: Retrieves the token count for `id=my-token`. If no record exists, returns `0` and creates a new record.

4. **Update Token Count** (POST `/tokens/count`):
   - Set Count:
     ```powershell
     $tokensEndpoint = "https://<api-id>.execute-api.<region>.amazonaws.com/prod/tokens/count"
     $apiKey = "<api_key>"
     $body = @{ id = "my-token"; action = "set"; count = 100 } | ConvertTo-Json
     Invoke-RestMethod -Uri $tokensEndpoint -Method Post -Headers @{ "x-api-key" = $apiKey } -Body $body -ContentType "application/json"
     ```
     - Example response:
       ```json
       { "count": 100 }
       ```
     - Notes: Sets the token count to a non-negative integer.
   - Subtract Token:
     ```powershell
     $body = @{ id = "my-token"; action = "subtract" } | ConvertTo-Json
     Invoke-RestMethod -Uri $tokensEndpoint -Method Post -Headers @{ "x-api-key" = $apiKey } -Body $body -ContentType "application/json"
     ```
     - Example response:
       ```json
       { "count": 99 }
       ```
     - Notes: Decrements the token count by 1, used when customers start the POD.


## Cleanup

To avoid charges, destroy the infrastructure:
```cmd
terraform destroy
```
Type `yes` to confirm.


## Architecture Diagram

The following diagram illustrates the CloudSurge hackathon project’s architecture, showing how the web pages, EC2 instances, API Gateway, Lambda function, and DynamoDB interact to manage EC2 instances and tokens.

```ascii
+-------------------+        +-------------------+        +-------------------+
|   Customer Page   |        |     Admin Page    |        |   EC2 Instance    |
|  (html/index.html)|        |  (html/admin.html)|        |  (Web Server)     |
|  - View Tokens 🪙 |        |  - View Tokens 🪙 |        |  - Hosts html/    |
|  - Start POD      |        |  - Set Tokens     |        |    index.html,    |
|                   |        |  - Start/Stop POD |        |    admin.html     |
+-------------------+        +-------------------+        +-------------------+
         |                           |                           |
         | HTTP GET/POST             | HTTP GET/POST             | HTTP GET
         v                           v                           v
+-------------------+                                              |
|    API Gateway    |                                              |
|  - /ec2/state     |                                              |
|  - /ec2           |                                              |
|  - /tokens/count  |                                              |
|  - Secured by     |                                              |
|    API Key        |                                              |
+-------------------+                                              |
         |                                                         |
         | AWS SDK (Lambda Invoke)                                 |
         v                                                         |
+-------------------+                                       +-------------------+
|   Lambda Function |                                       |  EC2 Instances    |
|  - Get EC2 State  |                                       |  (POD)            |
|  - Start/Stop EC2 |                                       |  - Tagged:        |
|  - Get/Set/       |       <---- AWS SDK (DynamoDB) ------>|    environment=ut |
|    Subtract Tokens|                                       |  - States:        |
|                   |                                       |    running,       |
|                   |                                       |    stopped, etc.  |
+-------------------+                                       +-------------------+
         |
         | AWS SDK (DynamoDB)
         v
+-------------------+
|    DynamoDB       |
|  - Table:         |
|    TokenStore     |
|  - id: my-token   |
|  - token: <count> |
+-------------------+

Legend:
- Solid lines: HTTP requests (GET/POST)
- Dashed lines: AWS SDK calls
- 🪙: Token count display on web pages
```

### Component Interactions

- **Customer Page**:
  - **GET /ec2/state**: Checks POD state (e.g., `stopped`, `running`).
  - **GET /tokens/count?id=my-token**: Retrieves token count.
  - **POST /ec2 {action: "start"}**: Starts POD if `stopped` and tokens > 0.
  - **POST /tokens/count {action: "subtract"}**: Decrements token count after starting POD.
- **Admin Page**:
  - **GET /ec2/state**: Checks POD state.
  - **GET /tokens/count?id=my-token**: Retrieves token count.
  - **POST /ec2 {action: "start/stop"}**: Starts/stops POD (no token cost).
  - **POST /tokens/count {action: "set", count: <number>}: Sets token count.
- **EC2 Web Server**:
  - Serves `html/index.html` and `html/admin.html` via Nginx.
- **API Gateway**:
  - Routes HTTP requests to the Lambda function, enforcing API key authentication.
- **Lambda Function**:
  - Queries EC2 for instance states (tagged `environment=ut`, excluding `terminated`/`terminating`).
  - Starts/stops EC2 instances via AWS SDK.
  - Manages token counts in DynamoDB (`TokenStore` table).
- **DynamoDB**:
  - Stores token counts (e.g., `id: my-token`, `token: 100`).
- **EC2 Instances (POD)**:
  - Controlled by Lambda, represent the customer’s workload.

### Notes

- **Security**: The API key is hardcoded in `html/index.html` and `html/admin.html` for simplicity. In production, use AWS Cognito or a backend proxy.
- **Token ID**: Uses `my-token` by default. Update `TOKEN_ID` in HTML files for different IDs.
- **EC2 States**: The Lambda ignores `terminated`/`terminating` instances to avoid `mix` states.
- **Web Hosting**: Assumes an EC2 instance with Nginx serves the HTML files from `/var/www/html/html/`.

For setup details, see [Deployment](#deployment). For API usage, see [Calling the API Directly with PowerShell](#calling-the-api-directly-with-powershell).

## License

This project is for demonstration purposes only and is not licensed for production use.

---

Built for the Hackathon by the Transform Engineering Team. Happy cloud surging🤘!
