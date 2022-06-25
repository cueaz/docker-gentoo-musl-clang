NAME = jaeuk
PORT = 12222
WORK = $(HOME)

.PHONY: build start

build:
	docker buildx create --use \
			     --name builder \
			     --driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=200000000 \
			     --driver-opt env.BUILDKIT_STEP_LOG_MAX_SPEED=200000000 \
			     --buildkitd-flags '--allow-insecure-entitlement security.insecure'
	docker buildx build --platform linux/amd64 \
			    --allow security.insecure \
			    --build-arg BUID=$$(id -u) \
	            	    --build-arg BGID=$$(id -g) \
			    --build-arg BUSER=$(NAME) \
			    --output type=oci,dest=$(NAME).tar \
			    .
	docker buildx rm builder

start:
	docker run -d -p $(PORT):22 \
			   -v $(WORK):/home/$(NAME)/work \
			   --env MYUID=$$(id -u) \
			   --env MYGID=$$(id -g) \
			   --env MYUSER=$(NAME) \
			   --init \
			   --restart always \
			   --gpus all \
			   --shm-size 2g \
			   --add-host host.docker.internal:host-gateway \
			   --pid host \
			   --cap-add SYS_PTRACE \
			   --tmpfs /var/tmp:exec \
			   --tmpfs /tmp:exec \
			   --name $(NAME) \
			   $(NAME)
