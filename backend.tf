terraform {
    backend "s3" {
        bucket = "my-unique-terraform-state-bucket-1234567890"
        key    = "path/to/my/key"
        region = "eu-west-2"
        encrypt = true
    }
}