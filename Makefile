.PHONY: deps snapshot check apply plan tofu-apply fmt lint

SOPS_ENV = sops exec-env ../secrets/pve.sops.yaml

deps: ; cd ansible && ansible-galaxy collection install -r requirements.yml
snapshot: ; ./scripts/snapshot.sh
check: ; cd ansible && ansible-playbook site.yml --check --diff
apply: ; cd ansible && ansible-playbook site.yml --diff
plan: ; cd tofu && $(SOPS_ENV) 'tofu init -upgrade >/dev/null && tofu plan'
tofu-apply: ; cd tofu && $(SOPS_ENV) 'tofu apply'
fmt: ; cd tofu && tofu fmt -recursive
lint:
	shellcheck scripts/*.sh ansible/roles/*/files/*.sh || true
	cd ansible && ansible-playbook site.yml --syntax-check
	cd tofu && tofu fmt -check -recursive
