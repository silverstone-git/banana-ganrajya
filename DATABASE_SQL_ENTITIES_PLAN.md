# Banana Ganrajya — Database & SQL Entities Plan

This document outlines the complete SQL relational schema design to transition **Banana Ganrajya** from mock offline files to a robust, normalized relational database (PostgreSQL recommended).

---

## 🌟 Milestone 1 Implementation Status: COMPLETE

The relational database architecture has been **fully mapped and deployed** using SQLAlchemy 2.0 and SQLite (fully compatible with future PostgreSQL migrations).
*   **Active ORM Mapping (`backend/app/db/models.py`)**: All tables (`users`, `authors`, `articles`, `bookmarks`, `comments`, `transactions`, `analytics_reads`, and `tags`) have been fully declared and linked via relational properties.
*   **Alembic Migration Path (`backend/alembic/`)**: Initialized, generated, and fully upgraded schemas to establish the physical database tables.
*   **Pre-loaded Seeding Engine (`backend/app/seed.py`)**: Populated the database with complete relational graphs of authors, columnists, categories, tags, threaded discussions, and all stories.

---

## 🏛️ Entity Relationship Diagram (Conceptual)

```
       [Users] ──(1:N)── [Bookmarks] ──(N:1)── [Articles]
          │                                       │
        (1:N)                                   (1:N)
          │                                       │
   [Transactions]                             [Comments]
          │                                       │
          └─────────────(1:N)─────────────────────┘
          │
        (1:N)
          │
  [AnalyticsReads]
```

---

## 💾 SQL Schema Definition

Below is the DDL (Data Definition Language) specification, complete with foreign keys, checks, and performance indexes.

### 1. Authors Table
Stores content creators, journalists, and columnists.
```sql
CREATE TABLE authors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    title VARCHAR(100) NOT NULL,
    bio TEXT,
    avatar_s3_key TEXT NOT NULL, -- Stored as S3 key, backend generates presigned URL
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_authors_name ON authors(name);
```

### 2. Articles Table
Stores news stories, editorial pieces, and deep dives. Includes support for S3 media keys.
```sql
CREATE TYPE article_category AS ENUM (
    'POLITICS', 'ECONOMY', 'TECH', 'DIPLOMACY', 
    'ENVIRONMENT', 'SCIENCE', 'SOCIETY', 'FOREIGN POLICY'
);

CREATE TABLE articles (
    id VARCHAR(100) PRIMARY KEY, -- e.g., 'hero-1', 'gr-1' or UUIDs
    category article_category NOT NULL,
    title VARCHAR(500) NOT NULL,
    excerpt TEXT,
    body TEXT NOT NULL,
    
    -- Media (Backend converts these S3 keys to presigned URLs on read)
    cover_image_s3_key TEXT NOT NULL,
    video_s3_key TEXT, -- Optional embedded video
    
    author_id UUID NOT NULL REFERENCES authors(id) ON DELETE RESTRICT,
    read_time_minutes INT NOT NULL DEFAULT 5,
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    is_locked BOOLEAN NOT NULL DEFAULT FALSE,
    published_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_read_time CHECK (read_time_minutes >= 0)
);

CREATE INDEX idx_articles_published_at ON articles(published_at DESC);
CREATE INDEX idx_articles_category ON articles(category);
CREATE INDEX idx_articles_premium_locked ON articles(is_premium, is_locked);
CREATE INDEX idx_articles_author_id ON articles(author_id); -- Optimization for Author's Page query
```

### 3. Tags Table
For categorization and cross-referencing.
```sql
CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE article_tags (
    article_id VARCHAR(100) REFERENCES articles(id) ON DELETE CASCADE,
    tag_id INT REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (article_id, tag_id)
);

CREATE INDEX idx_article_tags_tag_id ON article_tags(tag_id);
```

### 4. Users & Subscriptions Table
Handles user profile metadata and subscription tiers mapped from Auth0.
```sql
CREATE TYPE subscription_tier AS ENUM ('FREE', 'DIGITAL', 'PATRON');

CREATE TABLE users (
    id VARCHAR(128) PRIMARY KEY, -- Maps directly to Auth0 'sub' claim identifier
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    tier subscription_tier NOT NULL DEFAULT 'FREE',
    subscription_expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
```

### 5. Transactions Table (Paytm Integration)
Tracks subscription purchases and payment lifecycle via Paytm.
```sql
CREATE TYPE payment_status AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED');

CREATE TABLE transactions (
    order_id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'INR',
    tier_purchased subscription_tier NOT NULL,
    status payment_status NOT NULL DEFAULT 'PENDING',
    paytm_transaction_id VARCHAR(255),
    paytm_response_msg TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_status ON transactions(status);
```

### 6. Bookmarks Table
Saves user-bookmarked articles (tied to logged-in user state).
```sql
CREATE TABLE bookmarks (
    user_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    article_id VARCHAR(100) REFERENCES articles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, article_id)
);
```

### 7. Newsletter Subscriptions Table
Captures leads and email subscriptions.
```sql
CREATE TYPE newsletter_type AS ENUM ('MORNING_BRIEF', 'CLARITY');

CREATE TABLE newsletter_subscriptions (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    newsletter newsletter_type NOT NULL,
    subscribed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (email, newsletter)
);

CREATE INDEX idx_newsletter_subs_email ON newsletter_subscriptions(email);
```

### 8. Comments Table
Allows users to engage in article-level discussions.
```sql
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    article_id VARCHAR(100) NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    user_id VARCHAR(128) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES comments(id) ON DELETE CASCADE, -- For nested comment threads
    body TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_comments_article_id ON comments(article_id);
CREATE INDEX idx_comments_parent_id ON comments(parent_id);
```

### 9. Analytics Reads Table
Logs granular metrics on reading habits, retention, and completion rates.
```sql
CREATE TABLE analytics_reads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    article_id VARCHAR(100) NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    user_id VARCHAR(128) REFERENCES users(id) ON DELETE SET NULL, -- Nullable for anonymous readers
    time_spent_seconds INT NOT NULL DEFAULT 0,
    max_scroll_percentage INT NOT NULL DEFAULT 0 CHECK (max_scroll_percentage BETWEEN 0 AND 100),
    is_completed BOOLEAN NOT NULL DEFAULT FALSE, -- Set true if scroll reaches 90%+ and time spent is reasonable
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_analytics_reads_article_id ON analytics_reads(article_id);
CREATE INDEX idx_analytics_reads_completed ON analytics_reads(is_completed);
```

---

## 🔍 Key Performance Queries

### Fetching Article Comments
Recursively fetch comment threads (up to 2 levels deep):
```sql
SELECT 
    c.id, c.body, c.created_at, c.parent_id,
    u.name AS user_name, u.tier AS user_subscription_tier
FROM comments c
JOIN users u ON c.user_id = u.id
WHERE c.article_id = :article_id
ORDER BY COALESCE(c.parent_id, c.id), c.created_at ASC;
```

### Aggregating Read Metrics for Editor Dashboard
```sql
SELECT 
    a.title,
    COUNT(r.id) AS total_clicks,
    AVG(r.time_spent_seconds) AS avg_duration_seconds,
    AVG(r.max_scroll_percentage) AS avg_scroll_depth,
    SUM(CASE WHEN r.is_completed THEN 1 ELSE 0 END)::FLOAT / COUNT(r.id) * 100 AS completion_rate_percentage
FROM articles a
LEFT JOIN analytics_reads r ON a.id = r.article_id
GROUP BY a.id;
```
