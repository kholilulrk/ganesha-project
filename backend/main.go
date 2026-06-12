package main

import (
	"log"
	"time"
	"website-backend/config"
	"website-backend/models"
	"website-backend/routes"
	"website-backend/services"

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

	go func() {
		loc, err := time.LoadLocation("Asia/Jakarta")
		if err != nil {
			log.Printf("SCHEDULER: failed to load Asia/Jakarta: %v", err)
			return
		}
		for {
			now := time.Now().In(loc)
			if now.Hour() == 8 && now.Minute() == 0 {
				services.SendAttendanceReminders()
			}
			if now.Hour() == 17 && now.Minute() == 0 {
				services.SendOvertimeReminders()
			}
			time.Sleep(1 * time.Minute)
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
