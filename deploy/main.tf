terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  version = "~> 6.0"
  region  = "ap-southeast-2"
}



resource "aws_dynamodb_table" "drawing-table" {
  name = "drawing dynamodb"  
  billing_mode = "PAY_PER_REQUEST"
  stream_enabled = true
  
  attribute {
    name = "canvas-id"
    type = "S"
  }
}
