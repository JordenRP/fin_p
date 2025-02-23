package models

import (
    "finance/internal/db"
    "time"
)

type CategoryTotal struct {
    CategoryID   uint    `json:"category_id"`
    CategoryName string  `json:"category_name"`
    Total       float64 `json:"total"`
    Type        string  `json:"type"`
}

type DailyTotal struct {
    Date   time.Time `json:"date"`
    Total  float64   `json:"total"`
    Type   string    `json:"type"`
}

func GetCategoryTotals(userID uint, startDate, endDate time.Time) ([]CategoryTotal, error) {
    query := `
        SELECT c.id, c.name, c.type, COALESCE(SUM(t.amount), 0) as total
        FROM categories c
        LEFT JOIN transactions t ON c.id = t.category_id 
            AND t.user_id = $1 
            AND t.date BETWEEN $2 AND $3
        WHERE c.user_id = $1
        GROUP BY c.id, c.name, c.type
        ORDER BY total DESC
    `

    rows, err := db.DB.Query(query, userID, startDate, endDate)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var totals []CategoryTotal
    for rows.Next() {
        var ct CategoryTotal
        err := rows.Scan(&ct.CategoryID, &ct.CategoryName, &ct.Type, &ct.Total)
        if err != nil {
            return nil, err
        }
        totals = append(totals, ct)
    }

    return totals, nil
}

func GetDailyTotals(userID uint, startDate, endDate time.Time, transactionType string) ([]DailyTotal, error) {
    query := `
        SELECT DATE(date) as date, COALESCE(SUM(amount), 0) as total, type
        FROM transactions
        WHERE user_id = $1 
            AND date BETWEEN $2 AND $3
            AND type = $4
        GROUP BY DATE(date), type
        ORDER BY date
    `

    rows, err := db.DB.Query(query, userID, startDate, endDate, transactionType)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var totals []DailyTotal
    for rows.Next() {
        var dt DailyTotal
        err := rows.Scan(&dt.Date, &dt.Total, &dt.Type)
        if err != nil {
            return nil, err
        }
        totals = append(totals, dt)
    }

    return totals, nil
}

func GetBalanceHistory(userID uint, startDate, endDate time.Time) ([]DailyTotal, error) {
    query := `
        WITH RECURSIVE dates AS (
            SELECT date_trunc('day', $2::timestamp) as date
            UNION ALL
            SELECT date + interval '1 day'
            FROM dates
            WHERE date < date_trunc('day', $3::timestamp)
        ),
        daily_balance AS (
            SELECT 
                d.date,
                COALESCE(SUM(
                    CASE 
                        WHEN t.type = 'income' THEN COALESCE(t.amount, 0)
                        ELSE -COALESCE(t.amount, 0)
                    END
                ), 0) as daily_change
            FROM dates d
            LEFT JOIN transactions t 
                ON date_trunc('day', t.date) = d.date 
                AND t.user_id = $1
            GROUP BY d.date
        )
        SELECT 
            date,
            SUM(daily_change) OVER (ORDER BY date) as balance,
            'balance' as type
        FROM daily_balance
        ORDER BY date
    `

    rows, err := db.DB.Query(query, userID, startDate, endDate)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var history []DailyTotal
    for rows.Next() {
        var dt DailyTotal
        err := rows.Scan(&dt.Date, &dt.Total, &dt.Type)
        if err != nil {
            return nil, err
        }
        history = append(history, dt)
    }

    return history, nil
} 