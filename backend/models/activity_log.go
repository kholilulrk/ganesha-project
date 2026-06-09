package models

import (
	"fmt"
	"time"

	"gorm.io/gorm"
)

type ActivityLog struct {
	gorm.Model
	UserID     uint   `json:"user_id"`
	Username   string `json:"username"`
	Role       string `json:"role"`
	Action     string `json:"action"`
	Resource   string `json:"resource"`
	ResourceID string `json:"resource_id"`
	Detail     string `json:"detail"`
	IPAddress  string `json:"ip_address"`
}

func CleanupOldActivityLogs() {
	days := GetActivityLogRetentionDays()
	cutoff := time.Now().AddDate(0, 0, -days)
	DB.Where("created_at < ?", cutoff).Delete(&ActivityLog{})
}

func GetActivityLogRetentionDays() int {
	var setting AppSetting
	if err := DB.Where("\"key\" = ?", "activity_log_retention_days").First(&setting).Error; err != nil {
		return 30
	}
	days := 0
	fmt.Sscanf(setting.Value, "%d", &days)
	if days < 1 {
		return 30
	}
	return days
}

func SetActivityLogRetentionDays(days int) {
	DB.Where("\"key\" = ?", "activity_log_retention_days").Assign(AppSetting{Value: fmt.Sprintf("%d", days)}).FirstOrCreate(&AppSetting{Key: "activity_log_retention_days"})
}
