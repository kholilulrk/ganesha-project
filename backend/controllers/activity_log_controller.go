package controllers

import (
	"net/http"
	"website-backend/models"

	"github.com/gin-gonic/gin"
)

func GetActivityLogs(c *gin.Context) {
	role, _ := c.Get("role")
	if role != "Super Admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Only Super Admin can view activity logs"})
		return
	}

	var logs []models.ActivityLog
	if err := models.DB.Order("created_at DESC").Find(&logs).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"activity_logs": logs})
}

func GetActivityLogSettings(c *gin.Context) {
	role, _ := c.Get("role")
	if role != "Super Admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Only Super Admin can view activity log settings"})
		return
	}

	days := models.GetActivityLogRetentionDays()
	c.JSON(http.StatusOK, gin.H{"retention_days": days})
}

func UpdateActivityLogSettings(c *gin.Context) {
	role, _ := c.Get("role")
	if role != "Super Admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Only Super Admin can update activity log settings"})
		return
	}

	var input struct {
		RetentionDays int `json:"retention_days"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}
	if input.RetentionDays < 1 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Retention days must be at least 1"})
		return
	}

	models.SetActivityLogRetentionDays(input.RetentionDays)
	c.JSON(http.StatusOK, gin.H{"message": "Retention days updated", "retention_days": input.RetentionDays})
}
