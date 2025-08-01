FROM registry.fedoraproject.org/fedora-bootc:latest

# Set image name
ENV imagename="dev-wks"

# Install basic system
RUN dnf install -y \
	--exclude="rootfiles" \
	--exclude="virtualbox-guest-additions" \
	--setopt="install_weak_deps=False" \
	@^workstation-product-environment \
	usbutils \
	freeipa-client \
	zsh \
	glibc-all-langpacks && dnf clean packages

# Copy vscode repository.
COPY --chmod=644 configs/dnf-vscode.repo /etc/yum.repos.d/vscode.repo

# RPMFusion Repositories and additional firmware packages from there
RUN <<END_OF_BLOCK
set -eu

REL=$(rpm -E %fedora)

dnf -y install \
	https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$REL.noarch.rpm \
	https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$REL.noarch.rpm

dnf -y install rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted

dnf -y --repo=rpmfusion-nonfree-tainted --repo=rpmfusion-free-tainted install \
	"*-firmware"

dnf clean packages
END_OF_BLOCK

# Tools and admin stuff.
RUN dnf -y install --setopt="install_weak_deps=False" \
	cockpit \
	cockpit-selinux \
	cockpit-storaged \
	cockpit-bridge \
	cockpit-system \
	cockpit-networkmanager \
	cockpit-ostree \
	yubikey-manager \
	pcsc-tools \
	testdisk \
	sleuthkit \
	f3 \
	pass \
	htop \
	mc \
	toolbox && dnf clean packages

# Developer tools, libraries and documentation.
RUN dnf -y install --setopt="install_weak_deps=False" \
	@development-tools \
	@c-development \
	glib2-devel \
	gtk4-devel \
	mariadb-connector-c-devel \
	pcsc-lite-devel \
	libevent-devel \
	mingw64-libssh2 \
	mingw64-gtk4 \
	mingw64-glib2 \
	sqlite-devel \
	gtk4-devel-docs \
	glib2-doc \
	pcsc-lite-doc \
	glibc-doc && dnf clean packages

# GUI applications
RUN dnf -y install --setopt="install_weak_deps=False" \
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
	virt-manager \
	gnome-extensions-app && dnf clean packages

# Install local packages if provided
RUN <<END_OF_BLOCK
set -eu
shopt -s extglob
shopt -s nullglob

for file in /packages/*.@($(arch).rpm|noarch.rpm); do
	dnf -y install "$file"
done

dnf clean packages
END_OF_BLOCK

# System Configuration
COPY --chmod=644 configs/polkit-40-freeipa.rules /etc/polkit-1/rules.d/40-freeipa.rules
COPY --chmod=600 configs/sshd-00-0local.conf /etc/ssh/sshd_config.d/00-0local.conf
COPY --chmod=644 configs/rpm-ostreed.conf /etc/rpm-ostreed.conf
COPY --chmod=644 systemd /usr/lib/systemd/system
COPY --chmod=600 authorized_keys /usr/ssh/root.keys
COPY skel /etc/skel

# Image signature settings
COPY --chmod=644 configs/registries-sigstore.yaml /usr/share/containers/registries.d/sigstore.yaml
COPY --chmod=644 configs/containers-toolbox.conf /etc/containers/toolbox.conf
COPY --chmod=644 configs/containers-policy.json /usr/share/containers/policy.json
COPY --chmod=644 keys /usr/share/containers/keys


# Add metadata after package installation to avoid a rebuilding the whole image
# if it is not necessary.
ARG buildid="unset"
LABEL org.opencontainers.image.name=${imagename} \
	org.opencontainers.image.version=${buildid} \
	org.opencontainers.image.description="Developer workstation" \
	org.opencontainers.image.vendor="Dirk Gottschalk" \
	org.opencontainers.image.author="Dirk Gottschalk"

# Final configuration
RUN <<END_OF_BLOCK
set -eu

dnf -y clean all

chown 755 /usr/share/containers/keys
chown 644 /usr/share/containers/keys/*
rm -f /etc/containers/policy.json
ln -s /usr/share/containers/policy.json /etc/containers/policy.json

echo "IMAGE_ID=${imagename}" >>/usr/lib/os-release
echo "IMAGE_VERSION=${buildid}" >>/usr/lib/os-release

systemctl enable \
	cockpit.socket \
	sshd \
	systemd-zram-setup@zram0.service \
	bootc-fetch-update-only.timer \
	bootloader-update.service

systemctl mask bootc-fetch-apply-updates.timer
find /var/{log,cache} -type f ! -empty -delete
bootc container lint
END_OF_BLOCK
