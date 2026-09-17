# Product Requirements Document — Knowledge AI Chat Engine

**Project Name:** Knowledge AI Chat Engine  
**Repository:** `knowledge-ai-chat-engine`  
**Type:** Generic AI knowledge/retrieval backend  
**Primary Language:** Go  
**Primary Database:** PostgreSQL  
**Vector Search:** PostgreSQL + pgvector, introduced when justified by evaluation  
**Initial LLM Gateway:** OpenRouter  
**Architecture:** Production-capable modular monolith  
**First Consumer:** AI Technology & Architecture Advisor book

## 1. Purpose

Knowledge AI Chat Engine is a reusable backend for conversational AI over a controlled knowledge corpus.

The first corpus is the AI Technology & Architecture Advisor book, but the backend must remain generic enough for:

- books and handbooks;
- SOPs;
- regulations;
- technical documentation;
- internal knowledge bases;
- multiple independent knowledge bases.

Core principle:

> The system should make knowledge easier to retrieve and reason about without weakening the evidentiary discipline of the underlying knowledge.

The engine is **not an LLM wrapper**. Its core flow is:

```text
Knowledge
  ↓
Retrieval
  ↓
Evidence
  ↓
Context
  ↓
LLM Generation
  ↓
Grounded Response
  ↓
Citation / Provenance
```

Keep these concepts separate:

```text
Knowledge ≠ Retrieval ≠ Evidence ≠ LLM capability ≠ Answer ≠ Truth
```

## 2. Product Vision

```text
                 Knowledge AI Chat Engine
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
     Book A             Book B             SOP
        │                  │                  │
        └──────────────────┼──────────────────┘
                           ▼
                    Common Chat API
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
          Web UI        Other UI       API Client
```

No book-specific concepts, prompts, chapter assumptions, or provider dependencies should leak into the core engine.

## 3. Initial Use Case

Example:

> “When should we reject an AI proposal?”

The backend should:

1. identify the relevant knowledge;
2. retrieve appropriate sections;
3. construct grounded context;
4. generate an answer using that context;
5. distinguish source-supported statements from inference;
6. return traceable citations;
7. state when evidence is insufficient.

Preferred response structure where appropriate:

```text
Answer
Evidence
Interpretation
Recommendation
Limitations
Sources
```

Not every answer needs every section.

## 4. Product Principles

### 4.1 Grounded by Knowledge

Default chat answers must use the configured knowledge base. External knowledge must not be silently introduced.

### 4.2 Evidence Before Confidence

LLM confidence must not substitute for evidence.

### 4.3 Citation Is Provenance, Not Proof

A citation identifies source material; it does not automatically establish correctness, applicability, completeness, or sufficiency.

### 4.4 Model-Agnostic

OpenRouter is the initial provider gateway, not a domain-level dependency.

Future providers may include OpenAI, Google, Anthropic, local inference, or other compatible providers.

### 4.5 Retrieval-Agnostic

Retrieval must be behind an interface so PostgreSQL FTS, pgvector, Qdrant, OpenSearch, or another implementation can be substituted.

### 4.6 Architecture Before Infrastructure

Do not introduce vector databases, Redis, message brokers, Kubernetes, or microservices without evidence that they are required.

## 5. MVP Scope

### Knowledge

- knowledge base management;
- document ingestion;
- document metadata;
- document versioning;
- section/chunk representation;
- source/provenance metadata;
- publication status.

### Retrieval

- PostgreSQL full-text search;
- metadata filtering;
- retrieval abstraction;
- top-K retrieval;
- relevance metadata;
- provenance;
- optional semantic retrieval path.

### AI

- LLM provider abstraction;
- OpenRouter adapter;
- configurable model;
- prompt construction;
- grounded generation;
- streaming.

### Chat

- conversations;
- messages;
- bounded conversation context;
- citations;
- source references;
- insufficient-evidence behavior.

### Security

- authentication;
- authorization;
- rate limiting;
- knowledge-base isolation;
- provider credential protection;
- prompt-injection defenses.

### Operations

