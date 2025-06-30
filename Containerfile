FROM registry.fedoraproject.org/fedora-bootc:latest

ARG buildid="unset"
ENV imagename="dev-wks"

LABEL org.opencontainers.image.name=${imagename} \
	org.opencontainers.image.version=${buildid} \
	org.opencontainers.image.description="Developer workstation" \
	org.opencontainers.image.vendor="Dirk Gottschalk" \
	org.opencontainers.image.author="Dirk Gottschalk"

# Setup the basic system
RUN <<END_OF_BLOCK
set -eu

dnf install \
	--assumeyes \
	--exclude="rootfiles" \
	--setopt="install_weak_deps=False" \
	@^workstation-product-environment \
	greenboot-default-health-checks \
	freeipa-client \
	glibc-all-langpacks \
	chromium \
	evolution \
	cockpit \
	bootc-gtk

dnf -y clean all

END_OF_BLOCK

COPY systemd /usr/lib/systemd
COPY etc /etc
COPY --chown=root:root --chmod=600 authorized_keys /usr/ssh/root.keys

RUN <<END_OF_BLOCK
set -eu

dnf install \
	--assumeyes \
	@development-tools \
	mingw64-libssh2 \
	mingw64-gtk4 \
	mingw64-glib2 \
	@c-development \
	glib2-devel \
	gtk4-devel \
	mariadb-connector-c-devel \
	fedora-chromium-config-gssapi \
	pcsc-lite-devel \
	libevent-devel \
	sqlite-devel \
	toolbox \
	code \
	htop \
	mc \
	cockpit-selinux \
	cockpit-storaged \
	cockpit-bridge \
	cockpit-system \
	cockpit-networkmanager \
	cockpit-ostree \
	testdisk \
	sleuthkit \
	filezilla \
	zsh \
	f3

dnf -y clean all
rm /var/{log,cache,lib,spool,account,www} -rf
END_OF_BLOCK

RUN <<END_OF_BLOCK
set -eu

echo "Writing image version information"
echo "IMAGE_ID=${imagename}" >>/usr/lib/os-release
echo "IMAGE_VERSION=${buildid}" >>/usr/lib/os-release

echo "Enable services."
systemctl enable \
	cockpit.socket \
	sshd \
	systemd-zram-setup@zram0.service \
	bootc-fetch-update-only.service \
	bootc-fetch-update-only.timer

echo "Mask update and apply timer to avoid auto-reboot."
systemctl mask bootc-fetch-apply-updates.timer

bootc container lint
echo "The magic is done!"
END_OF_BLOCK
