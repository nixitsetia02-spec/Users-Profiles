# GZONESPHERE DATABASE SCHEMA DOCUMENTATION

## Overview
This database is structured with **8 schemas total**:
- 1 Master Schema (public) containing the master user profile
- 7 Profile-Specific Schemas, one for each profile type
- All profile schemas are linked to the master profile via `user_id`

---

## SCHEMA STRUCTURE

### 1. PUBLIC SCHEMA (Master Schema)
**Contains:**
- `master_profiles` - The master table for all users
- `skills_catalog` - Shared catalog of all skills across all profiles

**Master Profiles Table Structure:**
```
public.master_profiles
├── user_id (UUID) [PRIMARY KEY] ← Links to all 7 profile schemas
├── display_name
├── username (UNIQUE)
├── email (UNIQUE)
├── Authentication fields
├── Location data
├── Availability settings
├── Aggregated metrics
├── Trust & reputation
├── Platform activity counts
└── Bio & links
```

**Skills Catalog:**
```
public.skills_catalog
├── skill_id (UUID) [PRIMARY KEY]
├── skill_name (UNIQUE)
├── skill_category
├── skill_group
└── profile_type (links to one of 7 profile types)
```

---

## 7 PROFILE SCHEMAS

Each of the following schemas has an **identical table structure** but is **isolated** by profile type:

### SCHEMA 1: game_creation_development
### SCHEMA 2: esports_play_performance
### SCHEMA 3: content_media_community
### SCHEMA 4: business_strategy_future
### SCHEMA 5: art_visual_character
### SCHEMA 6: writing_narrative_editorial
### SCHEMA 7: music_audio_sound

---

## TABLES WITHIN EACH PROFILE SCHEMA

Each profile schema contains 6 tables:

### 1. sub_profiles
**Purpose:** Core profile information for this specific profile type
**Links to:** `public.master_profiles(user_id)`

```
[schema_name].sub_profiles
├── sub_profile_id (UUID) [PRIMARY KEY]
├── user_id (UUID) [FOREIGN KEY → public.master_profiles]
├── primary_role
├── secondary_roles (JSONB)
├── experience_level
├── availability_override (JSONB)
├── active (BOOLEAN)
└── display_order

CONSTRAINT: Only ONE profile per user per schema (user_id UNIQUE)
```

### 2. profile_specific_data
**Purpose:** Type-specific flexible data storage
**Links to:** 
- `[schema_name].sub_profiles(sub_profile_id)`
- `public.master_profiles(user_id)`

```
[schema_name].profile_specific_data
├── data_id (UUID) [PRIMARY KEY]
├── sub_profile_id (UUID) [FOREIGN KEY → schema.sub_profiles]
├── user_id (UUID) [FOREIGN KEY → public.master_profiles]
└── data (JSONB) - Flexible storage for profile-specific fields
```

### 3. user_skills
**Purpose:** Skills claimed by users for this profile
**Links to:** 
- `public.master_profiles(user_id)`
- `[schema_name].sub_profiles(sub_profile_id)`
- `public.skills_catalog(skill_id)`

```
[schema_name].user_skills
├── user_skill_id (UUID) [PRIMARY KEY]
├── user_id (UUID) [FOREIGN KEY → public.master_profiles]
├── sub_profile_id (UUID) [FOREIGN KEY → schema.sub_profiles]
├── skill_id (UUID) [FOREIGN KEY → public.skills_catalog]
├── skill_level (1-5)
├── proof_type
├── proof_urls (JSONB)
├── proof_description
├── verification_status
├── verification_date
└── verified_by
```

### 4. projects
**Purpose:** Portfolio projects for this profile
**Links to:** 
- `public.master_profiles(user_id)`
- `[schema_name].sub_profiles(sub_profile_id)`

