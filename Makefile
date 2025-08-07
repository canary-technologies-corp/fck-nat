VERSION := 1.4.0

package: package-rpm

ensure-build:
	mkdir -p build

package-rpm: ensure-build
	rm -f build/fck-nat-$(VERSION)-any.rpm
	@mv .fpm .fpm.bak 2>/dev/null || true
	/opt/homebrew/lib/ruby/gems/3.4.0/bin/fpm \
		-t rpm --version $(VERSION) -p build/fck-nat-$(VERSION)-any.rpm \
		-s dir --name fck-nat --license mit --architecture noarch \
		--rpm-os linux \
		--description "A NAT instance konfigurator" \
		--url "https://github.com/AndrewGuenther/fck-nat" \
		--maintainer "Andrew Guenther <guenther.andrew.j@gmail.com>" \
		--after-install service/post-install.sh \
		--depends aws-cli \
		service/fck-nat.sh=/opt/fck-nat/fck-nat.sh \
		service/fck-nat.service=/etc/systemd/system/fck-nat.service
	@mv .fpm.bak .fpm 2>/dev/null || true

al2023-ami-arm64: package-rpm
	packer build -var 'version=$(VERSION)' -var-file="packer/fck-nat-arm64.pkrvars.hcl" -var-file="packer/fck-nat-al2023.pkrvars.hcl" -var-file="packer/fck-nat-private.pkrvars.hcl" packer/fck-nat.pkr.hcl

al2023-ami-nat64-arm64: package-rpm
	packer build -var 'version=$(VERSION)' -var 'ami_prefix=nat64-' -var-file="packer/fck-nat-arm64.pkrvars.hcl" -var-file="packer/fck-nat-al2023.pkrvars.hcl" -var-file="packer/fck-nat-private.pkrvars.hcl" packer/fck-nat.pkr.hcl

al2023-ami-x86: package-rpm
	packer build -var 'version=$(VERSION)' -var-file="packer/fck-nat-x86_64.pkrvars.hcl" -var-file="packer/fck-nat-al2023.pkrvars.hcl" -var-file="packer/fck-nat-private.pkrvars.hcl" packer/fck-nat.pkr.hcl

al2023-ami-nat64-x86: package-rpm
	packer build -var 'version=$(VERSION)' -var 'ami_prefix=nat64-' -var-file="packer/fck-nat-x86_64.pkrvars.hcl" -var-file="packer/fck-nat-al2023.pkrvars.hcl" -var-file="packer/fck-nat-private.pkrvars.hcl" packer/fck-nat.pkr.hcl

al2023-ami: al2023-ami-arm64 al2023-ami-x86

all-amis: al2023-ami

publish: regions_file = -var-file="packer/fck-nat-public-all-regions.pkrvars.hcl"
publish: all-amis
