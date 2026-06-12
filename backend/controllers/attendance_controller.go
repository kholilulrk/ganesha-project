package controllers

import (
	"fmt"
	"math"
	"net/http"
	"time"
	"website-backend/models"

	"github.com/gin-gonic/gin"
)

func getCurrentTime() time.Time {
	loc, _ := time.LoadLocation("Asia/Jakarta")
	return time.Now().In(loc)
}

func todayDateString() string {
	return getCurrentTime().Format("2006-01-02")
}

func currentTimeString() string {
	return getCurrentTime().Format("15:04")
}

func formatDuration(clockIn, clockOut string) (string, int, int) {
	layout := "15:04"
	in, err1 := time.Parse(layout, clockIn)
	out, err2 := time.Parse(layout, clockOut)
	if err1 != nil || err2 != nil {
		return "-", 0, 0
	}
	if out.Before(in) {
		out = out.Add(24 * time.Hour)
	}
	diff := out.Sub(in)
	hours := int(math.Floor(diff.Hours()))
	minutes := int(math.Round(diff.Minutes())) % 60
	if hours > 0 || minutes > 0 {
		return fmt.Sprintf("%d jam %d menit", hours, minutes), hours, minutes
	}
	return "-", 0, 0
}

func GetTodayAttendance(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := userID.(uint)
	today := todayDateString()

	var att models.Attendance
	err := models.DB.Where("user_id = ? AND date = ?", uid, today).Preload("User").First(&att).Error
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"attendance": nil})
		return
	}
	c.JSON(http.StatusOK, gin.H{"attendance": att})
}

func AttendanceHadir(c *gin.Context) {
	userID, _ := c.Get("user_id")
	role, _ := c.Get("role")
	uid, _ := userID.(uint)
	roleStr, _ := role.(string)

	if roleStr == "Super Admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Super Admin tidak perlu absen"})
		return
	}

	now := getCurrentTime()
	hour := now.Hour()
	minute := now.Minute()
	totalMinutes := hour*60 + minute

	if totalMinutes < 30 || hour >= 17 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Waktu absen: 00:30 - 17:00"})
		return
	}

	var input struct {
		Location string `json:"location"`
	}
	c.ShouldBindJSON(&input)
	if input.Location != "luar_kota" && input.Location != "kantor" {
		input.Location = "kantor"
	}

	today := todayDateString()
	clockIn := currentTimeString()

	var existing models.Attendance
	err := models.DB.Where("user_id = ? AND date = ?", uid, today).First(&existing).Error
	if err == nil {
		if existing.Type == "hadir" || existing.Type == "lembur" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Sudah absen hari ini"})
			return
		}
	}

	att := models.Attendance{
		UserID:   uid,
		Date:     today,
		Type:     "hadir",
		Location: input.Location,
		ClockIn:  clockIn,
	}

	if err := models.DB.Create(&att).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menyimpan absensi"})
		return
	}

	models.DB.Preload("User").First(&att, att.ID)
	c.JSON(http.StatusCreated, gin.H{"attendance": att, "message": "Absensi berhasil"})
}