- structured logging;
- request IDs;
- latency metrics;
- token/cost tracking;
- retrieval diagnostics;
- provider failure handling.

### Evaluation

- evaluation cases;
- expected evidence;
- retrieval evaluation;
- answer evaluation;
- citation evaluation;
- regression testing.

## 6. Explicitly Out of Scope for MVP

Do not initially build:

- autonomous agents;
- arbitrary tool execution;
- web browsing;
- autonomous research;
- multi-agent orchestration;
- fine-tuning infrastructure;
- custom foundation models;
- real-time collaboration;
- enterprise SSO;
- complex workflow engines;
- microservices;
- Kubernetes;
- dedicated vector database;
- long-term user memory;
- automatic decision-making.

The MVP is primarily:

> **Knowledge retrieval + grounded conversational generation.**

## 7. High-Level Architecture

```text
Client
  │ HTTPS
  ▼
┌──────────────────────┐
│ HTTP API             │
│ Auth / Rate Limiting │
└──────────┬───────────┘
           ▼
┌──────────────────────┐
│ Chat Application     │
└──────────┬───────────┘
           │
     ┌─────┼───────────────┐
     ▼     ▼               ▼
Conversation Retrieval     Policy
           │
           ▼
     ┌─────────────┐
     │ PostgreSQL  │
     │             │
     │ Documents   │
     │ Sections    │
     │ Chunks      │
     │ Metadata    │
     │ Sources     │
     │ Conversations│
     └──────┬──────┘
            │ optional
            ▼
         pgvector
            │
            ▼
     Context Assembly
            │
            ▼
      ┌─────────────┐
      │ LLM Gateway │
      └──────┬──────┘
             ▼
         OpenRouter
```

## 8. Architectural Style

Use a **modular monolith**.

Recommended structure:

```text
cmd/
└── server/

internal/
├── domain/
│   ├── knowledge/
│   ├── retrieval/
│   ├── conversation/
│   ├── generation/
│   ├── evidence/
│   └── evaluation/
│
├── application/
│   ├── knowledge/
│   ├── retrieval/
│   ├── chat/
│   └── evaluation/
│
├── infrastructure/
│   ├── postgres/
│   ├── retrieval/
│   ├── llm/
│   │   └── openrouter/
│   ├── embeddings/
│   └── observability/
│
└── interfaces/
    └── http/
```

Domain code must not depend on OpenRouter, PostgreSQL, HTTP, or a specific embedding provider.

## 9. Core Domain Model

### Knowledge Base

An independently addressable body of knowledge.

```text
id
name
slug
description
status
version
created_at
updated_at
```

### Document

```text
id
knowledge_base_id
external_id
title
document_type
version
status
source_uri
source_type
published_at
created_at
updated_at
```

### Document Version

Required for reproducibility.

```text
id
document_id
version
content_hash
status
created_at
published_at
```

### Section

Preserves semantic hierarchy.

```text
id
document_version_id
parent_section_id
heading
section_path
ordinal
content
```

### Chunk

Retrieval unit. Must retain source lineage.

```text
id
knowledge_base_id
document_id
document_version_id
section_id
content
ordinal
metadata
```

### Source / Provenance

```text
id
document_id
source_type
title
uri
publisher
author
publication_date
version
retrieved_at
content_hash
```

### Citation

Must point to actual retrieved material.

```text
document_id
document_version_id
section_id
chunk_id
source metadata
```

### Conversation

```text
id
knowledge_base_id
user_id / anonymous_session_id
title
created_at
updated_at
```

### Message

```text
id
conversation_id
role
content
model
provider
created_at
latency_ms
token_usage
```

Roles:

```text
user
assistant
system
```

## 10. Retrieval Architecture

Define:

```go
type Retriever interface {
    Search(ctx context.Context, query RetrievalQuery) ([]RetrievalResult, error)
}
```

Potential implementations:

```text
PostgresFullTextRetriever
PostgresHybridRetriever
QdrantRetriever
OpenSearchRetriever
```

The application layer must not know which implementation is active.

### Initial Strategy

Start with:

