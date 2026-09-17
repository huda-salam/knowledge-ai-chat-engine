CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE knowledge_bases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    version INTEGER NOT NULL DEFAULT 0 CHECK (version >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    knowledge_base_id UUID NOT NULL REFERENCES knowledge_bases(id),
    external_id TEXT NOT NULL,
    title TEXT NOT NULL,
    document_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    source_uri TEXT,
    source_type TEXT NOT NULL,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (knowledge_base_id, external_id)
);

CREATE INDEX documents_knowledge_base_idx ON documents(knowledge_base_id);

CREATE TABLE document_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id),
    version INTEGER NOT NULL CHECK (version > 0),
    content_hash TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'validated', 'published', 'superseded')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    published_at TIMESTAMPTZ,
    UNIQUE (document_id, version),
    UNIQUE (document_id, content_hash)
);

CREATE INDEX document_versions_document_idx ON document_versions(document_id);

CREATE TABLE sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_version_id UUID NOT NULL REFERENCES document_versions(id),
    parent_section_id UUID REFERENCES sections(id),
    heading TEXT NOT NULL DEFAULT '',
    section_path TEXT NOT NULL,
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    content TEXT NOT NULL DEFAULT '',
    UNIQUE (document_version_id, ordinal)
);

CREATE INDEX sections_document_version_idx ON sections(document_version_id);
CREATE INDEX sections_parent_idx ON sections(parent_section_id);

CREATE TABLE sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id),
    source_type TEXT NOT NULL,
    title TEXT NOT NULL,
    uri TEXT,
    publisher TEXT,
    author TEXT,
    publication_date DATE,
    version TEXT,
    retrieved_at TIMESTAMPTZ,
    content_hash TEXT
);

CREATE INDEX sources_document_idx ON sources(document_id);

CREATE TABLE chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    knowledge_base_id UUID NOT NULL REFERENCES knowledge_bases(id),
    document_id UUID NOT NULL REFERENCES documents(id),
    document_version_id UUID NOT NULL REFERENCES document_versions(id),
    section_id UUID NOT NULL REFERENCES sections(id),
    content TEXT NOT NULL,
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    search_vector TSVECTOR GENERATED ALWAYS AS (
        to_tsvector('simple', coalesce(content, ''))
    ) STORED,
    UNIQUE (document_version_id, ordinal)
);

CREATE INDEX chunks_kb_idx ON chunks(knowledge_base_id);
CREATE INDEX chunks_document_version_idx ON chunks(document_version_id);
CREATE INDEX chunks_section_idx ON chunks(section_id);
CREATE INDEX chunks_search_idx ON chunks USING GIN(search_vector);

CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    knowledge_base_id UUID NOT NULL REFERENCES knowledge_bases(id),
    user_id TEXT,
    anonymous_session_id TEXT,
    title TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (user_id IS NOT NULL OR anonymous_session_id IS NOT NULL)
);

CREATE INDEX conversations_kb_idx ON conversations(knowledge_base_id);
CREATE INDEX conversations_user_idx ON conversations(user_id);
CREATE INDEX conversations_session_idx ON conversations(anonymous_session_id);

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    model TEXT,
    provider TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    latency_ms BIGINT,
    input_tokens INTEGER,
    output_tokens INTEGER,
    total_tokens INTEGER
);

CREATE INDEX messages_conversation_idx ON messages(conversation_id, created_at);

CREATE TABLE citations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    document_id UUID NOT NULL REFERENCES documents(id),
    document_version_id UUID NOT NULL REFERENCES document_versions(id),
    section_id UUID NOT NULL REFERENCES sections(id),
    chunk_id UUID NOT NULL REFERENCES chunks(id),
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    UNIQUE (message_id, chunk_id)
);

CREATE INDEX citations_message_idx ON citations(message_id);
CREATE INDEX citations_chunk_idx ON citations(chunk_id);
