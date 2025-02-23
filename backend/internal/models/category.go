package models

import (
    "finance/internal/db"
)

type Category struct {
    ID     uint   `json:"id"`
    UserID uint   `json:"user_id"`
    Name   string `json:"name"`
    Type   string `json:"type"`
}

func CreateCategory(userID uint, name, categoryType string) (*Category, error) {
    var id uint
    err := db.DB.QueryRow(
        "INSERT INTO categories (user_id, name, type) VALUES ($1, $2, $3) RETURNING id",
        userID, name, categoryType,
    ).Scan(&id)
    if err != nil {
        return nil, err
    }

    return &Category{
        ID:     id,
        UserID: userID,
        Name:   name,
        Type:   categoryType,
    }, nil
}

func GetUserCategories(userID uint) ([]Category, error) {
    rows, err := db.DB.Query(
        "SELECT id, user_id, name, type FROM categories WHERE user_id = $1",
        userID,
    )
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var categories []Category
    for rows.Next() {
        var c Category
        err := rows.Scan(&c.ID, &c.UserID, &c.Name, &c.Type)
        if err != nil {
            return nil, err
        }
        categories = append(categories, c)
    }
    return categories, nil
} 