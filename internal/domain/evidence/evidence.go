package evidence

// Item represents source material that was actually retrieved and may be used
// to ground a generated answer. Citation references must resolve to these items.
type Item struct {
	ChunkID           string
	DocumentID        string
	DocumentVersionID string
	SectionID         string
	Content           string
	Score             float64
}

type Set struct {
	Items []Item
}

type Status string

const (
	StatusSufficient   Status = "sufficient"
	StatusInsufficient Status = "insufficient_evidence"
)
