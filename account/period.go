package account

import (
	"fmt"
	"time"
)

// Period represent a time period between two dates.
type Period struct {
	start time.Time
	end   time.Time
}

func (t Period) String() string {
	return fmt.Sprintf(
		"Period <%s - %s>",
		t.start.Format(time.RFC3339),
		t.end.Format(time.RFC3339),
	)
}
