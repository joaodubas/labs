package main

import "time"

// Entry indicate movement between accounts.
type Entry struct {
	Credit     Account
	Debit      Account
	Created    time.Time
	Updated    time.Time
	Effective  time.Time
	Quantity   int
	UnitValue  int
	TotalValue int
	MetaInfo   map[string]string
}
