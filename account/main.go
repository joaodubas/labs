package main // import "github.com/joaodubas/labs/account"

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log"

	"github.com/cockroachdb/cockroach-go/crdb"
	_ "github.com/lib/pq"
)

func main() {
	db := conn()
	defer db.Close()

	// NOTE: basic usage
	create(db)
	insert(db)
	fetch(db)

	// NOTE: transaction with retry logic
	execTransfer(db)
	fetch(db)
}

func conn() *sql.DB {
	log.Println("conn: access database")

	user := "maxroach"
	userCert := fmt.Sprintf("/certs/client.%s.crt", user)
	userKey := fmt.Sprintf("/certs/client.%s.key", user)
	rootCert := "/certs/ca.crt"
	dataSource := fmt.Sprintf(
		"postgresql://%s@proxy:26257/bank?sslrootcert=%s&sslcert=%s&sslkey=%s&sslmode=verify-full",
		user,
		rootCert,
		userCert,
		userKey,
	)

	db, err := sql.Open("postgres", dataSource)
	if err != nil {
		log.Fatal("conn: error access database: ", err)
	}

	if err := db.Ping(); err != nil {
		log.Fatal("conn: error access database: ", err)
	}
	return db
}

func create(db *sql.DB) {
	log.Println("create: `accounts` table")

	s := `CREATE TABLE IF NOT EXISTS accounts (
		id      INT PRIMARY KEY,
		balance INT
	)`
	if _, err := db.Exec(s); err != nil {
		log.Fatal("create: error in `accounts` table: ", err)
	}
}

func insert(db *sql.DB) {
	log.Println("insert: rows in `accounts` table")

	s := `UPSERT INTO accounts(id, balance) VALUES
	(1, 1000),
	(2, 250)`
	if _, err := db.Exec(s); err != nil {
		log.Fatal("insert: error in `accounts` table: ", err)
	}
}

func fetch(db *sql.DB) {
	log.Println("fetch: balance available in `accounts` table")

	s := `SELECT id, balance FROM accounts`
	rows, err := db.Query(s)
	if err != nil {
		log.Fatal("fetch: error in `accounts` table: ", err)
	}
	defer rows.Close()

	log.Println("fetch: initial balances")
	for rows.Next() {
		var id, balance int
		if err := rows.Scan(&id, &balance); err != nil {
			log.Fatal("fetch: error scanning value in `accounts` table: ", err)
		}
		log.Printf("fetch: id #%d | balance $ %d\n", id, balance)
	}
}

func execTransfer(db *sql.DB) {
	log.Println("exec tranfer: execute transfer between accounts")

	err := crdb.ExecuteTx(context.Background(), db, nil, func(tx *sql.Tx) error {
		return transferFunds(
			tx,
			1,   /* from account */
			2,   /* to account */
			100, /* amount */
		)
	})

	if err != nil {
		log.Fatal("exec transfer: error transfering funds: ", err)
	}
	log.Println("exec transfer: success")
}

func transferFunds(tx *sql.Tx, from, to, amount int) error {
	log.Println("transfer: funds between accounts")

	if err := validateBalance(tx, from, amount); err != nil {
		return err
	}

	if err := transfer(tx, from, to, amount); err != nil {
		return err
	}

	return nil
}

func validateBalance(tx *sql.Tx, account, amount int) error {
	log.Println("validate: account has enough funds")

	fromBalance, err := balance(tx, account)
	if err != nil {
		return err
	}

	if fromBalance < amount {
		return errors.New("validate: error insufficient funds")
	}

	return nil
}

func balance(tx *sql.Tx, account int) (int, error) {
	log.Println("balance: fetch from account")

	s := `SELECT balance FROM accounts WHERE id = $1`
	var b int
	if err := tx.QueryRow(s, account).Scan(&b); err != nil {
		return b, fmt.Errorf("balance: error get balance for from account: %v", err)
	}
	return b, nil
}

func transfer(tx *sql.Tx, from, to, amount int) error {
	log.Println("transfer: movement amount from origin to destination")

	if err := withdraw(tx, from, amount); err != nil {
		return err
	}

	if err := credit(tx, to, amount); err != nil {
		return err
	}

	return nil
}

func withdraw(tx *sql.Tx, account, amount int) error {
	log.Println("withdraw: amount from account")

	s := `UPDATE accounts SET balance = balance - $1 WHERE id = $2`
	if _, err := tx.Exec(s, amount, account); err != nil {
		return fmt.Errorf("withdraw: error update balance: %v", err)
	}
	return nil
}

func credit(tx *sql.Tx, account, amount int) error {
	log.Println("credit: amount to account")

	s := `UPDATE accounts SET balance = balance + $1 WHERE id = $2`
	if _, err := tx.Exec(s, amount, account); err != nil {
		return fmt.Errorf("credit: error update balance: %v", err)
	}
	return nil
}
