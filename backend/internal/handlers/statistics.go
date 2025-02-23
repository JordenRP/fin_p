package handlers

import (
    "encoding/json"
    "net/http"
    "finance/internal/models"
    "github.com/golang-jwt/jwt/v5"
    "time"
)

type StatisticsHandler struct{}

type StatisticsRequest struct {
    StartDate time.Time `json:"start_date"`
    EndDate   time.Time `json:"end_date"`
    Type      string    `json:"type,omitempty"`
}

type StatisticsResponse struct {
    CategoryTotals []models.CategoryTotal `json:"category_totals,omitempty"`
    DailyTotals   []models.DailyTotal   `json:"daily_totals,omitempty"`
    BalanceHistory []models.DailyTotal   `json:"balance_history,omitempty"`
}

func NewStatisticsHandler() *StatisticsHandler {
    return &StatisticsHandler{}
}

func (h *StatisticsHandler) GetStatistics(w http.ResponseWriter, r *http.Request) {
    var req StatisticsRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request", http.StatusBadRequest)
        return
    }

    claims := r.Context().Value("claims").(jwt.MapClaims)
    userID := uint(claims["user_id"].(float64))

    var response StatisticsResponse
    var err error

    // Получаем статистику по категориям
    response.CategoryTotals, err = models.GetCategoryTotals(userID, req.StartDate, req.EndDate)
    if err != nil {
        http.Error(w, "Could not get category statistics", http.StatusInternalServerError)
        return
    }

    // Если указан тип транзакции, получаем ежедневную статистику
    if req.Type != "" {
        response.DailyTotals, err = models.GetDailyTotals(userID, req.StartDate, req.EndDate, req.Type)
        if err != nil {
            http.Error(w, "Could not get daily statistics", http.StatusInternalServerError)
            return
        }
    }

    // Получаем историю баланса
    response.BalanceHistory, err = models.GetBalanceHistory(userID, req.StartDate, req.EndDate)
    if err != nil {
        http.Error(w, "Could not get balance history", http.StatusInternalServerError)
        return
    }

    json.NewEncoder(w).Encode(response)
} 