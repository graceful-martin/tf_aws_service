terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 3.27"
        }
    }

    required_version = ">= 0.14.9"
}



provider "aws" {
    profile = "default"
    region  = "ap-northeast-2"
}


locals {
    date = "220420"
    tail = "service"
}