```
[schema_name].projects
├── project_id (UUID) [PRIMARY KEY]
├── user_id (UUID) [FOREIGN KEY → public.master_profiles]
├── sub_profile_id (UUID) [FOREIGN KEY → schema.sub_profiles]
├── project_name
├── project_type
├── role_in_project
├── description
├── media_urls (JSONB)
├── thumbnail_url
├── project_url
├── repository_url
├── start_date / end_date
├── status
├── public (BOOLEAN)
├── featured (BOOLEAN)
├── team_size
└── collaborators
```

### 5. project_skills
**Purpose:** Links projects to skills used
**Links to:** 
- `[schema_name].projects(project_id)`
- `public.skills_catalog(skill_id)`

```
[schema_name].project_skills
├── project_skill_id (UUID) [PRIMARY KEY]
├── project_id (UUID) [FOREIGN KEY → schema.projects]
└── skill_id (UUID) [FOREIGN KEY → public.skills_catalog]
```

### 6. user_posts
**Purpose:** User-generated content, updates, showcases
**Links to:** 
- `public.master_profiles(user_id)`
- `[schema_name].sub_profiles(sub_profile_id)`

```
[schema_name].user_posts
├── post_id (UUID) [PRIMARY KEY]
├── user_id (UUID) [FOREIGN KEY → public.master_profiles]
├── sub_profile_id (UUID) [FOREIGN KEY → schema.sub_profiles]
├── post_type
├── title
├── content
├── excerpt
├── media_urls (JSONB)
├── featured_image_url
├── linked_skills (JSONB)
├── linked_projects (JSONB)
├── visibility
├── view_count
└── published_at
```

### 7. verification_requests
**Purpose:** Queue for skill verification
**Links to:** 
- `[schema_name].user_skills(user_skill_id)`
- `public.master_profiles(user_id)`

```
[schema_name].verification_requests
├── request_id (UUID) [PRIMARY KEY]
├── user_skill_id (UUID) [FOREIGN KEY → schema.user_skills]
├── user_id (UUID) [FOREIGN KEY → public.master_profiles]
├── submitted_date
├── reviewed_date
├── reviewer_id
├── reviewer_type
├── status
├── admin_notes
├── rejection_reason
└── priority
```

---

## RELATIONSHIP DIAGRAM

```
┌─────────────────────────────────────────────────────────────┐
│                    PUBLIC SCHEMA                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  master_profiles (MASTER TABLE)                     │    │
│  │  - user_id (PK) ←──┐                               │    │
│  │  - username        │                               │    │
│  │  - email           │                               │    │
│  │  - profile info    │                               │    │
│  └─────────────────────┼────────────────────────────────┘    │
│                        │                                     │
│  ┌─────────────────────┼────────────────────────────────┐    │
│  │  skills_catalog     │                                │    │
│  │  - skill_id (PK) ←──┼────────────┐                  │    │
│  │  - skill_name       │            │                  │    │
│  └─────────────────────┼────────────┼───────────────────┘    │
└────────────────────────┼────────────┼────────────────────────┘
                         │            │
         ┌───────────────┼────────────┼───────────────┐
         │               │            │               │
         ▼               │            │               ▼
┌────────────────────────┼────────────┼────────────────────────┐
│ SCHEMA: game_creation_development   │                        │
│ ┌─────────────────────┼────────────┼──────────────────┐     │
│ │ sub_profiles        │            │                  │     │
│ │ - user_id (FK) ─────┘            │                  │     │
│ │ - sub_profile_id (PK)            │                  │     │
│ └──────────┬───────────────────────┼───────────────────┘     │
│            │                       │                         │
│ ┌──────────▼───────────────────────┼───────────────────┐     │
│ │ user_skills                      │                  │     │
│ │ - user_id (FK) ──────────────────┘                  │     │
│ │ - skill_id (FK) ─────────────────────────────────────┘     │
│ └─────────────────────────────────────────────────────┘      │
│                                                               │
│ [Similar structure for: profile_specific_data, projects,     │
│  project_skills, user_posts, verification_requests]          │
└───────────────────────────────────────────────────────────────┘

         ... Same pattern for remaining 6 schemas ...

┌───────────────────────────────────────────────────────────────┐
│ SCHEMA: esports_play_performance                              │
│    [Identical table structure as above]                       │
└───────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────┐
│ SCHEMA: content_media_community                               │
│    [Identical table structure as above]                       │
└───────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────┐
│ SCHEMA: business_strategy_future                              │
│    [Identical table structure as above]                       │
└───────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────┐
│ SCHEMA: art_visual_character                                  │
│    [Identical table structure as above]                       │
└───────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────┐
│ SCHEMA: writing_narrative_editorial                           │
│    [Identical table structure as above]                       │
└───────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────┐
│ SCHEMA: music_audio_sound                                     │
│    [Identical table structure as above]                       │
└───────────────────────────────────────────────────────────────┘
```

