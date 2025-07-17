resource "aws_security_group" "ec2_sg" {
  vpc_id = var.vpc_id

  ingress {
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

  tags = {
    Name = "ec2-sg",
  }
}

locals {
  instance_names = [for i in range(var.ec2_count) : "${var.ec2_name}-${i + 1}"]
}

resource "aws_instance" "app" {
  for_each = toset(local.instance_names)

  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              # Log output for debugging
              exec > /var/log/user-data.log 2>&1
              set -x

              # Install Nginx
              yum update -y
              yum install -y amazon-linux-extras
              amazon-linux-extras enable nginx1
              yum clean metadata
              yum install -y nginx

              # Remove default pages
              rm -f /usr/share/nginx/html/index.html /var/www/html/index.html

              # Create and set directory permissions
              mkdir -p /var/www/html
              chmod 755 /var/www/html
              chown nginx:nginx /var/www/html

              # Write webpage content
              cat << 'HTML' > /var/www/html/index.html
              <html>
              <head><title>CloudSurge</title></head>
              <body>
                  <h1>Welcome to CloudSurge!</h1>
                  <img src="https://s3.us-east-1.amazonaws.com/derrickfoos.com/images/OnBase-Logo.png" alt="OnBase Logo">
              </body>
              </html>
              HTML

              # Set file permissions and SELinux context
              chmod 644 /var/www/html/index.html
              chown nginx:nginx /var/www/html/index.html
              if command -v chcon >/dev/null; then
                  chcon -t httpd_sys_content_t /var/www/html/index.html
              fi

              # Configure Nginx
              cat << 'CONF' > /etc/nginx/conf.d/default.conf
              server {
                  listen       80;
                  server_name  localhost;
                  root         /var/www/html;
                  index        index.html;
                  location / {
                      try_files $uri $uri/ /index.html;
                  }
                  error_page 404 /index.html;
              }
              CONF
              chmod 644 /etc/nginx/conf.d/default.conf
              chown nginx:nginx /etc/nginx/conf.d/default.conf

              # Start and enable Nginx
              systemctl start nginx
              systemctl enable nginx
              systemctl restart nginx

              # Log status
              systemctl status nginx >> /var/log/user-data.log
              ls -lZ /var/www/html >> /var/log/user-data.log
              cat /var/www/html/index.html >> /var/log/user-data.log
              cat /etc/nginx/conf.d/default.conf >> /var/log/user-data.log
              EOF

  tags = {
    Name = each.value
    environment = "ut"
  }
}