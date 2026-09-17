package knowledge

import "context"

type Repository interface {
	GetByID(ctx context.Context, id string) (KnowledgeBase, error)
	GetBySlug(ctx context.Context, slug string) (KnowledgeBase, error)
	List(ctx context.Context) ([]KnowledgeBase, error)
	Create(ctx context.Context, knowledgeBase KnowledgeBase) (KnowledgeBase, error)
}

type DocumentRepository interface {
	GetByID(ctx context.Context, id string) (Document, error)
	ListByKnowledgeBase(ctx context.Context, knowledgeBaseID string) ([]Document, error)
	Create(ctx context.Context, document Document) (Document, error)
}
