package conversation

import "context"

type Repository interface {
	GetByID(ctx context.Context, id string) (Conversation, error)
	Create(ctx context.Context, conversation Conversation) (Conversation, error)
}

type MessageRepository interface {
	ListByConversation(ctx context.Context, conversationID string, limit int) ([]Message, error)
	Create(ctx context.Context, message Message) (Message, error)
}
