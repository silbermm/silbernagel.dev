---
title: "Deploying Elixir on ECS - Part 2"
description: "Deploying Elixir on AWS ECS using Terraform and Github Actions. This second part will get your service deployed and running using Github Actions."
date: 2020-08-23T23:37:04-04:00
keywords: "elixir,terraform,aws,ecs"
draft: true
---

In [part 1]({{< ref "posts/deploying-elixir-on-ecs-part-1.md" >}}) of this series, we built a terraform file that will build all of our required infrastructure in AWS. Now we need to actually build an image, push it to our image repo and tell ECS to run it. This is pretty easy in most CI/CD services, but we'll use Github Actions.

# Part 2 - CONTAINERS and CI/CD

