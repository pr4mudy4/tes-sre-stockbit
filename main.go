package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"
	_ "github.com/lib/pq"
)

type Row struct {
	ID int    `json:"id"`
	Data string `json:"data"`
}

var db *sql.DB

func main() {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL env var required (postgres://user:pass@host:5432/dbname?sslmode=disable)")
	}
	var err error
	db, err = sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatal(err)
	}
	db.SetMaxOpenConns(50)
	db.SetConnMaxLifetime(5 * time.Minute)

	http.HandleFunc("/query", queryHandler)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(200); w.Write([]byte("OK")) })

	port := os.Getenv("PORT")
	if port == "" { port = "8080" }
	log.Printf("listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func queryHandler(w http.ResponseWriter, r *http.Request) {
	row := Row{}
	err := db.QueryRow("SELECT id, data FROM demo LIMIT 1").Scan(&row.ID, &row.Data)
	if err != nil {
		http.Error(w, "db error", 500)
		log.Println("db query:", err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(row)
}

