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