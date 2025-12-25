vps-infra
=========

Infrastructure as Code (IaC) for the **nutra.tk** platform.

This repository handles the automated provisioning, security hardening, and configuration management for the project's Development (VPS16) and Production (VPS76) environments.

Stack
-----
* **OS:** Ubuntu 24.04 LTS
* **Web Server:** Nginx Mainline (HTTP/3 + QUIC, TLS 1.3)
* **Security:** UFW (TCP/UDP), Fail2Ban, SSH Hardening
* **Automation:** Bash (Idempotent scripting) & GNU Make

Workflow
--------

Provisioning
~~~~~~~~~~~~
Bootstrap a fresh VPS instance using the setup script. This installs dependencies, configures the firewall, and sets up auto-renewal for SSL.

.. code:: bash

    # Run as non-root user with sudo privileges
    ./setup.sh

Deployment
~~~~~~~~~~
Configuration changes are managed locally and pushed to environments via Make/Rsync.

.. code:: bash

    # Deploy to Dev (VPS16) - Immediate reload
    make deploy-dev

    # Deploy to Prod (VPS76) - Requires manual confirmation
    make deploy-prod

Structure
---------
::

    .
    ├── configs/
    │   ├── common/     # Shared snippets (mime.types, params)
    │   ├── dev/        # Dev-specific configs (Relaxed caching)
    │   └── prod/       # Prod-specific configs (HTTP/3, HSTS)
    ├── setup.sh        # Idempotent server provisioning
    └── Makefile        # Deployment orchestrator
