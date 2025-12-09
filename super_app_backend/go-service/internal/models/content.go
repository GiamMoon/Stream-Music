package models

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"
)

// --- UTILIDADES PARA ARRAYS EN POSTGRES ---
type StringArray []string

func (a StringArray) Value() (driver.Value, error) {
	return json.Marshal(a)
}

func (a *StringArray) Scan(value interface{}) error {
	b, ok := value.([]byte)
	if !ok {
		return errors.New("type assertion to []byte failed")
	}
	return json.Unmarshal(b, a)
}

// --- MODELOS DE BASE DE DATOS ---

type Artist struct {
	ID         string   `json:"id"`
	Name       string   `json:"name"`
	Bio        string   `json:"bio"`
	ImageURL   string   `json:"image_url"`
	Popularity int      `json:"popularity"`
}

type Album struct {
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	ArtistID    string    `json:"artist_id"`
	CoverURL    string    `json:"cover_url"`
	ReleaseDate time.Time `json:"release_date"`
	Label       string    `json:"label"`
}

type Track struct {
	ID          string      `json:"id"`
	Title       string      `json:"title"`
	ArtistID    string      `json:"artist_id"`
	AlbumID     string      `json:"album_id"`
	DurationMs  int         `json:"duration_ms"`
	StreamURL   string      `json:"stream_url"`
	CanvasURL   string      `json:"canvas_url"`
	HasLyrics   bool        `json:"has_lyrics"`
	IsExplicit  bool        `json:"is_explicit"`
	Producers   StringArray `json:"producers"` 
	Writers     StringArray `json:"writers"`
}

type LyricLine struct {
    TimeMs int    `json:"time_ms"`
    Text   string `json:"text"`
}

type Playlist struct {
    ID          string  `json:"id"`
    Name        string  `json:"name"`
    Description string  `json:"description"`
    Tracks      []Track `json:"tracks"`
}

// --- NUEVO: Estructura para recibir datos de sincronización ---
type SyncTrackInput struct {
	DeezerID   string `json:"deezer_id"`
	Title      string `json:"title"`
	Duration   int    `json:"duration"`
	StreamUrl  string `json:"stream_url"` // Guardaremos la URL de YouTube o Deezer
	Cover      string `json:"cover"`
	ArtistName string `json:"artist_name"`
	ArtistImg  string `json:"artist_image"`
	AlbumTitle string `json:"album_title"`
}