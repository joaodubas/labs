package account_test

import (
	"fmt"
	"sync"
	"time"

	"github.com/joaodubas/labs/account"
)

type accountStore struct {
	accounts []*account.Account
	mux      sync.Mutex
}

func newAccountStore() *accountStore {
	return &accountStore{
		accounts: make([]*account.Account, 10),
		mux:      sync.Mutex{},
	}
}

func (s *accountStore) All() ([]*account.Account, error) {
	return s.accounts[:], nil
}

func (s *accountStore) Get(id int) (*account.Account, error) {
	if id >= len(s.accounts) {
		return nil, fmt.Errorf("Get: %d id unavailable", id)
	}
	return s.accounts[id], nil
}

func (s *accountStore) Insert(a *account.Account) (*account.Account, error) {
	s.mux.Lock()
	a.ID = len(s.accounts)
	a.Created = time.Now()
	a.Updated = a.Created
	s.accounts = append(s.accounts, a)
	s.mux.Unlock()
	return a, nil
}

func (s *accountStore) Update(a *account.Account) (*account.Account, error) {
	if a.ID >= len(s.accounts) {
		return a, fmt.Errorf("Update: %d id is can't be updated", a.ID)
	}
	s.mux.Lock()
	a.Updated = time.Now()
	s.accounts[a.ID] = a
	s.mux.Unlock()
	return a, nil
}

func (s *accountStore) Balance(a *account.Account, p account.Period) (int, error) {
	return 0, nil
}

func (s *accountStore) Withdraw(a *account.Account, p account.Period) (int, error) {
	return 0, nil
}

func (s *accountStore) Deposit(a *account.Account, p account.Period) (int, error) {
	return 0, nil
}

func (s *accountStore) Entries(a *account.Account, p account.Period) ([]*account.Entry, error) {
	return nil, nil
}
