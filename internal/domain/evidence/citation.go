package evidence

import "context"

type Citation struct {
	DocumentID        string
	DocumentVersionID string
	SectionID         string
	ChunkID           string
	Ordinal           int
}

// CitationValidator is intentionally independent of the LLM provider.
// Implementations must validate every cited chunk against the evidence used
// for the current answer before a citation is persisted or returned.
type CitationValidator interface {
	Validate(ctx context.Context, citations []Citation, evidence Set) error
}
