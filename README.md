# Mokta - Mock okta

## Build

`docker build -t citizensadvice/mokta .`

## Start

```
docker-compose up

# OR

docker-compose run -p 4001:4001 -v /path/to/custom/form:/app/form app
```

Visit http://localhost:4001/embed_uri

### JWT claims

The family name and given name are automatically generated from the username. A `sub` is generated from the hash of the preferred username.

Like Okta, the domain `@citizensadvice.org.uk` is optional in the username.

Additional claims are generated from a [custom form](spec/fixtures/custom_form.haml) using the param `claims`.

Passwords are ignored as we are not testing Okta itself.

If an `OTP_SECRET` env is provided, 2FA will be enabled.

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

| Key name           | Description                                     |
| ---                | ---                                             |
| URL_HOST           | The parent app host and port                    |
| MOKTA_ISSUER       | The issuer id must match the iss in your claims |
| AUTH_AUDIENCE      | The audience claim                              |
| MOKTA_REDIRECT_URL | The URL to redirect to (POST) after login       |
| OTP_SECRET         | If present, enable OTP based 2fa                |

