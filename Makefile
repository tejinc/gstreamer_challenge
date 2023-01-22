# Makefile Reference: https://gist.github.com/mpneuried/0594963ad38e68917ef189b4e6a269db


# import deploy config
# You can change the default config with `make dpl="config_special.env" build`
dpl ?= docker/configs/deploy.env
include $(dpl)
export $(shell sed 's/=.*//' $(dpl))

# You can change the default config with `make work="config_special.env" build`
work ?= docker/configs/work.env
include $(work)
export $(shell sed 's/=.*//' $(work))

build:
	docker build --tag ${APPLICATION_NAME} .

build-nc:
	docker build --no-cache --tag ${APPLICATION_NAME} .


check-dependency:
	if [ "`docker images -q ${DEPENDENCY}`" = "" ]; then \
		echo "$(DEPENDENCY) not built"; \
		exit 1; \
	else \
		echo "dependency met"; \
	fi

inspect-image:
	docker run -it --rm --entrypoint bash ${APPLICATION_NAME}

test:
	docker run --name ${DEPENDENCY}_test ${DEPENDENCY}
	mkdir -p ${TEMPDIR}
	docker cp ${DEPENDENCY}_test:${TEST_CONTAINER_DIRECTORY}/${TEST_CONTAINER_FILE} ${TEMPDIR}/
	docker container rm ${DEPENDENCY}_test
	docker run  --rm --name ${APPLICATION_NAME} \
				--privileged \
				--net=host \
				--user=0 \
				--security-opt seccomp=unconfined  \
				--runtime nvidia \
				--gpus all \
				--device /dev/dri \
				-v ${TEMPDIR}:${WORKDIR} \
				${APPLICATION_NAME} ${WORKDIR}/${TEST_CONTAINER_FILE} ${WORKDIR}/${TEST_OUTPUT_NAME}
	cp ${TEMPDIR}/${TEST_OUTPUT_NAME} .
	rm ${TEMPDIR} -rf

test-clean:
	docker container rm ${DEPENDENCY}_test

clean:
	docker image rm ${APPLICATION_NAME}

# Docker publish
publish: publish-latest publish-version ## Publish the `{version}` ans `latest` tagged containers to ECR

publish-latest: tag-latest ## Publish the `latest` taged container to ECR
	@echo 'publish latest to $(DOCKER_REPO)'
	docker push $(DOCKER_REPO)/$(APP_NAME):latest

publish-version: tag-version ## Publish the `{version}` taged container to ECR
	@echo 'publish $(VERSION) to $(DOCKER_REPO)'
	docker push $(DOCKER_REPO)/$(APP_NAME):$(VERSION)

# Docker tagging
tag: tag-latest tag-version ## Generate container tags for the `{version}` ans `latest` tags

tag-latest: ## Generate container `{version}` tag
	@echo 'create tag latest'
	docker tag $(APPLICATION_NAME) $(DOCKER_REPO)/$(APPLICATION_NAME):latest

tag-version: ## Generate container `latest` tag
	@echo 'create tag $(VERSION)'
	docker tag $(APPLICATION_NAME) $(DOCKER_REPO)/$(APPLICATION_NAME):$(VERSION)

