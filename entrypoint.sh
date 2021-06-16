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

echo "starting nerdctl image pull $(date)" && \
nerdctl image pull ${CONVERT_IMAGE} && \
echo "ending nerdctl image pull $(date)" && \
echo "starting ctr-remote image optimize $(date)" && \
ctr-remote image optimize --oci --reuse ${CONVERT_IMAGE} ${CONVERT_IMAGE}-esgz && \
echo "ending ctr-remote image optimize $(date)" && \
echo "starting nerdctl image push $(date)" && \
nerdctl image push ${CONVERT_IMAGE}-esgz && \
echo "ending nerdctl image push $(date)"