---

## KEY RELATIONSHIPS

### PRIMARY LINKING KEY: user_id
Every profile schema links back to `public.master_profiles` using `user_id`:

```
public.master_profiles.user_id
    ↓
    ├─→ game_creation_development.sub_profiles.user_id
    ├─→ esports_play_performance.sub_profiles.user_id
    ├─→ content_media_community.sub_profiles.user_id
    ├─→ business_strategy_future.sub_profiles.user_id
    ├─→ art_visual_character.sub_profiles.user_id
    ├─→ writing_narrative_editorial.sub_profiles.user_id
    └─→ music_audio_sound.sub_profiles.user_id
```

### SHARED CATALOG: skills_catalog
All profile schemas reference the same skills catalog:

```
public.skills_catalog.skill_id
    ↓
    ├─→ game_creation_development.user_skills.skill_id
    ├─→ esports_play_performance.user_skills.skill_id
    ├─→ content_media_community.user_skills.skill_id
    ├─→ business_strategy_future.user_skills.skill_id
    ├─→ art_visual_character.user_skills.skill_id
    ├─→ writing_narrative_editorial.user_skills.skill_id
    └─→ music_audio_sound.user_skills.skill_id
```

---

## DATA FLOW EXAMPLES

### Example 1: User with Multiple Profiles
A user can have profiles in multiple schemas:

```
User: John Doe (user_id: 123-abc-456)
    ↓
    ├─→ game_creation_development.sub_profiles
    │   └─→ Primary Role: "Game Designer"
    │
    ├─→ art_visual_character.sub_profiles
    │   └─→ Primary Role: "Concept Artist"
    │
    └─→ music_audio_sound.sub_profiles
        └─→ Primary Role: "Sound Designer"
```

### Example 2: Skill Verification Flow
```
1. User adds skill to their profile
   ↓
   [schema].user_skills (verification_status: 'unverified')
   
2. User submits proof
   ↓
   [schema].verification_requests (status: 'pending')
   
3. Admin reviews
   ↓
   [schema].verification_requests (status: 'approved')
   
4. Skill verified
   ↓
   [schema].user_skills (verification_status: 'verified')
   
5. Master profile updated
   ↓
   public.master_profiles.total_verified_skills += 1
```

---

## BENEFITS OF THIS STRUCTURE

### 1. **Clear Separation of Concerns**
- Each profile type has its own isolated schema
- Easy to understand which data belongs to which profile type

### 2. **Scalability**
- Can add new profile types by creating new schemas
- Each schema is independent and self-contained

### 3. **Security & Permissions**
- Can set different permissions per schema
- Easy to grant role-based access (e.g., developers only access game_creation_development)

### 4. **Performance**
- Queries are faster due to smaller, focused tables
- Indexes are more efficient within each schema

### 5. **Maintenance**
- Easy to backup/restore individual profile types
- Can update one profile type without affecting others

### 6. **Data Integrity**
- Foreign key constraints ensure referential integrity
- CASCADE deletes ensure clean data removal

---

## QUERYING EXAMPLES

