NAME=recombee/elastalert
REGISTRY=reg.recombee.net:5000
esalert ?= v0.1.28

all: release

remote:
	git push

build:
	docker build --build-arg VERSION=$(esalert) -t $(NAME) .

bash:
	docker run -it $(NAME) /bin/bash

clean:
	docker rm `docker ps -aq`

define RELEASE
	git tag "$(1)"
	git push
	git push origin --tags
	docker tag $(NAME) $(REGISTRY)/$(NAME):$(1)
	docker tag $(NAME) $(REGISTRY)/$(NAME):latest
	docker push $(REGISTRY)/$(NAME)
endef

release: build
	$(call RELEASE,$(v))

push:
	docker push $(REGISTRY)/$(NAME)
