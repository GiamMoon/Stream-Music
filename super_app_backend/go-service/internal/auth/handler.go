package auth

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"fmt"      
	"net/http" 
	"time"

	"github.com/gin-gonic/gin"
	"github.com/giampier/super-app-api/internal/db"     
	"github.com/giampier/super-app-api/internal/models" 
	"github.com/giampier/super-app-api/pkg/utils"       
)

// Register maneja la creación de usuarios
func Register(c *gin.Context) {
	var input models.RegisterInput

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Datos inválidos: " + err.Error()})
		return
	}

	hashedPassword, err := utils.HashPassword(input.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error de seguridad"})
		return
	}

	var userID string
	query := `INSERT INTO users (username, email, password_hash) VALUES ($1, $2, $3) RETURNING id`

	err = db.DB.QueryRow(query, input.Username, input.Email, hashedPassword).Scan(&userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No se pudo registrar el usuario. ¿Quizás el email ya existe?"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Usuario creado exitosamente",
		"user_id": userID,
	})
}

// Login maneja el inicio de sesión
func Login(c *gin.Context) {
	var input models.LoginInput

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Datos incompletos"})
		return
	}

	var storedHash string
	var userID string

	query := `SELECT id, password_hash FROM users WHERE email = $1`
	err := db.DB.QueryRow(query, input.Email).Scan(&userID, &storedHash)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Usuario o contraseña incorrectos"})
		return
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error del servidor"})
		return
	}

	if !utils.CheckPassword(input.Password, storedHash) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Usuario o contraseña incorrectos"})
		return
	}

	accessToken, refreshToken, err := utils.GenerateTokens(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error generando tokens"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"token_type":    "Bearer",
		"expires_in":    900, 
	})
}

// RefreshToken
func RefreshToken(c *gin.Context) {
	var input struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Refresh token requerido"})
		return
	}

	claims, err := utils.ValidateToken(input.RefreshToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Token inválido o expirado"})
		return
	}

	if claims["type"] != "refresh" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "El token provisto no es un Refresh Token"})
		return
	}

	userID := claims["user_id"].(string)
	newAccess, newRefresh, err := utils.GenerateTokens(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error rotando tokens"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"access_token":  newAccess,
		"refresh_token": newRefresh,
		"token_type":    "Bearer",
	})
}

// --- RECUPERACIÓN DE CONTRASEÑA ---

func GenerateRandomToken() (string, error) {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

func ForgotPassword(c *gin.Context) {
	var input struct {
		Email string `json:"email" binding:"required,email"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Email inválido"})
		return
	}

	var userID string
	query := `SELECT id FROM users WHERE email = $1`
	err := db.DB.QueryRow(query, input.Email).Scan(&userID)
	
	if err == sql.ErrNoRows {
		c.JSON(http.StatusOK, gin.H{"message": "Si el correo existe, recibirás instrucciones."})
		return
	}

	token, _ := GenerateRandomToken()
	
	// CORRECCIÓN CRÍTICA: Usamos .UTC() para coincidir con el reloj de Postgres/Docker
	expiry := time.Now().UTC().Add(15 * time.Minute)

	updateQuery := `UPDATE users SET reset_token = $1, reset_token_expiry = $2 WHERE id = $3`
	_, err = db.DB.Exec(updateQuery, token, expiry, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al procesar solicitud"})
		return
	}

	emailBody := fmt.Sprintf("Hola,\n\nPara resetear tu contraseña usa este token:\n\n%s\n\nEste token expira en 15 minutos.", token)
	go utils.SendEmail(input.Email, "Recuperar Contraseña - Super App", emailBody)

	c.JSON(http.StatusOK, gin.H{"message": "Si el correo existe, recibirás instrucciones."})
}

func ResetPassword(c *gin.Context) {
	var input struct {
		Token       string `json:"token" binding:"required"`
		NewPassword string `json:"new_password" binding:"required,min=6"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Datos incompletos o contraseña muy corta"})
		return
	}

	var userID string
	// Postgres comparará su NOW() (UTC) con nuestra expiry (UTC) y funcionará correctamente
	query := `SELECT id FROM users WHERE reset_token = $1 AND reset_token_expiry > NOW()`
	err := db.DB.QueryRow(query, input.Token).Scan(&userID)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Token inválido o expirado"})
		return
	}

	hashedPassword, err := utils.HashPassword(input.NewPassword)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error de seguridad"})
		return
	}

	updateQuery := `UPDATE users SET password_hash = $1, reset_token = NULL, reset_token_expiry = NULL WHERE id = $2`
	_, err = db.DB.Exec(updateQuery, hashedPassword, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No se pudo actualizar la contraseña"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Contraseña actualizada correctamente. Ya puedes iniciar sesión."})
}