package main // import "github.com/joaodubas/labs/account/examples/app"

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/VoltDB/voltdb-client-go/voltdbclient"
	_ "github.com/lib/pq"
)

func main() {
}

func connInDisk() *sql.DB {
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

func connInMemory() *sql.DB {
	log.Println("conn: access database")

	db, err := sql.Open("voltdb", "db:21212")
	if err != nil {
		log.Fatal("conn: error access database: ", err)
	}

	if err = db.Ping(); err != nil {
		log.Fatal("conn: error access database: ", err)
	}

	return db
}
