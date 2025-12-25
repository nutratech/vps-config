SHELL:=/bin/bash


DEPLOY_HOST ?= vps76

.PHONY: sync
sync:
	rsync -av ./configs/nginx/ $(DEPLOY_HOST):/tmp/nginx_configs/
	ssh $(DEPLOY_HOST) "sudo cp /tmp/nginx_configs/*.conf /etc/nginx/conf.d/ && sudo nginx -t && sudo systemctl reload nginx"

