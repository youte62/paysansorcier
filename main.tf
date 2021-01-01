provider "aws" {
    region = "eu-west-3"
}

variable "username" {
  default = "ubuntu"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "ssh" {
  name = "ssh"
  description = "Allow inbound ssh"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["75.71.5.185/32", "90.35.197.186/32"]
  }
  ingress {
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }
  ingress {
    from_port = 8384
    to_port = 8384
    protocol = "tcp"
    cidr_blocks = ["174.209.28.180/32"]
  }
}

resource "aws_instance" "paysansorcier" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name	= "pierre"
  security_groups = ["default", "${aws_security_group.ssh.name}"]
  availability_zone = "eu-west-3a"
  root_block_device {
    volume_type = "gp2"
    volume_size = "20"
    delete_on_termination = "false"
  }
}


resource "aws_cloudfront_distribution" "distribution" {

  origin {
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
      origin_protocol_policy = "match-viewer"
    }

    # If this syntax looks cumbersome, check https://github.com/hashicorp/terraform/issues/16580
    domain_name = "paysansorcier.fr"
    origin_id   = "paysansorcier.fr"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Managed via terraform"
  # default_root_object = "${var.default_root_object}"

  # logging_config {
  #   include_cookies = true
  #   bucket          = "${aws_s3_bucket.logs_bucket.bucket_domain_name}"
  # }

  aliases = ["www.paysansorcier.fr"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "paysansorcier.fr"

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }

      headers = ["Host"]
    }

    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    min_ttl                = 3600
    default_ttl            = 86400
    max_ttl                = 86400
  }

  restrictions {
  geo_restriction {
        restriction_type = "none"
      }
  }

  # ordered_cache_behavior = "${var.ordered_cache_behavior}"

  # custom_error_response = "${var.custom_error_response}"

  price_class = "PriceClass_200"

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:791346624208:certificate/f13d5c19-0622-4635-96e6-c1bef52852dd"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }
}

output "ip" {
  value = "${aws_instance.paysansorcier.public_ip}"
}

