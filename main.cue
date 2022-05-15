package main

import (
    "dagger.io/dagger"

    "universe.dagger.io/go"
    "universe.dagger.io/docker"
)

dagger.#Plan & {
    client: {
        filesystem: ".": read: contents: dagger.#FS
        env: {
            // load as a string
            REGISTRY_USER: string
            // load as a secret
            REGISTRY_TOKEN: dagger.#Secret
            // image that will be pushed
            REGISTRY_IMAGE: string
        }
    }

    actions: {
        test: go.#Test & {
            source:  client.filesystem.".".read.contents
            package: "./..."
        }

        build: go.#Build & {
            source: client.filesystem.".".read.contents
        }

        dockerimage: docker.#Dockerfile & {
          source: client.filesystem.".".read.contents
        }

        push: docker.#Push & {
            image: dockerimage.output
            dest: client.env.REGISTRY_IMAGE
            auth: {
              username: client.env.REGISTRY_USER
              secret:   client.env.REGISTRY_TOKEN
            }
        }
    }
}
