package main

import (
	"log"
	"net/http"
	"os"
	"github.com/gorilla/mux"
	"finance/internal/handlers"
	"finance/internal/db"
	"finance/internal/middleware"
)

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "http://localhost:3000")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		w.Header().Set("Access-Control-Allow-Credentials", "true")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func main() {
	err := db.InitDB(
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
	)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	r := mux.NewRouter()
	r.Use(corsMiddleware)
	
	jwtSecret := []byte("your-secret-key")
	authHandler := handlers.NewAuthHandler(string(jwtSecret))
	transactionHandler := handlers.NewTransactionHandler()
	categoryHandler := handlers.NewCategoryHandler()
	budgetHandler := handlers.NewBudgetHandler()
	statisticsHandler := handlers.NewStatisticsHandler()
	exportHandler := handlers.NewExportHandler()

	r.HandleFunc("/api/auth/login", authHandler.Login).Methods("POST", "OPTIONS")
	r.HandleFunc("/api/auth/register", authHandler.Register).Methods("POST", "OPTIONS")

	api := r.PathPrefix("/api").Subrouter()
	api.Use(middleware.AuthMiddleware(jwtSecret))

	api.HandleFunc("/transactions", transactionHandler.Create).Methods("POST", "OPTIONS")
	api.HandleFunc("/transactions", transactionHandler.List).Methods("GET", "OPTIONS")

	api.HandleFunc("/categories", categoryHandler.Create).Methods("POST", "OPTIONS")
	api.HandleFunc("/categories", categoryHandler.List).Methods("GET", "OPTIONS")

	api.HandleFunc("/budgets", budgetHandler.Create).Methods("POST", "OPTIONS")
	api.HandleFunc("/budgets", budgetHandler.List).Methods("GET", "OPTIONS")
	api.HandleFunc("/budgets/{id}", budgetHandler.Delete).Methods("DELETE", "OPTIONS")

	api.HandleFunc("/statistics", statisticsHandler.GetStatistics).Methods("POST", "OPTIONS")

	api.HandleFunc("/export/transactions", exportHandler.ExportTransactions).Methods("POST", "OPTIONS")

	log.Println("Server starting on port 8080...")
	if err := http.ListenAndServe(":8080", r); err != nil {
		log.Fatal(err)
	}
} 