package knowledge

import "time"

type KnowledgeBase struct {
	ID          string
	Name        string
	Slug        string
	Description string
	Status      string
	Version     int
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type Document struct {
	ID              string
	KnowledgeBaseID string
	ExternalID      string
	Title           string
	DocumentType    string
	Status          string
	SourceURI       string
	SourceType      string
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type DocumentVersion struct {
	ID         string
	DocumentID string
	Version    int
	ContentHash string
	Status     string
	CreatedAt  time.Time
	PublishedAt *time.Time
}

type Section struct {
	ID                string
	DocumentVersionID string
	ParentSectionID   *string
	Heading           string
	SectionPath       string
	Ordinal           int
	Content           string
}

type Chunk struct {
	ID                string
	KnowledgeBaseID   string
	DocumentID        string
	DocumentVersionID string
	SectionID         string
	Content           string
	Ordinal           int
	Metadata          map[string]any
}
