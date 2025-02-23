package models

import (
    "todo-app/internal/db"
    "time"
)

type Task struct {
    ID          uint      `json:"id"`
    Title       string    `json:"title"`
    Description string    `json:"description"`
    Completed   bool      `json:"completed"`
    UserID      uint      `json:"user_id"`
    CreatedAt   time.Time `json:"created_at"`
    UpdatedAt   time.Time `json:"updated_at"`
}

func CreateTask(title, description string, userID uint) (*Task, error) {
    var task Task
    err := db.DB.QueryRow(
        `INSERT INTO tasks (title, description, completed, user_id, created_at, updated_at) 
         VALUES ($1, $2, false, $3, NOW(), NOW()) 
         RETURNING id, title, description, completed, user_id, created_at, updated_at`,
        title, description, userID,
    ).Scan(&task.ID, &task.Title, &task.Description, &task.Completed, &task.UserID, &task.CreatedAt, &task.UpdatedAt)

    if err != nil {
        return nil, err
    }
    return &task, nil
}

func GetUserTasks(userID uint) ([]Task, error) {
    rows, err := db.DB.Query(
        `SELECT id, title, description, completed, user_id, created_at, updated_at 
         FROM tasks WHERE user_id = $1 
         ORDER BY created_at DESC`,
        userID,
    )
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var tasks []Task
    for rows.Next() {
        var task Task
        err := rows.Scan(&task.ID, &task.Title, &task.Description, &task.Completed, &task.UserID, &task.CreatedAt, &task.UpdatedAt)
        if err != nil {
            return nil, err
        }
        tasks = append(tasks, task)
    }
    return tasks, nil
}

func UpdateTask(id uint, title, description string, completed bool) (*Task, error) {
    var task Task
    err := db.DB.QueryRow(
        `UPDATE tasks 
         SET title = $1, description = $2, completed = $3, updated_at = NOW() 
         WHERE id = $4 
         RETURNING id, title, description, completed, user_id, created_at, updated_at`,
        title, description, completed, id,
    ).Scan(&task.ID, &task.Title, &task.Description, &task.Completed, &task.UserID, &task.CreatedAt, &task.UpdatedAt)

    if err != nil {
        return nil, err
    }
    return &task, nil
}

func DeleteTask(id uint) error {
    _, err := db.DB.Exec("DELETE FROM tasks WHERE id = $1", id)
    return err
} 