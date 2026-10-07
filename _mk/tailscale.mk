.PHONY: setup-tailscale-wifi-routing remove-tailscale-wifi-routing tailscale-wifi-routing-status test-tailscale-wifi-routing

TAILSCALE_WIFI_IFACE ?= wlo1
TAILSCALE_WIFI_ROUTE_TABLE ?= 200
TAILSCALE_WIFI_RULE_PRIORITY ?= 5000

setup-tailscale-wifi-routing: ## Tailscale の外向き通信を Wi-Fi へ優先ルーティング
	@if [ "$$(uname -s)" != "Linux" ]; then \
		echo "⏭️  Linux 以外では Tailscale Wi-Fi routing をスキップします"; \
		exit 0; \
	fi
	@if ! command -v ip >/dev/null 2>&1 || ! command -v nmcli >/dev/null 2>&1; then \
		echo "❌ iproute2 と NetworkManager (nmcli) が必要です" >&2; \
		exit 1; \
	fi
	@if ! ip link show "$(TAILSCALE_WIFI_IFACE)" >/dev/null 2>&1; then \
		echo "❌ Wi-Fi interface が見つかりません: $(TAILSCALE_WIFI_IFACE)" >&2; \
		exit 1; \
	fi
	@tmp="$$(mktemp)"; \
	trap 'rm -f "$$tmp"' EXIT; \
	printf '%s\n' \
		'WIFI_IFACE=$(TAILSCALE_WIFI_IFACE)' \
		'ROUTE_TABLE=$(TAILSCALE_WIFI_ROUTE_TABLE)' \
		'RULE_PRIORITY=$(TAILSCALE_WIFI_RULE_PRIORITY)' \
		'TAILSCALE_MARK=0x80000/0xff0000' > "$$tmp"; \
	sudo install -m 0755 _scripts/network/tailscale-wifi-route.sh /usr/local/sbin/tailscale-wifi-route; \
	sudo install -m 0755 _scripts/network/90-tailscale-wifi-route /etc/NetworkManager/dispatcher.d/90-tailscale-wifi-route; \
	sudo install -m 0644 "$$tmp" /etc/default/tailscale-wifi-routing; \
	sudo /usr/local/sbin/tailscale-wifi-route apply

remove-tailscale-wifi-routing: ## Tailscale Wi-Fi routing を撤去
	@if [ -x /usr/local/sbin/tailscale-wifi-route ]; then \
		sudo /usr/local/sbin/tailscale-wifi-route remove; \
	else \
		while sudo ip -4 rule del pref "$(TAILSCALE_WIFI_RULE_PRIORITY)" 2>/dev/null; do :; done; \
		sudo ip -4 route flush table "$(TAILSCALE_WIFI_ROUTE_TABLE)" 2>/dev/null || true; \
	fi
	@sudo rm -f /etc/NetworkManager/dispatcher.d/90-tailscale-wifi-route
	@sudo rm -f /etc/default/tailscale-wifi-routing
	@sudo rm -f /usr/local/sbin/tailscale-wifi-route
	@echo "✅ Tailscale Wi-Fi routing の設定ファイルを撤去しました"

tailscale-wifi-routing-status: ## Tailscale Wi-Fi routing の状態確認
	@if [ -x /usr/local/sbin/tailscale-wifi-route ]; then \
		sudo /usr/local/sbin/tailscale-wifi-route status; \
	else \
		WIFI_IFACE="$(TAILSCALE_WIFI_IFACE)" ROUTE_TABLE="$(TAILSCALE_WIFI_ROUTE_TABLE)" RULE_PRIORITY="$(TAILSCALE_WIFI_RULE_PRIORITY)" \
			bash _scripts/network/tailscale-wifi-route.sh status; \
	fi

test-tailscale-wifi-routing: ## Tailscale Wi-Fi routing の回帰テスト
	@bash _tests/tailscale-wifi-route-test.sh
