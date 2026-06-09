package models

import "time"

type AppSetting struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Key       string    `gorm:"uniqueIndex;size:100;not null" json:"key"`
	Value     string    `gorm:"size:255;not null" json:"value"`
	UpdatedAt time.Time `json:"updated_at"`
}
