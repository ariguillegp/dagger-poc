package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/go"
  "universe.dagger.io/alpine"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
	client: {
		filesystem: ".": read: contents: dagger.#FS
		env: {
			// image that will be pushed
			REGISTRY_IMAGE: string
			// load as a string
			REGISTRY_USER: string
			// load as a secret
			REGISTRY_TOKEN: dagger.#Secret
		}
	}

	actions: {
    // Test app in a "golang" container image.
		test_go: go.#Test & {
			source:  client.filesystem.".".read.contents
			package: "./..."
		}

    // Build app in a "golang" container image.
		build_go: go.#Build & {
			source: client.filesystem.".".read.contents
		}

    // Build container image using Dockerfile
		build_dockerfile: docker.#Dockerfile & {
			source: client.filesystem.".".read.contents
		}

    // Build lighter image, without app's build dependencies.
    // TODO: Add package to handle "scratch" images
    build_cue: docker.#Build & {
      steps: [
        alpine.#Build & {
          packages: "ca-certificates": _
        },
        // This is the important part, it works like
        // `COPY --from=build /output /opt` in a Dockerfile.
        docker.#Copy & {
          contents: build_go.output
          dest:     "/opt"
        },
        docker.#Set & {
          config: cmd: ["/opt/server"]
        },
      ]
    }

    // Push image built with Dockerfile to registry
		push_dockerfile: docker.#Push & {
			image: build_dockerfile.output
			dest:  client.env.REGISTRY_IMAGE
			auth: {
				username: client.env.REGISTRY_USER
				secret:   client.env.REGISTRY_TOKEN
			}
		}

    // Push image built with CUE to registry
		push_cue: docker.#Push & {
			image: build_cue.output
			dest:  client.env.REGISTRY_IMAGE
			auth: {
				username: client.env.REGISTRY_USER
				secret:   client.env.REGISTRY_TOKEN
			}
		}
	}
}