```text
PostgreSQL
+
Full-Text Search
+
Metadata Filtering
```

Pipeline:

```text
User Query
  ↓
Query processing
  ↓
Metadata filters
  ↓
PostgreSQL FTS
  ↓
Ranking
  ↓
Top-K candidates
```

Do not require embeddings for MVP.

### Semantic Evolution

If evaluation shows lexical retrieval is insufficient:

```text
PostgreSQL
  +
pgvector
```

Target:

```text
Query
 ├── lexical retrieval
 └── semantic retrieval
          ↓
    candidate set
          ↓
       reranking
          ↓
    context builder
```

The target is **hybrid retrieval**, not vector search for its own sake.

## 11. Why PostgreSQL

PostgreSQL is the default because it can initially support:

- relational domain data;
- metadata;
- full-text search;
- transactions;
- versioning;
- conversations;
- evaluation data;
- audit data;
- optional vectors via pgvector.

Initial infrastructure should preferably be:

```text
Go
+
PostgreSQL
+
LLM Provider
```

Redis is optional and should be introduced only when caching or other requirements justify it.

## 12. Database Evolution

### Stage 1

```text
PostgreSQL
├── relational data
├── metadata
└── FTS
```

### Stage 2

```text
PostgreSQL
├── relational data
├── FTS
└── pgvector
```

### Stage 3 — only if justified

```text
PostgreSQL
+
Dedicated Retrieval Infrastructure
```

Candidates include Qdrant or OpenSearch.

The retrieval abstraction must make such migration an infrastructure change, not an application rewrite.

## 13. LLM Provider Architecture

Use:

```go
type LLMProvider interface {
    Generate(ctx context.Context, request GenerateRequest) (GenerateResponse, error)
    Stream(ctx context.Context, request GenerateRequest) (<-chan Token, error)
}
```

Initial implementation:

```text
LLMProvider
    └── OpenRouterProvider
```

Future:

```text
LLMProvider
├── OpenRouterProvider
├── OpenAIProvider
├── GeminiProvider
├── AnthropicProvider
└── LocalProvider
```

Configuration example:

```text
LLM_PROVIDER=openrouter
LLM_MODEL=...
OPENROUTER_API_KEY=...
```

Never commit provider credentials.

## 14. Free LLM Strategy

OpenRouter free models are appropriate for:

- development;
- prototyping;
- retrieval testing;
- prompt development;
- architecture validation;
- evaluation framework development.

They must not be treated as a production SLA.

The production architecture must allow model replacement without application changes.

Recommended progression:

```text
Free model
  ↓
Build retrieval
  ↓
Build grounding/citation
  ↓
Build evaluation
  ↓
Run representative test corpus
  ↓
Identify weaknesses
  ↓
Compare production candidates
```

Model selection must be evidence-driven.

## 15. Chat Request Flow

```text
User
 ↓
POST /chat
 ↓
Authentication
 ↓
Knowledge Base Authorization
 ↓
Conversation Context
 ↓
Query Processing
 ↓
Retriever
 ↓
Candidate Chunks
 ↓
Reranking / Filtering
 ↓
Evidence Context
 ↓
Prompt Assembly
 ↓
LLM Provider
 ↓
Response Validation
 ↓
Citation Mapping
 ↓
Assistant Response
```

## 16. Grounded Answer Policy

The generation layer must instruct the model to:

1. answer using retrieved knowledge;
2. distinguish source statements from inference;
3. avoid unsupported claims;
4. identify insufficient evidence;
5. preserve uncertainty;
6. cite relevant source material;
7. never fabricate citations;
8. never claim retrieval establishes truth;
9. not silently introduce external knowledge.

## 17. Insufficient Evidence

Support an explicit state:

```text
INSUFFICIENT_EVIDENCE
```

Example:

> “The knowledge base does not currently provide sufficient evidence to answer this question reliably.”

Possible response metadata:

```json
{
  "grounded": false,
  "confidence": "insufficient_evidence",
  "citations": []
}
```

The exact API schema can evolve.

## 18. Conversation Memory

