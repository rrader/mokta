# mokta
Mock Okta

## Build

`docker build -t citizensadvice/mokta .`

## Start

```
docker-compose run -p 4001:4001 -v /path/to/fixtures:/app/data app
```

```
docker run
  -p 4001:4001
  -v your-okta-json-directory:/app/data
  --env URL_HOST=app.test
  --env MOKTA_ISSUER=https://cadev.oktapreview.com
  --env MOKTA_REDIRECT_URL=http://app.test:3001/session
citizensadvice/mokta
```

### JWT claims

Example JSON claims file:

```
{
  "iss": "https://cadev.oktapreview.com",
  "zoneinfo": "Europe/London",
}
```

You can link to your host folder with `-v your-okta-json-directory:/app/data`

The login maps from `test.user@email.com` to `test.user.json` in the data folder.

Passwords are ignored as we are not testing Okta itself.

### Example usage

```
version: "3"

services:
  app:
    build: .
    links:
      - okta:okta.test

  okta:
    image: citizensadvice/mokta
    ports: 4001:4001
    volumes: ./fixtures/okta:/app/data
    env_file: ./default.env
```

### Testing

```
docker-compose run --rm app bundle exec rspec
```

### Configuration

| Key name | Description |
|---|---|
| URL_HOST | The parent app host
| MOKTA_ISSUER | The issuer id must match the iss in your claims
| MOKTA_REDIRECT_URL | The URL to redirect to (POST) after login