FROM registry.fedoraproject.org/fedora-bootc:latest

ARG buildid="unset"

LABEL org.opencontainers.image.version=${buildid}
LABEL org.opencontainers.image.description="Developer workstation"
LABEL org.opencontainers.image.vendor="Dirk Gottschalk"
LABEL org.opencontainers.image.author="Dirk Gottschalk"

COPY etc /etc

RUN <<END_OF_BLOCK
set -eu

mkdir -p /usr/bootc-image
echo "IMAGE_ID=dev-wks" >> /etc/os-release
echo "IMAGE_VERSION=${buildid}" >> /etc/os-release

echo VARIANT_ID=bootserver >> /usr/lib/os-release
dnf -y --exclude=rootfiles --setopt="install_weak_deps=False" install \
	@^workstation-product-environment \
	greenboot-default-health-checks \
	@development-tools \
	libevent-devel \
	pcsc-lite-devel \
	@c-development \
	glib2-devel \
	gtk4-devel \
	chromium \
	mingw64* \
	evolution \
	cockpit \
	greenboot \
	code

END_OF_BLOCK