MVP memory is limited to the current conversation.

Do not implement long-term user memory initially.

Context should be bounded:

```text
Recent messages
+
Relevant retrieved knowledge
```

Never blindly send an unlimited conversation history.

## 19. Context Budget

Context assembly must consider:

- chunk count;
- chunk size;
- relevance;
- duplication;
- document diversity;
- token budget;
- model context limit.

Example:

```text
Query
 ↓
50 candidates
 ↓
Deduplicate
 ↓
Rerank
 ↓
10 relevant chunks
 ↓
Context budget
 ↓
LLM
```

The actual values must be established by evaluation.

## 20. Knowledge Ingestion

First source:

```text
Markdown
```

Pipeline:

```text
Markdown
  ↓
Parser
  ↓
Document Structure
  ↓
Sections
  ↓
Chunks
  ↓
Metadata
  ↓
PostgreSQL
```

Future adapters:

```text
Markdown
PDF
HTML
DOCX
JSON
API
```

The ingestion layer must be independent from retrieval and chat.

## 21. Corpus Versioning

A published knowledge base must identify:

```text
Knowledge Base
Version
Document Versions
Content Hashes
```

This allows the system to answer:

> Which knowledge version generated this answer?

Content changes should produce a new version rather than silently mutating a published corpus.

## 22. Content Update Flow

```text
Source Repository
      ↓
Ingestion
      ↓
Validation
      ↓
New Version
      ↓
Chunk Generation
      ↓
Indexing
      ↓
Evaluation
      ↓
Publish
```

A new version should not automatically become active without validation.

## 23. API Design

Initial style:

```text
REST / JSON
```

Candidate endpoints:

```text
GET    /health
GET    /ready

GET    /knowledge-bases
GET    /knowledge-bases/:id

POST   /conversations
GET    /conversations/:id
GET    /conversations/:id/messages

POST   /chat
POST   /chat/stream

POST   /search

POST   /admin/knowledge-bases
POST   /admin/documents
POST   /admin/ingest

POST   /admin/evaluations
GET    /admin/evaluations
```

Exact endpoint naming can be refined during implementation.

## 24. Streaming

Use Server-Sent Events initially:

```text
POST /chat/stream

LLM
 ↓
token stream
 ↓
Go backend
 ↓
SSE
 ↓
browser
```

## 25. Authentication and Authorization

MVP must support API authentication.

Possible mechanisms:

- API keys;
- JWT;
- session authentication.

Authorization must be independent of the LLM layer.

Authorization applies to:

```text
User
 ↓
Knowledge Base
 ↓
Document
 ↓
Retrieval
```

Critical rule:

> **Retrieval relevance is not authorization.**

Unauthorized chunks must never enter the LLM context.

## 26. Multi-Knowledge-Base Isolation

Support:

```text
Knowledge Base A
Knowledge Base B
Knowledge Base C
```

Every retrieval operation must carry explicit knowledge-base scope.

No cross-KB leakage is acceptable.

## 27. Security Requirements

Minimum:

- HTTPS in production;
- secrets outside source code;
- provider API key protection;
- authentication;
- authorization;
- rate limiting;
- input validation;
- request size limits;
- prompt-injection awareness;
- retrieval authorization;
- secure logging;
- sensitive-data redaction;
- database least privilege;
- dependency updates;
- administrative auditability.

## 28. Prompt Injection

Retrieved content is **data**, not system instruction.

Prompt layers must be clearly separated:

```text
System Instructions
User Request
Retrieved Knowledge
Conversation Context
```

Retrieved content must not override system policy.

## 29. Output Validation

Validate:

- response structure;
- citation references;
- referenced chunk IDs;
- provider errors;
- empty responses;
- malformed structured output.

The system must not expose fabricated citation identifiers.

## 30. Rate Limiting

Rate limiting should operate at an appropriate combination of:

```text
IP
Session
API Credential
Knowledge Base
```

depending on deployment.

Rate limiting is both a reliability and cost-control mechanism.

## 31. Reliability

Handle explicitly:

