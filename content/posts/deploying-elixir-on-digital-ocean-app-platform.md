---
title: "Deploying Elixir to Digital Ocean App Platform"
description: "Deploying Elixir to Digital Oceans App Platform"
date: 2021-06-17T18:00:00-04:00
keywords: "elixir,digitalocean,docker"
categories:
- Elixir
tags:
- Elixir
- Digital Ocean
draft: true
---

I recently worked on a project that used [Digital Ocean](https://www.digitalocean.com/) as the infrastructure. We decided to try out their new [App Platform](https://www.digitalocean.com/products/app-platform/), but couldn't find any good examples for Elixir/Phoenix. Here is what we did to get our app deployed and working.

## Assumptions
* You have an existing app that you want to deploy
* You already have your app configured as a [release](https://elixir-lang.org/getting-started/mix-otp/config-and-releases.html)
* You have docker installed and have basic understanding


## Containerize

### Dockerfile
To get started, we'll need a [Dockerfile](https://docs.docker.com/engine/reference/builder/) added to the root of the application. Create a new file called `Dockerfile` and add the following contents (mostly taken from the [Phoenix Docs](https://hexdocs.pm/phoenix/releases.html#containers)):
```docker
FROM elixir:1.12.1-alpine AS build

RUN apk add --no-cache build-base npm git python3

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY priv priv
COPY assets assets
RUN npm run --prefix ./assets deploy
RUN mix phx.digest

COPY lib lib
RUN mix do compile, release

FROM alpine:3.13 AS app
RUN apk add --no-cache openssl ncurses-libs libstdc++

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/your_app ./

ENV HOME=/app

CMD trap 'exit' INT; ./bin/your_app start
```

This is a [multi-stage](https://docs.docker.com/develop/develop-images/multistage-build/) Dockerfile that builds the elixir release.

Test the docker build by running
```bash
docker build -t your_app:latest .
```

Once build, try running it
```bash
docker run --expose 8080 -p 4000:4000 -e SECRET_KEY_BASE=secret_key -e DATABASE_URL=your_db_url -e PORT=4000 --rm -it your_app:latest
```
>be sure to replace `your_db_url` with an actual database url and `secret_key` with the output of `mix phx.gen.secret` and add any other runtime variables you've defined in your app.

### DockerHub

Make sure to create an account on [DockerHub](https://hub.docker.com/) then use `docker login` to authenticate.
Now you can rebuild your docker image using your dockerhub username
```bash
docker build -t docker_username/your_app:latest .
```

and push it to dockerhub

```bash
docker push docker_username/your_app:latest
```

## Digital Ocean Setup

Once you are logged into Digital Ocean, choose the Apps link in the lefthand menu.

![Digital Ocean menu](/img/do_apps.png)

## Deploying

## CI/CD
