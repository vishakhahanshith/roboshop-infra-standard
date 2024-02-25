terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.17.0"
    }
  }

backend "s3" {
  bucket = "roboshop-remote-state"
  key = "redis"
  region = "us-east-1"
  dynamodb_table = "roboshop-locking"
}

}



provider "aws" {
  # Configuration options
  # you can give access key and secret access key here, but security problem
  region = "us-east-1"
}