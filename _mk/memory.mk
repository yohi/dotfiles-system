# Memory Management and Optimization
# メモリ管理と最適化設定
#
# Note: This module is Linux-specific and uses GNU sed.
# It modifies /etc/sysctl.conf and other Linux system files.

.PHONY: memory-check memory-cleanup memory-monitor memory-optimize

# メモリ使用状況の確認
memory-check:
	@echo "🔍 Memory Usage Analysis"
	@echo "========================"
	@free -h
	@echo ""
	@echo "📊 Top Memory Consuming Processes:"
	@ps aux --sort=-%mem | head -15
	@echo ""
	@echo "💾 Swap Usage:"
	@swapon --show 2>/dev/null || echo "No swap configured"

# メモリクリーンアップ
memory-cleanup:
	@echo "🧹 Memory Cleanup Starting..."
	@echo "Clearing page cache, dentries and inodes..."
	@sudo sync
	@echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
	@echo "✅ Memory cleanup completed"
	@echo ""
	@$(MAKE) memory-check

# 高メモリ使用プロセスの監視
memory-monitor:
	@echo "👀 Monitoring high memory processes (Ctrl+C to stop)..."
	@while true; do \
		clear; \
		echo "$(shell date): Memory Monitor"; \
		echo "==============================="; \
		free -h; \
		echo ""; \
		echo "Top 10 Memory Consumers:"; \
		ps aux --sort=-%mem | head -11; \
		echo ""; \
		echo "Press Ctrl+C to stop monitoring..."; \
		sleep 5; \
	done

# システムメモリ最適化設定
memory-optimize:
	@echo "⚙️  Applying memory optimization settings..."
	
	# Swappiness設定（デフォルト60→10に変更してSSDを保護）
	@echo "Setting swappiness to 10..."
	@if ! grep -q "^vm.swappiness=" /etc/sysctl.conf 2>/dev/null; then \
		echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf > /dev/null; \
	else \
		sudo sed -i 's/^vm.swappiness=.*/vm.swappiness=10/' /etc/sysctl.conf; \
	fi
	@sudo sysctl vm.swappiness=10
	
	# Dirty ratio設定（メモリ使用量を最適化）
	@echo "Optimizing dirty ratios..."
	@if ! grep -q "^vm.dirty_ratio=" /etc/sysctl.conf 2>/dev/null; then \
		echo 'vm.dirty_ratio=15' | sudo tee -a /etc/sysctl.conf > /dev/null; \
	else \
		sudo sed -i 's/^vm.dirty_ratio=.*/vm.dirty_ratio=15/' /etc/sysctl.conf; \
	fi
	@if ! grep -q "^vm.dirty_background_ratio=" /etc/sysctl.conf 2>/dev/null; then \
		echo 'vm.dirty_background_ratio=5' | sudo tee -a /etc/sysctl.conf > /dev/null; \
	else \
		sudo sed -i 's/^vm.dirty_background_ratio=.*/vm.dirty_background_ratio=5/' /etc/sysctl.conf; \
	fi
	@sudo sysctl vm.dirty_ratio=15
	@sudo sysctl vm.dirty_background_ratio=5
	
	# プロセスのOOM killer保護設定
	@echo "Setting up OOM killer protection for important processes..."
	@sudo mkdir -p /etc/systemd/system/user@.service.d
	@echo -e '[Service]\nOOMScoreAdjust=-100' | sudo tee /etc/systemd/system/user@.service.d/oom.conf > /dev/null
	
	@echo "✅ Memory optimization settings applied"
	@echo "🔄 Please reboot to ensure all settings take effect"

# 問題のあるプロセスを特定・対処
memory-troubleshoot:
	@echo "🔧 Memory Troubleshooting"
	@echo "========================"
	@echo ""
	
	# 5GB以上使用しているプロセスを特定
	@echo "🚨 High Memory Processes (>5GB):"
	@ps aux --sort=-%mem | awk 'NR==1 || $$6 > 5242880 {print $$0}'
	@echo ""
	
	# Cursorプロセスの確認
	@echo "🎯 Cursor/Code Processes:"
	@ps aux | grep -E "(cursor|code)" | grep -v grep || echo "No Cursor processes found"
	@echo ""
	
	# Chromeプロセスの確認
	@echo "🌐 Chrome Processes:"
	@ps aux | grep chrome | grep -v grep | wc -l | xargs echo "Chrome process count:"
	@ps aux | grep chrome | grep -v grep | awk '{sum+=$$6} END {printf "Total Chrome memory: %.1f GB\n", sum/1024/1024}' 2>/dev/null || echo "No Chrome processes found"
	@echo ""
	
	# メモリリーク疑いプロセス
	@echo "⚠️  Potential Memory Leak Suspects:"
	@echo "Processes running longer than 24h with high memory:"
	@ps -eo pid,ppid,cmd,etime,%mem,rss --sort=-%mem | awk 'NR==1 || ($$5 > 5 && $$4 ~ /-[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ ) {print $$0}'

