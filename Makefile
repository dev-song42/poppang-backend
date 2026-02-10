# =========================================================
# PopPang Local DB Makefile
# - Uses .env file (if exists)
# - Safe local-only reset
# - DROP -> CREATE -> SCHEMA APPLY
# =========================================================

.DEFAULT_GOAL := help

# ---------------------------------------------------------
# Load .env (if exists)
# ---------------------------------------------------------
ifneq (,$(wildcard .env))
  include .env
  export
endif

# ---------------------------------------------------------
# Required env vars (in .env)
#   DB_HOST=127.0.0.1
#   DB_PORT=3306
#   DB_USER=root
#   DB_PASSWORD=your_password
#   DB_NAME=poppang_local_schema

#   SCHEMA_FILE=sql/schema/schema.sql
#   SEED_RECOMMEND=/sql/seed/recommend_seed.sql
#   SEED_POPUP_100K_FILE=sql/seed/popup_seed_100k.sql
#   SEED_USER_100K_FILE=./sql/seed/user_seed_100k.sql
#   VERIFY_COUNTS_FILE=sql/verify/counts.sql
#   VERIFY_FK_FILE=sql/verify/fk_check.sql

# Optional safety:
#   ALLOW_DB_RESET=true
# ---------------------------------------------------------

# ---------------------------------------------------------
# MySQL command (secure password handling)
# ---------------------------------------------------------
MYSQL_CMD = MYSQL_PWD=$(DB_PASSWORD) mysql -h $(DB_HOST) -P $(DB_PORT) -u $(DB_USER)


# ---------------------------------------------------------
# Helper function: Check file exists
# ---------------------------------------------------------
define check_file
	@if [ ! -f "$(1)" ]; then \
		echo "❌ File not found: $(1)"; \
		exit 1; \
	fi
endef

# ---------------------------------------------------------
# Phony targets
# ---------------------------------------------------------
.PHONY: help guard check-env db-reset db-drop db-create db-schema db-status db-seed-recommend db-seed-popup-100k db-seed-all db-seed-user-100k db-verify db-counts db-fk-check

help: ## Show available commands
	@echo ""
	@echo "Available commands:"
	@grep -hE '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "Example:"
	@echo "  make db-reset"
	@echo "  make db-seed-all"
	@echo ""

# ---------------------------------------------------------
# Check environment variables
# ---------------------------------------------------------
check-env: ## Check if required env vars are set
	@echo "🔍 Checking environment variables..."

	@if [ -z "$(DB_HOST)" ]; then echo "❌ DB_HOST is not set"; exit 1; fi
	@if [ -z "$(DB_PORT)" ]; then echo "❌ DB_PORT is not set"; exit 1; fi
	@if [ -z "$(DB_USER)" ]; then echo "❌ DB_USER is not set"; exit 1; fi
	@if [ -z "$(DB_PASSWORD)" ]; then echo "❌ DB_PASSWORD is not set"; exit 1; fi
	@if [ -z "$(DB_NAME)" ]; then echo "❌ DB_NAME is not set"; exit 1; fi
	@if [ -z "$(SCHEMA_FILE)" ]; then echo "❌ SCHEMA_FILE is not set"; exit 1; fi
	@if [ -z "$(SEED_RECOMMEND)" ]; then echo "❌ SEED_RECOMMEND is not set"; exit 1; fi
	@if [ -z "$(SEED_POPUP_100K_FILE)" ]; then echo "❌ SEED_POPUP_100K_FILE is not set"; exit 1; fi
	@if [ -z "$(SEED_USER_100K_FILE)" ]; then echo "❌ SEED_USER_100K_FILE is not set"; exit 1; fi

	@echo "✅ All required environment variables are set"

# ---------------------------------------------------------
# Safety Guard (prevent production accidents)
# - Requires ALLOW_DB_RESET=true
# - Blocks dangerous hostnames
# ---------------------------------------------------------
guard: check-env ## Safety guard (prevents accidental prod reset)
	@echo "🛡️  Running safety checks..."
	@if [ "$(ALLOW_DB_RESET)" != "true" ]; then \
		echo "❌ Refusing to run: set ALLOW_DB_RESET=true in .env (local only)"; \
		exit 1; \
	fi
	@if [ "$(DB_HOST)" != "127.0.0.1" ] && [ "$(DB_HOST)" != "localhost" ]; then \
		echo "❌ Refusing to run on non-local DB_HOST=$(DB_HOST)"; \
		exit 1; \
	fi
	@if echo "$(DB_NAME)" | grep -Eiq 'prod|production|real'; then \
		echo "❌ Refusing to run on suspicious DB_NAME=$(DB_NAME)"; \
		exit 1; \
	fi
	@echo "✅ Safety checks passed"

# ---------------------------------------------------------
# Main workflow
# ---------------------------------------------------------
db-reset: guard db-drop db-create db-schema ## Reset database completely (DROP -> CREATE -> APPLY schema)
	@echo ""
	@echo "✅ Database reset complete!"
	@echo ""

db-drop: guard ## Drop database
	@echo "🧨 Dropping database: $(DB_NAME)"
	@$(MYSQL_CMD) -e "DROP DATABASE IF EXISTS \`$(DB_NAME)\`;" 2>&1 || \
		(echo "❌ Failed to drop database"; exit 1)
	@echo "✅ Database dropped"

db-create: guard ## Create database
	@echo "🆕 Creating database: $(DB_NAME)"
	@$(MYSQL_CMD) -e "CREATE DATABASE \`$(DB_NAME)\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;" 2>&1 || \
		(echo "❌ Failed to create database"; exit 1)
	@echo "✅ Database created"

