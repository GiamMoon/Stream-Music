package music

import (
	"net/http"
	"github.com/gin-gonic/gin"
	"github.com/giampier/super-app-api/internal/db"
	"github.com/giampier/super-app-api/internal/models"
)

// GetTrendingArtists devuelve artistas para la pantalla de "Gustos" (Req 1.2)
func GetTrendingArtists(c *gin.Context) {
	// Consultamos los 20 artistas más populares
	rows, err := db.DB.Query("SELECT id, name, image_url, popularity FROM artists ORDER BY popularity DESC LIMIT 20")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error consultando artistas"})
		return
	}
	defer rows.Close()

	var artists []models.Artist
	for rows.Next() {
		var a models.Artist
		// Escaneamos solo los campos que pedimos en el SELECT
		if err := rows.Scan(&a.ID, &a.Name, &a.ImageURL, &a.Popularity); err != nil {
			continue
		}
		artists = append(artists, a)
	}

	c.JSON(http.StatusOK, artists)
}

// GetTrackDetails devuelve metadatos completos y créditos (Req 3.4)
func GetTrackDetails(c *gin.Context) {
	trackID := c.Param("id")
	var t models.Track

	// Query compleja para traer todo (en la vida real usaríamos un ORM o JOINs, aquí simplificado)
	query := `
		SELECT id, title, stream_url, canvas_url, has_lyrics, is_explicit 
		FROM tracks WHERE id = $1`
	
	err := db.DB.QueryRow(query, trackID).Scan(
		&t.ID, &t.Title, &t.StreamURL, &t.CanvasURL, &t.HasLyrics, &t.IsExplicit,
	)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Canción no encontrada"})
		return
	}

	c.JSON(http.StatusOK, t)
}

// GetLyrics (Endpoint 3.3)
func GetLyrics(c *gin.Context) {
    trackID := c.Param("id")

    rows, err := db.DB.Query("SELECT time_ms, text FROM lyrics WHERE track_id = $1 ORDER BY time_ms ASC", trackID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error buscando letras"})
        return
    }
    defer rows.Close()

    var lyrics []models.LyricLine
    for rows.Next() {
        var l models.LyricLine
        if err := rows.Scan(&l.TimeMs, &l.Text); err != nil {
            continue
        }
        lyrics = append(lyrics, l)
    }

    // Si no hay letras, devolvemos array vacío (no 404)
    if lyrics == nil {
        lyrics = []models.LyricLine{}
    }
    c.JSON(http.StatusOK, lyrics)
}

// GenerateWelcomeMix (Endpoint 1.3 - Simulación de Recomendación)
func GenerateWelcomeMix(c *gin.Context) {
    // Nota: En un sistema real, aquí recibiríamos los artist_ids del body
    // y llamaríamos a Python/Qdrant.
    // Aquí simulamos "Inteligencia" seleccionando canciones aleatorias.

    query := `
        SELECT id, title, artist_id, album_id, duration_ms, stream_url, canvas_url, has_lyrics, is_explicit 
        FROM tracks 
        ORDER BY RANDOM() 
        LIMIT 5`

    rows, err := db.DB.Query(query)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error generando mix"})
        return
    }
    defer rows.Close()

    var tracks []models.Track
    for rows.Next() {
        var t models.Track
        // Usamos variables dummy para los campos que no tenemos en el struct simple
        // Ojo: Asegúrate de que tu struct Track coincida con estos campos
        err := rows.Scan(
            &t.ID, &t.Title, &t.ArtistID, &t.AlbumID, &t.DurationMs, 
            &t.StreamURL, &t.CanvasURL, &t.HasLyrics, &t.IsExplicit,
        )
        if err != nil { continue }
        tracks = append(tracks, t)
    }

    playlist := models.Playlist{
        ID:          "mix_welcome_gen",
        Name:        "Tu Mix Diario",
        Description: "Generado especialmente para ti",
        Tracks:      tracks,
    }

    c.JSON(http.StatusOK, playlist)
}