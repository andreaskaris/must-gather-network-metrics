IMAGE ?= "quay.io/akaris/must-gather-network-metrics:v0.4"

.PHONY: build-container
build-container: ## Build the container image, customize with IMAGE="".
	podman build -t $(IMAGE) .

.PHONY: push-container
push-container: ## Push container to registry, customize with IMAGE="".
	podman push $(IMAGE)

.PHONY: must-gather
must-gather: ## Run the must-gather tool, customize with IMAGE="".
	oc adm must-gather --image=$(IMAGE) -- gather

# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

###################################################
# The below targets are for testing only.
###################################################
.PHONY: deploy-network-metrics
deploy-network-metrics:
	sed -i "s#^  newName:.*#  newName: $(IMAGE)#" "resources/kustomization.yaml"
	kubectl apply -k resources/

.PHONY: undeploy-network-metrics
undeploy-network-metrics:
	kubectl delete -k resources/
