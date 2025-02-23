package models

import (
    "finance/internal/db"
    "time"
)

type Budget struct {
    ID         uint      `json:"id"`
    UserID     uint      `json:"user_id"`
    CategoryID uint      `json:"category_id"`
    Amount     float64   `json:"amount"`
    Spent      float64   `json:"spent"`
    StartDate  time.Time `json:"start_date"`
    EndDate    time.Time `json:"end_date"`
}

func CreateBudget(userID, categoryID uint, amount float64, startDate, endDate time.Time) (*Budget, error) {
    var id uint
    err := db.DB.QueryRow(
        "INSERT INTO budgets (user_id, category_id, amount, spent, start_date, end_date) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id",
        userID, categoryID, amount, 0, startDate, endDate,
    ).Scan(&id)
    if err != nil {
        return nil, err
    }

    return &Budget{
        ID:         id,
        UserID:     userID,
        CategoryID: categoryID,
        Amount:     amount,
        Spent:      0,
        StartDate:  startDate,
        EndDate:    endDate,
    }, nil
}

func GetUserBudgets(userID uint) ([]Budget, error) {
    rows, err := db.DB.Query(
        "SELECT id, user_id, category_id, amount, spent, start_date, end_date FROM budgets WHERE user_id = $1",
        userID,
    )
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var budgets []Budget
    for rows.Next() {
        var b Budget
        err := rows.Scan(&b.ID, &b.UserID, &b.CategoryID, &b.Amount, &b.Spent, &b.StartDate, &b.EndDate)
        if err != nil {
            return nil, err
        }
        budgets = append(budgets, b)
    }
    return budgets, nil
}

func GetActiveBudgetsForCategory(userID, categoryID uint, date time.Time) ([]Budget, error) {
    rows, err := db.DB.Query(
        `SELECT id, user_id, category_id, amount, spent, start_date, end_date 
         FROM budgets 
         WHERE user_id = $1 
         AND category_id = $2 
         AND start_date <= $3 
         AND end_date >= $3`,
        userID, categoryID, date,
    )
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var budgets []Budget
    for rows.Next() {
        var b Budget
        err := rows.Scan(&b.ID, &b.UserID, &b.CategoryID, &b.Amount, &b.Spent, &b.StartDate, &b.EndDate)
        if err != nil {
            return nil, err
        }
        budgets = append(budgets, b)
    }
    return budgets, nil
}

func UpdateBudgetSpent(budgetID uint, spent float64) error {
    _, err := db.DB.Exec(
        "UPDATE budgets SET spent = $1 WHERE id = $2",
        spent, budgetID,
    )
    return err
}

func DeleteBudget(budgetID uint) error {
    _, err := db.DB.Exec("DELETE FROM budgets WHERE id = $1", budgetID)
    return err
} 