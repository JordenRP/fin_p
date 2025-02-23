package models

import (
	"finance/internal/db"
	"time"
)

type Transaction struct {
	ID          uint      `json:"id"`
	UserID      uint      `json:"user_id"`
	Amount      float64   `json:"amount"`
	Type        string    `json:"type"`
	Description string    `json:"description"`
	Date        time.Time `json:"date"`
}

func CreateTransaction(userID uint, amount float64, transactionType, description string) (*Transaction, error) {
	var id uint
	err := db.DB.QueryRow(
		"INSERT INTO transactions (user_id, amount, type, description, date) VALUES ($1, $2, $3, $4, $5) RETURNING id",
		userID, amount, transactionType, description, time.Now(),
	).Scan(&id)
	if err != nil {
		return nil, err
	}

	return &Transaction{
		ID:          id,
		UserID:      userID,
		Amount:      amount,
		Type:        transactionType,
		Description: description,
		Date:        time.Now(),
	}, nil
}

func GetUserTransactions(userID uint) ([]Transaction, error) {
	rows, err := db.DB.Query(
		"SELECT id, user_id, amount, type, description, date FROM transactions WHERE user_id = $1 ORDER BY date DESC",
		userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var transactions []Transaction
	for rows.Next() {
		var t Transaction
		err := rows.Scan(&t.ID, &t.UserID, &t.Amount, &t.Type, &t.Description, &t.Date)
		if err != nil {
			return nil, err
		}
		transactions = append(transactions, t)
	}
	return transactions, nil
} 