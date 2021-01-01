resource "aws_security_group" "alb" {
  name = "alb"
  description = "Allow inbound https"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "alb" {
  name            = "alb"
  internal        = false
  security_groups = ["${aws_security_group.alb.id}"]
  subnets         = ["subnet-dc4d5fb5", "subnet-1d334d50"]

  enable_deletion_protection = true

  access_logs {
    bucket = "us-west-alb-logs"
    prefix = "paysansorcier"
  }

  tags {
    Environment = "production"
  }
}

resource "aws_alb_target_group" "paysansorcier" {
  name     = "paysansorcier"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = "vpc-506c9838"
  health_check {
    path = "/"
    healthy_threshold = 2
    protocol = "HTTP"
  }
}

resource "aws_alb_target_group_attachment" "paysansorcier_https" {
  target_group_arn = "${aws_alb_target_group.paysansorcier.arn}"
  target_id        = "${aws_instance.paysansorcier.id}"
  port             = 8000
}

resource "aws_alb_listener" "front_end_ssl" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-1-2017-01"
  certificate_arn   = "arn:aws:acm:eu-west-3:791346624208:certificate/1a08c5f2-77cc-40e6-ad8b-899a150726da"

  # default_action {
  #   target_group_arn = "${aws_alb_target_group.chaton.arn}"
  #   type             = "forward"
  # }
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener_rule" "paysansorcier" {
  listener_arn  = "${aws_alb_listener.front_end_ssl.arn}"
  priority      = "2"
  action {
      type = "forward"
      target_group_arn = "${aws_alb_target_group.paysansorcier.arn}"
    }
  condition {
      host_header {
        values = ["www.paysansorcier.fr", "paysansorcier.fr"]
      }
  }
  lifecycle {
      ignore_changes = ["priority"]
  }
}
