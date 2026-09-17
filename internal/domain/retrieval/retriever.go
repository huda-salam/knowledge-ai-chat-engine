package retrieval

import "context"

type Query struct {
	Text            string
	KnowledgeBaseID string
	Limit           int
}

type Result struct {
	ChunkID           string
	DocumentID        string
	DocumentVersionID string
	SectionID         string
	Content           string
	Score             float64
}

type Retriever interface {
	Search(ctx context.Context, query Query) ([]Result, error)
}
