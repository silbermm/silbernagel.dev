---
title: "Deploying Elixir on ECS - Part 2"
description: "Deploying Elixir on AWS ECS using Terraform and Github Actions. This second part will get your service deployed and running using Github Actions."
date: 2020-08-23T23:37:04-04:00
keywords: "elixir,terraform,aws,ecs"
draft: true
---

In [Part 1]({{< ref "posts/deploying-elixir-on-ecs-part-1.md" >}}) I described how to use terraform to build all of the required infrastructure in AWS. Next I'll build an image, push it to the image repo and tell ECS to run it. This is pretty easy in most CI/CD services, we use Github Actions, but a similar solution can be used in CircleCI or TravisCI.

# Containers and CI

## A simple project
Start by building a simple Phoenix app or feel free to use an existing app that you want to deploy to ECS.

```bash
$ mix phx.new ecs_app --no-ecto --live
```

Add a health controller that has a single endpoint that the ALB will use to determine the health of the service. Make a new file at `lib/ecs_app_web/controllers/health_controller.ex` and add the following content:
```elixir
defmodule EcsAppWeb.HealthController do
  use EcsAppWeb, :controller

  def index(conn, _params) do
    {:ok, vsn} = :application.get_key(:ecs_app, :vsn)

    conn
    |> put_status(200)
    |> json(%{healhy: true, version: List.to_string(vsn), node_name: node()})
  end
end
```

and in `lib/ecs_app_web/router.ex`

```elixir
scope "/", EcsAppWeb do
  get "/health", HealthController, :index
end

```

> This is a pattern I add to a lot of my web services so I can verify the version that's deployed and the node name.

## Dockerfile
The Dockerfile is rather simple and taken almost directly from the [Phoenix Documentation](https://hexdocs.pm/phoenix/releases.html#content). 

Create the file `Dockerfile` and add the following:

```docker
FROM elixir:1.10.0-alpine AS build

ARG MIX_ENV

RUN apk add --no-cache build-base git npm python

WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=${MIX_ENV}
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}

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

FROM alpine:3.9 AS app

ARG MIX_ENV

RUN apk add --no-cache openssl ncurses-libs

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/${MIX_ENV}/rel/ecs_app ./

ENV HOME=/app

CMD ["bin/ecs_app", "start"]
```

## Build Configuraton
I like to create a `Makefile` for building my Docker images and pushing them to ECR. Note the `your_ecr_url` is the url of your ECR that was created in [Part 1]({{< ref "posts/deploying-elixir-on-ecs-part-1.md#build-the-container-repo" >}}).

```makefile
APP_NAME ?= `grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g'`
APP_VSN ?= `grep 'version:' mix.exs | cut -d '"' -f2`
BUILD ?= `git rev-parse --short HEAD`

build_local:
  docker build --build-arg APP_VSN=$(APP_VSN) \
    --build-arg MIX_ENV=dev \
    --build-arg SECRET_KEY_BASE=$(SECRET_KEY_BASE) \
    -t $(APP_NAME):$(APP_VSN) .

build:
  docker build --build-arg APP_VSN=$(APP_VSN) \
    --build-arg MIX_ENV=prod \
    --build-arg SECRET_KEY_BASE=$(SECRET_KEY_BASE) \
    -t your_ecr_url:$(APP_VSN)-$(BUILD) \
    -t your_ecr_url:latest .

push:
  eval `aws ecr get-login --no-include-email --region us-east-1`
  docker push your_ecr_url:$(APP_VSN)-$(BUILD)
  docker push your_ecr_url:latest

deploy:
  ./bin/ecs-deploy -c your_cluster_name -n your_service_name -i your_ecr_url:$(APP_VSN)-$(BUILD) -r us-east-1 -t 300

```
For this to work, you'll need to set an environment variable `SECRET_KEY_BASE`. You can generate a random string with `mix phx.gen.secret`.

Assuming you have docker on your computer, you can now run `make build_local` and it should build and package a production release docker image.

The `push` task will require that you have your AWS access_key and secret setup correctly. See [AWS Documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) to set it up locally. In the next section, I'll talk through getting it setup correctly for Github Actions.

For the `deploy` step, I reference a script at `./bin/ecs-deploy`. You can get this script at [silinternational/ecs-deploy](https://github.com/silinternational/ecs-deploy). Create a folder at the root of your project called `bin` and place the `ecs-deploy` script in it. This will require the same AWS authentication as the `push` task.

## Github Actions
We're going to create one workflow that does three jobs:
  1. Run Tests
  2. Build and push the docker image
  3. Deploy to ECS 

Steps 1 and 2 will run in parallel and only if they are both successful, step 3 will run.


Create a new file at `.github/workflows/ci.yml` with the following content:
```yaml
name: ECS DEPLOYMENT

on:
  push:
    branches: [ main ] #i renamed my master branch to main

jobs:
  test:
  name: Run Tests
  runs-on: ubuntu-latest
   steps:
    - uses: actions/checkout@v2
      with:
        ref: main 
    - uses: actions/cache@v2
      with:
        path: deps
        key: ${{ runner.os }}-mix-${{ hashFiles(format('{0}{1}', github.workspace, '/mix.lock')) }}
        restore-keys: |
          ${{ runner.os }}-mix-
    - name: Set up Elixir
      uses: actions/setup-elixir@v1
      with:
        elixir-version: '1.10.3' 
        otp-version: '22.3' 
    - name: Install dependencies
      run: mix deps.get
    - name: Run tests
      run: MIX_ENV=test mix do compile, test 

  build:
    name: Build And Push Container
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
      with:
        ref: main
    - uses: actions/cache@v2
      with:
        path: deps
        key: ${{ runner.os }}-mix-${{ hashFiles(format('{0}{1}', github.workspace, '/mix.lock')) }}
        restore-keys: |
          ${{ runner.os }}-mix-
    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1

    - name: Build Docker Image
      run: make build
      env:
        SECRET_KEY_BASE: ${{ secrets.SECRET_KEY_BASE }}

    - name: Push Docker Image
      run: make push

  deploy:
    name: Deploy
    runs-on: ubuntu-latest
    needs: [test, build]
    steps:
    - uses: actions/checkout@v2
      with:
        ref: main
    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1

    - name: Deploy
      run: make deploy
```

You'll notice that there are references to three different ${{secrets}}. You can set these in your Github repos Settings page. There is section there call secrets, just add the three secrets and this build will have access.

Now push your code the the repo and your `ci` action should test, build and deploy your code to ECS.

Verify this by going to `your-lb-url.com/health` to see the version and node name of your app.

## Wrap Up

Now there is a reproducable infrastructure definition, and its being deployed on a push to repository. Most projects would probably be done at this point.

In Part 3, I'll show you how I went about building a distributed cluster on ECS using the built in Service Discovery tools.


