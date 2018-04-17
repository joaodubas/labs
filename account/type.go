package account

import "errors"

// ErrAccountTypeInvalid show this is an invalid account type.
var ErrAccountTypeInvalid = errors.New("invalid account type")

// accountType enumerate possible types of an account.
type accountType int

const (
	// AccountTypeSystem indicate that a given account is private, and managed by system.
	AccountTypeSystem accountType = iota
	// AccountTypeUser indicate that a given account is public, and managed by user.
	AccountTypeUser
)

// String representation for this account type.
func (a accountType) String() string {
	switch a {
	case AccountTypeSystem:
		return "System Account"
	case AccountTypeUser:
		return "User Account"
	default:
		return "--"
	}
}

// Valid ensure this account type is one of the defineds.
func (a accountType) Valid() error {
	for _, v := range []accountType{AccountTypeSystem, AccountTypeUser} {
		if a == v {
			return nil
		}
	}
	return ErrAccountTypeInvalid
}
