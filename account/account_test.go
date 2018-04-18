package account_test

import (
	"testing"

	"github.com/joaodubas/labs/account"
)

func TestAccountStore(t *testing.T) {
	s := newAccountStore()

	t.Run("Test insert", func(t *testing.T) {
		t.Run("Success insert without ID", func(t *testing.T) {
			a := account.NewUserAccount("Test Account", s)
			if p, err := s.Insert(a); err != nil {
				t.Errorf("failed to insert account: %v", err)
			} else if p.Name != a.Name {
				t.Errorf("failed to persist same account, expected name %s, got name %s", a.Name, p.Name)
			}
		})

		t.Run("Success insert with wrong ID", func(t *testing.T) {
			id := len(s.accounts) + 1
			a := account.NewUserAccount("Wrong ID test", s)
			a.ID = id
			if p, err := s.Insert(a); err != nil {
				t.Errorf("failed to insert account: %v", err)
			} else if p.ID == id {
				t.Errorf("failed to fix id, expected %d, got %d", p.ID, id)
			}
		})
	})

	t.Run("Test update", func(t *testing.T) {
		insertAccount := func() *account.Account {
			a, err := account.NewUserAccount("Insert test", s).Insert()
			if err != nil {
				t.Fatalf("failed to insert account: %v", err)
			}
			return a
		}

		t.Run("Success update", func(t *testing.T) {
			a := insertAccount()
			oName, oUpdated := a.Name, a.Updated
			nName := "Update test"
			a.Name = nName
			if a, err := s.Update(a); err != nil {
				t.Errorf("failed to update account: %v", err)
			} else if a.Name == oName {
				t.Errorf("failed to update name, expected %s, got %s", nName, oName)
			} else if a.Updated == oUpdated {
				t.Error("failed to update `updated` prop")
			}
		})

		t.Run("Fail update", func(t *testing.T) {
			a := insertAccount()
			nID := len(s.accounts) + 1
			a.ID = nID
			if _, err := s.Update(a); err == nil {
				t.Errorf("success update account with id %d", nID)
			}
		})
	})
}
