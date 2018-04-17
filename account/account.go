package account // import "github.com/joaodubas/labs/account"

import "time"

// Account represent an aggregation of entries credited/debited.
type Account struct {
	ID      int
	Name    string
	Type    accountType
	Created time.Time
	Updated time.Time
}
