package controllers

import (
	"net/http"
	"time"
	"website-backend/models"
	"website-backend/services"

	"github.com/gin-gonic/gin"
)

type AnnouncementInput struct {
	Title   string `json:"title" binding:"required"`
	Content string `json:"content"`
	StartAt string `json:"start_at" binding:"required"`
	EndAt   string `json:"end_at" binding:"required"`
}

func GetAnnouncements(c *gin.Context) {
	var announcements []models.Announcement
	if err := models.DB.Order("created_at DESC").Find(&announcements).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"announcements": announcements})
}

func GetActiveAnnouncements(c *gin.Context) {
	var announcements []models.Announcement
	if err := models.DB.Where("is_active = ? AND DATE(start_at) <= CURRENT_DATE AND DATE(end_at) >= CURRENT_DATE", true).Order("created_at DESC").Find(&announcements).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"announcements": announcements})
}

func CreateAnnouncement(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var input AnnouncementInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	startAt, err := time.Parse("2006-01-02", input.StartAt)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Format tanggal mulai tidak valid"})
		return
	}

	endAt, err := time.Parse("2006-01-02", input.EndAt)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Format tanggal akhir tidak valid"})
		return
	}

	if endAt.Before(startAt) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Tanggal akhir harus setelah tanggal mulai"})
		return
	}

	currentUserID, _ := userID.(uint)

	announcement := models.Announcement{
		Title:     input.Title,
		Content:   input.Content,
		StartAt:   startAt,
		EndAt:     endAt,
		IsActive:  true,
		CreatedBy: currentUserID,
	}

	if err := models.DB.Create(&announcement).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	go services.SendPushToAllUsers(
		"📢 Pengumuman Baru",
		input.Title,
		"announcement",
		announcement.ID,
		"announcement",
	)

	c.JSON(http.StatusCreated, gin.H{"announcement": announcement})
}

func UpdateAnnouncement(c *gin.Context) {
	id := c.Param("id")
	var announcement models.Announcement
	if err := models.DB.First(&announcement, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Pengumuman tidak ditemukan"})
		return
	}

	var input AnnouncementInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	startAt, err := time.Parse("2006-01-02", input.StartAt)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Format tanggal mulai tidak valid"})
		return
	}

	endAt, err := time.Parse("2006-01-02", input.EndAt)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Format tanggal akhir tidak valid"})
		return
	}

	if endAt.Before(startAt) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Tanggal akhir harus setelah tanggal mulai"})
		return
	}

	announcement.Title = input.Title
	announcement.Content = input.Content
	announcement.StartAt = startAt
	announcement.EndAt = endAt

	if err := models.DB.Save(&announcement).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"announcement": announcement})
}

func ToggleAnnouncement(c *gin.Context) {
	id := c.Param("id")
	var announcement models.Announcement
	if err := models.DB.First(&announcement, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Pengumuman tidak ditemukan"})
		return
	}

	announcement.IsActive = !announcement.IsActive

	if err := models.DB.Save(&announcement).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"announcement": announcement})
}

func DeleteAnnouncement(c *gin.Context) {
	id := c.Param("id")
	var announcement models.Announcement
	if err := models.DB.First(&announcement, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Pengumuman tidak ditemukan"})
		return
	}

	if err := models.DB.Delete(&announcement).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Pengumuman dihapus"})
}
