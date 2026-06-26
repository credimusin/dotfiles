function drills-up --description 'Start drills-dev container'
    podman compose -f /var/home/bmo/Devs/Drills/docker-compose.yml up -d
end
