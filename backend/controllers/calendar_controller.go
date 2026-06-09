package controllers

import (
	"net/http"
	"website-backend/models"

	"github.com/gin-gonic/gin"
)

func GetCalendarEvents(c *gin.Context) {
	var events []models.CalendarEvent
	if err := models.DB.Order("date ASC, time ASC").Find(&events).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"events": events})
}

func CreateCalendarEvent(c *gin.Context) {
	currentUserID := getCurrentUserID(c)

	var input struct {
		Title       string `json:"title" binding:"required"`
		Description string `json:"description"`
		Date        string `json:"date" binding:"required"`
		Time        string `json:"time"`
		Color       string `json:"color"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	color := input.Color
	if color == "" {
		color = "#667eea"
	}

	event := models.CalendarEvent{
		Title:       input.Title,
		Description: input.Description,
		Date:        input.Date,
		Time:        input.Time,
		Color:       color,
		CreatedBy:   currentUserID,
	}

	if err := models.DB.Create(&event).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"event": event})
}

func UpdateCalendarEvent(c *gin.Context) {
	id := c.Param("id")

	var event models.CalendarEvent
	if err := models.DB.First(&event, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Event not found"})
		return
	}

	var input struct {
		Title       string `json:"title"`
		Description string `json:"description"`
		Date        string `json:"date"`
		Time        string `json:"time"`
		Color       string `json:"color"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if input.Title != "" {
		event.Title = input.Title
	}
	if input.Description != "" {
		event.Description = input.Description
	}
	if input.Date != "" {
		event.Date = input.Date
	}
	event.Time = input.Time
	if input.Color != "" {
		event.Color = input.Color
	}

	if err := models.DB.Save(&event).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"event": event})
}

func DeleteCalendarEvent(c *gin.Context) {
	id := c.Param("id")

	var event models.CalendarEvent
	if err := models.DB.First(&event, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Event not found"})
		return
	}

	if err := models.DB.Delete(&event).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Event deleted"})
}
