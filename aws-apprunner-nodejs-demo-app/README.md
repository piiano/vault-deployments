# Demo App for AWS AppRunner

## About

The sample node application has been built on top of AWS AppRunner using typescript and the Vault [typescript-sdk](https://github.com/piiano/vault-typescript/tree/main/sdk/vault-client).

## Installation

TBD

## Usage

Once deployed this application exposes port 3000 on the AppRunner URL for calls from the internet.
Example:

```
curl <app runner endpoint>:3000
```

The application connects to the Vault and retrieves the status and version.