- provider timeout;
- provider rate limit;
- provider unavailable;
- malformed provider response;
- database timeout;
- retrieval failure;
- empty retrieval;
- context overflow;
- client disconnect.

Never silently fabricate an answer after infrastructure failure.

## 32. Observability

Minimum structured events:

```text
request_started
retrieval_started
retrieval_completed
llm_started
llm_completed
citation_generated
chat_completed
provider_error
retrieval_error
```

Useful metrics:

```text
request latency
retrieval latency
LLM latency
time-to-first-token
total response time
retrieval result count
token usage
estimated cost
provider error rate
empty retrieval rate
```

## 33. Cost Tracking

Where available, record:

```text
provider
model
input tokens
output tokens
total tokens
estimated cost
```

Support analysis such as:

```text
Cost per conversation
Cost per answer
Cost per knowledge base
Cost per useful answer
```

Do not equate lower token price with lower TCO.

## 34. Evaluation Architecture

Evaluation is a first-class capability.

Evaluation records should support:

```text
Question
Expected Relevant Sections
Expected Evidence
Expected Answer Characteristics
Forbidden Claims
Evaluation Result
Model
Retrieval Strategy
Knowledge Version
```

## 35. Retrieval Evaluation

Measure:

- recall of relevant chunks;
- precision of retrieved chunks;
- ranking quality;
- irrelevant-context rate;
- citation coverage.

Example:

```text
Question
 ↓
Expected source sections
 ↓
Retriever
 ↓
Retrieved sections
 ↓
Compare
```

## 36. Answer Evaluation

Measure:

- groundedness;
- factual consistency with corpus;
- citation correctness;
- completeness;
- unsupported claims;
- insufficient-evidence behavior;
- usefulness;
- robustness.

Avoid meaningless false precision such as “93.7%” unless the methodology supports that interpretation.

## 37. Evaluation Matrix

| Dimension | Question |
|---|---|
| Retrieval | Did we retrieve the right evidence? |
| Grounding | Is the answer supported by retrieved evidence? |
| Citation | Do citations actually support claims? |
| Completeness | Did the answer omit important evidence? |
| Hallucination | Did it introduce unsupported claims? |
| Robustness | Does it survive adversarial phrasing? |
| Regression | Did changes make previous cases worse? |
| Latency | Is response time acceptable? |
| Cost | Is the result economically acceptable? |

## 38. Model Selection

Model selection is separate from architecture.

Configurable attributes:

```text
provider
model
temperature / equivalent
max output
context limits
```

Production comparison should consider:

```text
Quality
Grounding
Latency
Reliability
Cost
Context capability
Safety
Operational constraints
```

## 39. Generic Knowledge Adapter

First adapter:

```text
MarkdownKnowledgeSource
```

Conceptual interface:

```go
type KnowledgeSource interface {
    Load(ctx context.Context) ([]Document, error)
}
```

Future implementations:

```text
GitKnowledgeSource
FilesystemKnowledgeSource
S3KnowledgeSource
DatabaseKnowledgeSource
HTTPKnowledgeSource
```

## 40. Configuration

Support:

```text
APP_ENV
HTTP_PORT

DATABASE_URL

LLM_PROVIDER
LLM_MODEL
LLM_API_KEY

RETRIEVAL_PROVIDER

KNOWLEDGE_BASE

RATE_LIMIT

LOG_LEVEL
```

Secrets must use environment variables or a production secret manager.

## 41. Deployment

Initial production target:

```text
Internet
  ↓
Reverse Proxy
  ↓
Go Application
  ↓
PostgreSQL
  ↓
LLM Provider
```

Docker support is required.

Kubernetes is not required for MVP.

## 42. Testing Strategy

### Unit

- domain;
- chunking;
- ranking;
- prompt construction;
- citation mapping;
- policy enforcement.

### Integration

- PostgreSQL;
- retrieval;
- LLM provider;
- HTTP API.

### Retrieval

Known questions must retrieve expected sections.

### Evaluation

Known questions must produce acceptable grounded answers.

### Security

Test:

