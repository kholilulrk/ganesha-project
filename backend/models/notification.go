package models

type FCMToken struct {
	ID     uint   `gorm:"primaryKey" json:"id"`
	UserID uint   `gorm:"not null;index" json:"user_id"`
	Token  string `gorm:"not null;uniqueIndex:idx_fcm_token" json:"token"`
}

func (FCMToken) TableName() string {
	return "fcm_tokens"
}

type Notification struct {
	ID        uint   `gorm:"primaryKey" json:"id"`
	UserID    uint   `gorm:"not null;index" json:"user_id"`
	Title     string `gorm:"not null" json:"title"`
	Body      string `gorm:"not null" json:"body"`
	Type      string `gorm:"not null;index" json:"type"`
	RefID     uint   `json:"ref_id"`
	RefType   string `json:"ref_type"`
	IsRead    bool   `gorm:"not null;default:false;index" json:"is_read"`
	CreatedAt int64  `gorm:"autoCreateTime" json:"created_at"`
}

func (Notification) TableName() string {
	return "notifications"
}
