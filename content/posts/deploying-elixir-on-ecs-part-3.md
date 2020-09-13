---
title: "Deploying Elixir on ECS - Part 3"
description: "Deploying Elixir on AWS ECS using Terraform and Github Actions. This third part will get help you build a distrubuted Elixir cluster using ECS service discovery"
date: 2020-09-12T21:14:19-04:00
categories:
- Elixir
tags:
- Elixir
- AWS
- Terraform
keywords: "elixir,terraform,aws,ecs"
draft: false
---

* [Part 1 - using Terraform to describe and build the infrastructure]({{< ref "posts/deploying-elixir-on-ecs-part-1.md" >}})
* [Part 2 - building and deploying a docker image to ECS]({{< ref "posts/deploying-elixir-on-ecs-part-2.md" >}})
* **Part 3 - using ECS Service Discovery to build a distributed Elixir cluster**


In Parts 1 and 2, we built the infrastructure and deployed a very simple Phoenix application. We can scale up our application since it's behind a load balancer by increasing the number of Tasks in our ECS service. For a lot of use cases, that works just fine. But if we are using Phoenix Presence or anything that requires coordination between the Elixir nodes, we'll need to build a cluster.

In order to do this we'll need do a several things:

  * Update our ECS service to include Service Discovery
  * Include libcluster to automatically connect nodes
  * Update our Release to include a pre-start script that names our node
  * Make sure all nodes have the same COOKIE
  
## Update the ECS Service

ECS includes [Service Discovery](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html) that we can setup via Terraform. Add this to our previous Terraform file:

```tf

resource "aws_service_discovery_private_dns_namespace" dns_namespace {
  name        = "${var.app_name}.local"
  description = "some desc"
  vpc         = aws_vpc.main.id
}

resource "aws_service_discovery_service" service_discovery {
  name = var.app_name

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.dns_namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

```

and then reference the service discovery in the `service` resource:
```tf {hl_lines=[19,20,21,22]}
resource aws_ecs_service service {
  name            = "${var.app_name}_service"
  cluster         = aws_ecs_cluster.ecs_cluster.id

  task_definition = "arn:aws:ecs:us-east-1:${data.aws_caller_identity.current.account_id}:task-definition/${aws_ecs_task_definition.task_definition.family}:${var.task_version}"
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    security_groups   = [aws_security_group.security_group.id]
    subnets           = data.aws_subnet.default_subnet.*.id
    assign_public_ip  = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name   = var.app_name
    container_port   = "4000"
  }

  service_registries {
    registry_arn =  aws_service_discovery_service.service_discovery.arn
    container_name = var.app_name 
  }
}
```
This will create a service registry and register our services ip address when it starts up. It uses Route53 to do this by creating a private DNS entry that can be called anything you like. In the above definition, we called it `ecs_app.local`. When a new task starts up, it will be registed as an `A` record under that DNS namespace.

Make sure to run `terraform plan` and  `terraform apply`. 

> Adding service registries to a ECS service is a destructive action, so don't be alarmed that it will destroy then recreate your ECS service.

## Auto connecting nodes with libcluster

Now that our nodes are registered, we need a way to connect them.  To do this, we'll use [libcluster](https://github.com/bitwalker/libcluster) which is a great small library that makes cluster auto formation very easy. It comes with several different strategys out-of-the-box including kubernetes, network gossip, using an Erlang hosts file, and the one we'll use, DNSPoll.

Lets first add libcluster as a dependency.

```elixir
# mix.exs
defmodule EcsApp.MixProject do
  use Mix.Project

  # ...

  defp deps do
    {:libcluster, "~> 3.2"},
    # all your other deps
  end

end
```

and run `mix deps.get`

Now we need to configure libcluster. I like to do this in the `application.ex` file.
```elixir {hl_lines=["6-15", 18]}
# lib/ecs_app/application.ex
defmodule EcsApp.Application do
  use Application

  def start(_type, _args) do
  topologies = [
      ecs_app: [
        strategy: Cluster.Strategy.DNSPoll,
        config: [
          polling_interval: 1000,
          query: "ecs_app.ecs_app.local",
          node_basename: "ecs_app"
        ]
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies, [name: EcsApp.ClusterSupervisor]]},
      EcsAppWeb.Telemetry,
      {Phoenix.PubSub, name: EcsApp.PubSub},
      EcsAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: EcsApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
```

## Naming the Nodes

Libcluster assumes that your nodes are named a certain way - app @ ip address - for example `ecs_app@192.168.1.10`. In order to do this, we'll use a release script to set the [long name](https://erlang.org/doc/reference_manual/distributed.html#nodes) of our node.

Start by generating the default templates
```bash
mix release.init
```

This will create a new folder at `rel/` with three new files. The one we care about is `env.sh.eex`. Make it look like the following:
```bash {linenos=true}
#!/bin/sh
export PUBLIC_HOSTNAME=`curl ${ECS_CONTAINER_METADATA_URI}/task | jq -r ".Containers[0].Networks[0].IPv4Addresses[0]"`
export RELEASE_DISTRIBUTION=name
export RELEASE_NODE=<%= @release.name %>@${PUBLIC_HOSTNAME}
```

Here is whats happening in this file. 
  * Line 2 - This gets the [Metadata](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-metadata-endpoint-v3.html#task-metadata-endpoint-v3-response) for the current Task, parses it using `jq` to get the IP Address and sets the variable `PUBLIC_HOSTNAME` to that ip address.
  * Line 3 - This tells the Release to use the long name format
  * Line 4 - Sets the long name of the node to `app_name@ip_address` i.e `ecs_app@192.168.1.10`

This script runs as part of the release, but we still need to tell Docker to include it. We also need to install `jq` and `curl` in our container.

```dockerfile {hl_lines=[32,41]}
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

RUN echo $SECRET_KEY_BASE

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
COPY rel rel

RUN mix do compile, release

FROM alpine:3.9 AS app

ARG MIX_ENV
ARG SECRET_KEY_BASE

RUN apk add --no-cache openssl ncurses-libs curl jq

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/${MIX_ENV}/rel/ecs_app ./

ENV HOME=/app

CMD ["bin/ecs_app", "start"]
```

## Set the cookie
The last thing we need to do is make sure all the nodes have the same cookie. This is required for the nodes to connect.

In the AWS ECS console, we can set environment variables and the release will look for one called `RELEASE_COOKIE`. Lets set that up.

  * Find your current TaskDefinition for your service and choose to `Create a New Revision`. 
  * In the Container Definition settings, click your container name and find the Environment Variables section. 
    * In the Key field type `RELEASE_COOKIE` and in the value field the result of running `mix phx.gen.secret`. 
  * Click update then scroll down and click Create
  * In the Actions dropdown, choose Update Service
  * Scroll down and click Skip to Review
  * Scroll down and click Update Service

Assuming everything goes well, your new Task Definition will start running.

## Finalize

Finally, push up your latest changes and let it deploy. Once deployed, you should be able to increase the number of tasks running, and your nodes should all connect. This is usually easily verified via logging or by turning on the LiveDashboard in production.

For an example application, see [this github repo](https://github.com/silbermm/ecs_example)
