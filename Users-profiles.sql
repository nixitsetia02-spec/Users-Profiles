-- ========================================================================
-- GZONESPHERE USER DATABASE - RESTRUCTURED
-- Master Profile in Public Schema + 7 Profile-Specific Schemas
-- ========================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- For gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pg_trgm";   -- For text search optimization

-- Set timezone
SET timezone = 'UTC';

-- ========================================================================
-- SCHEMA: public (Master Profile)
-- ========================================================================

-- ------------------------------------------------------------------------
-- TABLE: master_profiles
-- Purpose: Core user identity - one per user (MASTER TABLE)
-- ------------------------------------------------------------------------
CREATE TABLE public.master_profiles (
    -- Primary Key
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Identity & Account
    display_name VARCHAR(255) NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    profile_photo_url VARCHAR(500),
    
    -- Authentication
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    
    -- Location
    location_country VARCHAR(100),
    location_city VARCHAR(100),
    location_timezone VARCHAR(100) DEFAULT 'UTC',
    
    -- Languages
    languages JSONB DEFAULT '[]'::JSONB,
    
    -- Availability
    overall_availability_status VARCHAR(50) DEFAULT 'selective' NOT NULL,
    open_to_hiring BOOLEAN DEFAULT FALSE NOT NULL,
    open_to_freelance BOOLEAN DEFAULT FALSE NOT NULL,
    open_to_collaboration BOOLEAN DEFAULT FALSE NOT NULL,
    open_to_playtesting BOOLEAN DEFAULT FALSE NOT NULL,
    
    -- Aggregated Metrics (auto-calculated by application)
    total_sub_profiles INTEGER DEFAULT 0 NOT NULL,
    total_skills INTEGER DEFAULT 0 NOT NULL,
    total_verified_skills INTEGER DEFAULT 0 NOT NULL,
    
    -- Trust & Reputation (system-managed)
    trust_level VARCHAR(50) DEFAULT 'medium' NOT NULL,
    reliability_indicator VARCHAR(50),
    platform_standing VARCHAR(50) DEFAULT 'good' NOT NULL,
    
    -- Platform Activity Counts (auto-calculated)
    companies_worked_with INTEGER DEFAULT 0 NOT NULL,
    commissions_completed INTEGER DEFAULT 0 NOT NULL,
    hires_completed INTEGER DEFAULT 0 NOT NULL,
    playtests_participated INTEGER DEFAULT 0 NOT NULL,
    events_joined INTEGER DEFAULT 0 NOT NULL,
    
    -- Bio & Links
    bio TEXT,
    portfolio_url VARCHAR(500),
    resume_url VARCHAR(500),
    social_links JSONB DEFAULT '{}'::JSONB,
    
    -- Timestamps
    joined_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_active TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_availability CHECK (
        overall_availability_status IN ('open', 'selective', 'not_available')
    ),
    CONSTRAINT chk_trust_level CHECK (
        trust_level IN ('low', 'medium', 'high')
    ),
    CONSTRAINT chk_platform_standing CHECK (
        platform_standing IN ('good', 'limited', 'restricted', 'banned')
    )
);

-- Indexes for master_profiles
CREATE INDEX idx_master_username ON public.master_profiles(username);
CREATE INDEX idx_master_email ON public.master_profiles(email);
CREATE INDEX idx_master_joined ON public.master_profiles(joined_date DESC);
CREATE INDEX idx_master_availability ON public.master_profiles(overall_availability_status);
CREATE INDEX idx_master_standing ON public.master_profiles(platform_standing);
CREATE INDEX idx_master_name_trgm ON public.master_profiles USING gin(display_name gin_trgm_ops);
CREATE INDEX idx_master_verified_skills ON public.master_profiles(total_verified_skills DESC);

-- Comments
COMMENT ON TABLE public.master_profiles IS 'Master user profile - single source of truth for each user';
COMMENT ON COLUMN public.master_profiles.user_id IS 'Auto-generated UUID primary key - links to all 7 profile schemas';

-- ========================================================================
-- SHARED CATALOG TABLE (in public schema)
-- ========================================================================

-- ------------------------------------------------------------------------
-- TABLE: skills_catalog
-- Purpose: Master list of all available skills (shared across all profiles)
-- ------------------------------------------------------------------------
CREATE TABLE public.skills_catalog (
    -- Primary Key
    skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Skill Identity
    skill_name VARCHAR(255) UNIQUE NOT NULL,
    
    -- Classification
    skill_category VARCHAR(50) NOT NULL,
    skill_group VARCHAR(100) NOT NULL,
    
    -- Association
    profile_type VARCHAR(50) NOT NULL,
    
    -- Metadata
    description TEXT,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    -- Constraints
    CONSTRAINT chk_skill_category CHECK (
        skill_category IN ('design', 'art', 'audio', 'systems', 'writing', 'business', 'esports')
    ),
    CONSTRAINT chk_skill_profile_type CHECK (
        profile_type IN (
            'game_creation_development',
            'esports_play_performance',
            'content_media_community',
            'business_strategy_future',
            'art_visual_character',
            'writing_narrative_editorial',
            'music_audio_sound'
        )
    )
);

-- Indexes
CREATE INDEX idx_skills_name ON public.skills_catalog(skill_name);
CREATE INDEX idx_skills_category ON public.skills_catalog(skill_category);
CREATE INDEX idx_skills_profile_type ON public.skills_catalog(profile_type);
CREATE INDEX idx_skills_active ON public.skills_catalog(is_active);
CREATE INDEX idx_skills_name_trgm ON public.skills_catalog USING gin(skill_name gin_trgm_ops);

-- ========================================================================
-- SCHEMA 1: game_creation_development
-- ========================================================================
CREATE SCHEMA IF NOT EXISTS game_creation_development;

-- Sub Profile
CREATE TABLE game_creation_development.sub_profiles (
    sub_profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    -- Roles
    primary_role VARCHAR(255) NOT NULL,
    secondary_roles JSONB DEFAULT '[]'::JSONB,
    
    -- Experience
    experience_level VARCHAR(50),
    
    -- Availability Override
    availability_override JSONB,
    
    -- Status
    active BOOLEAN DEFAULT TRUE NOT NULL,
    display_order INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_experience_level CHECK (
        experience_level IS NULL OR
        experience_level IN ('beginner', 'intermediate', 'advanced', 'expert')
    ),
    CONSTRAINT unique_user_profile UNIQUE (user_id)
);

CREATE INDEX idx_gcd_subprofile_user ON game_creation_development.sub_profiles(user_id);
CREATE INDEX idx_gcd_subprofile_active ON game_creation_development.sub_profiles(active);

