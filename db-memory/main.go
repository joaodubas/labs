package main // import "github.com/joaodubas/db-memory"

import (
	"database/sql"
	"log"
	"time"

	_ "github.com/VoltDB/voltdb-client-go/voltdbclient"
)

func main() {
	db := conn()
	defer db.Close()
	fetch(db)
	prepared(db)
}

func conn() *sql.DB {
	var db *sql.DB
	var err error
	var retry int

	innerConn := func (retry int, err error) (*sql.DB, error) {
		log.Print("conn: connecting to db")
		if retry >= 10 {
			log.Fatalf("conn: error connecting to db: %v", err)
		}

		db, err := sql.Open("voltdb", "db:21212")
		if err != nil {
			return db, err
		}

		if err := db.Ping(); err != nil {
			return db, err
		}
		return db, err
	}

	for {
		db, err = innerConn(retry, err)
		if err == nil {
			break
		}
		retry++
		time.Sleep(1 * time.Second)
	}

	return db
}

func fetch(db *sql.DB) {
	rows, err := db.Query("HELLOWORLD.select", "French")
	if err != nil {
		log.Fatalf("fetch: error getting rows: %v", err)
	}
	defer rows.Close()
	for rows.Next() {
		var hello, world, dialect string
		if err := rows.Scan(&hello, &world, &dialect); err != nil {
			log.Fatalf("fetch: error getting row value: %v", err)
		}
		log.Printf("fetch: hello %s | world %s | dialect %s", hello, world, dialect)
	}
}

func prepared(db *sql.DB) {
	stmt, err := db.Prepare(`SELECT hello, world, dialect FROM HELLOWORLD WHERE dialect = ?`)
	if err != nil {
		log.Fatalf("prepared: error preparing statement: %v", err)
	}
	defer stmt.Close()

	rows, err := stmt.Query("French")
	if err != nil {
		log.Fatalf("prepared: error fetchinig data: %v", err)
	}
	defer rows.Close()

	for rows.Next() {
		var hello, world, dialect string
		if err := rows.Scan(&hello, &world, &dialect); err != nil {
			log.Fatalf("fetch: error getting row value: %v", err)
		}
		log.Printf("fetch: hello %s | world %s | dialect %s", hello, world, dialect)
	}
}
