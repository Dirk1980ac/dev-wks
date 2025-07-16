FROM registry.fedoraproject.org/fedora-bootc:latest

ARG buildid="unset"
ENV imagename="dev-wks"

LABEL org.opencontainers.image.name=${imagename} \
	org.opencontainers.image.version=${buildid} \
	org.opencontainers.image.description="Developer workstation" \
	org.opencontainers.image.vendor="Dirk Gottschalk" \
	org.opencontainers.image.author="Dirk Gottschalk"

# Install basic system
RUN dnf install -y --exclude="rootfiles" --setopt="install_weak_deps=False" \
	@^workstation-product-environment usbutils && dnf -y clean all

# Copy vscode repository
COPY --chmod=644 configs/dnf-vscode.repo /etc/yum.repos.d/vscode.repo

# Setup install addidional packaged
RUN <<END_OF_BLOCK
set -eu

echo "Add and enable RPMFusion repos install nasty things like evil (proptietary) codecs."
dnf -y install \
	https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
	https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

dnf -y install rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted
dnf -y --repo=rpmfusion-nonfree-tainted --repo=rpmfusion-free-tainted install "*-firmware"

dnf -y install --setopt="install_weak_deps=False" \
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

echo "Installing local packages."
ARCH=$(arch)
shopt -s extglob
shopt -s nullglob

for file in /packages/*.@(${ARCH}.rpm|noarch.rpm); do
	dnf -y install "$file"
done

dnf -y clean all
END_OF_BLOCK

# Copy prepared files
COPY --chmod=600 configs/sshd-00-0local.conf /etc/ssh/sshd_config.d/00-0local.conf
COPY --chmod=644 configs/polkit-40-freeipa.rules /etc/polkit-1/rules.d/40-freeipa.rules
COPY --chmod=644 configs/rpm-ostreed.conf /etc/rpm-ostreed.conf
COPY systemd /usr/lib/systemd/system
COPY skel /etc/skel

# Final configuration
RUN <<END_OF_BLOCK
echo "Writing image version information"
echo "IMAGE_ID=${imagename}" >>/usr/lib/os-release
echo "IMAGE_VERSION=${buildid}" >>/usr/lib/os-release

echo "Enable services."
systemctl enable \
	cockpit.socket \
	sshd \
	systemd-zram-setup@zram0.service \
	bootc-fetch-update-only.timer

echo "Masking update timer."
systemctl mask bootc-fetch-apply-updates.timer

rm /var/{log,cache,spool} -rf

bootc container lint
echo "The magic is done!"
END_OF_BLOCK
