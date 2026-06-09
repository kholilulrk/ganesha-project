package models

import "gorm.io/gorm"

type Comment struct {
	gorm.Model
	JobID    uint   `json:"job_id" gorm:"not null;index"`
	UserID   uint   `json:"user_id"`
	Name     string `json:"name" gorm:"not null"`
	Text     string `json:"text" gorm:"type:text;not null"`
	ParentID *uint  `json:"parent_id"`
}
