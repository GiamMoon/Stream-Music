package music

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/giampier/super-app-api/internal/db"
	"github.com/giampier/super-app-api/internal/models"
)

// SyncTrack recibe metadata de Deezer y la guarda en Postgres
func SyncTrack(c *gin.Context) {
	var input models.SyncTrackInput
	
	// Validar JSON entrante
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 1. SINCRONIZAR ARTISTA
	// Intentamos buscarlo primero
	var artistID string
	err := db.DB.QueryRow("SELECT id FROM artists WHERE name = $1", input.ArtistName).Scan(&artistID)
	
	if err == sql.ErrNoRows {
		// No existe, lo creamos
		err = db.DB.QueryRow(`
			INSERT INTO artists (name, image_url, popularity) 
			VALUES ($1, $2, 100) 
			RETURNING id`, 
			input.ArtistName, input.ArtistImg).Scan(&artistID)
		
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error creando artista: " + err.Error()})
			return
		}
	}

	// 2. SINCRONIZAR ÁLBUM
	// Buscamos si existe este álbum para este artista
	var albumID string
	err = db.DB.QueryRow("SELECT id FROM albums WHERE title = $1 AND artist_id = $2", input.AlbumTitle, artistID).Scan(&albumID)

	if err == sql.ErrNoRows {
		// No existe, lo creamos
		err = db.DB.QueryRow(`
			INSERT INTO albums (title, artist_id, cover_url) 
			VALUES ($1, $2, $3) 
			RETURNING id`, 
			input.AlbumTitle, artistID, input.Cover).Scan(&albumID)
		
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error creando álbum: " + err.Error()})
			return
		}
	}

	// 3. SINCRONIZAR TRACK
	// Verificamos si la canción ya existe en ese álbum
	var trackID string
	err = db.DB.QueryRow("SELECT id FROM tracks WHERE title = $1 AND album_id = $2", input.Title, albumID).Scan(&trackID)

	if err == sql.ErrNoRows {
		// Insertamos el track nuevo
		_, err = db.DB.Exec(`
			INSERT INTO tracks (title, artist_id, album_id, duration_ms, stream_url, cover_url, has_lyrics)
			VALUES ($1, $2, $3, $4, $5, $6, $7)`,
			input.Title, artistID, albumID, input.Duration, input.StreamUrl, input.Cover, true)

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error guardando track: " + err.Error()})
			return
		}
		c.JSON(http.StatusCreated, gin.H{"status": "saved", "message": "Canción nueva guardada"})
	} else {
		// Ya existía
		c.JSON(http.StatusOK, gin.H{"status": "existing", "message": "Canción ya existía"})
	}
}