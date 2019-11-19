REVISION_ID		:= 1.6.1-$(shell git rev-parse --short HEAD)
PROJECT_ID		:= rehive-core
REPO_NAME		:= spilo

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

spilo.cloud_build: postgres-appliance/scm-source.json
	gcloud builds submit . \
		--config contrib/cloudbuild-latest.yaml \
		--substitutions _PROJECT_ID=$(PROJECT_ID),_REVISION_ID=$(REVISION_ID),_REPO_NAME=$(REPO_NAME) \
		--gcs-log-dir gs://rehive-core-cloudbuild-logs/$(REPO_NAME)/$(REVISION_ID)

clean:
	rm postgres-appliance/scm-source.json
