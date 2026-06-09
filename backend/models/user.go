package models

import "gorm.io/gorm"

type User struct {
	gorm.Model
	Name     string `json:"name" gorm:"not null"`
	Username string `json:"username" gorm:"unique;not null"`
	Role     string `json:"role" gorm:"not null"`
	Password string `json:"-" gorm:"not null"`
	Phone    string `json:"phone"`
	Photo    string `json:"photo"`
}
