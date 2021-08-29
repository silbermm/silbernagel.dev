---
title: "Deploying Elixir on ECS - Part 1"
description: "Deploying Elixir on AWS ECS using Terraform and Github Actions. This first part deals entirely with setting up the Infrastructure using Terraform"
date: 2020-08-23T18:23:57-04:00
keywords: "elixir,terraform,aws,ecs"
#toc: true
series:
- deploying-elixir-on-ecs
categories:
- Elixir
tags:
- Elixir
- AWS
- Terraform
draft: false
---

* **Part 1 - using Terraform to describe and build the infrastructure**
* [Part 2 - building and deploying a docker image to ECS]({{< ref "posts/deploying-elixir-on-ecs-part-2.md" >}})
* [Part 3 - using ECS Service Discovery to build a distributed Elixir cluster]({{< ref "posts/deploying-elixir-on-ecs-part-3.md" >}})

I love PaaS systems like [Heroku](https://www.heroku.com/) for deploying simple Elixir web services. It makes the deployment relatively painless, but it limits the power of the BEAM by making it impossible to do distrubuted clustering. For a project that requires distribution, ECS is a good option. This series of posts will layout how to build the infrastructure, setup CI/CD and connect the Elixir nodes into a distributed cluster.

# The Infrastructure

Below I've split the terraform into sections and talk through each one. Installing and configuring [Terraform](https://www.terraform.io/) for your AWS account is outside the scope of this article, but [HashiCorp](https://learn.hashicorp.com/collections/terraform/aws-get-started) provides a great introduction.

## Initialize Terraform
To start with, you'll need to tell terraform that you want to use the AWS provider. Add this to a file called `main.tf` and run `terraform init`.

```hcl
provider aws {
  profile = "default"
  region  = "us-east-1"
}
```
> I typically keep my terraform files in an `infrastructure` folder in the root of my project

## Add a VPC
One requirment for ECS is a VPC. Most likely, you'll want to build a new VPC and use that, but for brevity you can just import the default VPC that comes with your AWS account. In the AWS console, go to VPC's and find your default VPC's id, it'll start with `vpc-`, and also find the CIDR block.

Add to your terraform file:
```hcl
resource aws_vpc main {
  cidr_block = "your_vpc_CIDR_block"
  tags = {
    Name = "Default VPC"
  }
}

data aws_subnet_ids vpc_subnets {
  vpc_id = aws_vpc.main.id
}

data aws_subnet default_subnet {
  count = "${length(data.aws_subnet_ids.vpc_subnets.ids)}"
  id    = "${tolist(data.aws_subnet_ids.vpc_subnets.ids)[count.index]}"
}

```
Save and run `terraform import aws_vpc.main your_vpc_id` and then `terraform apply` to pull all of the subnets which are needed for subsequent tasks.

This should import the current state of your default VPC and allow you to pass it around to other terraform modules.

## Build the container repo
You'll need a place to upload your container to so that ECS can pull it in. AWS offers ECR (Elastic Container Registry) which is essentially a private docker repo.

To create the registry add to your terraform:
```hcl
resource "aws_ecr_repository" "repo" {
  name                 = "your_repo"  # give this a better name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output repo_url {
  value = aws_ecr_repository.repo.repository_url
}
```

This creates a place to push our images too from our CI/CD process.
Notice the ouput is the URL of the created repository. This will be important later when we talk about deployment.

## Build the ALB (Application Load Balancer)
This will be the public entry point to your web service, and will direct traffic to one of your many containers. To make things easier, this shows how to allow port 80 traffic, but I've commented in the locations that would require a code change for port 443.

> If you want to use  SSL, you'll need to generate a certificate for your domain name. If you manage your domain with Route53, this is easy enough to do in AWS Certificate Manager.


```hcl
# configure the ALB target group
resource aws_lb_target_group lb_target_group {
  name        = "your-app-tg" # choose a name that makes sense
  port        = 4000          # Expose port 4000 from our container
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id # our default vpc id
  target_type = "ip"
  health_check {
    path = "/health"
    port = "4000"
  }
  stickiness {
    type            = "lb_cookie"
    enabled         = "true"
    cookie_duration = "3600"
  }
}

resource aws_lb_listener ecs_listener {
  load_balancer_arn  = "${aws_lb.load_balancer.arn}"
  port               = "80"     # 443 if using SSL
  protocol           = "HTTP"   # HTTPS if using SSL

  # uncomment following lines if using SSL
  # ssl_policy        = "ELBSecurityPolicy-2016-08"
  # certificate_arn   = ""      # the ARN a valid cert from Certificate Manager

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.lb_target_group.arn}"
  }
}

resource aws_lb load_balancer {
  name               = "${var.app_name}_lb"
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
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"  # use HTTPS if ssl is enabled
    from_port   = 80      # use 443 if ssl is enabled
    to_port     = 80      # use 443 if ssl is enabled
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

# the url where you app will be accessible
output dns {
  value = aws_lb.load_balancer.dns_name
}

```

## Configure ECS
And now finally our ECS configuration. ECS has the concept of Clusters which are groups of Services which run 1 or more instances of a Task which is defined by a TaskDefinition. The following configuration will build 1 cluster that has 1 service that runs 2 instances of a task.

### Task Definition
The Task Definition is basically a description of how to run your container. Later on when we deploy, we'll create new versions of this initial Task Definition that point to different versions of your docker image. We can then instruct the ECS service to use our new Task Definition and start new tasks with newer versions of our code.

The Task Definition will also need some roles created.
* The ecs execution role is what is used when the task starts. It needs access to the repository and logs.
* The ecs role is what the task runs under. It is what you can use if you need your task to access other AWS services like S3.

And we'll also need to create the log group so the task can log output.

```hcl
# this may need to change depending
# on how often you run this
variable task_version {
  default = 1
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
      "image": "${aws_ecr_repository.repo.repository_url}:latest",
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.log_group.name}",
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
```

### Cluster and Service
These are pretty easy. We just need to
* create the service and tell it about the task and load balancer
* create a security group to allow traffic out to the world and in from our VPC
* create a cluster

```hcl

# this gets your AWS account id
# needed to build the task ARN later
data "aws_caller_identity" "current" {}

resource aws_ecs_cluster ecs_cluster {
  name = "your_app_cluster"
}

resource aws_ecs_service service {
  name            = "your_app_service"
  cluster         = aws_ecs_cluster.ecs_cluster.id

  task_definition = "arn:aws:ecs:us-east-1:${data.aws_caller_identity.current.account_id}:task-definition/${aws_ecs_task_definition.task_definition.family}:${var.task_version}"
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
```

## The final file
Assuming you have the permission, you should be able `terraform plan` and `terraform apply` the following file.

``` tf {linenos=true}
provider aws {
  profile = "default"
  region  = "us-east-1"
}

variable app_name {
  default = "ecs_app"
}

variable task_version {
  default = 1
}

resource aws_vpc main {
  cidr_block = "172.31.0.0/16"
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_ecr_repository" "repo" {
  name                 = "${var.app_name}_repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

data aws_subnet_ids vpc_subnets {
  vpc_id = aws_vpc.main.id
}

data aws_subnet default_subnet {
  count = "${length(data.aws_subnet_ids.vpc_subnets.ids)}"
  id    = "${tolist(data.aws_subnet_ids.vpc_subnets.ids)[count.index]}"
}

data "aws_caller_identity" "current" {}

resource aws_lb_target_group lb_target_group {
  name        = "ecs-app-tg"
  port        = 4000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path = "/health"
    port = "4000"
  }
  stickiness {
    type            = "lb_cookie"
    enabled         = "true"
    cookie_duration = "3600"
  }
}

resource aws_lb_listener ecs_listener {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}

resource aws_lb load_balancer {
  name               = "ecs-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_security_group.id]
  subnets            = data.aws_subnet.default_subnet.*.id

  enable_deletion_protection = true
}

resource aws_security_group lb_security_group {
  name        = "lb_security_group"
  description = "Allow all outbound traffic and https inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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

resource aws_ecs_cluster ecs_cluster {
  name = "${var.app_name}_cluster"
}

resource aws_ecs_task_definition task_definition {
  family                    = "${var.app_name}_task"
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
      "image": "${aws_ecr_repository.repo.repository_url}:latest",
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.log_group.name}",
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
      "environment": [],
      "mountPoints": [],
      "volumesFrom": [],
      "essential": true,
      "links": [],
      "name": "${var.app_name}"
    }
  ]
  EOF
}

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
}

resource aws_security_group security_group {
  name        = var.app_name
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
  name = "/ecs/${var.app_name}"
}

output repo_url {
  value = aws_ecr_repository.repo.repository_url
}

output dns {
  value = aws_lb.load_balancer.dns_name
}
```

# Wrap up
With the provided terraform file, you should be able to get the infrastructure setup. Of course, there is no image to pull and run yet, so ECS will likely try several times and fail.

In [Part 2]({{< ref "posts/deploying-elixir-on-ecs-part-2.md" >}}) we'll push a Docker container with a simple Phoenix app to our private image repo and instruct ECS to pull and run it.
