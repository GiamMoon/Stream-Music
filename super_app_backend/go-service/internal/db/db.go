package db

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq" // Importamos el driver de Postgres
)

var DB *sql.DB

func Connect() {
	// Datos de conexión (los mismos de tu docker-compose)
	dbHost := "localhost"
	dbPort := "5435"
	dbUser := "admin"
	dbPassword := "password123"
	dbName := "streaming_db"

	// Construimos la URL de conexión
	psqlInfo := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		dbHost, dbPort, dbUser, dbPassword, dbName)

	// Abrimos la conexión
	var err error
	DB, err = sql.Open("postgres", psqlInfo)
	if err != nil {
		log.Fatal("Error al configurar la BD: ", err)
	}

	// Hacemos un "Ping" para ver si responde de verdad
	err = DB.Ping()
	if err != nil {
		log.Fatal("❌ No se pudo conectar a la base de datos: ", err)
	}

	fmt.Println("✅ ¡Conexión a PostgreSQL exitosa!")
}