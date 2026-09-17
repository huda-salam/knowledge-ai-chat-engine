package conversation

import "time"

type Role string

const (
	RoleUser      Role = "user"
	RoleAssistant Role = "assistant"
	RoleSystem    Role = "system"
)

type Conversation struct {
	ID                  string
	KnowledgeBaseID     string
	UserID              *string
	AnonymousSessionID  *string
	Title               string
	CreatedAt           time.Time
	UpdatedAt           time.Time
}

type Message struct {
	ID             string
	ConversationID string
	Role           Role
	Content        string
	Model          string
	Provider       string
	CreatedAt      time.Time
	LatencyMS      int64
	InputTokens    int
	OutputTokens   int
	TotalTokens    int
}
