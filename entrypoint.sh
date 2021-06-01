#!/bin/bash

if [ -z "${CONVERT_IMAGE}" ]; then
  echo "CONVERT_IMAGE env is empty"
  exit 1
fi

containerd-stargz-grpc --log-level=debug \
                       --address="${REMOTE_SNAPSHOTTER_SOCKET}" \
                       --config="${REMOTE_SNAPSHOTTER_CONFIG_DIR}config.toml" &

until ls "${REMOTE_SNAPSHOTTER_SOCKET}"; do
  sleep 1;
done

containerd --config="${CONTAINERD_CONFIG_DIR}config.toml" &

until ls /run/containerd/containerd.sock; do
  sleep 1;
done

echo "get current image in containerd"
nerdctl image ls
ctr-remote image ls

echo "converting ${CONVERT_IMAGE}"
nerdctl image pull ${CONVERT_IMAGE} && \
ctr-remote image optimize --oci ${CONVERT_IMAGE} ${CONVERT_IMAGE}-esgz && \
nerdctl image push ${CONVERT_IMAGE}-esgz

