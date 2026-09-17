package retrieval

import "errors"

var (
	ErrInvalidQuery = errors.New("invalid retrieval query")
	ErrNoResults    = errors.New("no retrieval results")
)