func AttendanceTidakHadir(c *gin.Context) {
	userID, _ := c.Get("user_id")
	role, _ := c.Get("role")
	uid, _ := userID.(uint)
	roleStr, _ := role.(string)

	if roleStr == "Super Admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Super Admin tidak perlu absen"})
		return
	}

	var input struct {
		Reason string `json:"reason"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Alasan wajib diisi"})
		return
	}

	today := todayDateString()

	var existing models.Attendance
	err := models.DB.Where("user_id = ? AND date = ?", uid, today).First(&existing).Error
	if err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Sudah absen hari ini"})
		return
	}

	att := models.Attendance{
		UserID: uid,
		Date:   today,
		Type:   "tidak_hadir",
		Reason: input.Reason,
	}

	if err := models.DB.Create(&att).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menyimpan absensi"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"attendance": att, "message": "Absensi berhasil"})
}

func AttendanceLemburStart(c *gin.Context) {
	userID, _ := c.Get("user_id")
	role, _ := c.Get("role")
	uid, _ := userID.(uint)
	roleStr, _ := role.(string)

	if roleStr == "Super Admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Super Admin tidak perlu lembur"})
		return
	}

	now := getCurrentTime()
	hour := now.Hour()
	if hour < 17 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Lembur hanya bisa dimulai pukul 17:00 - 24:00"})
		return
	}

	today := todayDateString()

	var existing models.Attendance
	err := models.DB.Where("user_id = ? AND date = ?", uid, today).First(&existing).Error
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Belum absen hari ini"})
		return
	}

	if existing.Location == "luar_kota" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Absen luar kota tidak bisa lembur"})
		return
	}

	if existing.Type == "lembur" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Sudah mulai lembur"})
		return
	}

	if existing.Type != "hadir" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Hanya bisa lembur jika sudah absen hadir"})
		return
	}

	existing.Type = "lembur"
	if err := models.DB.Save(&existing).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menyimpan lembur"})
		return
	}

	models.DB.Preload("User").First(&existing, existing.ID)
	c.JSON(http.StatusOK, gin.H{"attendance": existing, "message": "Lembur dimulai"})
}

func AttendanceLemburEnd(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := userID.(uint)

	today := todayDateString()

	var existing models.Attendance
	err := models.DB.Where("user_id = ? AND date = ? AND type = ?", uid, today, "lembur").First(&existing).Error
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Belum mulai lembur"})
		return
	}

	if existing.ClockOut != "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Lembur sudah diakhiri"})
		return
	}

	existing.ClockOut = currentTimeString()
	if err := models.DB.Save(&existing).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menyimpan"})
		return
	}

	models.DB.Preload("User").First(&existing, existing.ID)
	c.JSON(http.StatusOK, gin.H{"attendance": existing, "message": "Lembur selesai"})
}

func GetAttendanceReport(c *gin.Context) {
	role, _ := c.Get("role")
	roleStr, _ := role.(string)

	if roleStr != "Super Admin" && roleStr != "Administrasi" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Tidak memiliki akses"})
		return
	}

	dateFilter := c.Query("date")
	roleFilter := c.Query("role")

	query := models.DB.Model(&models.Attendance{}).Preload("User")

	if dateFilter != "" {
		query = query.Where("date = ?", dateFilter)
	} else {
		query = query.Where("date = ?", todayDateString())
	}

	if roleFilter != "" {
		query = query.Where("user_id IN (SELECT id FROM users WHERE role = ?)", roleFilter)
	}

	var records []models.Attendance
	if err := query.Order("created_at DESC").Find(&records).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	type AttendanceReportItem struct {
		models.Attendance
		TypeDisplay  string `json:"type_display"`
		DurasiLembur string `json:"durasi_lembur"`
		LemburJam    int    `json:"lembur_jam"`
		LemburMenit  int    `json:"lembur_menit"`
	}

	var items []AttendanceReportItem
	for _, r := range records {
		item := AttendanceReportItem{Attendance: r}
		if r.Type == "hadir" {
			if r.Location == "luar_kota" {
				item.TypeDisplay = "Hadir (Luar Kota)"
			} else {
				item.TypeDisplay = "Hadir"
			}
		} else if r.Type == "lembur" {
			item.TypeDisplay = "Hadir + Lembur"
			if r.ClockOut != "" {
				durasi, jam, menit := formatDuration(r.ClockIn, r.ClockOut)
				item.DurasiLembur = durasi
				item.LemburJam = jam
				item.LemburMenit = menit
			} else {
				item.DurasiLembur = "Sedang lembur"
			}
		} else if r.Type == "tidak_hadir" {
			item.TypeDisplay = "Tidak Hadir"
		}
		items = append(items, item)
	}

	c.JSON(http.StatusOK, gin.H{"attendance": items})
}

func UpdateAttendanceRecord(c *gin.Context) {
	userRole, _ := c.Get("role")
	if userRole != "Super Admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Hanya Super Admin"})
		return
	}

	id := c.Param("id")
	var att models.Attendance
	if err := models.DB.First(&att, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Record tidak ditemukan"})
		return
	}

	var input struct {
		Type     string `json:"type"`
		Location string `json:"location"`
		Reason   string `json:"reason"`
		ClockIn  string `json:"clock_in"`
		ClockOut string `json:"clock_out"`
		Date     string `json:"date"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if input.Type != "" {
		att.Type = input.Type
	}
	if input.Location != "" {
		att.Location = input.Location
	}
	if input.Reason != "" {
		att.Reason = input.Reason
	}
	if input.ClockIn != "" {
		att.ClockIn = input.ClockIn
	}
	if input.ClockOut != "" {
		att.ClockOut = input.ClockOut
	}
	if input.Date != "" {
		att.Date = input.Date
	}

	if err := models.DB.Save(&att).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal update"})
		return
	}

	models.DB.Preload("User").First(&att, att.ID)
	c.JSON(http.StatusOK, gin.H{"attendance": att})
}

func DeleteAttendanceRecord(c *gin.Context) {
	userRole, _ := c.Get("role")
	if userRole != "Super Admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Hanya Super Admin"})
		return
	}

	id := c.Param("id")
	var att models.Attendance
	if err := models.DB.First(&att, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Record tidak ditemukan"})
		return
	}

	if err := models.DB.Delete(&att).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal hapus"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Record dihapus"})
}


