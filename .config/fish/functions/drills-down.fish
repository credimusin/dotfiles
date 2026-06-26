function drills-down --description 'Stop drills-dev container'
    podman compose -f /var/home/bmo/Devs/Drills/docker-compose.yml down
end
