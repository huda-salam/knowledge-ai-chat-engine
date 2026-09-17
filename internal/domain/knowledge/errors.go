package knowledge

import "errors"

var (
	ErrNotFound       = errors.New("knowledge resource not found")
	ErrAlreadyExists  = errors.New("knowledge resource already exists")
	ErrInvalidVersion = errors.New("invalid knowledge version")
)
