package account // import "github.com/joaodubas/labs/account"

import "time"

// Account represent an aggregation of entries credited/debited.
type Account struct {
	ID      int
	Name    string
	Type    accountType
	Created time.Time
	Updated time.Time
	store   Accounter
}

// All fetch accounts from store.
func (a Account) All() ([]*Account, error) {
	return a.store.All()
}

// Get specific account from store.
func (a *Account) Get() (*Account, error) {
	return a.store.Get(a.ID)
}

// Insert this account in store
func (a *Account) Insert() (*Account, error) {
	return a.store.Insert(a)
}

// Update this account in store.
func (a *Account) Update() (*Account, error) {
	return a.store.Update(a)
}

// Balance summarizes withdraws/deposits for this account in a given period.
func (a *Account) Balance(p Period) (int, error) {
	return a.store.Balance(a, p)
}

// Withdraw summarizes values debited for this account in a given period.
func (a *Account) Withdraw(p Period) (int, error) {
	return a.store.Withdraw(a, p)
}

// Deposit summarizes values credited for this account in a given period.
func (a *Account) Deposit(p Period) (int, error) {
	return a.store.Deposit(a, p)
}

// Entries added for this account in a given period.
func (a *Account) Entries(p Period) ([]*Entry, error) {
	return a.store.Entries(a, p)
}