# クイックメモリ修復
memory-fix:
	@echo "🚑 Quick Memory Fix"
	@echo "==================="

	# 保護対象プロセスのパターンを定義
	@PROTECTED_PATTERNS="systemd|sshd|NetworkManager|dbus|kernel|init|migration|rcu_|watchdog|ksoftirqd"; \

	# 異常に高いメモリ使用プロセスを特定（保護プロセス除外）
	HIGH_MEM_PIDS=$$(ps aux --sort=-%mem --no-headers | awk -v patterns="$$PROTECTED_PATTERNS" '$$4 > 10 && $$1 != "root" && $$11 !~ /^\[/ && $$11 !~ patterns {print $$2}' | head -5); \
	if [ -n "$$HIGH_MEM_PIDS" ]; then \
		echo "Found high memory processes (excluding system-critical processes):"; \
		ps aux --sort=-%mem | awk -v patterns="$$PROTECTED_PATTERNS" 'NR==1 || ($$4 > 10 && $$1 != "root" && $$11 !~ /^\[/ && $$11 !~ patterns)' | head -6; \
		echo ""; \
		echo "⚠️  重要な確認事項:"; \
		echo "   - 重要なデータが保存されているかご確認ください"; \
		echo "   - 終了対象プロセスが必須アプリケーションでないかご確認ください"; \
		echo "   - システム重要プロセス（systemd, sshd, NetworkManager等）は除外済みです"; \
		echo ""; \
		read -p "これらのプロセスを終了しますか? (y/N): " confirm; \
		if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
			for pid in $$HIGH_MEM_PIDS; do \
				echo "Terminating process $$pid..."; \
				kill -TERM $$pid 2>/dev/null || true; \
			done; \
			sleep 3; \
			echo "Checking if processes terminated gracefully..."; \
			for pid in $$HIGH_MEM_PIDS; do \
				if kill -0 $$pid 2>/dev/null; then \
					echo "Force killing stubborn process $$pid..."; \
					kill -KILL $$pid 2>/dev/null || true; \
				fi; \
			done; \
		else \
			echo "プロセス終了をキャンセルしました。"; \
		fi; \
	else \
		echo "No killable high memory processes found."; \
	fi
	
	@echo ""
	@$(MAKE) memory-cleanup
	@echo "🎉 Memory fix completed!"

# システム情報とメモリ推奨事項
memory-info:
	@echo "💡 Memory System Information & Recommendations"
	@echo "=============================================="
	@echo ""
	
	@echo "💾 Memory Hardware:"
	@sudo dmidecode -t memory 2>/dev/null | grep -E "(Size|Speed|Type|Manufacturer)" | head -10 || echo "Memory info not available"
	@echo ""
	
	@echo "📈 Memory Usage History (if available):"
	@if command -v sar >/dev/null 2>&1; then \
		echo "Recent memory usage:"; \
		sar -r 1 1 2>/dev/null || echo "SAR data not available"; \
	else \
		echo "Install sysstat package for historical memory data"; \
	fi
	@echo ""
	
	@echo "🎯 Recommendations:"
	@TOTAL_MEM=$$(free -m | awk '/^Mem:/ {print $$2}'); \
	if [ $$TOTAL_MEM -lt 8192 ]; then \
		echo "- Consider upgrading to 16GB+ RAM for development"; \
	elif [ $$TOTAL_MEM -lt 16384 ]; then \
		echo "- Good RAM amount for most development tasks"; \
	else \
		echo "- Excellent RAM amount for heavy development"; \
	fi
	@echo "- Monitor Cursor/Chrome memory usage regularly"
	@echo "- Use 'make memory-monitor' for real-time monitoring"
	@echo "- Run 'make memory-cleanup' weekly"

help-memory:
	@echo "🧠 Memory Management Commands"
	@echo "============================"
	@echo ""
	@echo "memory-check        - Check current memory usage"
	@echo "memory-cleanup      - Clean system caches and free memory"
	@echo "memory-monitor      - Real-time memory monitoring"
	@echo "memory-optimize     - Apply system memory optimizations"
	@echo "memory-troubleshoot - Identify problematic processes"
	@echo "memory-fix          - Quick fix for high memory usage"
	@echo "memory-info         - System memory info and recommendations"
	@echo ""
	@echo "Example usage:"
	@echo "  make memory-check           # Quick memory status"
	@echo "  make memory-troubleshoot    # Find memory hogs"
	@echo "  make memory-fix            # Emergency memory cleanup"