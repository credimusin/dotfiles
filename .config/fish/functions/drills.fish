function drills --description 'Execute commands inside the drills-dev container'
    podman compose -f /var/home/bmo/Devs/Drills/docker-compose.yml exec drills $argv
end
