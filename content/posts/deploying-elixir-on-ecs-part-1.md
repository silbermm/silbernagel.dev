---
title: "Deploying Elixir on ECS - Part 1"
description: "Deploying Elixir on AWS ECS using Terraform and Github Actions. This first part deals entirely with setting up the Infrastructure using Terraform"
date: 2020-08-23T18:23:57-04:00
keywords: "elixir,terraform,aws,ecs"
draft: true
---

I love PaaS systems like [Heroku](https://www.heroku.com/) for deploying simple elixir web services. It makes the deployment relatively painless, but it limits the power of the BEAM by making it impossible to do distrubuted clusting. [Gigalixir](https://www.gigalixir.com/) has sovled that issue and is probably my plaform of choice... given I have the choice.

At work I am limited to using AWS. So for deployment my options are usig EC2 instances or ECS. I opted for ECS with Fargate. It wasn't (at least for me) straight forward to get up and running, and there were few resources specific to elixir, imparticularly connecting nodes. Hopefully this guide will help others that are using AWS to run their Elixir services.

# The Infrastructure
In order to help build the infrastructure correctly, in a reproducable way and in the right order, we use [Terraform](https://www.terraform.io/). Terraform itself can be maddening (the subject of a future post), but it also seeems like a neccesary evil, since the AWS console can be frustrating to work with and often limits the functionality of services.

Below I've split the terraform into sections and talk through each one, or if you prefer, feel free to  [skip ahead to the final file](#the-final-file). Installing and configuring terraform for your AWS account is outside the scope of this article, but [HashiCorp](https://learn.hashicorp.com/collections/terraform/aws-get-started) provides a great introduction.

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
  name                 = "your_repo"  # give this a better name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
```

## Build the ALB (Application Load Balancer)
This will be the public entry point to your web service, and will direct traffic to one of your many containers.

In order to build our ALB, we need to know which subnets to include from our VPC - the following will choose them all, which works fine for our use case.
```terraform
data aws_subnet_ids vpc_subnets {
  vpc_id = aws_vpc.main.id
}

data aws_subnet default_subnet {
  count = "${length(data.aws_subnet_ids.vpc_subnets.ids)}"
  id    = "${tolist(data.aws_subnet_ids.vpc_subnets.ids)[count.index]}"
}
```
Now the rather long ALB configuration.

> If you want an SSL ALB, you will need to generate a certificate for your domain name. If you manage your domain with Route53, this is easy enough to do in AWS Certificate Manager. Once you have the certificate provisioned, grab the ARN for use in the below terraform.


```terraform
# configure the ALB target group
resource aws_lb_target_group lb_target_group {
  name        = "your-app-tg" # choose a name that makes sense
  port        = 4000          # We expose port 4000 from our container
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id # our default vpc id
  target_type = "ip"
  health_check {
    path = "/health" # we configured a rest endpoint that just returns 200 for this
    port = "4000"
  }
  stickiness {
    type            = "lb_cookie"
    enabled         = "true"
    cookie_duration = "3600"
  }
}

# Only listen on 443
resource aws_lb_listener ecs_listener {
  load_balancer_arn = "${aws_lb.load_balancer.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "your_certificate_arn" # Get this from AWS Certificate Manager
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.lb_target_group.arn}"
  }
}

resource aws_lb load_balancer {
  name               = "your_app_lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_security_group.id]
  subnets            = data.aws_subnet.default_subnet.*.id

  enable_deletion_protection = true
}

# needed to allow web traffic to hit the ALB
resource aws_security_group lb_security_group {
  name        = "lb_security_group"
  description = "Allow all outbound traffic and https inbound"
  vpc_id      = var.vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

```
## Configure ECS
And now finally our ECS configuration. ECS has the concept of Clusters which are groups of Services which run 1 or more instances of your container. Here we'll build 1 cluster that has 1 service that runs 2 instances of a container (defined by a Task Definition).

```terraform
resource aws_ecs_cluster ecs_cluster {
  name = "your_app_clister"
}

resource aws_ecs_task_definition task_definition {
  family                    = "your_app_task"
  task_role_arn             = aws_iam_role.ecs_role.arn
  execution_role_arn        = aws_iam_role.ecs_execution_role.arn
  requires_compatibilities  = ["FARGATE"]
  memory                    = 8192
  cpu                       = 4096

  network_mode              = "awsvpc"

  container_definitions     = <<-EOF
  [
    {
      "cpu": 0,
      "image": "${aws_ecr_repository.repository_url}:latest",
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/your_app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "portMappings": [
        {
          "hostPort": 4000,
          "protocol": "tcp",
          "containerPort": 4000
        }
      ],
      # define any enviroment variables you app needs at runtime
      "environment": [],
      "mountPoints": [],
      "volumesFrom": [],
      "essential": true,
      "links": [],
      "name": "your_app"
    }
  ]
  EOF
}

resource aws_ecs_service service {
  name            = "your_app_service"
  cluster         = aws_ecs_cluster.ecs_cluster.id

  # note, you will need to subsitute your_account_id with your actual aws account id
  # I have not found an easier way to get the full task_definition ARN
  task_definition = "arn:aws:ecs:us-east-1:your_account_id:task-definition/${aws_ecs_task_definition.task_definition.family}:1"
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    security_groups   = [aws_security_group.security_group.id]
    subnets           = data.aws_subnet.default_subnet.*.id
    assign_public_ip  = true # this seems to be required to access the container repo
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name   = "your_app"
    container_port   = "4000"
  }

  # this will come into play when we talk about distributed clustering
  service_registries {
    registry_arn =  aws_service_discovery_service.service_discovery.arn
    container_name = "your_app"
  }
}

# needed that that our container can access the outside world
# and traffic in your VPC can access the containers
resource aws_security_group security_group {
  name        = "your_app_ecs"
  description = "Allow all outbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP/S Traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# this is the role that your container runs as
# you can give it permissions to other parts of AWS that it may need to access
# like S3 or DynamoDB for instance.
resource aws_iam_role ecs_role {
  name = "ecs_role"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

# this role and the following permissions are required
# for the ECS service to pull the container from ECR
# and write log events
resource aws_iam_role ecs_execution_role {
  name = "ecs_execution_role"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource aws_iam_policy ecs_policy {
  name = "ecs_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "ecr:GetAuthorizationToken",
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
          ],
          "Resource": "*"
      }
  ]
}
EOF
}

resource aws_iam_policy_attachment attach_ecs_policy {
  name        = "attach-ecs-policy"
  roles       = [aws_iam_role.ecs_execution_role.name]
  policy_arn  = aws_iam_policy.ecs_policy.arn
}

resource aws_cloudwatch_log_group log_group {
  name = "/ecs/your_app"
}

# these enable service discovery to help us cluster our servers
resource "aws_service_discovery_private_dns_namespace" dns_namespace {
  name        = "your_app.local"
  description = "some desc"
  vpc         = aws_vpc.main.id
}

resource "aws_service_discovery_service" service_discovery {
  name = "your_app"

  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.dns_namespace.id}"

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

```

## The final file
Assuming you have the permission, you should be able `terraform plan` and `terraform apply` the following file. Also note that I configured the DNS manually through Route53, although I'm sure there is a way to use terraform for that as well.

{{< gist silbermm 8f5f08389c23a84325259118a47dd22d >}}

# Wrap up
With the provided terraform file, you should be able to get the infrastructure setup. Of course, there is no image to pull and run yet, so ECS will likely try several times and fail. 

In Part 2 we'll push an Elixir container to our private image repo and instruct ECS to pull and run it.



