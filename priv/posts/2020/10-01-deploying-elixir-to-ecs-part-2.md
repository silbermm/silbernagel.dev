%{
  title: "Deploying Elixir to ECS - Part 2",
  author: "Matt Silbernagel",
  tags: ~w(Elixir AWS Terraform),
  description: "Part 2 in the series of Deploying Elixir to AWS ECS using Terraform. In this post we'll build a simple Phoenix app and deploy it to ECS using Github Actions"
}
---

* [Part 1 - using Terraform to describe and build the infrastructure](/blog/deploying-elixir-to-ecs-part-1)
* **Part 2 - building and deploying a docker image to ECS**
* [Part 3 - using ECS Service Discovery to build a distributed Elixir cluster](/blog/deploying-elixir-to-ecs-part-3)

In [Part 1]("blog/deploying-elixir-to-ecs-part-1") we used terraform to build all of the required ECS infrastructure in AWS. Next we'll build an image, push it to the image repo and tell ECS to run it.

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

## Configuration
There's a few things we'll need to update in the default phoenix configuration.

First update the `prod.exs` by changeing the host to your load balancer url. This was one of the terraform outputs when we built the infrastructure, or it can also be found in the AWS web console:
```elixir
config :ecs_app, EcsAppWeb.Endpoint,
  url: [host: "your-lb.us-east-1.elb.amazonaws.com", port: 4000],
  cache_static_manifest: "priv/static/cache_manifest.json"
```

This will ensure live view works correctly.

Secondly, make sure you uncomment the following line in `config/prod.secret.exs`

```elixir
config :ecs_app, EcsAppWeb.Endpoint, server: true
```

This will ensure the endpoint starts up when running a release.

## Dockerfile
The Dockerfile is rather simple and taken almost directly from the [Phoenix Documentation](https://hexdocs.pm/phoenix/releases.html#content).

Create the file `Dockerfile` and add the following:

```docker
FROM elixir:1.10.0-alpine AS build

ARG MIX_ENV
ARG SECRET_KEY_BASE

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
    --build-arg MIX_ENV=prod \
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
For this to work, you'll need to set an environment variable `SECRET_KEY_BASE` which you can generate with `mix phx.gen.secret`.

Assuming you have docker on your computer, you can now run `make build_local` and it should build and package a production release docker image. And it's always a good idea to try it out locally before deploying:

```bash
$ docker run -p 4000:4000 -it ecs_app:0.1.0
```

You should be able to hit [http://localhost:4000](http://localhost:4000) now.

The `push` task will require that you have the [AWS CLI](https://aws.amazon.com/cli/) installed on your computer and your AWS access_key and secret setup correctly. See [AWS Documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) to set it up locally.

For the `deploy` step, I reference a script at `./bin/ecs-deploy`. You can get this script at [silinternational/ecs-deploy](https://github.com/silinternational/ecs-deploy). Create a folder at the root of your project called `bin` and place the `ecs-deploy` script in it. This will require the same AWS authentication as the `push` task. It also requires that you have `jq` installed on your system and may require you to set the execution bit on the file `chmod +X ./bin/ecs-deploy`.

## Deploy!

Now that we have a simple project, lets get it deployed to ECS. Assuming you have your AWS credentials setup correctly, you should be able to run the following commands in order:
1. `make build`  - builds and tags a docker image
2. `make push`   - pushs that image to your private docker repository
3. `make deploy` - instructs ECS to create a new task defifnition with your latest image and start running it

The deploy task can take some time. It trys to verify that the task is running and that the previous task is stopped. You can now browse to the ECS web console and watch the progress of your task starting.

If everything worked correctly, you should be able to browse to the Load Balancer URL and see the default Phoenix welcome screen!

## Github Actions
It's great that we can build and deploy the app locally, now lets automate the deployment process with Github Actions.

We're going to create one workflow that does three jobs:
  1. Run Tests
  2. Build and push the docker image
  3. Deploy to ECS

Steps 1 and 2 will run in parallel and step 3 will run only if 1 and 2 are both successful.


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

You'll notice that there are references to three different `${{secrets}}`. You can set these in your Github repos Settings page. There is section there called secrets, just add the three secrets and this build will have access.

Now push your code the the repo and your `ci` action should test, build and deploy your code to ECS. You can watch the progress in the Actions tab of your Github repo.

Verify this by going to `your-lb-url.com/health` to see the version and node name of your app.

## Wrap Up

Now there is a reproducable infrastructure definition, and its being deployed on a push to repository. Most projects would probably be done at this point.

In Part 3, I'll show you how to use ECS Service Discovery to build a distributed cluster on ECS.