- unauthorized KB access;
- prompt injection;
- citation manipulation;
- oversized input;
- rate limits.

## 43. MVP Acceptance Criteria

### Knowledge

- [ ] Markdown corpus can be ingested.
- [ ] Document hierarchy is retained.
- [ ] Chunks retain provenance.
- [ ] Knowledge version is identifiable.
- [ ] Content changes produce a new version.

### Retrieval

- [ ] PostgreSQL FTS works.
- [ ] Retriever interface exists.
- [ ] Metadata filtering works.
- [ ] Retrieval results expose provenance.
- [ ] Unauthorized content cannot enter context.

### LLM

- [ ] OpenRouter integration works.
- [ ] Model is configurable.
- [ ] Provider abstraction exists.
- [ ] Streaming works.
- [ ] Provider failures are handled.

### Chat

- [ ] Conversations work.
- [ ] Context is bounded.
- [ ] Answers are grounded.
- [ ] Citations are returned.
- [ ] Insufficient evidence can be returned.

### Operations

- [ ] Structured logging exists.
- [ ] Request IDs exist.
- [ ] Basic metrics exist.
- [ ] Token usage is tracked.
- [ ] Rate limiting exists.

### Evaluation

- [ ] Evaluation dataset exists.
- [ ] Retrieval quality can be measured.
- [ ] Citation correctness can be tested.
- [ ] Regression tests exist.

## 44. Non-Functional Requirements

### Performance

Do not invent final SLOs before measuring the actual workload.

The system should:

- provide responsive retrieval;
- begin streaming promptly when the provider supports it;
- keep retrieval latency materially below LLM generation latency where practical.

### Scalability

The application should support horizontal scaling:

```text
Load Balancer
      │
 ┌────┼────┐
 ▼    ▼    ▼
Go   Go   Go
 │    │    │
 └────┼────┘
      ▼
 PostgreSQL
```

Application instances should remain stateless.

## 45. Initial Architectural Decisions

| Decision | Choice |
|---|---|
| Language | Go |
| Architecture | Modular monolith |
| API | REST + SSE |
| Primary DB | PostgreSQL |
| Initial retrieval | PostgreSQL FTS |
| Vector search | Optional pgvector |
| Dedicated vector DB | Not initially |
| LLM gateway | OpenRouter |
| LLM abstraction | Required |
| Knowledge source | Markdown first |
| Frontend | Separate project |
| Deployment | Container-friendly |
| Microservices | No |
| Agent | No |
| Web browsing | No |
| Long-term memory | No |

## 46. Evolution Path

```text
MVP
 │
 ├── Go
 ├── PostgreSQL
 ├── FTS
 └── OpenRouter
       ↓
Evaluation
       ↓
Hybrid Retrieval
       ├── FTS
       └── pgvector
       ↓
Production
       ├── stronger model
       ├── caching if justified
       ├── observability
       └── scaling
       ↓
Optional Specialized Infrastructure
       ├── Qdrant
       └── OpenSearch
```

## 47. Architectural Guardrails

Do not drift into these patterns without explicit justification:

### LLM-as-Database

The LLM is not the knowledge store.

### RAG-as-Silver-Bullet

Retrieval does not automatically eliminate hallucination.

### Vector-DB-by-Default

Semantic retrieval must be justified by evaluation.

### Model-as-Application

Changing models must not require application redesign.

### Citation-as-Truth

Citation establishes provenance, not correctness.

### Human-Approval-as-Security

If future consequential actions are introduced, human approval must sit within a real authorization/control architecture.

### OpenRouter Lock-In

OpenRouter remains a provider adapter.

## 48. Relationship with the Book Repository

The book repository remains responsible for:

- content;
- chapters;
- evidence;
- editorial standards;
- navigation;
- GitHub Pages presentation.

Knowledge AI Chat Engine is responsible for:

- ingestion;
- indexing;
- retrieval;
- LLM interaction;
- conversation;
- grounding;
- citations;
- evaluation.

Dependency:

```text
Book Repository
      │
      │ published knowledge
      ▼
Knowledge Ingestion
      │
      ▼
Knowledge AI Chat Engine
      │
      ▼
Book Chat UI
```

