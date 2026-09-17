package generation

import "context"

type Message struct {
	Role    string
	Content string
}

type GenerateRequest struct {
	Messages    []Message
	Model       string
	Temperature float64
}

type Usage struct {
	InputTokens  int
	OutputTokens int
	TotalTokens  int
}

type GenerateResponse struct {
	Content string
	Model   string
	Usage   Usage
}

type Token struct {
	Content string
}

type LLMProvider interface {
	Generate(ctx context.Context, request GenerateRequest) (GenerateResponse, error)
	Stream(ctx context.Context, request GenerateRequest) (<-chan Token, error)
}
