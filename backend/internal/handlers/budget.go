package handlers

import (
    "encoding/json"
    "net/http"
    "finance/internal/models"
    "github.com/golang-jwt/jwt/v5"
    "github.com/gorilla/mux"
    "strconv"
    "time"
    "log"
)

type BudgetHandler struct{}

type CreateBudgetRequest struct {
    CategoryID uint      `json:"category_id"`
    Amount     float64   `json:"amount"`
    StartDate  time.Time `json:"start_date"`
    EndDate    time.Time `json:"end_date"`
}

func NewBudgetHandler() *BudgetHandler {
    return &BudgetHandler{}
}

func (h *BudgetHandler) Create(w http.ResponseWriter, r *http.Request) {
    var req CreateBudgetRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        log.Printf("Error decoding request body: %v", err)
        http.Error(w, "Invalid request", http.StatusBadRequest)
        return
    }

    log.Printf("Received budget request: %+v", req)

    claims := r.Context().Value("claims").(jwt.MapClaims)
    userID := uint(claims["user_id"].(float64))

    log.Printf("Creating budget for user %d", userID)

    budget, err := models.CreateBudget(userID, req.CategoryID, req.Amount, req.StartDate, req.EndDate)
    if err != nil {
        log.Printf("Error creating budget: %v", err)
        http.Error(w, "Could not create budget", http.StatusInternalServerError)
        return
    }

    log.Printf("Successfully created budget: %+v", budget)
    json.NewEncoder(w).Encode(budget)
}

func (h *BudgetHandler) List(w http.ResponseWriter, r *http.Request) {
    claims := r.Context().Value("claims").(jwt.MapClaims)
    userID := uint(claims["user_id"].(float64))

    budgets, err := models.GetUserBudgets(userID)
    if err != nil {
        http.Error(w, "Could not get budgets", http.StatusInternalServerError)
        return
    }

    json.NewEncoder(w).Encode(budgets)
}

func (h *BudgetHandler) Delete(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    budgetID, err := strconv.ParseUint(vars["id"], 10, 32)
    if err != nil {
        http.Error(w, "Invalid budget ID", http.StatusBadRequest)
        return
    }

    err = models.DeleteBudget(uint(budgetID))
    if err != nil {
        http.Error(w, "Could not delete budget", http.StatusInternalServerError)
        return
    }

    w.WriteHeader(http.StatusOK)
} 