The book must not depend on backend implementation details.

## 49. Future Multi-Book Architecture

```text
Knowledge AI Chat Engine
│
├── AI Architecture Advisor
├── ERP Architecture
├── Government Finance
├── Technical Handbook
└── Organization SOP
```

Each knowledge base may eventually have:

- documents;
- versions;
- retrieval configuration;
- access policy;
- system instructions;
- evaluation dataset;
- preferred model;
- citation policy.

## 50. Frontend Relationship

The first frontend can remain on GitHub Pages:

```text
GitHub Pages
      ↓
Book UI
      ↓
Chat UI
      ↓
Knowledge AI Chat Engine API
```

GitHub Pages is sufficient for the static frontend.

The LLM API must remain server-side because API credentials, retrieval authorization, rate limiting, and provider abstraction must not be exposed to the browser.

## 51. AI Behavior Contract

Generic contract:

> Answer questions using the configured knowledge base, identify relevant evidence, distinguish source-supported statements from inference, cite the underlying material, and explicitly state when available knowledge is insufficient.

The first book may additionally configure epistemic categories such as:

```text
Fact
Assumption
Inference
Technical Judgment
Recommendation
Unknown
```

These must remain configuration/policy, not hard-coded engine concepts.

## 52. Implementation Sequence

### Phase 0 — Architecture

- repository initialization;
- ADR baseline;
- Go project;
- configuration;
- Docker;
- PostgreSQL;
- migration framework;
- health endpoints.

### Phase 1 — Knowledge

- knowledge base;
- document;
- document version;
- section;
- chunk;
- source;
- Markdown ingestion.

### Phase 2 — Retrieval

- Retriever interface;
- PostgreSQL FTS;
- metadata filtering;
- ranking;
- retrieval diagnostics.

### Phase 3 — LLM

- LLMProvider interface;
- OpenRouter adapter;
- model configuration;
- error handling;
- streaming.

### Phase 4 — Chat

- conversation;
- messages;
- context assembly;
- grounded prompt;
- citation mapping;
- insufficient-evidence response.

### Phase 5 — Security

- authentication;
- authorization;
- KB isolation;
- rate limiting;
- prompt-injection defenses.

### Phase 6 — Evaluation

- evaluation dataset;
- retrieval tests;
- answer tests;
- citation tests;
- regression suite.

### Phase 7 — pgvector

Only after baseline retrieval is measured.

- embedding provider abstraction;
- embedding generation;
- pgvector;
- hybrid retrieval;
- evaluation comparison.

### Phase 8 — Production Hardening

- metrics;
- tracing;
- cost monitoring;
- resilience;
- backups;
- deployment;
- security review;
- load testing.

## 53. First Vertical Slice

Do **not** begin by implementing full RAG.

First working path:

```text
Markdown
   ↓
PostgreSQL
   ↓
FTS Retrieval
   ↓
OpenRouter
   ↓
Grounded Answer
   ↓
Citation
   ↓
HTTP API
```

One complete vertical slice is more valuable than many incomplete abstractions.

## 54. Definition of Success

The system succeeds when a frontend can ask:

> “What does this knowledge base say about X?”

and reliably receive:

```text
Useful answer
+
Relevant evidence
+
Traceable sources
+
Clear epistemic boundary
+
No fabricated citation
+
Explicit uncertainty when evidence is insufficient
```

Ultimate success criterion:

> **The system makes knowledge easier to retrieve and reason about without weakening the evidentiary discipline of the underlying knowledge.**

## 55. Guiding Principle

```text
Requirement
    ↓
Architecture
    ↓
Evidence
    ↓
Implementation
    ↓
Evaluation
    ↓
Technical Position
```

Do not introduce technology merely because it is common in AI systems.

Do not optimize before measuring.

Do not treat model capability as system capability.

Do not treat retrieval as truth.

Do not treat citations as proof.

Do not treat free-model availability as production readiness.

Do not let the AI assistant become an opaque authority over the knowledge base.
