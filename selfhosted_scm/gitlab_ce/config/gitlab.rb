#SSH Port
gitlab_rails['gitlab_shell_ssh_port'] = 7474
external_url 'http://gitlab.kk.host'

letsencrypt['enable'] = false

nginx['listen_port'] = 80
nginx['listen_https'] = false

nginx['redirect_http_to_https'] = false