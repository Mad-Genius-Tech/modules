mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name   = "us-west-2"
      region = "us-west-2"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
      user_id    = "AIDATEST"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }
}

run "private_static_alias_uses_weighted_cname" {
  command = plan

  variables {
    org_name                   = "mgb"
    stage_name                 = "test"
    service_name               = "fabric"
    team_name                  = "platform"
    tags                       = {}
    private_subnets            = ["subnet-private"]
    public_subnets             = ["subnet-public"]
    ingress_cidr_blocks        = ["10.0.0.0/16"]
    vpc_id                     = "vpc-test"
    vpc_cidr                   = "10.0.0.0/16"
    create_internal_alb        = false
    service_discovery_dns_name = "fabric.test"

    ecs_services = {
      api = {
        container_image                = "123456789012.dkr.ecr.us-west-2.amazonaws.com/api:test"
        require_repository_credentials = false
        enable_service_discovery       = true
      }
    }
    service_discovery_cname_aliases = {
      docs   = "s3.fabric.test"
      agents = "s3.fabric.test"
    }
  }

  assert {
    condition = (
      aws_service_discovery_service.cname_alias["docs"].dns_config[0].routing_policy == "WEIGHTED" &&
      aws_service_discovery_service.cname_alias["docs"].dns_config[0].dns_records[0].type == "CNAME" &&
      aws_service_discovery_service.cname_alias["docs"].dns_config[0].dns_records[0].ttl == 10
    )
    error_message = "Private static aliases must be weighted Cloud Map CNAME records with the standard short TTL."
  }

  assert {
    condition     = aws_service_discovery_instance.cname_alias["agents"].attributes.AWS_INSTANCE_CNAME == "s3.fabric.test"
    error_message = "The Cloud Map instance must return the requested stable CNAME target."
  }
}

run "reject_alias_that_collides_with_ecs_discovery" {
  command = plan

  variables {
    org_name                   = "mgb"
    stage_name                 = "test"
    service_name               = "fabric"
    team_name                  = "platform"
    tags                       = {}
    private_subnets            = ["subnet-private"]
    public_subnets             = ["subnet-public"]
    ingress_cidr_blocks        = ["10.0.0.0/16"]
    vpc_id                     = "vpc-test"
    vpc_cidr                   = "10.0.0.0/16"
    create_internal_alb        = false
    service_discovery_dns_name = "fabric.test"

    ecs_services = {
      docs = {
        container_image          = "123456789012.dkr.ecr.us-west-2.amazonaws.com/docs:test"
        require_repository_credentials = false
        enable_service_discovery = true
      }
    }
    service_discovery_cname_aliases = {
      docs = "s3.fabric.test"
    }
  }

  expect_failures = [aws_service_discovery_service.cname_alias]
}
