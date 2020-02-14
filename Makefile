REVISION_ID		:= 1.6.3-build.$(shell git rev-parse --short HEAD)
PROJECT_ID		:= rehive-services
REPO_NAME		:= spilo-11

REV				:=$(shell git rev-parse HEAD)
URL				:=$(shell git config --get remote.origin.url)
STATUS			:=$(shell git status --porcelain)
GITAUTHOR		:=$(shell git show -s --format="%aN <%aE>" "$(REV)")

postgres-appliance/scm-source.json:
	echo '\
	{\n\
		"url": "git:$(URL)",\n\
		"revision": "$(REV)",\n\
		"author": "$(GITAUTHOR)",\n\
		"status": "$(STATUS)"\n\
	}' > postgres-appliance/scm-source.json

spilo.latest_build: clean postgres-appliance/scm-source.json
	gcloud builds submit . \
		--config contrib/cloudbuild-latest.yaml \
		--substitutions _PROJECT_ID=$(PROJECT_ID),_REVISION_ID=$(REVISION_ID),_REPO_NAME=$(REPO_NAME) \
		--gcs-log-dir gs://$(PROJECT_ID)-cloudbuild-logs/$(REPO_NAME)/$(REVISION_ID)

local.build:
	cd postgres-appliance && \
		./build.sh \
		--build-arg WITH_PERL=false \
		--build-arg COMPRESS=true \
		--build-arg DEMO=false \
		--build-arg PGVERSION=12 \
		--build-arg PGOLDVERSIONS="9.6 11" \
		--build-arg COMPRESS=true \
		-t $(REPO_NAME) -t $(REPO_NAME):$(REVISION_ID) \
		--file Dockerfile --no-cache .

docker.build: local.build
	docker tag $(REPO_NAME):$(REVISION_ID) rehive/$(REPO_NAME):$(REVISION_ID)
	docker tag $(REPO_NAME):$(REVISION_ID) rehive/$(REPO_NAME):latest
	docker push rehive/$(REPO_NAME):$(REVISION_ID)
	docker push rehive/$(REPO_NAME):latest
	git tag $(REVISION_ID) -m "Docker Release $(REVISION_ID)"
	git push origin


clean:
	rm postgres-appliance/scm-source.json
