package handlers

import (
	"encoding/json"
	"finance/internal/models"
	"github.com/golang-jwt/jwt/v5"
	"net/http"
	"time"
)

type TransactionHandler struct{}

type CreateTransactionRequest struct {
	Amount      float64 `json:"amount"`
	CategoryID  *uint   `json:"category_id,omitempty"`
	Type        string  `json:"type"`
	Description string  `json:"description"`
}

func NewTransactionHandler() *TransactionHandler {
	return &TransactionHandler{}
}

func (h *TransactionHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateTransactionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	claims := r.Context().Value("claims").(jwt.MapClaims)
	userID := uint(claims["user_id"].(float64))

	transaction, err := models.CreateTransaction(userID, req.CategoryID, req.Amount, req.Type, req.Description)
	if err != nil {
		http.Error(w, "Could not create transaction", http.StatusInternalServerError)
		return
	}

	// Обновляем бюджеты, если транзакция относится к категории расходов
	if req.Type == "expense" && req.CategoryID != nil {
		budgets, err := models.GetActiveBudgetsForCategory(userID, *req.CategoryID, time.Now())
		if err != nil {
			http.Error(w, "Could not get budgets", http.StatusInternalServerError)
			return
		}

		for _, budget := range budgets {
			newSpent := budget.Spent + req.Amount
			if err := models.UpdateBudgetSpent(budget.ID, newSpent); err != nil {
				http.Error(w, "Could not update budget", http.StatusInternalServerError)
				return
			}
		}
	}

	json.NewEncoder(w).Encode(transaction)
}

func (h *TransactionHandler) List(w http.ResponseWriter, r *http.Request) {
	claims := r.Context().Value("claims").(jwt.MapClaims)
	userID := uint(claims["user_id"].(float64))

	transactions, err := models.GetUserTransactions(userID)
	if err != nil {
		http.Error(w, "Could not get transactions", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(transactions)
} 