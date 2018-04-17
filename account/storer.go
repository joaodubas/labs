package account

// Accounter define operations to handling persistence of accounts.
type Accounter interface {
	// All get all accounts available.
	All() ([]*Account, error)
	// Get specific account by its id.
	Get(id int) (*Account, error)
	// Insert this account.
	Insert(a *Account) (*Account, error)
	// Update this account.
	Update(a *Account) (*Account, error)
	// Balance aggregate deposists and withdraws made in an account for a given period.
	Balance(a *Account, p Period) (int, error)
	// Withdraw summarizes movements made in an account for a given period.
	Withdraw(a *Account, p Period) (int, error)
	// Deposit summarizes movements made in an account for a given period.
	Deposit(a *Account, p Period) (int, error)
	// Entries lists all movements made in an account for a given period.
	Entries(a *Account, p Period) ([]*Entry, error)
}

// Entrier define operations to handling persistence of entries.
type Entrier interface {
	// All get all entries available.
	All() ([]*Entry, error)
	// Get specific entry by its id.
	Get(id int) (*Entry, error)
	// Insert this entry.
	Insert(e *Entry) (*Entry, error)
	// Update this entry.
	Update(e *Entry) (*Entry, error)
	// ForAccount list all entries for a given account and period.
	ForAccount(a *Account, p Period) ([]*Entry, error)
}
