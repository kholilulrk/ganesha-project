package models

import "gorm.io/gorm"

type CalendarEvent struct {
	gorm.Model
	Title       string `json:"title" gorm:"not null"`
	Description string `json:"description"`
	Date        string `json:"date" gorm:"not null"`
	Time        string `json:"time"`
	Color       string `json:"color" gorm:"default:#667eea"`
	CreatedBy   uint   `json:"created_by"`
}
