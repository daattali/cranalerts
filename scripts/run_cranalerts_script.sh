#!/bin/bash
# Don't forget to make this file executable to the cronjob user

echo "RUNNING UPDATE SCRIPT"$(date -u +%Y-%m-%dT%H:%M:%SZ)

Rscript /srv/shiny-server/cranalerts/scripts/update_pkgs_send_emails.R

echo "FINISHED RUNNING SCRIPT"$(date -u +%Y-%m-%dT%H:%M:%SZ)