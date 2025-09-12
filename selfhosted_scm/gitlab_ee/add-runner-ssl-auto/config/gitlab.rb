#SSH Port
gitlab_rails['gitlab_shell_ssh_port'] = 7474
external_url 'https://gitlab.aes-core.com'

letsencrypt['enable'] = false

nginx['listen_port'] = 443
nginx['listen_https'] = true
nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.aes-core.com.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.aes-core.com.key"
nginx['redirect_http_to_https'] = true