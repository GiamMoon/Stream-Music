package utils  // <--- ¡ESTO ES LO IMPORTANTE!

import (
	"golang.org/x/crypto/bcrypt"
)

// HashPassword encripta la contraseña
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	return string(bytes), err
}

// CheckPassword compara contraseña y hash
func CheckPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}