# Justfile for local BlueBuild operations

validate-gaming:
    @echo "Validating gaming desktop recipe..."
    podman run --rm -v {{invocation_directory()}}:/workspace ghcr.io/blue-build/cli:latest validate /workspace/recipes/gaming-desktop.yml

validate-server:
    @echo "Validating server recipe..."
    podman run --rm -v {{invocation_directory()}}:/workspace ghcr.io/blue-build/cli:latest validate /workspace/recipes/server.yml

# Build locally using Podman / Docker
build-gaming:
    @echo "Building gaming desktop image locally..."
    podman run --rm -it --privileged \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v {{invocation_directory()}}:/workspace \
        ghcr.io/blue-build/cli:latest build --recipe /workspace/recipes/gaming-desktop.yml

build-server:
    @echo "Building server image locally..."
    podman run --rm -it --privileged \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v {{invocation_directory()}}:/workspace \
        ghcr.io/blue-build/cli:latest build --recipe /workspace/recipes/server.yml
