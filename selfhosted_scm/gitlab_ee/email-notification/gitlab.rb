# master@gitlab:~$ cat /var/www/gitlab/config/gitlab.rb 
# #SSH Port
gitlab_rails['gitlab_shell_ssh_port'] = 7474
#external_url 'https://gitlab.cloudaes.com'
external_url 'https://172.17.19.247'
letsencrypt['enable'] = false

nginx['listen_port'] = 443
nginx['listen_https'] = true
nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.cloudaes.com.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.cloudaes.com.key"
nginx['redirect_http_to_https'] = true



gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mail.quickops.io"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "gitlab@quickops.io"
gitlab_rails['smtp_password'] = "7DqR2qNn1tzq"
gitlab_rails['smtp_domain'] = "quickops.io"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
#gitlab_rails['smtp_tls'] = true

gitlab_rails['gitlab_email_from'] = 'gitlab@quickops.io'
gitlab_rails['gitlab_email_display_name'] = 'GitLab'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@quickops.io'
