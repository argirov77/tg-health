CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    tg_chat_id BIGINT NOT NULL UNIQUE,
    tg_user_id BIGINT NULL,
    username TEXT NULL,
    first_name TEXT NULL,
    last_name TEXT NULL,
    timezone TEXT NOT NULL DEFAULT 'Europe/Sofia',
    locale TEXT NOT NULL DEFAULT 'ru',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ix_users_is_active ON users (is_active);

CREATE TABLE user_settings (
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    wake_deadline_time TIME NOT NULL DEFAULT '10:00',
    sleep_deadline_time TIME NOT NULL DEFAULT '01:00',
    evening_report_time TIME NOT NULL DEFAULT '21:00',
    training_reminder_time TIME NOT NULL DEFAULT '18:00',
    weighin_days_mask SMALLINT NOT NULL DEFAULT 42,
    weighin_time TIME NOT NULL DEFAULT '09:00',
    calories_target INTEGER NULL,
    protein_g_per_day INTEGER NULL,
    allow_sweets_per_week INTEGER NOT NULL DEFAULT 2,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE tg_updates (
    id BIGSERIAL PRIMARY KEY,
    update_id BIGINT NOT NULL UNIQUE,
    user_id BIGINT NULL REFERENCES users(id) ON DELETE SET NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    payload JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX ix_tg_updates_user_id_received_at_desc ON tg_updates (user_id, received_at DESC);

CREATE TABLE conversation_state (
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    state_key TEXT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}',
    expires_at TIMESTAMPTZ NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ix_conversation_state_expires_at ON conversation_state (expires_at);

CREATE TABLE daily_checkins (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    day DATE NOT NULL,
    wake_time TIMESTAMPTZ NULL,
    sleep_time TIMESTAMPTZ NULL,
    mood SMALLINT NULL CHECK (mood BETWEEN 1 AND 10),
    energy SMALLINT NULL CHECK (energy BETWEEN 1 AND 10),
    stress SMALLINT NULL CHECK (stress BETWEEN 1 AND 10),
    notes TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, day)
);

CREATE INDEX ix_daily_checkins_user_id_day_desc ON daily_checkins (user_id, day DESC);

CREATE TABLE sleep_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind TEXT NOT NULL CHECK (kind IN ('night', 'nap')),
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ NULL,
    quality SMALLINT NULL CHECK (quality BETWEEN 1 AND 10),
    awakenings SMALLINT NULL,
    notes TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ix_sleep_sessions_user_id_started_at_desc ON sleep_sessions (user_id, started_at DESC);
CREATE INDEX ix_sleep_sessions_user_id_ended_at_desc ON sleep_sessions (user_id, ended_at DESC);

CREATE TABLE weighins (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    taken_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    weight_kg NUMERIC(5, 2) NOT NULL,
    body_fat_pct NUMERIC(5, 2) NULL,
    notes TEXT NULL
);

CREATE INDEX ix_weighins_user_id_taken_at_desc ON weighins (user_id, taken_at DESC);

CREATE TABLE progress_photos (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    taken_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    kind TEXT NOT NULL CHECK (kind IN ('front', 'side', 'back', 'other')),
    tg_file_id TEXT NOT NULL,
    tg_file_unique_id TEXT NULL,
    caption TEXT NULL
);

CREATE INDEX ix_progress_photos_user_id_taken_at_desc ON progress_photos (user_id, taken_at DESC);

CREATE TABLE meals (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    eaten_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'other')),
    calories_kcal INTEGER NULL,
    protein_g INTEGER NULL,
    carbs_g INTEGER NULL,
    fat_g INTEGER NULL,
    notes TEXT NULL
);

CREATE INDEX ix_meals_user_id_eaten_at_desc ON meals (user_id, eaten_at DESC);
CREATE INDEX ix_meals_user_id_eaten_date ON meals (user_id, (eaten_at::date));

CREATE TABLE meal_photos (
    id BIGSERIAL PRIMARY KEY,
    meal_id BIGINT NOT NULL REFERENCES meals(id) ON DELETE CASCADE,
    tg_file_id TEXT NOT NULL,
    tg_file_unique_id TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ix_meal_photos_meal_id ON meal_photos (meal_id);

CREATE TABLE workouts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    planned_for DATE NULL,
    started_at TIMESTAMPTZ NULL,
    ended_at TIMESTAMPTZ NULL,
    kind TEXT NOT NULL CHECK (kind IN ('strength', 'run', 'mixed', 'mobility', 'other')),
    status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'done', 'skipped', 'canceled')),
    rpe SMALLINT NULL CHECK (rpe BETWEEN 1 AND 10),
    notes TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ix_workouts_user_id_planned_for_desc ON workouts (user_id, planned_for DESC);
CREATE INDEX ix_workouts_user_id_started_at_desc ON workouts (user_id, started_at DESC);
CREATE INDEX ix_workouts_user_id_status ON workouts (user_id, status);

