docker run --log-driver=awslogs --log-opt awslog-group=docker-logs -d -e SECRET_KEY='${SECRET_KEY}' \
-e WEB_APP_URL='${WEB_APP_URL}' -e WEB_HOOK_SECRET='${WEB_HOOK_SECRET}'
-p ${server_port}:${server_port} 3444866/nomad