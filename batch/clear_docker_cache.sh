# clears the build cache
#https://stackoverflow.com/questions/35594987/how-to-force-docker-for-a-clean-build-of-an-image#comment113906016_45097423
docker stop $(docker ps -aq) && docker builder prune -af && docker image prune -af && docker system prune -af