db-schema: guard ## Apply schema.sql to DB_NAME
	$(call check_file,$(SCHEMA_FILE))
	@echo "📥 Applying schema: $(SCHEMA_FILE) -> $(DB_NAME)"
	@$(MYSQL_CMD) $(DB_NAME) < $(SCHEMA_FILE) 2>&1 || \
		(echo "❌ Failed to apply schema"; exit 1)
	@echo "✅ Schema applied"

db-status: check-env ## Show basic DB status (tables)
	@echo "🔎 DB status: $(DB_NAME)"
	@echo ""
	@echo "Database exists:"
	@$(MYSQL_CMD) -e "SHOW DATABASES LIKE '$(DB_NAME)';" 2>&1 || true
	@echo ""
	@echo "Tables in $(DB_NAME):"
	@$(MYSQL_CMD) $(DB_NAME) -e "SHOW TABLES;" 2>&1 || \
		echo "⚠️  Database does not exist or has no tables"
	@echo ""

db-seed-recommend: guard ## Insert fixed recommend seed data
	$(call check_file,$(SEED_RECOMMEND))
	@echo "🌱 Seeding recommend data from: $(SEED_RECOMMEND)"
	@$(MYSQL_CMD) $(DB_NAME) < $(SEED_RECOMMEND) 2>&1 || \
		(echo "❌ Failed to seed recommend data"; exit 1)
	@echo "✅ Recommend seed inserted"

# db-seed-popup-100k: guard ## Insert 100k popups (+ children)
# 	@$(MYSQL_CMD) $(DB_NAME) -e "SELECT COUNT(*) AS cnt FROM recommend WHERE id BETWEEN 1 AND 20;" | tail -n 1 | awk '{if ($$1!=20) exit 1}'
# 	$(call check_file,$(SEED_POPUP_100K_FILE))
# 	@echo "🌱 Seeding 100k popup data from: $(SEED_POPUP_100K_FILE)"
# 	@echo "⏳ This may take a while..."
# 	@$(MYSQL_CMD) $(DB_NAME) < $(SEED_POPUP_100K_FILE) 2>&1 || \
# 		(echo "❌ Failed to seed popup data"; exit 1)
# 	@echo "✅ Popup 100k seeded"

db-seed-popup-100k: guard ## Insert 100k popups (+ children)
	@$(MYSQL_CMD) $(DB_NAME) -e "SELECT COUNT(*) AS cnt FROM recommend WHERE id BETWEEN 1 AND 20;" | tail -n 1 | awk '{if ($$1!=20) exit 1}'
	$(call check_file,$(SEED_POPUP_100K_FILE))
	@echo "🌱 Seeding 100k popup data from: $(SEED_POPUP_100K_FILE)"
	@echo "⏳ This may take a while..."

	@bash -lc 'time $(MYSQL_CMD) $(DB_NAME) < "$(SEED_POPUP_100K_FILE)"' 2>&1 || \
		(echo "❌ Failed to seed popup data"; exit 1)

	@echo "✅ Popup 100k seeded"

db-seed-user-100k: guard ## Insert 100k users (+ user_* relations)
	$(call check_file,$(SEED_USER_100K_FILE))
	@echo "🌱 Seeding 100k user data from: $(SEED_USER_100K_FILE)"
	@echo "⏳ This may take a while..."
	@time $(MYSQL_CMD) $(DB_NAME) < $(SEED_USER_100K_FILE) 2>&1 || \
		(echo "❌ Failed to seed user data"; exit 1)
	@echo "✅ User 100k seeded"

db-seed-all: db-seed-recommend db-seed-popup-100k db-seed-user-100k ## Seed all data (recommend + popup 100k + user 100k)
	@echo ""
	@echo "✅ All seed data inserted!"
	@echo "➡️  Next: make db-verify"
	@echo ""

db-seed-and-verify: db-seed-all db-verify ## Seed all + verify integrity
	@echo ""
	@echo "✅ Seed + verification complete!"
	@echo ""

# ---------------------------------------------------------
# Advanced: Full reset + seed
# ---------------------------------------------------------
db-full-reset: db-reset db-seed-and-verify ## Complete reset with all seed data + verify
	@echo ""
	@echo "🎉 Full database reset + seeding + verification complete!"
	@echo ""

# ---------------------------------------------------------
# Utility: Test connection
# ---------------------------------------------------------
db-test: check-env ## Test database connection
	@echo "🔌 Testing connection to $(DB_USER)@$(DB_HOST):$(DB_PORT)..."
	@$(MYSQL_CMD) -e "SELECT 'Connection successful!' as status;" 2>&1 || \
		(echo "❌ Connection failed"; exit 1)
	@echo "✅ Connection successful"


# ---------------------------------------------------------
# Verify: 데이터 삽입 결과 검증
# ---------------------------------------------------------
db-verify: guard db-counts db-fk-check ## Verify all tables have data + FK integrity checks
	@echo ""
	@echo "✅ DB verification finished!"
	@echo ""

db-counts: guard ## Show row counts for all tables
	$(call check_file,$(VERIFY_COUNTS_FILE))
	@echo "📊 Row counts (must be > 0 for seeded tables)"
	@$(MYSQL_CMD) $(DB_NAME) < $(VERIFY_COUNTS_FILE)

db-fk-check: guard ## Check orphan rows (FK integrity)
	$(call check_file,$(VERIFY_FK_FILE))
	@echo ""
	@echo "🧩 FK integrity checks (all must be 0)"
	@$(MYSQL_CMD) $(DB_NAME) < $(VERIFY_FK_FILE)