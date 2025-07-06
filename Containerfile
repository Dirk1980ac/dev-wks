FROM registry.fedoraproject.org/fedora-bootc:latest

ARG buildid="unset"
ENV imagename="dev-wks"

LABEL org.opencontainers.image.name=${imagename} \
	org.opencontainers.image.version=${buildid} \
	org.opencontainers.image.description="Developer workstation" \
	org.opencontainers.image.vendor="Dirk Gottschalk" \
	org.opencontainers.image.author="Dirk Gottschalk"

COPY --chown=root:root --chmod=600 authorized_keys /usr/ssh/root.keys
COPY systemd /usr/lib/systemd
COPY etc /etc

# Setup the basic system
RUN <<END_OF_BLOCK
set -eu

dnf install \
	--assumeyes \
	--exclude="rootfiles" \
	--setopt="install_weak_deps=False" \
	@^workstation-product-environment \
	glibc-all-langpacks \
	zsh \
	freeipa-client \
	cockpit \
	cockpit-selinux \
	cockpit-storaged \
	cockpit-bridge \
	cockpit-system \
	cockpit-networkmanager \
	cockpit-ostree \
	htop \
	mc \
	testdisk \
	sleuthkit \
	f3 \
	pass \
	yubikey-manager \
	pcsc-tools \
	toolbox \
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
	sqlite-devel \
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
	bootc-gtk \
	gtk4-devel-docs \
	glib2-doc \
	pcsc-lite-doc \
	glibc-doc \
	virt-manager \
	gnome-extensions-app

dnf -y clean all

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

rm /var/{log,cache,spool,account,www} -rf

bootc container lint
echo "The magic is done!"
END_OF_BLOCK
