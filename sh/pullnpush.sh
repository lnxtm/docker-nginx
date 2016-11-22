#!/bin/bash
cd /code && git pull origin ${BRANCH} && \
git add . && git commit -m "commit from container | $(date +%H:%M:%S) $(date '+%b %d, %Y') " && \
git push origin ${BRANCH}
chown -R www-data:www-data /code
find /code/ -type d -exec chmod -R 755 {} + 
find /code/ -type f -exec chmod -R 644 {} + 
exit 0