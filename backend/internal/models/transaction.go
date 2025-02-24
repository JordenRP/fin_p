package models

import (
	"finance/internal/db"
	"database/sql"
	"time"
)

type Transaction struct {
	ID          uint    `json:"id"`
	UserID      uint    `json:"user_id"`
	CategoryID  *uint   `json:"category_id"`
	Amount      float64 `json:"amount"`
	Type        string  `json:"type"`
	Description string  `json:"description"`
	Date        time.Time `json:"date"`
}

func CreateTransaction(userID uint, categoryID *uint, amount float64, transactionType, description string) (*Transaction, error) {
	var id uint
	var err error
	
	if categoryID != nil {
		err = db.DB.QueryRow(
			"INSERT INTO transactions (user_id, category_id, amount, type, description, date) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id",
			userID, categoryID, amount, transactionType, description, time.Now(),
		).Scan(&id)
	} else {
		err = db.DB.QueryRow(
			"INSERT INTO transactions (user_id, amount, type, description, date) VALUES ($1, $2, $3, $4, $5) RETURNING id",
			userID, amount, transactionType, description, time.Now(),
		).Scan(&id)
	}
	
	if err != nil {
		return nil, err
	}

	return &Transaction{
		ID:          id,
		UserID:      userID,
		CategoryID:  categoryID,
		Amount:      amount,
		Type:        transactionType,
		Description: description,
		Date:        time.Now(),
	}, nil
}

func GetUserTransactions(userID uint) ([]Transaction, error) {
	rows, err := db.DB.Query(
		"SELECT id, user_id, category_id, amount, type, description, date FROM transactions WHERE user_id = $1 ORDER BY date DESC",
		userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var transactions []Transaction
	for rows.Next() {
		var t Transaction
		var categoryID sql.NullInt64
		err := rows.Scan(&t.ID, &t.UserID, &categoryID, &t.Amount, &t.Type, &t.Description, &t.Date)
		if err != nil {
			return nil, err
		}
		if categoryID.Valid {
			catID := uint(categoryID.Int64)
			t.CategoryID = &catID
		}
		transactions = append(transactions, t)
	}
	return transactions, nil
}

func GetUserTransactionsInRange(userID uint, startDate, endDate time.Time) ([]Transaction, error) {
	rows, err := db.DB.Query(
		"SELECT id, user_id, category_id, amount, type, description, date FROM transactions WHERE user_id = $1 AND date BETWEEN $2 AND $3 ORDER BY date DESC",
		userID, startDate, endDate,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var transactions []Transaction
	for rows.Next() {
		var t Transaction
		var categoryID sql.NullInt64
		err := rows.Scan(&t.ID, &t.UserID, &categoryID, &t.Amount, &t.Type, &t.Description, &t.Date)
		if err != nil {
			return nil, err
		}
		if categoryID.Valid {
			catID := uint(categoryID.Int64)
			t.CategoryID = &catID
		}
		transactions = append(transactions, t)
	}
	return transactions, nil
} 