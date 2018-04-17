package main

import (
	"time"
)

// AccountType enumerate possible types of an account.
type AccountType int

const (
	// AccountTypeSystem indicate that a given account is private, and managed by system.
	AccountTypeSystem AccountType = iota
	// AccountTypeUser indicate that a given account is public, and managed by user.
	AccountTypeUser
)

// Account represent an aggregation of entries credited/debited.
type Account struct {
	ID      int
	Name    string
	Type    AccountType
	Created time.Time
	Updated time.Time
}
