-- +goose Up
-- +goose StatementBegin

CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,
    username VARCHAR(100) NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) NOT NULL
        CHECK (role IN ('admin', 'operator', 'reader')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_full_name_not_empty CHECK (LENGTH(TRIM(full_name)) > 0),
    CONSTRAINT chk_username_not_empty CHECK (LENGTH(TRIM(username)) > 0)
);

CREATE UNIQUE INDEX uq_users_username_lower ON users (LOWER(username));
CREATE INDEX idx_users_role_active ON users (role, is_active);

CREATE TABLE plots (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_plots_name UNIQUE (name),
    CONSTRAINT chk_plots_name_not_empty CHECK (LENGTH(TRIM(name)) > 0)
);

CREATE TABLE user_plots (
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    plot_id BIGINT NOT NULL REFERENCES plots(id) ON DELETE RESTRICT,
    PRIMARY KEY (user_id, plot_id)
);

CREATE INDEX idx_user_plots_plot_id
    ON user_plots (plot_id);

CREATE TABLE routers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plot_id BIGINT NOT NULL REFERENCES plots(id) ON DELETE RESTRICT,
    name VARCHAR(150) NOT NULL,
    host VARCHAR(255) NOT NULL,
    port INTEGER NOT NULL DEFAULT 8729 CHECK (port BETWEEN 1 AND 65535),
    use_tls BOOLEAN NOT NULL DEFAULT TRUE,
    username VARCHAR(100) NOT NULL,
    password BYTEA NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_routers_plot_name UNIQUE (plot_id, name),
    CONSTRAINT uq_routers_id_plot UNIQUE (id, plot_id),
    CONSTRAINT chk_router_name_not_empty CHECK (LENGTH(TRIM(name)) > 0)
);

CREATE INDEX idx_routers_plot_active
    ON routers (plot_id, is_active);

CREATE TABLE router_access (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    router_id BIGINT NOT NULL REFERENCES routers(id) ON DELETE RESTRICT,
    name VARCHAR(150) NOT NULL,
    last_synced_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_router_access_list UNIQUE (router_id, name),
    CONSTRAINT uq_router_access_id_router UNIQUE (id, router_id),
    CONSTRAINT chk_router_access_name CHECK (LENGTH(TRIM(name)) > 0)
);

CREATE TABLE router_queues (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    router_id BIGINT NOT NULL REFERENCES routers(id) ON DELETE RESTRICT,
    queue_type VARCHAR(30) NOT NULL
        CHECK (
            queue_type IN (
                'simple_queue',
                'queue_tree'
            )
        ),
    name VARCHAR(150) NOT NULL,
    last_synced_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_router_queue UNIQUE (router_id, queue_type, name),
    CONSTRAINT uq_router_queue_id_router UNIQUE (id, router_id),
    CONSTRAINT chk_router_queue_name CHECK (LENGTH(TRIM(name)) > 0)
);

CREATE TABLE requests (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    plot_id BIGINT NOT NULL,
    router_id BIGINT NOT NULL,
    executor_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    employee_name VARCHAR(200) NOT NULL,
    ip_address INET NOT NULL,
    mac_address MACADDR NOT NULL,
    access_id BIGINT NOT NULL,
    queue_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'in_progress'
    CHECK (
        status IN ('in_progress', 'completed', 'failed')
    ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_requests_router_plot
        FOREIGN KEY (router_id, plot_id)
        REFERENCES routers (id, plot_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_requests_access_router
        FOREIGN KEY (access_id, router_id)
        REFERENCES router_access (id, router_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_requests_queue_router
        FOREIGN KEY (queue_id, router_id)
        REFERENCES router_queues (id, router_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_requests_employee_name
        CHECK (LENGTH(TRIM(employee_name)) > 0),

    CONSTRAINT chk_requests_ipv4_or_ipv6_host
        CHECK (
            masklen(ip_address) =
            CASE family(ip_address)
                WHEN 4 THEN 32
                WHEN 6 THEN 128
            END
        )
);

CREATE INDEX idx_requests_created_at ON requests (created_at DESC, id DESC);
CREATE INDEX idx_requests_plot_created ON requests (plot_id, created_at DESC, id DESC);
CREATE INDEX idx_requests_router_created ON requests (router_id, created_at DESC, id DESC);
CREATE INDEX idx_requests_executor_created ON requests (executor_id, created_at DESC, id DESC);
CREATE INDEX idx_requests_ip ON requests (ip_address);
CREATE INDEX idx_requests_mac ON requests (mac_address);

CREATE TABLE request_history (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    request_id BIGINT NOT NULL REFERENCES requests(id) ON DELETE RESTRICT,
    attempt_number INTEGER NOT NULL CHECK (attempt_number > 0),
    outcome VARCHAR(20) NOT NULL CHECK (outcome IN ('started', 'succeeded', 'failed')),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMPTZ,
    error_message TEXT,

    CONSTRAINT uq_request_attempt_number UNIQUE (request_id, attempt_number),
    CONSTRAINT chk_attempt_finished
        CHECK (
            (outcome = 'started' AND finished_at IS NULL)
            OR
            (outcome IN ('succeeded', 'failed')
                AND finished_at IS NOT NULL)
        )
);

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin

DROP TABLE IF EXISTS request_history;
DROP TABLE IF EXISTS requests;
DROP TABLE IF EXISTS router_queues;
DROP TABLE IF EXISTS router_access;
DROP TABLE IF EXISTS routers;
DROP TABLE IF EXISTS user_plots;
DROP TABLE IF EXISTS plots;
DROP TABLE IF EXISTS users;

-- +goose StatementEnd