CREATE TABLE runs (
    id BIGSERIAL PRIMARY KEY,
    workout_id BIGINT NOT NULL UNIQUE REFERENCES workouts(id) ON DELETE CASCADE,
    distance_km NUMERIC(6, 2) NOT NULL,
    duration_sec INTEGER NOT NULL,
    avg_hr SMALLINT NULL,
    max_hr SMALLINT NULL,
    pace_sec_per_km INTEGER NULL,
    notes TEXT NULL
);

CREATE TABLE strength_sets (
    id BIGSERIAL PRIMARY KEY,
    workout_id BIGINT NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercise TEXT NOT NULL,
    set_index SMALLINT NOT NULL DEFAULT 1,
    reps SMALLINT NULL,
    weight_kg NUMERIC(6, 2) NULL,
    is_failure BOOLEAN NOT NULL DEFAULT false,
    notes TEXT NULL
);

CREATE INDEX ix_strength_sets_workout_id ON strength_sets (workout_id);
CREATE INDEX ix_strength_sets_exercise ON strength_sets (exercise);

CREATE TABLE decisions_log (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    kind TEXT NOT NULL,
    input JSONB NOT NULL DEFAULT '{}',
    output JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX ix_decisions_log_user_id_created_at_desc ON decisions_log (user_id, created_at DESC);
CREATE INDEX ix_decisions_log_kind ON decisions_log (kind);

CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind TEXT NOT NULL CHECK (kind IN ('wake_reminder', 'evening_report', 'weighin', 'workout', 'other')),
    planned_at TIMESTAMPTZ NOT NULL,
    sent_at TIMESTAMPTZ NULL,
    status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'sent', 'failed', 'canceled')),
    attempts SMALLINT NOT NULL DEFAULT 0,
    last_error TEXT NULL,
    meta JSONB NOT NULL DEFAULT '{}',
    UNIQUE (user_id, kind, planned_at)
);

CREATE INDEX ix_notifications_user_id_planned_at_desc ON notifications (user_id, planned_at DESC);
CREATE INDEX ix_notifications_status_planned_at ON notifications (status, planned_at);

CREATE TABLE rule_counters (
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    skips_in_row SMALLINT NOT NULL DEFAULT 0,
    sweets_used_this_week SMALLINT NOT NULL DEFAULT 0,
    week_start DATE NOT NULL DEFAULT date_trunc('week', now())::date,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE programs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    goal TEXT NOT NULL CHECK (goal IN ('cut', 'bulk', 'maintenance', 'recomp', 'custom')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'archived')),
    starts_on DATE NOT NULL,
    ends_on DATE NULL,
    notes TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ix_programs_user_id_status ON programs (user_id, status);
CREATE INDEX ix_programs_user_id_starts_on_desc ON programs (user_id, starts_on DESC);

CREATE TABLE program_targets (
    id BIGSERIAL PRIMARY KEY,
    program_id BIGINT NOT NULL UNIQUE REFERENCES programs(id) ON DELETE CASCADE,
    calories_target INTEGER NULL,
    protein_g_target INTEGER NULL,
    carbs_g_target INTEGER NULL,
    fat_g_target INTEGER NULL,
    steps_target INTEGER NULL,
    sleep_minutes_target INTEGER NULL,
    water_ml_target INTEGER NULL,
    training_sessions_per_week_target SMALLINT NULL,
    cardio_sessions_per_week_target SMALLINT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE program_rules (
    id BIGSERIAL PRIMARY KEY,
    program_id BIGINT NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
    rule_key TEXT NOT NULL,
    rule_json JSONB NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    priority SMALLINT NOT NULL DEFAULT 100,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (program_id, rule_key)
);

CREATE INDEX ix_program_rules_program_id_enabled_priority ON program_rules (program_id, is_enabled, priority);

CREATE TABLE program_workout_templates (
    id BIGSERIAL PRIMARY KEY,
    program_id BIGINT NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    kind TEXT NOT NULL CHECK (kind IN ('strength', 'run', 'mixed', 'mobility')),
    template_json JSONB NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (program_id, name)
);

CREATE INDEX ix_program_workout_templates_program_id_active ON program_workout_templates (program_id, is_active);

CREATE TABLE program_schedule (
    id BIGSERIAL PRIMARY KEY,
    program_id BIGINT NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
    week_start DATE NOT NULL,
    schedule_json JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (program_id, week_start)
);

CREATE INDEX ix_program_schedule_program_id_week_start_desc ON program_schedule (program_id, week_start DESC);

CREATE TABLE program_changes_log (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    program_id BIGINT NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    change_kind TEXT NOT NULL CHECK (change_kind IN ('create', 'activate', 'pause', 'update_targets', 'update_rules')),
    before_json JSONB NOT NULL DEFAULT '{}',
    after_json JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX ix_program_changes_log_user_id_changed_at_desc ON program_changes_log (user_id, changed_at DESC);
CREATE INDEX ix_program_changes_log_program_id_changed_at_desc ON program_changes_log (program_id, changed_at DESC);
