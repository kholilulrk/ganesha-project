package middleware

import (
	"website-backend/models"

	"gorm.io/gorm"
)

func HasPermission(db *gorm.DB, role, resource, action string) bool {
	if role == "Super Admin" {
		return true
	}

	var count int64
	db.Model(&models.Permission{}).
		Where("role = ? AND resource = ? AND action = ?", role, resource, action).
		Count(&count)

	return count > 0
}
