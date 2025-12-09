package main

import (
	"github.com/gin-gonic/gin"
	"github.com/giampier/super-app-api/internal/auth"
	"github.com/giampier/super-app-api/internal/db"
	"github.com/giampier/super-app-api/internal/music"
)

func main() {
	db.Connect()
	r := gin.Default()

	// AUTH
	authGroup := r.Group("/auth")
	{
		authGroup.POST("/register", auth.Register)
		authGroup.POST("/login", auth.Login)
		authGroup.POST("/refresh", auth.RefreshToken) // <--- NUEVO (1.1)
		authGroup.POST("/forgot-password", auth.ForgotPassword)
		authGroup.POST("/reset-password", auth.ResetPassword)
	}

	// MUSIC
	musicGroup := r.Group("/music")
	{
		musicGroup.GET("/artists/trending", music.GetTrendingArtists)
		musicGroup.GET("/recommendations/mix", music.GenerateWelcomeMix) // <--- NUEVO (1.3)
		
		musicGroup.GET("/tracks/:id", music.GetTrackDetails)
		musicGroup.GET("/tracks/:id/lyrics", music.GetLyrics) // <--- NUEVO (3.3)
		musicGroup.POST("/sync/track", music.SyncTrack)
	}

	r.Run(":8080")
}