package handlers

import (
    "encoding/csv"
    "encoding/json"
    "finance/internal/models"
    "github.com/golang-jwt/jwt/v5"
    "net/http"
    "strconv"
    "time"
)

type ExportHandler struct{}

type ExportRequest struct {
    StartDate time.Time `json:"start_date"`
    EndDate   time.Time `json:"end_date"`
}

func NewExportHandler() *ExportHandler {
    return &ExportHandler{}
}

func (h *ExportHandler) ExportTransactions(w http.ResponseWriter, r *http.Request) {
    var req ExportRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request", http.StatusBadRequest)
        return
    }

    claims := r.Context().Value("claims").(jwt.MapClaims)
    userID := uint(claims["user_id"].(float64))

    transactions, err := models.GetUserTransactionsInRange(userID, req.StartDate, req.EndDate)
    if err != nil {
        http.Error(w, "Could not get transactions", http.StatusInternalServerError)
        return
    }

    categories, err := models.GetUserCategories(userID)
    if err != nil {
        http.Error(w, "Could not get categories", http.StatusInternalServerError)
        return
    }

    categoryMap := make(map[uint]string)
    for _, category := range categories {
        categoryMap[category.ID] = category.Name
    }

    w.Header().Set("Content-Type", "text/csv")
    w.Header().Set("Content-Disposition", "attachment; filename=transactions.csv")

    csvWriter := csv.NewWriter(w)
    defer csvWriter.Flush()

    // Записываем заголовки
    headers := []string{"Дата", "Тип", "Категория", "Сумма", "Описание"}
    if err := csvWriter.Write(headers); err != nil {
        http.Error(w, "Could not write CSV headers", http.StatusInternalServerError)
        return
    }

    // Записываем данные
    for _, t := range transactions {
        categoryName := "Без категории"
        if t.CategoryID != nil {
            if name, ok := categoryMap[*t.CategoryID]; ok {
                categoryName = name
            }
        }

        record := []string{
            t.Date.Format("02.01.2006 15:04"),
            t.Type,
            categoryName,
            strconv.FormatFloat(t.Amount, 'f', 2, 64),
            t.Description,
        }

        if err := csvWriter.Write(record); err != nil {
            http.Error(w, "Could not write CSV record", http.StatusInternalServerError)
            return
        }
    }
} 