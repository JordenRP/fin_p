package db

import (
    "database/sql"
    _ "github.com/lib/pq"
    "fmt"
)

var DB *sql.DB

func InitDB(host, port, user, password, dbname string) error {
    connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
        host, port, user, password, dbname)
    
    var err error
    DB, err = sql.Open("postgres", connStr)
    if err != nil {
        return err
    }

    err = DB.Ping()
    if err != nil {
        return err
    }

    err = createTables()
    if err != nil {
        return err
    }

    return nil
}

func createTables() error {
    queries := []string{
        `CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            email VARCHAR(255) UNIQUE NOT NULL,
            password VARCHAR(255) NOT NULL,
            name VARCHAR(255) NOT NULL
        )`,
        `CREATE TABLE IF NOT EXISTS categories (
            id SERIAL PRIMARY KEY,
            user_id INTEGER REFERENCES users(id),
            name VARCHAR(255) NOT NULL,
            type VARCHAR(50) NOT NULL
        )`,
        `CREATE TABLE IF NOT EXISTS transactions (
            id SERIAL PRIMARY KEY,
            user_id INTEGER REFERENCES users(id),
            category_id INTEGER REFERENCES categories(id),
            amount DECIMAL(10,2) NOT NULL,
            type VARCHAR(50) NOT NULL,
            description TEXT,
            date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        )`,
    }

    for _, query := range queries {
        _, err := DB.Exec(query)
        if err != nil {
            return err
        }
    }

    return nil
} 