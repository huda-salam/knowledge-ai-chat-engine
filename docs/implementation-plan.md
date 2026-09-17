# Implementation Plan

## Goal

Build the Knowledge AI Chat Engine as a production-capable Go modular monolith centered on grounded knowledge retrieval, evidence handling, conversational generation, and traceable citations.

## KISS and SOLID rules

- Prefer the standard library and PostgreSQL before adding infrastructure or framework dependencies.
- One responsibility per package/component; avoid god services and god repositories.
- Keep interfaces small and owned by the consumer. Introduce an interface only where it creates a meaningful substitution or test boundary.
- Depend on domain/application contracts, not concrete infrastructure.
- Prefer composition over inheritance-style abstractions.
- Keep data models simple; do not build a generic metadata framework until a real requirement appears.
- Do not create abstractions for hypothetical providers or databases beyond the contracts already required by the PRD.
- Favor readable SQL and explicit application flow over clever ORM behavior.
- One complete vertical slice is more valuable than many incomplete abstractions.

## Architecture invariants

- Domain code must not depend on HTTP, PostgreSQL, OpenRouter, or embedding vendors.
- Retrieval is behind a `Retriever` interface.
- LLM access is behind an `LLMProvider` interface.
- Retrieved material becomes explicit evidence before prompt construction.
- Published knowledge versions are immutable and reproducible.
- Citations may only reference material actually retrieved for the answer.
- MVP starts with PostgreSQL FTS; pgvector is introduced only when evaluation justifies it.
- No Redis, broker, dedicated vector database, Kubernetes, agents, or microservices without measured requirements.

## Delivery sequence

1. Project/bootstrap: Go module, HTTP server, configuration, structured logging, request IDs, health/readiness.
2. Persistence: PostgreSQL migrations and repositories for knowledge, versions, sections, chunks, conversations, messages, and citations.
3. Knowledge ingestion: Markdown parser, structural section extraction, deterministic chunking, metadata, content hashing, validation, and publication workflow.
4. Retrieval: PostgreSQL full-text search, metadata filters, ranking, top-K, provenance-rich retrieval results, and `/search`.
5. Evidence/context: evidence set construction, deduplication, diversity controls, token budgeting, and prompt context assembly.
6. LLM: provider abstraction and OpenRouter adapter; model/provider configuration stays outside domain code.
7. Chat: conversation context, grounded generation, insufficient-evidence behavior, citation validation, persistence, and `/chat`.
8. Streaming: SSE `/chat/stream` with explicit lifecycle/token/evidence/citation events.
9. Security: authentication, authorization, knowledge-base isolation, rate limits, request/body limits, secret handling, prompt-injection defenses, output validation, and audit events.
10. Evaluation: retrieval recall/relevance, groundedness, citation correctness, insufficient-evidence behavior, latency, token/cost tracking, and regression cases.
11. Optimization: use measured evaluation and operational data to decide on pgvector, reranking, caching, queues, or dedicated retrieval infrastructure.

## First end-to-end milestone

Markdown source → document version → sections/chunks → PostgreSQL FTS → evidence → OpenRouter → validated grounded answer → citation metadata → REST API.

## Security baseline

Treat user input and retrieved documents as untrusted content. Keep application/system instructions structurally separate from retrieved text. Never expose provider credentials to clients or logs. Validate citation references server-side rather than trusting LLM-produced identifiers.

## Testing strategy

- Unit tests for domain rules, chunking, retrieval query construction, context budgeting, and citation validation.
- Repository integration tests against PostgreSQL.
- Provider contract tests using a fake LLM provider.
- HTTP integration tests for authorization, error handling, search, chat, and streaming.
- Evaluation regression suite with a fixed representative corpus.
- Security tests for tenant/knowledge-base isolation, injection attempts, malformed input, rate limits, and secret leakage.
