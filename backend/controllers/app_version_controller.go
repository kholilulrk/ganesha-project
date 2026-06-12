package controllers

import (
	"net/http"
	"website-backend/config"

	"github.com/gin-gonic/gin"
)

func GetAppVersion(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"latest_version": config.AppConfig.AppLatestVersion,
		"download_url":   config.AppConfig.AppDownloadURL,
	})
}
