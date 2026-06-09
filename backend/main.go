package main

import (
	"time"
	"website-backend/config"
	"website-backend/models"
	"website-backend/routes"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func main() {
	config.LoadConfig()

	if err := models.ConnectDatabase(); err != nil {
		panic("Failed to connect to database: " + err.Error())
	}

	go func() {
		for {
			models.CleanupOldActivityLogs()
			time.Sleep(1 * time.Hour)
		}
	}()

	r := gin.Default()
	r.MaxMultipartMemory = 50 << 20 // 50 MB

	r.Use(cors.New(cors.Config{
		AllowAllOrigins:  true,
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		AllowCredentials: false,
	}))

	routes.SetupRouter(r)

	r.Run("0.0.0.0:" + config.AppConfig.ServerPort)
}
