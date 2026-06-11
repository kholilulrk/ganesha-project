package models

import (
	"time"
	"gorm.io/gorm"
)

type Announcement struct {
	gorm.Model
	Title     string    `json:"title" gorm:"not null"`
	Content   string    `json:"content" gorm:"type:text"`
	StartAt   time.Time `json:"start_at"`
	EndAt     time.Time `json:"end_at"`
	IsActive  bool      `json:"is_active" gorm:"default:true"`
	CreatedBy uint      `json:"created_by"`
}
