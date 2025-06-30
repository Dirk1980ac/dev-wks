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
	glibc-all-langpacks \
	zsh

dnf -y clean all

END_OF_BLOCK

COPY --chown=root:root --chmod=600 authorized_keys /usr/ssh/root.keys
COPY static /usr
COPY etc /etc

# Domain membership and remote admin
RUN <<END_OF_BLOCK
set -eu

echo "Install base packages:"

dnf install \
	--assumeyes \
	--setopt="install_weak_deps=False" \
	freeipa-client \
	cockpit \
	cockpit-selinux \
	cockpit-storaged \
	cockpit-bridge \
	cockpit-system \
	cockpit-networkmanager \
	cockpit-ostree

dnf -y clean all
END_OF_BLOCK

# CLI tools
RUN <<END_OF_BLOCK
set -eu

echo "Install cli tools packages:"

dnf install \
	--assumeyes \
	--setopt="install_weak_deps=False" \
	htop \
	mc \
	testdisk \
	sleuthkit \
	f3 \
	pass \
	yubikey-manager \
	pcsc-tools \
	toolbox

dnf -y clean all
END_OF_BLOCK

# Developement packages
RUN <<END_OF_BLOCK
set -eu

echo "Install Developement packages:"
dnf install \
	--assumeyes \
	--setopt="install_weak_deps=False" \
	@development-tools \
	mingw64-libssh2 \
	mingw64-gtk4 \
	mingw64-glib2 \
	@c-development \
	glib2-devel \
	gtk4-devel \
	mariadb-connector-c-devel \
	pcsc-lite-devel \
	libevent-devel \
	sqlite-devel

dnf -y clean all
END_OF_BLOCK

# GUI
RUN <<END_OF_BLOCK
set -eu

echo "Install GUI software:"

dnf install \
	--assumeyes \
	--setopt="install_weak_deps=False" \
	fedora-chromium-config-gssapi \
	fedora-chromium-config \
	fedora-chromium-config-gssapi \
	fedora-chromium-config-gnome \
	code \
	filezilla \
	gnome-tweaks \
	sqlitebrowser \
	chromium \
	evolution \
	bootc-gtk

dnf -y clean all
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

echo "Masking update timer."
systemctl mask bootc-fetch-apply-updates.timer

rm /var/{log,cache,lib,spool,account,www} -rf

bootc container lint
echo "The magic is done!"
END_OF_BLOCK
