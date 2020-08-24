---
title: "Deploying Elixir on ECS with Terraform and Github Actions - Part 1"
date: 2020-08-23T18:23:57-04:00
draft: true
---

I love PaaS systems like [Heroku](https://www.heroku.com/) for deploying simple web services. It makes the deployment relatively painless, but it limits the power of the BEAM by making it impossible to do distrubuted clusting. [Gigalixir](https://www.gigalixir.com/) seems to have sovled that issue and is probably my plaform of choice... given I have the choice.

At work we are solely AWS customers. We decided to use ECS (Elastic Container Service) which is a container management service. It allows you to use EC2 instances to run your conatiners,or a Serverless offering - Fargate.  We opted to use Fargate to mimimize the amount of infrastructure we needed to manage.

# The Infrastructure
The hardest part of all of this is builing the infrastructure correctly, in a reproducable way and in the right order. To help with this, we use [Terraform](https://www.terraform.io/). Terraform itself can be maddening (the subject of a future post), but it also seeems like a neccesary evil, since the AWS console is so hard to work with.

Below you'll see step-by-step how to build the terraform that will build the required infrastructure. If you prefer, you can skip ahead to the final file

## Initialize Terraform
To start with, you'll need to tell terraform that you want to use the AWS provider. Add this to a file called `main.tf` and run `terraform init`.

```terraform
provider aws {
  profile = "default"
  region  = "us-east-1"
}

```

The other thing we'll need is a VPC. Most likely, you'll want to build your own VPC and use that, but for brevity, we'll just import the default VPC that comes with your AWS account. In the AWS console, go to VPC's and find your default VPC's id, it'll start with `vpc-`, and the CIDR block.

Add to your terraform file:
```terraform
resource aws_vpc main {
  cidr_block = "your_vpc_CIDR_block"
  tags = {
    Name = "Default VPC"
  }
}
```
Save and run `terraform import aws_vpc.main your_vpc_id`

This should import the current state of your default VPC and allow you to pass it around to other terraform modules.

## Build the container repo
You'll need a place to upload your container to so that ECS can pull it in. AWS offers ECR (Elastic Container Registry) which is essentially a private docker repo.

To create the registry add to your terraform:
```terraform
resource "aws_ecr_repository" "repo" {
  name                 = "my_repo"  # give this a better name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output repo_url {
  value = aws_ecr_repository.repo.repository_url
}
```

When it's time, we'll build an image and upload to the url that gets defined.

## The final file

