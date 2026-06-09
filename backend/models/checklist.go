package models

import "gorm.io/gorm"

type TaskChecklist struct {
	gorm.Model
	JobID     uint    `json:"job_id" gorm:"not null;index"`
	Role      string  `json:"role" gorm:"not null"`
	Item      string  `json:"item" gorm:"not null"`
	Completed bool    `json:"completed" gorm:"default:false"`
	Status    string  `json:"status" gorm:"default:pending"`
	CreatedBy uint    `json:"created_by"`
	Images    string  `json:"images"`
	Quantity  int     `json:"quantity" gorm:"default:0"`
	Unit      string  `json:"unit"`
	Notes     string  `json:"notes"`
	Price     float64 `json:"price" gorm:"default:0"`
}
