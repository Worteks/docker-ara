SKIP_SQUASH?=1

.PHONY: build
build:
	@@SKIP_SQUASH=$(SKIP_SQUASH) hack/build.sh

.PHONY: test
test:
	@@SKIP_SQUASH=$(SKIP_SQUASH) TAG_ON_SUCCESS=$(TAG_ON_SUCCESS) TEST_MODE=true hack/build.sh

.PHONY: run
run:
	@@docker run -d \
	    -e POSTGRESQL_USER=ara -e POSTGRESQL_PASSWORD=ara \
	    -e POSTGRESQL_DATABASE=ara -e POSTGRESQL_ADMIN_PASSWORD=aradmin \
	    -p 5432:5432 docker.io/centos/postgresql-10-centos7:latest
	@@sleep 10
	@@MAINDEV=`ip r | awk '/default/' | sed 's|.* dev \([^ ]*\).*|\1|'`; \
	MAINIP=`ip r | awk "/ dev $$MAINDEV .* src /" | sed 's|.* src \([^ ]*\).*$$|\1|'`; \
	docker run -e POSTGRES_DB=ara -e POSTGRES_HOST=$$MAINIP \
	    -e POSTGRES_PASSWORD=ara -e POSTGRES_USER=ara worteks/ara

.PHONY: ocbuild
ocbuild: occheck
	oc process -f openshift/imagestream.yaml -p FRONTNAME=demo | oc apply -f-
	BRANCH=`git rev-parse --abbrev-ref HEAD`; \
	if test "$$GIT_DEPLOYMENT_TOKEN"; then \
	    oc process -f openshift/build-with-secret.yaml \
		-p "FRONTNAME=demo" \
		-p "GIT_DEPLOYMENT_TOKEN=$$GIT_DEPLOYMENT_TOKEN" \
		-p "ARA_REPOSITORY_REF=$$BRANCH" \
		| oc apply -f-; \
	else \
	    oc process -f openshift/build.yaml \
		-p "FRONTNAME=demo" \
		-p "ARA_REPOSITORY_REF=$$BRANCH" \
		| oc apply -f-; \
	fi

.PHONY: occheck
occheck:
	oc whoami >/dev/null 2>&1 || exit 42

.PHONY: occlean
occlean: occheck
	oc process -f openshift/run-persistent.yaml -p FRONTNAME=demo | oc delete -f- || true
	oc process -f openshift/secret.yaml -p FRONTNAME=demo | oc delete -f- || true

.PHONY: ocdemoephemeral
ocdemoephemeral: ocbuild
	if ! oc describe secret ara-demo >/dev/null 2>&1; then \
	    oc process -f openshift/secret.yaml -p FRONTNAME=demo | oc apply -f-; \
	fi
	oc process -f openshift/run-ephemeral.yaml -p FRONTNAME=demo | oc apply -f-

.PHONY: ocdemopersistent
ocdemopersistent: ocbuild
	if ! oc describe secret ara-demo >/dev/null 2>&1; then \
	    oc process -f openshift/secret.yaml -p FRONTNAME=demo | oc apply -f-; \
	fi
	oc process -f openshift/run-persistent.yaml -p FRONTNAME=demo | oc apply -f-

.PHONY: ocdemo
ocdemo: ocdemoephemeral

.PHONY: ocprod
ocprod: ocdemopersistent

.PHONY: ocpurge
ocpurge: occlean
	oc process -f openshift/build.yaml -p FRONTNAME=demo | oc delete -f- || true
	oc process -f openshift/imagestream.yaml -p FRONTNAME=demo | oc delete -f- || true
