package models

import "gorm.io/gorm"

type Attendance struct {
	gorm.Model
	UserID      uint   `json:"user_id" gorm:"not null;uniqueIndex:idx_user_date"`
	Date        string `json:"date" gorm:"not null;uniqueIndex:idx_user_date"`
	Type        string `json:"type" gorm:"default:hadir"`
	Location    string `json:"location" gorm:"default:kantor"`
	Reason      string `json:"reason"`
	ClockIn     string `json:"clock_in"`
	ClockOut    string `json:"clock_out"`
	LemburStart string `json:"lembur_start"`
	LemburEnd   string `json:"lembur_end"`

	User User `json:"user" gorm:"foreignKey:UserID"`
}
