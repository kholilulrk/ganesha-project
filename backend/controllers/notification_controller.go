package controllers

import (
	"net/http"
	"strconv"
	"website-backend/models"
	"website-backend/services"

	"github.com/gin-gonic/gin"
)

type FCMRegisterInput struct {
	Token string `json:"token" binding:"required"`
}

func RegisterFCMToken(c *gin.Context) {
	userID, _ := c.Get("user_id")
	currentUserID, _ := userID.(uint)

	var input FCMRegisterInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var existing models.FCMToken
	result := models.DB.Where("token = ?", input.Token).First(&existing)
	if result.Error == nil {
		if existing.UserID == currentUserID {
			c.JSON(http.StatusOK, gin.H{"message": "Token already registered"})
			return
		}
		models.DB.Model(&existing).Update("user_id", currentUserID)
		c.JSON(http.StatusOK, gin.H{"message": "Token reassigned"})
		return
	}

	token := models.FCMToken{
		UserID: currentUserID,
		Token:  input.Token,
	}
	if err := models.DB.Create(&token).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menyimpan token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Token registered"})
}

func UnregisterFCMToken(c *gin.Context) {
	userID, _ := c.Get("user_id")
	currentUserID, _ := userID.(uint)

	var input FCMRegisterInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	models.DB.Where("user_id = ? AND token = ?", currentUserID, input.Token).Delete(&models.FCMToken{})
	c.JSON(http.StatusOK, gin.H{"message": "Token unregistered"})
}

func GetNotifications(c *gin.Context) {
	userID, _ := c.Get("user_id")
	currentUserID, _ := userID.(uint)

	var notifications []models.Notification
	models.DB.Where("user_id = ?", currentUserID).Order("created_at DESC").Limit(50).Find(&notifications)

	c.JSON(http.StatusOK, gin.H{"notifications": notifications})
}

func GetUnreadNotificationCount(c *gin.Context) {
	userID, _ := c.Get("user_id")
	currentUserID, _ := userID.(uint)

	var count int64
	models.DB.Model(&models.Notification{}).Where("user_id = ? AND is_read = ?", currentUserID, false).Count(&count)

	c.JSON(http.StatusOK, gin.H{"count": count})
}

func MarkNotificationRead(c *gin.Context) {
	userID, _ := c.Get("user_id")
	currentUserID, _ := userID.(uint)

	id := c.Param("id")
	models.DB.Model(&models.Notification{}).Where("id = ? AND user_id = ?", id, currentUserID).Update("is_read", true)

	c.JSON(http.StatusOK, gin.H{"message": "Marked as read"})
}

func MarkAllNotificationsRead(c *gin.Context) {
	userID, _ := c.Get("user_id")
	currentUserID, _ := userID.(uint)

	models.DB.Model(&models.Notification{}).Where("user_id = ? AND is_read = ?", currentUserID, false).Update("is_read", true)

	c.JSON(http.StatusOK, gin.H{"message": "All marked as read"})
}

func TestFCMPush(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := strconv.ParseUint(userIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	services.SendPushToUser(uint(userID), "Test Notifikasi", "Ini adalah notifikasi test dari server", "test", 0, "")
	c.JSON(http.StatusOK, gin.H{"message": "Test push sent"})
}
