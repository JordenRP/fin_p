package handlers

import (
    "encoding/json"
    "net/http"
    "finance/internal/models"
    "github.com/golang-jwt/jwt/v5"
)

type CategoryHandler struct{}

type CreateCategoryRequest struct {
    Name string `json:"name"`
    Type string `json:"type"`
}

func NewCategoryHandler() *CategoryHandler {
    return &CategoryHandler{}
}

func (h *CategoryHandler) Create(w http.ResponseWriter, r *http.Request) {
    var req CreateCategoryRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request", http.StatusBadRequest)
        return
    }

    claims := r.Context().Value("claims").(jwt.MapClaims)
    userID := uint(claims["user_id"].(float64))

    category, err := models.CreateCategory(userID, req.Name, req.Type)
    if err != nil {
        http.Error(w, "Could not create category", http.StatusInternalServerError)
        return
    }

    json.NewEncoder(w).Encode(category)
}

func (h *CategoryHandler) List(w http.ResponseWriter, r *http.Request) {
    claims := r.Context().Value("claims").(jwt.MapClaims)
    userID := uint(claims["user_id"].(float64))

    categories, err := models.GetUserCategories(userID)
    if err != nil {
        http.Error(w, "Could not get categories", http.StatusInternalServerError)
        return
    }

    json.NewEncoder(w).Encode(categories)
} 