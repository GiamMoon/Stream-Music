package utils

import (
	"fmt"
	"log"
	"net/smtp"
	"os"
)

// SendEmail envía el correo real o lo simula en consola
func SendEmail(to string, subject string, body string) error {
	// Intentamos leer configuración de entorno (para producción)
	smtpHost := os.Getenv("SMTP_HOST") // ej: smtp.gmail.com
	smtpPort := os.Getenv("SMTP_PORT") // ej: 587
	smtpUser := os.Getenv("SMTP_USER")
	smtpPass := os.Getenv("SMTP_PASS")

	// MODO DESARROLLO: Si no hay config, imprimimos en consola (Simulación)
	if smtpHost == "" {
		log.Println("⚠️  SMTP no configurado. MODO SIMULACIÓN ACTIVADO.")
		log.Println("📨  ================ CORREO SALIENTE ================")
		log.Printf("PARA: %s\n", to)
		log.Printf("ASUNTO: %s\n", subject)
		log.Printf("CUERPO:\n%s\n", body)
		log.Println("📨  =================================================")
		return nil
	}

	// MODO PRODUCCIÓN: Envío real
	auth := smtp.PlainAuth("", smtpUser, smtpPass, smtpHost)
	msg := []byte("To: " + to + "\r\n" +
		"Subject: " + subject + "\r\n" +
		"\r\n" +
		body + "\r\n")

	addr := fmt.Sprintf("%s:%s", smtpHost, smtpPort)
	err := smtp.SendMail(addr, auth, smtpUser, []string{to}, msg)
	if err != nil {
		return err
	}

	return nil
}