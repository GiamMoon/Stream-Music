package utils

import (
	"time"
	"github.com/golang-jwt/jwt/v5"
)

var secretKey = []byte("SUPER_SECRETO_CAMBIAR_EN_PROD")

// GenerateTokens crea Access Token (15 min) y Refresh Token (7 días)
func GenerateTokens(userID string) (string, string, error) {
	// 1. Access Token
	accessClaims := jwt.MapClaims{
		"user_id": userID,
		"type":    "access",
		"exp":     time.Now().Add(time.Minute * 15).Unix(),
	}
	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	accessString, err := accessToken.SignedString(secretKey)
	if err != nil {
		return "", "", err
	}

	// 2. Refresh Token
	refreshClaims := jwt.MapClaims{
		"user_id": userID,
		"type":    "refresh",
		"exp":     time.Now().Add(time.Hour * 24 * 7).Unix(),
	}
	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshString, err := refreshToken.SignedString(secretKey)
	if err != nil {
		return "", "", err
	}

	return accessString, refreshString, nil
}

// ValidateToken verifica si un token es válido y devuelve los claims
func ValidateToken(tokenString string) (jwt.MapClaims, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		return secretKey, nil
	})
	if err != nil {
		return nil, err
	}
	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		return claims, nil
	}
	return nil, err
}