### Get all profiles for a user:
```sql
-- Master profile
SELECT * FROM public.master_profiles WHERE user_id = '123-abc-456';

-- All sub-profiles
SELECT 'game_creation' as type, * FROM game_creation_development.sub_profiles WHERE user_id = '123-abc-456'
UNION ALL
SELECT 'esports' as type, * FROM esports_play_performance.sub_profiles WHERE user_id = '123-abc-456'
UNION ALL
SELECT 'content' as type, * FROM content_media_community.sub_profiles WHERE user_id = '123-abc-456'
-- ... etc for all 7 schemas
```

### Get all skills across all profiles for a user:
```sql
SELECT 
    'game_creation' as profile_type,
    us.*,
    sc.skill_name
FROM game_creation_development.user_skills us
JOIN public.skills_catalog sc ON us.skill_id = sc.skill_id
WHERE us.user_id = '123-abc-456'
UNION ALL
SELECT 
    'esports' as profile_type,
    us.*,
    sc.skill_name
FROM esports_play_performance.user_skills us
JOIN public.skills_catalog sc ON us.skill_id = sc.skill_id
WHERE us.user_id = '123-abc-456'
-- ... etc for all 7 schemas
```

### Get master profile with aggregated data:
```sql
SELECT 
    mp.*,
    COUNT(DISTINCT gcd.sub_profile_id) + 
    COUNT(DISTINCT epp.sub_profile_id) + 
    COUNT(DISTINCT cmc.sub_profile_id) +
    COUNT(DISTINCT bsf.sub_profile_id) +
    COUNT(DISTINCT avc.sub_profile_id) +
    COUNT(DISTINCT wne.sub_profile_id) +
    COUNT(DISTINCT mas.sub_profile_id) as active_profiles
FROM public.master_profiles mp
LEFT JOIN game_creation_development.sub_profiles gcd ON mp.user_id = gcd.user_id AND gcd.active = true
LEFT JOIN esports_play_performance.sub_profiles epp ON mp.user_id = epp.user_id AND epp.active = true
LEFT JOIN content_media_community.sub_profiles cmc ON mp.user_id = cmc.user_id AND cmc.active = true
LEFT JOIN business_strategy_future.sub_profiles bsf ON mp.user_id = bsf.user_id AND bsf.active = true
LEFT JOIN art_visual_character.sub_profiles avc ON mp.user_id = avc.user_id AND avc.active = true
LEFT JOIN writing_narrative_editorial.sub_profiles wne ON mp.user_id = wne.user_id AND wne.active = true
LEFT JOIN music_audio_sound.sub_profiles mas ON mp.user_id = mas.user_id AND mas.active = true
WHERE mp.user_id = '123-abc-456'
GROUP BY mp.user_id;
```

---

## INDEX STRATEGY

Each schema has consistent indexing:
- `user_id` - for fast master profile lookups
- `sub_profile_id` - for profile-specific queries
- `skill_id` - for skill-based searches
- `verification_status` - for verification workflows
- `created_at` / `updated_at` - for temporal queries
- `public` / `active` - for visibility filtering

---

## CONSTRAINTS & DATA INTEGRITY

### Unique Constraints:
- One user can only have ONE profile per schema (enforced by UNIQUE constraint on user_id in sub_profiles)
- Skills can only be claimed once per user (UNIQUE constraint on user_id + skill_id in user_skills)

### Cascade Deletes:
- Deleting a master profile → deletes all associated sub-profiles and related data
- Deleting a sub-profile → deletes all associated skills, projects, posts

### Check Constraints:
- Experience levels: beginner, intermediate, advanced, expert
- Verification status: unverified, proof_submitted, under_review, verified, rejected
- Project status: planning, in_progress, completed, paused, archived, cancelled

---

## AUTOMATED TRIGGERS

All tables with `updated_at` columns have triggers that automatically update the timestamp on every row modification.

---

## SUMMARY

**Total Schemas:** 8
- 1 Master (public)
- 7 Profile-specific

**Total Tables per Profile Schema:** 6
- sub_profiles
- profile_specific_data
- user_skills
- projects
- project_skills
- user_posts
- verification_requests

**Total Tables:** 2 (public) + 7 × 6 (profiles) = **44 tables**

**All schemas are linked via `user_id` to `public.master_profiles`**
