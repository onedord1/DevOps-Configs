## Generate Nexus Auth Token

Run the following command in your terminal, replacing `<nexus_user>` and `<nexus_pass>` with your credentials:

```bash
echo -n "<nexus_user>:<nexus_pass>" | base64
```

## Export Token as Environment Variable

Export the generated token to an environment variable:

```bash
export NEXUS_AUTH_TOKEN=<base64_encoded_token>
```

You should now have `NEXUS_AUTH_TOKEN` available in your shell session.

## Build the Docker Image

Use the following `docker build` command. Update the build arguments as needed for your environment:

```bash
docker build \
  --no-cache \
  --build-arg VITE_API_BASE_URL=http://172.17.17.162/tracebe \
  --build-arg VITE_RECURRING_CALL=true \
  --build-arg VITE_OTEL_EXPORTER_OTLP_ENDPOINT=http://172.17.17.252:4318 \
  --build-arg NEXUS_AUTH_TOKEN=${NEXUS_AUTH_TOKEN} \
  -t registry.cloudaes.com/quickops-fe/tracefe:nexustest .
```


