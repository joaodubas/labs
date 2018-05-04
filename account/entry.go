package account

import (
	"fmt"
	"time"
)

// Entry indicate movement between accounts.
type Entry struct {
	ID         int
	Credit     *Account
	Debit      *Account
	Created    time.Time
	Updated    time.Time
	Effective  time.Time
	Quantity   int
	UnitValue  int
	TotalValue int
	MetaInfo   map[string]string
	storer     Entrier
}

// NewEntry creates an entry, indicanting finantial movement between credited and debited accounts.
// An entry must have an effective date where it was done, the quantity, unitary, and total value,
// and additional meta information, from the client system.
// Return an entry pointer and an error.
func NewEntry(credit, debit *Account, effective time.Time, qty, uValue, tValue int, meta map[string]string, storer Entrier) (*Entry, error) {
	if qty*uValue != tValue {
		return nil, fmt.Errorf("new entry: total value (%d) do not match unit (%d) * quantity (%d)", tValue, uValue, qty)
	}
	entry := Entry{
		Credit:     credit,
		Debit:      debit,
		Effective:  effective,
		Quantity:   qty,
		UnitValue:  uValue,
		TotalValue: tValue,
		MetaInfo:   meta,
		storer:     storer,
	}
	return &entry, nil
}

func (e *Entry) String() string {
	return fmt.Sprintf(
		"Entry for %v with value %d (quantity %d and unitary value %d)",
		e.Effective,
		e.TotalValue,
		e.Quantity,
		e.UnitValue,
	)
}

// All fetch all entries available.
func (e *Entry) All() ([]*Entry, error) {
	return e.storer.All()
}

// Get retrieve an entry based in its ID.
func (e *Entry) Get(id int) (*Entry, error) {
	return e.storer.Get(id)
}

// Insert a new entry in storer.
func (e *Entry) Insert() (*Entry, error) {
	return e.storer.Insert(e)
}

// Update an entry in storer.
func (e *Entry) Update() (*Entry, error) {
	return e.storer.Update(e)
}

// ForAccount fetches entries for a given account and period.
func (e *Entry) ForAccount(a *Account, p Period) ([]*Entry, error) {
	return e.storer.ForAccount(a, p)
}
