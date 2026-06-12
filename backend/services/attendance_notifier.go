package services

import (
	"log"
	"time"
	"website-backend/models"
)

func SendAttendanceReminders() {
	loc, err := time.LoadLocation("Asia/Jakarta")
	if err != nil {
		log.Printf("ATTENDANCE NOTIFIER: load location error: %v", err)
		return
	}
	now := time.Now().In(loc)
	today := now.Format("2006-01-02")
	startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, loc)
	startUnix := startOfDay.Unix()

	var users []models.User
	models.DB.Where("role != ?", "Super Admin").Find(&users)
	if len(users) == 0 {
		return
	}

	sent := 0
	for _, u := range users {
		var existing int64
		models.DB.Model(&models.Notification{}).Where("user_id = ? AND type = ? AND created_at >= ?", u.ID, "attendance_reminder", startUnix).Count(&existing)
		if existing > 0 {
			continue
		}
		var attCount int64
		models.DB.Model(&models.Attendance{}).Where("user_id = ? AND date = ?", u.ID, today).Count(&attCount)
		if attCount == 0 {
			SendPushToUser(u.ID, "Absen Hari Ini", "Jangan lupa absen hari ini sebelum jam 17:00!", "attendance_reminder", 0, "")
			sent++
		}
	}
	log.Printf("ATTENDANCE NOTIFIER: sent %d attendance reminders", sent)
}

func SendOvertimeReminders() {
	loc, err := time.LoadLocation("Asia/Jakarta")
	if err != nil {
		log.Printf("ATTENDANCE NOTIFIER: load location error: %v", err)
		return
	}
	now := time.Now().In(loc)
	today := now.Format("2006-01-02")
	startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, loc)
	startUnix := startOfDay.Unix()

	var users []models.User
	models.DB.Where("role != ?", "Super Admin").Find(&users)
	if len(users) == 0 {
		return
	}

	sent := 0
	for _, u := range users {
		var existing int64
		models.DB.Model(&models.Notification{}).Where("user_id = ? AND type = ? AND created_at >= ?", u.ID, "overtime_reminder", startUnix).Count(&existing)
		if existing > 0 {
			continue
		}
		var att models.Attendance
		result := models.DB.Where("user_id = ? AND date = ?", u.ID, today).First(&att)
		if result.Error != nil {
			continue
		}
		if att.Type == "hadir" && att.ClockIn != "" && att.Location != "luar_kota" {
			SendPushToUser(u.ID, "Lembur", "Jam kerja sudah selesai. Klik untuk mulai lembur!", "overtime_reminder", 0, "")
			sent++
		}
	}
	log.Printf("ATTENDANCE NOTIFIER: sent %d overtime reminders", sent)
}