-- Profile Specific Data
CREATE TABLE game_creation_development.profile_specific_data (
    data_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_profile_id UUID NOT NULL UNIQUE REFERENCES game_creation_development.sub_profiles(sub_profile_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    -- Type-specific fields as JSONB
    data JSONB NOT NULL DEFAULT '{}'::JSONB,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX idx_gcd_data_subprofile ON game_creation_development.profile_specific_data(sub_profile_id);
CREATE INDEX idx_gcd_data_user ON game_creation_development.profile_specific_data(user_id);
CREATE INDEX idx_gcd_data_jsonb ON game_creation_development.profile_specific_data USING gin(data);

-- User Skills
CREATE TABLE game_creation_development.user_skills (
    user_skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID NOT NULL REFERENCES game_creation_development.sub_profiles(sub_profile_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES public.skills_catalog(skill_id) ON DELETE CASCADE,
    
    skill_level INTEGER NOT NULL CHECK (skill_level BETWEEN 1 AND 5),
    
    -- Proof
    proof_type VARCHAR(50),
    proof_urls JSONB DEFAULT '[]'::JSONB,
    proof_description TEXT,
    
    -- Verification
    verification_status VARCHAR(50) DEFAULT 'unverified' NOT NULL,
    verification_date TIMESTAMP,
    verified_by VARCHAR(100),
    rejection_reason TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_proof_type CHECK (
        proof_type IS NULL OR
        proof_type IN ('portfolio', 'code_repo', 'audio', 'video', 'document',
                      'platform_verified', 'certificate', 'live_demo')
    ),
    CONSTRAINT chk_verification_status CHECK (
        verification_status IN ('unverified', 'proof_submitted', 'under_review', 'verified', 'rejected')
    ),
    CONSTRAINT unique_user_skill UNIQUE (user_id, skill_id)
);

CREATE INDEX idx_gcd_skills_user ON game_creation_development.user_skills(user_id);
CREATE INDEX idx_gcd_skills_subprofile ON game_creation_development.user_skills(sub_profile_id);
CREATE INDEX idx_gcd_skills_skill ON game_creation_development.user_skills(skill_id);
CREATE INDEX idx_gcd_skills_verification ON game_creation_development.user_skills(verification_status);

-- Projects
CREATE TABLE game_creation_development.projects (
    project_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID REFERENCES game_creation_development.sub_profiles(sub_profile_id) ON DELETE SET NULL,
    
    project_name VARCHAR(255) NOT NULL,
    project_type VARCHAR(50) NOT NULL,
    role_in_project VARCHAR(255),
    description TEXT,
    
    media_urls JSONB DEFAULT '[]'::JSONB,
    thumbnail_url VARCHAR(500),
    project_url VARCHAR(500),
    repository_url VARCHAR(500),
    
    start_date DATE,
    end_date DATE,
    
    status VARCHAR(50) NOT NULL,
    public BOOLEAN DEFAULT TRUE NOT NULL,
    featured BOOLEAN DEFAULT FALSE NOT NULL,
    
    team_size VARCHAR(50),
    collaborators TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_project_type CHECK (
        project_type IN ('personal', 'professional', 'commissioned', 'collaborative', 'academic', 'open_source')
    ),
    CONSTRAINT chk_project_status CHECK (
        status IN ('planning', 'in_progress', 'completed', 'paused', 'archived', 'cancelled')
    ),
    CONSTRAINT chk_project_dates CHECK (
        end_date IS NULL OR start_date IS NULL OR end_date >= start_date
    )
);

CREATE INDEX idx_gcd_projects_user ON game_creation_development.projects(user_id);
CREATE INDEX idx_gcd_projects_subprofile ON game_creation_development.projects(sub_profile_id);
CREATE INDEX idx_gcd_projects_status ON game_creation_development.projects(status);
CREATE INDEX idx_gcd_projects_public ON game_creation_development.projects(public, created_at DESC);

-- Project Skills
CREATE TABLE game_creation_development.project_skills (
    project_skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES game_creation_development.projects(project_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES public.skills_catalog(skill_id) ON DELETE CASCADE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT unique_project_skill UNIQUE (project_id, skill_id)
);

CREATE INDEX idx_gcd_project_skills_project ON game_creation_development.project_skills(project_id);
CREATE INDEX idx_gcd_project_skills_skill ON game_creation_development.project_skills(skill_id);

-- User Posts
CREATE TABLE game_creation_development.user_posts (
    post_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID REFERENCES game_creation_development.sub_profiles(sub_profile_id) ON DELETE SET NULL,
    
    post_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    
    media_urls JSONB DEFAULT '[]'::JSONB,
    featured_image_url VARCHAR(500),
    
    linked_skills JSONB DEFAULT '[]'::JSONB,
    linked_projects JSONB DEFAULT '[]'::JSONB,
    
    visibility VARCHAR(50) DEFAULT 'public' NOT NULL,
    view_count INTEGER DEFAULT 0 NOT NULL,
    
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_post_type CHECK (
        post_type IN ('showcase', 'update', 'tutorial', 'analysis', 'devlog', 'article', 'achievement', 'question')
    ),
    CONSTRAINT chk_visibility CHECK (
        visibility IN ('public', 'connections', 'private', 'unlisted')
    )
);

CREATE INDEX idx_gcd_posts_user ON game_creation_development.user_posts(user_id);
CREATE INDEX idx_gcd_posts_subprofile ON game_creation_development.user_posts(sub_profile_id);
CREATE INDEX idx_gcd_posts_type ON game_creation_development.user_posts(post_type);

-- Verification Requests
CREATE TABLE game_creation_development.verification_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_skill_id UUID NOT NULL REFERENCES game_creation_development.user_skills(user_skill_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    submitted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reviewed_date TIMESTAMP,
    
    reviewer_id VARCHAR(100),
    reviewer_type VARCHAR(50),
    
    status VARCHAR(50) DEFAULT 'pending' NOT NULL,
    admin_notes TEXT,
    rejection_reason TEXT,
    priority VARCHAR(50) DEFAULT 'normal',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_reviewer_type CHECK (
        reviewer_type IS NULL OR
        reviewer_type IN ('platform', 'expert', 'company', 'automated')
    ),
    CONSTRAINT chk_request_status CHECK (
        status IN ('pending', 'in_review', 'approved', 'rejected', 'cancelled')
    ),
    CONSTRAINT chk_priority CHECK (
        priority IN ('low', 'normal', 'high', 'urgent')
    )
);

CREATE INDEX idx_gcd_verify_skill ON game_creation_development.verification_requests(user_skill_id);
CREATE INDEX idx_gcd_verify_user ON game_creation_development.verification_requests(user_id);
CREATE INDEX idx_gcd_verify_status ON game_creation_development.verification_requests(status);

-- ========================================================================
-- SCHEMA 2: esports_play_performance
-- ========================================================================
CREATE SCHEMA IF NOT EXISTS esports_play_performance;

-- Sub Profile
CREATE TABLE esports_play_performance.sub_profiles (
    sub_profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    primary_role VARCHAR(255) NOT NULL,
    secondary_roles JSONB DEFAULT '[]'::JSONB,
    experience_level VARCHAR(50),
    availability_override JSONB,
    
    active BOOLEAN DEFAULT TRUE NOT NULL,
    display_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_experience_level CHECK (
        experience_level IS NULL OR
        experience_level IN ('beginner', 'intermediate', 'advanced', 'expert')
    ),
    CONSTRAINT unique_user_profile UNIQUE (user_id)
);

CREATE INDEX idx_epp_subprofile_user ON esports_play_performance.sub_profiles(user_id);
CREATE INDEX idx_epp_subprofile_active ON esports_play_performance.sub_profiles(active);

-- Profile Specific Data
CREATE TABLE esports_play_performance.profile_specific_data (
    data_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_profile_id UUID NOT NULL UNIQUE REFERENCES esports_play_performance.sub_profiles(sub_profile_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    data JSONB NOT NULL DEFAULT '{}'::JSONB,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX idx_epp_data_subprofile ON esports_play_performance.profile_specific_data(sub_profile_id);
CREATE INDEX idx_epp_data_user ON esports_play_performance.profile_specific_data(user_id);
CREATE INDEX idx_epp_data_jsonb ON esports_play_performance.profile_specific_data USING gin(data);

-- User Skills
CREATE TABLE esports_play_performance.user_skills (
    user_skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID NOT NULL REFERENCES esports_play_performance.sub_profiles(sub_profile_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES public.skills_catalog(skill_id) ON DELETE CASCADE,
    
    skill_level INTEGER NOT NULL CHECK (skill_level BETWEEN 1 AND 5),
    
    proof_type VARCHAR(50),
    proof_urls JSONB DEFAULT '[]'::JSONB,
    proof_description TEXT,
    
    verification_status VARCHAR(50) DEFAULT 'unverified' NOT NULL,
    verification_date TIMESTAMP,
    verified_by VARCHAR(100),
    rejection_reason TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_proof_type CHECK (
        proof_type IS NULL OR
        proof_type IN ('portfolio', 'code_repo', 'audio', 'video', 'document',
                      'platform_verified', 'certificate', 'live_demo')
    ),
    CONSTRAINT chk_verification_status CHECK (
        verification_status IN ('unverified', 'proof_submitted', 'under_review', 'verified', 'rejected')
    ),
    CONSTRAINT unique_user_skill UNIQUE (user_id, skill_id)
);

CREATE INDEX idx_epp_skills_user ON esports_play_performance.user_skills(user_id);
CREATE INDEX idx_epp_skills_subprofile ON esports_play_performance.user_skills(sub_profile_id);
CREATE INDEX idx_epp_skills_skill ON esports_play_performance.user_skills(skill_id);
CREATE INDEX idx_epp_skills_verification ON esports_play_performance.user_skills(verification_status);

-- Projects
CREATE TABLE esports_play_performance.projects (
    project_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID REFERENCES esports_play_performance.sub_profiles(sub_profile_id) ON DELETE SET NULL,
    
    project_name VARCHAR(255) NOT NULL,
    project_type VARCHAR(50) NOT NULL,
    role_in_project VARCHAR(255),
    description TEXT,
    
    media_urls JSONB DEFAULT '[]'::JSONB,
    thumbnail_url VARCHAR(500),
    project_url VARCHAR(500),
    repository_url VARCHAR(500),
    
    start_date DATE,
    end_date DATE,
    
    status VARCHAR(50) NOT NULL,
    public BOOLEAN DEFAULT TRUE NOT NULL,
    featured BOOLEAN DEFAULT FALSE NOT NULL,
    
    team_size VARCHAR(50),
    collaborators TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_project_type CHECK (
        project_type IN ('personal', 'professional', 'commissioned', 'collaborative', 'academic', 'open_source')
    ),
    CONSTRAINT chk_project_status CHECK (
        status IN ('planning', 'in_progress', 'completed', 'paused', 'archived', 'cancelled')
    ),
    CONSTRAINT chk_project_dates CHECK (
        end_date IS NULL OR start_date IS NULL OR end_date >= start_date
    )
);

CREATE INDEX idx_epp_projects_user ON esports_play_performance.projects(user_id);
CREATE INDEX idx_epp_projects_subprofile ON esports_play_performance.projects(sub_profile_id);
CREATE INDEX idx_epp_projects_status ON esports_play_performance.projects(status);
CREATE INDEX idx_epp_projects_public ON esports_play_performance.projects(public, created_at DESC);

-- Project Skills
CREATE TABLE esports_play_performance.project_skills (
    project_skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES esports_play_performance.projects(project_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES public.skills_catalog(skill_id) ON DELETE CASCADE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT unique_project_skill UNIQUE (project_id, skill_id)
);

CREATE INDEX idx_epp_project_skills_project ON esports_play_performance.project_skills(project_id);
CREATE INDEX idx_epp_project_skills_skill ON esports_play_performance.project_skills(skill_id);

-- User Posts
CREATE TABLE esports_play_performance.user_posts (
    post_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID REFERENCES esports_play_performance.sub_profiles(sub_profile_id) ON DELETE SET NULL,
    
    post_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    
    media_urls JSONB DEFAULT '[]'::JSONB,
    featured_image_url VARCHAR(500),
    
    linked_skills JSONB DEFAULT '[]'::JSONB,
    linked_projects JSONB DEFAULT '[]'::JSONB,
    
    visibility VARCHAR(50) DEFAULT 'public' NOT NULL,
    view_count INTEGER DEFAULT 0 NOT NULL,
    
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_post_type CHECK (
        post_type IN ('showcase', 'update', 'tutorial', 'analysis', 'devlog', 'article', 'achievement', 'question')
    ),
    CONSTRAINT chk_visibility CHECK (
        visibility IN ('public', 'connections', 'private', 'unlisted')
    )
);

CREATE INDEX idx_epp_posts_user ON esports_play_performance.user_posts(user_id);
CREATE INDEX idx_epp_posts_subprofile ON esports_play_performance.user_posts(sub_profile_id);
CREATE INDEX idx_epp_posts_type ON esports_play_performance.user_posts(post_type);

-- Verification Requests
CREATE TABLE esports_play_performance.verification_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_skill_id UUID NOT NULL REFERENCES esports_play_performance.user_skills(user_skill_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    submitted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reviewed_date TIMESTAMP,
    
    reviewer_id VARCHAR(100),
    reviewer_type VARCHAR(50),
    
    status VARCHAR(50) DEFAULT 'pending' NOT NULL,
    admin_notes TEXT,
    rejection_reason TEXT,
    priority VARCHAR(50) DEFAULT 'normal',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_reviewer_type CHECK (
        reviewer_type IS NULL OR
        reviewer_type IN ('platform', 'expert', 'company', 'automated')
    ),
    CONSTRAINT chk_request_status CHECK (
        status IN ('pending', 'in_review', 'approved', 'rejected', 'cancelled')
    ),
    CONSTRAINT chk_priority CHECK (
        priority IN ('low', 'normal', 'high', 'urgent')
    )
);

CREATE INDEX idx_epp_verify_skill ON esports_play_performance.verification_requests(user_skill_id);
CREATE INDEX idx_epp_verify_user ON esports_play_performance.verification_requests(user_id);
CREATE INDEX idx_epp_verify_status ON esports_play_performance.verification_requests(status);

-- ========================================================================
-- SCHEMA 3: content_media_community
-- ========================================================================
CREATE SCHEMA IF NOT EXISTS content_media_community;

-- Sub Profile
CREATE TABLE content_media_community.sub_profiles (
    sub_profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    primary_role VARCHAR(255) NOT NULL,
    secondary_roles JSONB DEFAULT '[]'::JSONB,
    experience_level VARCHAR(50),
    availability_override JSONB,
    
    active BOOLEAN DEFAULT TRUE NOT NULL,
    display_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_experience_level CHECK (
        experience_level IS NULL OR
        experience_level IN ('beginner', 'intermediate', 'advanced', 'expert')
    ),
    CONSTRAINT unique_user_profile UNIQUE (user_id)
);

CREATE INDEX idx_cmc_subprofile_user ON content_media_community.sub_profiles(user_id);
CREATE INDEX idx_cmc_subprofile_active ON content_media_community.sub_profiles(active);

-- Profile Specific Data
CREATE TABLE content_media_community.profile_specific_data (
    data_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_profile_id UUID NOT NULL UNIQUE REFERENCES content_media_community.sub_profiles(sub_profile_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    data JSONB NOT NULL DEFAULT '{}'::JSONB,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX idx_cmc_data_subprofile ON content_media_community.profile_specific_data(sub_profile_id);
CREATE INDEX idx_cmc_data_user ON content_media_community.profile_specific_data(user_id);
CREATE INDEX idx_cmc_data_jsonb ON content_media_community.profile_specific_data USING gin(data);

-- User Skills
CREATE TABLE content_media_community.user_skills (
    user_skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID NOT NULL REFERENCES content_media_community.sub_profiles(sub_profile_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES public.skills_catalog(skill_id) ON DELETE CASCADE,
    
    skill_level INTEGER NOT NULL CHECK (skill_level BETWEEN 1 AND 5),
    
    proof_type VARCHAR(50),
    proof_urls JSONB DEFAULT '[]'::JSONB,
    proof_description TEXT,
    
    verification_status VARCHAR(50) DEFAULT 'unverified' NOT NULL,
    verification_date TIMESTAMP,
    verified_by VARCHAR(100),
    rejection_reason TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_proof_type CHECK (
        proof_type IS NULL OR
        proof_type IN ('portfolio', 'code_repo', 'audio', 'video', 'document',
                      'platform_verified', 'certificate', 'live_demo')
    ),
    CONSTRAINT chk_verification_status CHECK (
        verification_status IN ('unverified', 'proof_submitted', 'under_review', 'verified', 'rejected')
    ),
    CONSTRAINT unique_user_skill UNIQUE (user_id, skill_id)
);

CREATE INDEX idx_cmc_skills_user ON content_media_community.user_skills(user_id);
CREATE INDEX idx_cmc_skills_subprofile ON content_media_community.user_skills(sub_profile_id);
CREATE INDEX idx_cmc_skills_skill ON content_media_community.user_skills(skill_id);
CREATE INDEX idx_cmc_skills_verification ON content_media_community.user_skills(verification_status);

-- Projects
CREATE TABLE content_media_community.projects (
    project_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID REFERENCES content_media_community.sub_profiles(sub_profile_id) ON DELETE SET NULL,
    
    project_name VARCHAR(255) NOT NULL,
    project_type VARCHAR(50) NOT NULL,
    role_in_project VARCHAR(255),
    description TEXT,
    
    media_urls JSONB DEFAULT '[]'::JSONB,
    thumbnail_url VARCHAR(500),
    project_url VARCHAR(500),
    repository_url VARCHAR(500),
    
    start_date DATE,
    end_date DATE,
    
    status VARCHAR(50) NOT NULL,
    public BOOLEAN DEFAULT TRUE NOT NULL,
    featured BOOLEAN DEFAULT FALSE NOT NULL,
    
    team_size VARCHAR(50),
    collaborators TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_project_type CHECK (
        project_type IN ('personal', 'professional', 'commissioned', 'collaborative', 'academic', 'open_source')
    ),
    CONSTRAINT chk_project_status CHECK (
        status IN ('planning', 'in_progress', 'completed', 'paused', 'archived', 'cancelled')
    ),
    CONSTRAINT chk_project_dates CHECK (
        end_date IS NULL OR start_date IS NULL OR end_date >= start_date
    )
);

CREATE INDEX idx_cmc_projects_user ON content_media_community.projects(user_id);
CREATE INDEX idx_cmc_projects_subprofile ON content_media_community.projects(sub_profile_id);
CREATE INDEX idx_cmc_projects_status ON content_media_community.projects(status);
CREATE INDEX idx_cmc_projects_public ON content_media_community.projects(public, created_at DESC);

-- Project Skills
CREATE TABLE content_media_community.project_skills (
    project_skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES content_media_community.projects(project_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES public.skills_catalog(skill_id) ON DELETE CASCADE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT unique_project_skill UNIQUE (project_id, skill_id)
);

CREATE INDEX idx_cmc_project_skills_project ON content_media_community.project_skills(project_id);
CREATE INDEX idx_cmc_project_skills_skill ON content_media_community.project_skills(skill_id);

-- User Posts
CREATE TABLE content_media_community.user_posts (
    post_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID REFERENCES content_media_community.sub_profiles(sub_profile_id) ON DELETE SET NULL,
    
    post_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    
    media_urls JSONB DEFAULT '[]'::JSONB,
    featured_image_url VARCHAR(500),
    
    linked_skills JSONB DEFAULT '[]'::JSONB,
    linked_projects JSONB DEFAULT '[]'::JSONB,
    
    visibility VARCHAR(50) DEFAULT 'public' NOT NULL,
    view_count INTEGER DEFAULT 0 NOT NULL,
    
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_post_type CHECK (
        post_type IN ('showcase', 'update', 'tutorial', 'analysis', 'devlog', 'article', 'achievement', 'question')
    ),
    CONSTRAINT chk_visibility CHECK (
        visibility IN ('public', 'connections', 'private', 'unlisted')
    )
);

CREATE INDEX idx_cmc_posts_user ON content_media_community.user_posts(user_id);
CREATE INDEX idx_cmc_posts_subprofile ON content_media_community.user_posts(sub_profile_id);
CREATE INDEX idx_cmc_posts_type ON content_media_community.user_posts(post_type);

-- Verification Requests
CREATE TABLE content_media_community.verification_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_skill_id UUID NOT NULL REFERENCES content_media_community.user_skills(user_skill_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    submitted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reviewed_date TIMESTAMP,
    
    reviewer_id VARCHAR(100),
    reviewer_type VARCHAR(50),
    
    status VARCHAR(50) DEFAULT 'pending' NOT NULL,
    admin_notes TEXT,
    rejection_reason TEXT,
    priority VARCHAR(50) DEFAULT 'normal',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_reviewer_type CHECK (
        reviewer_type IS NULL OR
        reviewer_type IN ('platform', 'expert', 'company', 'automated')
    ),
    CONSTRAINT chk_request_status CHECK (
        status IN ('pending', 'in_review', 'approved', 'rejected', 'cancelled')
    ),
    CONSTRAINT chk_priority CHECK (
        priority IN ('low', 'normal', 'high', 'urgent')
    )
);

CREATE INDEX idx_cmc_verify_skill ON content_media_community.verification_requests(user_skill_id);
CREATE INDEX idx_cmc_verify_user ON content_media_community.verification_requests(user_id);
CREATE INDEX idx_cmc_verify_status ON content_media_community.verification_requests(status);

-- ========================================================================
-- SCHEMA 4: business_strategy_future
-- ========================================================================
CREATE SCHEMA IF NOT EXISTS business_strategy_future;

-- Sub Profile
CREATE TABLE business_strategy_future.sub_profiles (
    sub_profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    primary_role VARCHAR(255) NOT NULL,
    secondary_roles JSONB DEFAULT '[]'::JSONB,
    experience_level VARCHAR(50),
    availability_override JSONB,
    
    active BOOLEAN DEFAULT TRUE NOT NULL,
    display_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_experience_level CHECK (
        experience_level IS NULL OR
        experience_level IN ('beginner', 'intermediate', 'advanced', 'expert')
    ),
    CONSTRAINT unique_user_profile UNIQUE (user_id)
);

CREATE INDEX idx_bsf_subprofile_user ON business_strategy_future.sub_profiles(user_id);
CREATE INDEX idx_bsf_subprofile_active ON business_strategy_future.sub_profiles(active);

-- Profile Specific Data
CREATE TABLE business_strategy_future.profile_specific_data (
    data_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_profile_id UUID NOT NULL UNIQUE REFERENCES business_strategy_future.sub_profiles(sub_profile_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    data JSONB NOT NULL DEFAULT '{}'::JSONB,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX idx_bsf_data_subprofile ON business_strategy_future.profile_specific_data(sub_profile_id);
CREATE INDEX idx_bsf_data_user ON business_strategy_future.profile_specific_data(user_id);
CREATE INDEX idx_bsf_data_jsonb ON business_strategy_future.profile_specific_data USING gin(data);

-- User Skills
CREATE TABLE business_strategy_future.user_skills (
    user_skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID NOT NULL REFERENCES business_strategy_future.sub_profiles(sub_profile_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES public.skills_catalog(skill_id) ON DELETE CASCADE,
    
    skill_level INTEGER NOT NULL CHECK (skill_level BETWEEN 1 AND 5),
    
    proof_type VARCHAR(50),
    proof_urls JSONB DEFAULT '[]'::JSONB,
    proof_description TEXT,
    
    verification_status VARCHAR(50) DEFAULT 'unverified' NOT NULL,
    verification_date TIMESTAMP,
    verified_by VARCHAR(100),
    rejection_reason TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_proof_type CHECK (
        proof_type IS NULL OR
        proof_type IN ('portfolio', 'code_repo', 'audio', 'video', 'document',
                      'platform_verified', 'certificate', 'live_demo')
    ),
    CONSTRAINT chk_verification_status CHECK (
        verification_status IN ('unverified', 'proof_submitted', 'under_review', 'verified', 'rejected')
    ),
    CONSTRAINT unique_user_skill UNIQUE (user_id, skill_id)
);

CREATE INDEX idx_bsf_skills_user ON business_strategy_future.user_skills(user_id);
CREATE INDEX idx_bsf_skills_subprofile ON business_strategy_future.user_skills(sub_profile_id);
CREATE INDEX idx_bsf_skills_skill ON business_strategy_future.user_skills(skill_id);
CREATE INDEX idx_bsf_skills_verification ON business_strategy_future.user_skills(verification_status);

-- Projects
CREATE TABLE business_strategy_future.projects (
    project_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID REFERENCES business_strategy_future.sub_profiles(sub_profile_id) ON DELETE SET NULL,
    
    project_name VARCHAR(255) NOT NULL,
    project_type VARCHAR(50) NOT NULL,
    role_in_project VARCHAR(255),
    description TEXT,
    
    media_urls JSONB DEFAULT '[]'::JSONB,
    thumbnail_url VARCHAR(500),
    project_url VARCHAR(500),
    repository_url VARCHAR(500),
    
    start_date DATE,
    end_date DATE,
    
    status VARCHAR(50) NOT NULL,
    public BOOLEAN DEFAULT TRUE NOT NULL,
    featured BOOLEAN DEFAULT FALSE NOT NULL,
    
    team_size VARCHAR(50),
    collaborators TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_project_type CHECK (
        project_type IN ('personal', 'professional', 'commissioned', 'collaborative', 'academic', 'open_source')
    ),
    CONSTRAINT chk_project_status CHECK (
        status IN ('planning', 'in_progress', 'completed', 'paused', 'archived', 'cancelled')
    ),
    CONSTRAINT chk_project_dates CHECK (
        end_date IS NULL OR start_date IS NULL OR end_date >= start_date
    )
);

CREATE INDEX idx_bsf_projects_user ON business_strategy_future.projects(user_id);
CREATE INDEX idx_bsf_projects_subprofile ON business_strategy_future.projects(sub_profile_id);
CREATE INDEX idx_bsf_projects_status ON business_strategy_future.projects(status);
CREATE INDEX idx_bsf_projects_public ON business_strategy_future.projects(public, created_at DESC);

-- Project Skills
CREATE TABLE business_strategy_future.project_skills (
    project_skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES business_strategy_future.projects(project_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES public.skills_catalog(skill_id) ON DELETE CASCADE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT unique_project_skill UNIQUE (project_id, skill_id)
);

CREATE INDEX idx_bsf_project_skills_project ON business_strategy_future.project_skills(project_id);
CREATE INDEX idx_bsf_project_skills_skill ON business_strategy_future.project_skills(skill_id);

-- User Posts
CREATE TABLE business_strategy_future.user_posts (
    post_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID REFERENCES business_strategy_future.sub_profiles(sub_profile_id) ON DELETE SET NULL,
    
    post_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    
    media_urls JSONB DEFAULT '[]'::JSONB,
    featured_image_url VARCHAR(500),
    
    linked_skills JSONB DEFAULT '[]'::JSONB,
    linked_projects JSONB DEFAULT '[]'::JSONB,
    
    visibility VARCHAR(50) DEFAULT 'public' NOT NULL,
    view_count INTEGER DEFAULT 0 NOT NULL,
    
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_post_type CHECK (
        post_type IN ('showcase', 'update', 'tutorial', 'analysis', 'devlog', 'article', 'achievement', 'question')
    ),
    CONSTRAINT chk_visibility CHECK (
        visibility IN ('public', 'connections', 'private', 'unlisted')
    )
);

CREATE INDEX idx_bsf_posts_user ON business_strategy_future.user_posts(user_id);
CREATE INDEX idx_bsf_posts_subprofile ON business_strategy_future.user_posts(sub_profile_id);
CREATE INDEX idx_bsf_posts_type ON business_strategy_future.user_posts(post_type);

-- Verification Requests
CREATE TABLE business_strategy_future.verification_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_skill_id UUID NOT NULL REFERENCES business_strategy_future.user_skills(user_skill_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    submitted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reviewed_date TIMESTAMP,
    
    reviewer_id VARCHAR(100),
    reviewer_type VARCHAR(50),
    
    status VARCHAR(50) DEFAULT 'pending' NOT NULL,
    admin_notes TEXT,
    rejection_reason TEXT,
    priority VARCHAR(50) DEFAULT 'normal',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_reviewer_type CHECK (
        reviewer_type IS NULL OR
        reviewer_type IN ('platform', 'expert', 'company', 'automated')
    ),
    CONSTRAINT chk_request_status CHECK (
        status IN ('pending', 'in_review', 'approved', 'rejected', 'cancelled')
    ),
    CONSTRAINT chk_priority CHECK (
        priority IN ('low', 'normal', 'high', 'urgent')
    )
);

CREATE INDEX idx_bsf_verify_skill ON business_strategy_future.verification_requests(user_skill_id);
CREATE INDEX idx_bsf_verify_user ON business_strategy_future.verification_requests(user_id);
CREATE INDEX idx_bsf_verify_status ON business_strategy_future.verification_requests(status);

-- ========================================================================
-- SCHEMA 5: art_visual_character
-- ========================================================================
CREATE SCHEMA IF NOT EXISTS art_visual_character;

-- Sub Profile
CREATE TABLE art_visual_character.sub_profiles (
    sub_profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    primary_role VARCHAR(255) NOT NULL,
    secondary_roles JSONB DEFAULT '[]'::JSONB,
    experience_level VARCHAR(50),
    availability_override JSONB,
    
    active BOOLEAN DEFAULT TRUE NOT NULL,
    display_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_experience_level CHECK (
        experience_level IS NULL OR
        experience_level IN ('beginner', 'intermediate', 'advanced', 'expert')
    ),
    CONSTRAINT unique_user_profile UNIQUE (user_id)
);

CREATE INDEX idx_avc_subprofile_user ON art_visual_character.sub_profiles(user_id);
CREATE INDEX idx_avc_subprofile_active ON art_visual_character.sub_profiles(active);

-- Profile Specific Data
CREATE TABLE art_visual_character.profile_specific_data (
    data_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_profile_id UUID NOT NULL UNIQUE REFERENCES art_visual_character.sub_profiles(sub_profile_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    data JSONB NOT NULL DEFAULT '{}'::JSONB,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX idx_avc_data_subprofile ON art_visual_character.profile_specific_data(sub_profile_id);
CREATE INDEX idx_avc_data_user ON art_visual_character.profile_specific_data(user_id);
CREATE INDEX idx_avc_data_jsonb ON art_visual_character.profile_specific_data USING gin(data);

-- User Skills
CREATE TABLE art_visual_character.user_skills (
    user_skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID NOT NULL REFERENCES art_visual_character.sub_profiles(sub_profile_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES public.skills_catalog(skill_id) ON DELETE CASCADE,
    
    skill_level INTEGER NOT NULL CHECK (skill_level BETWEEN 1 AND 5),
    
    proof_type VARCHAR(50),
    proof_urls JSONB DEFAULT '[]'::JSONB,
    proof_description TEXT,
    
    verification_status VARCHAR(50) DEFAULT 'unverified' NOT NULL,
    verification_date TIMESTAMP,
    verified_by VARCHAR(100),
    rejection_reason TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_proof_type CHECK (
        proof_type IS NULL OR
        proof_type IN ('portfolio', 'code_repo', 'audio', 'video', 'document',
                      'platform_verified', 'certificate', 'live_demo')
    ),
    CONSTRAINT chk_verification_status CHECK (
        verification_status IN ('unverified', 'proof_submitted', 'under_review', 'verified', 'rejected')
    ),
    CONSTRAINT unique_user_skill UNIQUE (user_id, skill_id)
);

CREATE INDEX idx_avc_skills_user ON art_visual_character.user_skills(user_id);
CREATE INDEX idx_avc_skills_subprofile ON art_visual_character.user_skills(sub_profile_id);
CREATE INDEX idx_avc_skills_skill ON art_visual_character.user_skills(skill_id);
CREATE INDEX idx_avc_skills_verification ON art_visual_character.user_skills(verification_status);

-- Projects
CREATE TABLE art_visual_character.projects (
    project_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID REFERENCES art_visual_character.sub_profiles(sub_profile_id) ON DELETE SET NULL,
    
    project_name VARCHAR(255) NOT NULL,
    project_type VARCHAR(50) NOT NULL,
    role_in_project VARCHAR(255),
    description TEXT,
    
    media_urls JSONB DEFAULT '[]'::JSONB,
    thumbnail_url VARCHAR(500),
    project_url VARCHAR(500),
    repository_url VARCHAR(500),
    
    start_date DATE,
    end_date DATE,
    
    status VARCHAR(50) NOT NULL,
    public BOOLEAN DEFAULT TRUE NOT NULL,
    featured BOOLEAN DEFAULT FALSE NOT NULL,
    
    team_size VARCHAR(50),
    collaborators TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_project_type CHECK (
        project_type IN ('personal', 'professional', 'commissioned', 'collaborative', 'academic', 'open_source')
    ),
    CONSTRAINT chk_project_status CHECK (
        status IN ('planning', 'in_progress', 'completed', 'paused', 'archived', 'cancelled')
    ),
    CONSTRAINT chk_project_dates CHECK (
        end_date IS NULL OR start_date IS NULL OR end_date >= start_date
    )
);

CREATE INDEX idx_avc_projects_user ON art_visual_character.projects(user_id);
CREATE INDEX idx_avc_projects_subprofile ON art_visual_character.projects(sub_profile_id);
CREATE INDEX idx_avc_projects_status ON art_visual_character.projects(status);
CREATE INDEX idx_avc_projects_public ON art_visual_character.projects(public, created_at DESC);

-- Project Skills
CREATE TABLE art_visual_character.project_skills (
    project_skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES art_visual_character.projects(project_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES public.skills_catalog(skill_id) ON DELETE CASCADE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT unique_project_skill UNIQUE (project_id, skill_id)
);

CREATE INDEX idx_avc_project_skills_project ON art_visual_character.project_skills(project_id);
CREATE INDEX idx_avc_project_skills_skill ON art_visual_character.project_skills(skill_id);

-- User Posts
CREATE TABLE art_visual_character.user_posts (
    post_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID REFERENCES art_visual_character.sub_profiles(sub_profile_id) ON DELETE SET NULL,
    
    post_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    
    media_urls JSONB DEFAULT '[]'::JSONB,
    featured_image_url VARCHAR(500),
    
    linked_skills JSONB DEFAULT '[]'::JSONB,
    linked_projects JSONB DEFAULT '[]'::JSONB,
    
    visibility VARCHAR(50) DEFAULT 'public' NOT NULL,
    view_count INTEGER DEFAULT 0 NOT NULL,
    
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_post_type CHECK (
        post_type IN ('showcase', 'update', 'tutorial', 'analysis', 'devlog', 'article', 'achievement', 'question')
    ),
    CONSTRAINT chk_visibility CHECK (
        visibility IN ('public', 'connections', 'private', 'unlisted')
    )
);

CREATE INDEX idx_avc_posts_user ON art_visual_character.user_posts(user_id);
CREATE INDEX idx_avc_posts_subprofile ON art_visual_character.user_posts(sub_profile_id);
CREATE INDEX idx_avc_posts_type ON art_visual_character.user_posts(post_type);

-- Verification Requests
CREATE TABLE art_visual_character.verification_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_skill_id UUID NOT NULL REFERENCES art_visual_character.user_skills(user_skill_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    submitted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reviewed_date TIMESTAMP,
    
    reviewer_id VARCHAR(100),
    reviewer_type VARCHAR(50),
    
    status VARCHAR(50) DEFAULT 'pending' NOT NULL,
    admin_notes TEXT,
    rejection_reason TEXT,
    priority VARCHAR(50) DEFAULT 'normal',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_reviewer_type CHECK (
        reviewer_type IS NULL OR
        reviewer_type IN ('platform', 'expert', 'company', 'automated')
    ),
    CONSTRAINT chk_request_status CHECK (
        status IN ('pending', 'in_review', 'approved', 'rejected', 'cancelled')
    ),
    CONSTRAINT chk_priority CHECK (
        priority IN ('low', 'normal', 'high', 'urgent')
    )
);

CREATE INDEX idx_avc_verify_skill ON art_visual_character.verification_requests(user_skill_id);
CREATE INDEX idx_avc_verify_user ON art_visual_character.verification_requests(user_id);
CREATE INDEX idx_avc_verify_status ON art_visual_character.verification_requests(status);

-- ========================================================================
-- SCHEMA 6: writing_narrative_editorial
-- ========================================================================
CREATE SCHEMA IF NOT EXISTS writing_narrative_editorial;

-- Sub Profile
CREATE TABLE writing_narrative_editorial.sub_profiles (
    sub_profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    primary_role VARCHAR(255) NOT NULL,
    secondary_roles JSONB DEFAULT '[]'::JSONB,
    experience_level VARCHAR(50),
    availability_override JSONB,
    
    active BOOLEAN DEFAULT TRUE NOT NULL,
    display_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_experience_level CHECK (
        experience_level IS NULL OR
        experience_level IN ('beginner', 'intermediate', 'advanced', 'expert')
    ),
    CONSTRAINT unique_user_profile UNIQUE (user_id)
);

CREATE INDEX idx_wne_subprofile_user ON writing_narrative_editorial.sub_profiles(user_id);
CREATE INDEX idx_wne_subprofile_active ON writing_narrative_editorial.sub_profiles(active);

-- Profile Specific Data
CREATE TABLE writing_narrative_editorial.profile_specific_data (
    data_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_profile_id UUID NOT NULL UNIQUE REFERENCES writing_narrative_editorial.sub_profiles(sub_profile_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    data JSONB NOT NULL DEFAULT '{}'::JSONB,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX idx_wne_data_subprofile ON writing_narrative_editorial.profile_specific_data(sub_profile_id);
CREATE INDEX idx_wne_data_user ON writing_narrative_editorial.profile_specific_data(user_id);
CREATE INDEX idx_wne_data_jsonb ON writing_narrative_editorial.profile_specific_data USING gin(data);

-- User Skills
CREATE TABLE writing_narrative_editorial.user_skills (
    user_skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID NOT NULL REFERENCES writing_narrative_editorial.sub_profiles(sub_profile_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES public.skills_catalog(skill_id) ON DELETE CASCADE,
    
    skill_level INTEGER NOT NULL CHECK (skill_level BETWEEN 1 AND 5),
    
    proof_type VARCHAR(50),
    proof_urls JSONB DEFAULT '[]'::JSONB,
    proof_description TEXT,
    
    verification_status VARCHAR(50) DEFAULT 'unverified' NOT NULL,
    verification_date TIMESTAMP,
    verified_by VARCHAR(100),
    rejection_reason TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_proof_type CHECK (
        proof_type IS NULL OR
        proof_type IN ('portfolio', 'code_repo', 'audio', 'video', 'document',
                      'platform_verified', 'certificate', 'live_demo')
    ),
    CONSTRAINT chk_verification_status CHECK (
        verification_status IN ('unverified', 'proof_submitted', 'under_review', 'verified', 'rejected')
    ),
    CONSTRAINT unique_user_skill UNIQUE (user_id, skill_id)
);

CREATE INDEX idx_wne_skills_user ON writing_narrative_editorial.user_skills(user_id);
CREATE INDEX idx_wne_skills_subprofile ON writing_narrative_editorial.user_skills(sub_profile_id);
CREATE INDEX idx_wne_skills_skill ON writing_narrative_editorial.user_skills(skill_id);
CREATE INDEX idx_wne_skills_verification ON writing_narrative_editorial.user_skills(verification_status);

-- Projects
CREATE TABLE writing_narrative_editorial.projects (
    project_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID REFERENCES writing_narrative_editorial.sub_profiles(sub_profile_id) ON DELETE SET NULL,
    
    project_name VARCHAR(255) NOT NULL,
    project_type VARCHAR(50) NOT NULL,
    role_in_project VARCHAR(255),
    description TEXT,
    
    media_urls JSONB DEFAULT '[]'::JSONB,
    thumbnail_url VARCHAR(500),
    project_url VARCHAR(500),
    repository_url VARCHAR(500),
    
    start_date DATE,
    end_date DATE,
    
    status VARCHAR(50) NOT NULL,
    public BOOLEAN DEFAULT TRUE NOT NULL,
    featured BOOLEAN DEFAULT FALSE NOT NULL,
    
    team_size VARCHAR(50),
    collaborators TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_project_type CHECK (
        project_type IN ('personal', 'professional', 'commissioned', 'collaborative', 'academic', 'open_source')
    ),
    CONSTRAINT chk_project_status CHECK (
        status IN ('planning', 'in_progress', 'completed', 'paused', 'archived', 'cancelled')
    ),
    CONSTRAINT chk_project_dates CHECK (
        end_date IS NULL OR start_date IS NULL OR end_date >= start_date
    )
);

CREATE INDEX idx_wne_projects_user ON writing_narrative_editorial.projects(user_id);
CREATE INDEX idx_wne_projects_subprofile ON writing_narrative_editorial.projects(sub_profile_id);
CREATE INDEX idx_wne_projects_status ON writing_narrative_editorial.projects(status);
CREATE INDEX idx_wne_projects_public ON writing_narrative_editorial.projects(public, created_at DESC);

-- Project Skills
CREATE TABLE writing_narrative_editorial.project_skills (
    project_skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES writing_narrative_editorial.projects(project_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES public.skills_catalog(skill_id) ON DELETE CASCADE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT unique_project_skill UNIQUE (project_id, skill_id)
);

CREATE INDEX idx_wne_project_skills_project ON writing_narrative_editorial.project_skills(project_id);
CREATE INDEX idx_wne_project_skills_skill ON writing_narrative_editorial.project_skills(skill_id);

-- User Posts
CREATE TABLE writing_narrative_editorial.user_posts (
    post_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID REFERENCES writing_narrative_editorial.sub_profiles(sub_profile_id) ON DELETE SET NULL,
    
    post_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    
    media_urls JSONB DEFAULT '[]'::JSONB,
    featured_image_url VARCHAR(500),
    
    linked_skills JSONB DEFAULT '[]'::JSONB,
    linked_projects JSONB DEFAULT '[]'::JSONB,
    
    visibility VARCHAR(50) DEFAULT 'public' NOT NULL,
    view_count INTEGER DEFAULT 0 NOT NULL,
    
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_post_type CHECK (
        post_type IN ('showcase', 'update', 'tutorial', 'analysis', 'devlog', 'article', 'achievement', 'question')
    ),
    CONSTRAINT chk_visibility CHECK (
        visibility IN ('public', 'connections', 'private', 'unlisted')
    )
);

CREATE INDEX idx_wne_posts_user ON writing_narrative_editorial.user_posts(user_id);
CREATE INDEX idx_wne_posts_subprofile ON writing_narrative_editorial.user_posts(sub_profile_id);
CREATE INDEX idx_wne_posts_type ON writing_narrative_editorial.user_posts(post_type);

-- Verification Requests
CREATE TABLE writing_narrative_editorial.verification_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_skill_id UUID NOT NULL REFERENCES writing_narrative_editorial.user_skills(user_skill_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    submitted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reviewed_date TIMESTAMP,
    
    reviewer_id VARCHAR(100),
    reviewer_type VARCHAR(50),
    
    status VARCHAR(50) DEFAULT 'pending' NOT NULL,
    admin_notes TEXT,
    rejection_reason TEXT,
    priority VARCHAR(50) DEFAULT 'normal',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_reviewer_type CHECK (
        reviewer_type IS NULL OR
        reviewer_type IN ('platform', 'expert', 'company', 'automated')
    ),
    CONSTRAINT chk_request_status CHECK (
        status IN ('pending', 'in_review', 'approved', 'rejected', 'cancelled')
    ),
    CONSTRAINT chk_priority CHECK (
        priority IN ('low', 'normal', 'high', 'urgent')
    )
);

CREATE INDEX idx_wne_verify_skill ON writing_narrative_editorial.verification_requests(user_skill_id);
CREATE INDEX idx_wne_verify_user ON writing_narrative_editorial.verification_requests(user_id);
CREATE INDEX idx_wne_verify_status ON writing_narrative_editorial.verification_requests(status);

-- ========================================================================
-- SCHEMA 7: music_audio_sound
-- ========================================================================
CREATE SCHEMA IF NOT EXISTS music_audio_sound;

-- Sub Profile
CREATE TABLE music_audio_sound.sub_profiles (
    sub_profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    primary_role VARCHAR(255) NOT NULL,
    secondary_roles JSONB DEFAULT '[]'::JSONB,
    experience_level VARCHAR(50),
    availability_override JSONB,
    
    active BOOLEAN DEFAULT TRUE NOT NULL,
    display_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_experience_level CHECK (
        experience_level IS NULL OR
        experience_level IN ('beginner', 'intermediate', 'advanced', 'expert')
    ),
    CONSTRAINT unique_user_profile UNIQUE (user_id)
);

CREATE INDEX idx_mas_subprofile_user ON music_audio_sound.sub_profiles(user_id);
CREATE INDEX idx_mas_subprofile_active ON music_audio_sound.sub_profiles(active);

-- Profile Specific Data
CREATE TABLE music_audio_sound.profile_specific_data (
    data_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_profile_id UUID NOT NULL UNIQUE REFERENCES music_audio_sound.sub_profiles(sub_profile_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    data JSONB NOT NULL DEFAULT '{}'::JSONB,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX idx_mas_data_subprofile ON music_audio_sound.profile_specific_data(sub_profile_id);
CREATE INDEX idx_mas_data_user ON music_audio_sound.profile_specific_data(user_id);
CREATE INDEX idx_mas_data_jsonb ON music_audio_sound.profile_specific_data USING gin(data);

-- User Skills
CREATE TABLE music_audio_sound.user_skills (
    user_skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID NOT NULL REFERENCES music_audio_sound.sub_profiles(sub_profile_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES public.skills_catalog(skill_id) ON DELETE CASCADE,
    
    skill_level INTEGER NOT NULL CHECK (skill_level BETWEEN 1 AND 5),
    
    proof_type VARCHAR(50),
    proof_urls JSONB DEFAULT '[]'::JSONB,
    proof_description TEXT,
    
    verification_status VARCHAR(50) DEFAULT 'unverified' NOT NULL,
    verification_date TIMESTAMP,
    verified_by VARCHAR(100),
    rejection_reason TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_proof_type CHECK (
        proof_type IS NULL OR
        proof_type IN ('portfolio', 'code_repo', 'audio', 'video', 'document',
                      'platform_verified', 'certificate', 'live_demo')
    ),
    CONSTRAINT chk_verification_status CHECK (
        verification_status IN ('unverified', 'proof_submitted', 'under_review', 'verified', 'rejected')
    ),
    CONSTRAINT unique_user_skill UNIQUE (user_id, skill_id)
);

CREATE INDEX idx_mas_skills_user ON music_audio_sound.user_skills(user_id);
CREATE INDEX idx_mas_skills_subprofile ON music_audio_sound.user_skills(sub_profile_id);
CREATE INDEX idx_mas_skills_skill ON music_audio_sound.user_skills(skill_id);
CREATE INDEX idx_mas_skills_verification ON music_audio_sound.user_skills(verification_status);

-- Projects
CREATE TABLE music_audio_sound.projects (
    project_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID REFERENCES music_audio_sound.sub_profiles(sub_profile_id) ON DELETE SET NULL,
    
    project_name VARCHAR(255) NOT NULL,
    project_type VARCHAR(50) NOT NULL,
    role_in_project VARCHAR(255),
    description TEXT,
    
    media_urls JSONB DEFAULT '[]'::JSONB,
    thumbnail_url VARCHAR(500),
    project_url VARCHAR(500),
    repository_url VARCHAR(500),
    
    start_date DATE,
    end_date DATE,
    
    status VARCHAR(50) NOT NULL,
    public BOOLEAN DEFAULT TRUE NOT NULL,
    featured BOOLEAN DEFAULT FALSE NOT NULL,
    
    team_size VARCHAR(50),
    collaborators TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_project_type CHECK (
        project_type IN ('personal', 'professional', 'commissioned', 'collaborative', 'academic', 'open_source')
    ),
    CONSTRAINT chk_project_status CHECK (
        status IN ('planning', 'in_progress', 'completed', 'paused', 'archived', 'cancelled')
    ),
    CONSTRAINT chk_project_dates CHECK (
        end_date IS NULL OR start_date IS NULL OR end_date >= start_date
    )
);

CREATE INDEX idx_mas_projects_user ON music_audio_sound.projects(user_id);
CREATE INDEX idx_mas_projects_subprofile ON music_audio_sound.projects(sub_profile_id);
CREATE INDEX idx_mas_projects_status ON music_audio_sound.projects(status);
CREATE INDEX idx_mas_projects_public ON music_audio_sound.projects(public, created_at DESC);

-- Project Skills
CREATE TABLE music_audio_sound.project_skills (
    project_skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES music_audio_sound.projects(project_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES public.skills_catalog(skill_id) ON DELETE CASCADE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT unique_project_skill UNIQUE (project_id, skill_id)
);

CREATE INDEX idx_mas_project_skills_project ON music_audio_sound.project_skills(project_id);
CREATE INDEX idx_mas_project_skills_skill ON music_audio_sound.project_skills(skill_id);

-- User Posts
CREATE TABLE music_audio_sound.user_posts (
    post_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    sub_profile_id UUID REFERENCES music_audio_sound.sub_profiles(sub_profile_id) ON DELETE SET NULL,
    
    post_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    
    media_urls JSONB DEFAULT '[]'::JSONB,
    featured_image_url VARCHAR(500),
    
    linked_skills JSONB DEFAULT '[]'::JSONB,
    linked_projects JSONB DEFAULT '[]'::JSONB,
    
    visibility VARCHAR(50) DEFAULT 'public' NOT NULL,
    view_count INTEGER DEFAULT 0 NOT NULL,
    
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_post_type CHECK (
        post_type IN ('showcase', 'update', 'tutorial', 'analysis', 'devlog', 'article', 'achievement', 'question')
    ),
    CONSTRAINT chk_visibility CHECK (
        visibility IN ('public', 'connections', 'private', 'unlisted')
    )
);

CREATE INDEX idx_mas_posts_user ON music_audio_sound.user_posts(user_id);
CREATE INDEX idx_mas_posts_subprofile ON music_audio_sound.user_posts(sub_profile_id);
CREATE INDEX idx_mas_posts_type ON music_audio_sound.user_posts(post_type);

-- Verification Requests
CREATE TABLE music_audio_sound.verification_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_skill_id UUID NOT NULL REFERENCES music_audio_sound.user_skills(user_skill_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.master_profiles(user_id) ON DELETE CASCADE,
    
    submitted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reviewed_date TIMESTAMP,
    
    reviewer_id VARCHAR(100),
    reviewer_type VARCHAR(50),
    
    status VARCHAR(50) DEFAULT 'pending' NOT NULL,
    admin_notes TEXT,
    rejection_reason TEXT,
    priority VARCHAR(50) DEFAULT 'normal',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT chk_reviewer_type CHECK (
        reviewer_type IS NULL OR
        reviewer_type IN ('platform', 'expert', 'company', 'automated')
    ),
    CONSTRAINT chk_request_status CHECK (
        status IN ('pending', 'in_review', 'approved', 'rejected', 'cancelled')
    ),
    CONSTRAINT chk_priority CHECK (
        priority IN ('low', 'normal', 'high', 'urgent')
    )
);

CREATE INDEX idx_mas_verify_skill ON music_audio_sound.verification_requests(user_skill_id);
CREATE INDEX idx_mas_verify_user ON music_audio_sound.verification_requests(user_id);
CREATE INDEX idx_mas_verify_status ON music_audio_sound.verification_requests(status);

-- ========================================================================
-- TRIGGERS for updated_at timestamps (Applied to all schemas)
-- ========================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Master Profiles
CREATE TRIGGER update_master_profiles_updated_at BEFORE UPDATE ON public.master_profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Game Creation Development
CREATE TRIGGER update_gcd_sub_profiles_updated_at BEFORE UPDATE ON game_creation_development.sub_profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_gcd_profile_data_updated_at BEFORE UPDATE ON game_creation_development.profile_specific_data
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_gcd_user_skills_updated_at BEFORE UPDATE ON game_creation_development.user_skills
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_gcd_projects_updated_at BEFORE UPDATE ON game_creation_development.projects
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_gcd_user_posts_updated_at BEFORE UPDATE ON game_creation_development.user_posts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Esports Play Performance
CREATE TRIGGER update_epp_sub_profiles_updated_at BEFORE UPDATE ON esports_play_performance.sub_profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_epp_profile_data_updated_at BEFORE UPDATE ON esports_play_performance.profile_specific_data
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_epp_user_skills_updated_at BEFORE UPDATE ON esports_play_performance.user_skills
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_epp_projects_updated_at BEFORE UPDATE ON esports_play_performance.projects
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_epp_user_posts_updated_at BEFORE UPDATE ON esports_play_performance.user_posts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Content Media Community
CREATE TRIGGER update_cmc_sub_profiles_updated_at BEFORE UPDATE ON content_media_community.sub_profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cmc_profile_data_updated_at BEFORE UPDATE ON content_media_community.profile_specific_data
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cmc_user_skills_updated_at BEFORE UPDATE ON content_media_community.user_skills
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cmc_projects_updated_at BEFORE UPDATE ON content_media_community.projects
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cmc_user_posts_updated_at BEFORE UPDATE ON content_media_community.user_posts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Business Strategy Future
CREATE TRIGGER update_bsf_sub_profiles_updated_at BEFORE UPDATE ON business_strategy_future.sub_profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bsf_profile_data_updated_at BEFORE UPDATE ON business_strategy_future.profile_specific_data
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bsf_user_skills_updated_at BEFORE UPDATE ON business_strategy_future.user_skills
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bsf_projects_updated_at BEFORE UPDATE ON business_strategy_future.projects
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bsf_user_posts_updated_at BEFORE UPDATE ON business_strategy_future.user_posts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Art Visual Character
CREATE TRIGGER update_avc_sub_profiles_updated_at BEFORE UPDATE ON art_visual_character.sub_profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_avc_profile_data_updated_at BEFORE UPDATE ON art_visual_character.profile_specific_data
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_avc_user_skills_updated_at BEFORE UPDATE ON art_visual_character.user_skills
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_avc_projects_updated_at BEFORE UPDATE ON art_visual_character.projects
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_avc_user_posts_updated_at BEFORE UPDATE ON art_visual_character.user_posts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Writing Narrative Editorial
CREATE TRIGGER update_wne_sub_profiles_updated_at BEFORE UPDATE ON writing_narrative_editorial.sub_profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wne_profile_data_updated_at BEFORE UPDATE ON writing_narrative_editorial.profile_specific_data
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wne_user_skills_updated_at BEFORE UPDATE ON writing_narrative_editorial.user_skills
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wne_projects_updated_at BEFORE UPDATE ON writing_narrative_editorial.projects
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wne_user_posts_updated_at BEFORE UPDATE ON writing_narrative_editorial.user_posts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Music Audio Sound
CREATE TRIGGER update_mas_sub_profiles_updated_at BEFORE UPDATE ON music_audio_sound.sub_profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mas_profile_data_updated_at BEFORE UPDATE ON music_audio_sound.profile_specific_data
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mas_user_skills_updated_at BEFORE UPDATE ON music_audio_sound.user_skills
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mas_projects_updated_at BEFORE UPDATE ON music_audio_sound.projects
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mas_user_posts_updated_at BEFORE UPDATE ON music_audio_sound.user_posts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================================================
-- SCHEMA RELATIONSHIP SUMMARY
-- ========================================================================

COMMENT ON SCHEMA game_creation_development IS 'Profile schema for Game Creation & Development professionals - linked to public.master_profiles via user_id';
COMMENT ON SCHEMA esports_play_performance IS 'Profile schema for Esports & Play Performance professionals - linked to public.master_profiles via user_id';
COMMENT ON SCHEMA content_media_community IS 'Profile schema for Content, Media & Community professionals - linked to public.master_profiles via user_id';
COMMENT ON SCHEMA business_strategy_future IS 'Profile schema for Business, Strategy & Future professionals - linked to public.master_profiles via user_id';
COMMENT ON SCHEMA art_visual_character IS 'Profile schema for Art, Visual & Character professionals - linked to public.master_profiles via user_id';
COMMENT ON SCHEMA writing_narrative_editorial IS 'Profile schema for Writing, Narrative & Editorial professionals - linked to public.master_profiles via user_id';
COMMENT ON SCHEMA music_audio_sound IS 'Profile schema for Music, Audio & Sound professionals - linked to public.master_profiles via user_id';

-- ========================================================================
-- END OF SCHEMA CREATION
-- ========================================================================
