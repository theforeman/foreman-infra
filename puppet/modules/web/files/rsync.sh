  # Permit transfer
  $SSH_ORIGINAL_COMMAND

  find /home/website/rsync_cache -type f -exec chmod 644 {} \;
  find /home/website/rsync_cache -type d -exec chmod 755 {} \;
  # Publish the site - stderr/out redirect is required to stop the noninteractive shell from hanging
  rsync -rvx --delete-after /home/website/rsync_cache/ /var/www/vhosts/web/htdocs/ 2>&1 >/dev/null ;
