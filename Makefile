SHELL:=/bin/bash

# Hosts (defined in your ~/.ssh/config)
PROD_HOST = vps76
DEV_HOST  = vps16

# Config directories
NGINX_DIR = /etc/nginx/conf.d

# ------------------------------------------------------------------
# DEVELOPER (VPS16)
# ------------------------------------------------------------------
.PHONY: deploy-dev
deploy-dev:
	@echo "🚧 Deploying to DEV ($(DEV_HOST))..."
	# 1. Upload common configs (optional)
	# rsync -av ./configs/common/ $(DEV_HOST):/tmp/nginx_common/

	# 2. Upload DEV specific configs
	rsync -avz ./configs/dev/nginx/ $(DEV_HOST):/tmp/nginx_configs/

	# 3. Move into place and reload
	ssh $(DEV_HOST) "sudo cp /tmp/nginx_configs/*.conf $(NGINX_DIR)/ && sudo nginx -t && sudo systemctl reload nginx"
	@echo "✅ Dev deployment complete."

# ------------------------------------------------------------------
# PRODUCTION (VPS76)
# ------------------------------------------------------------------
.PHONY: deploy-prod
deploy-prod:
	@echo "🚀 Deploying to PROD ($(PROD_HOST))..."
	# Safety check: Ask for confirmation
	@read -p "Are you sure you want to deploy to PROD? [y/N] " ans && [ $${ans:-N} = y ]

	rsync -avz ./configs/prod/nginx/ $(PROD_HOST):/tmp/nginx_configs/
	ssh $(PROD_HOST) "sudo cp /tmp/nginx_configs/*.conf $(NGINX_DIR)/ && sudo nginx -t && sudo systemctl reload nginx"
	@echo "✅ Prod deployment complete."
