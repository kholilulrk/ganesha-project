package middleware

import (
	"fmt"
	"strings"
	"website-backend/models"

	"github.com/gin-gonic/gin"
)

func ActivityLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		role, _ := c.Get("role")
		if role == "Super Admin" {
			return
		}
		if role == nil || role == "" {
			return
		}

		method := c.Request.Method
		if method == "GET" {
			return
		}

		status := c.Writer.Status()
		if status < 200 || status >= 300 {
			return
		}

		action := methodToAction(method)
		if action == "" {
			return
		}

		userID, _ := c.Get("user_id")
		username, _ := c.Get("username")
		roleStr, _ := c.Get("role")

		uid := uint(0)
		switch v := userID.(type) {
		case float64:
			uid = uint(v)
		case uint:
			uid = v
		case int:
			uid = uint(v)
		case int64:
			uid = uint(v)
		}

		log := models.ActivityLog{
			UserID:   uid,
			Username:  fmt.Sprintf("%v", username),
			Role:      fmt.Sprintf("%v", roleStr),
			Action:    action,
			Detail:    pathToPage(c.FullPath()),
		}

		models.DB.Create(&log)
	}
}

func methodToAction(method string) string {
	switch method {
	case "POST":
		return "create"
	case "PUT", "PATCH":
		return "update"
	case "DELETE":
		return "delete"
	}
	return ""
}

func pathToPage(fullPath string) string {
	path := strings.TrimPrefix(fullPath, "/")
	if strings.HasPrefix(path, "jobs/") && strings.Contains(path, "/checklist") {
		return "Checklist Teknisi"
	}
	if strings.HasPrefix(path, "jobs/") && strings.Contains(path, "/documents") {
		return "Dokumen Pekerjaan"
	}
	if strings.HasPrefix(path, "jobs/") && strings.Contains(path, "/comments") {
		return "Komentar"
	}
	if strings.HasPrefix(path, "jobs/") {
		return "Pekerjaan"
	}

	switch {
	case strings.HasPrefix(path, "dashboard"):
		return "Dashboard"
	case strings.HasPrefix(path, "permissions"):
		return "Atur Akses"
	case strings.HasPrefix(path, "profile"):
		return "Profile"
	case strings.HasPrefix(path, "users"):
		return "Pengguna"
	case strings.HasPrefix(path, "upload"):
		return "Upload"
	case strings.HasPrefix(path, "sph"):
		return "Kalkulasi SPH"
	case strings.HasPrefix(path, "surats"):
		return "Monitoring Surat"
	case strings.HasPrefix(path, "documents"):
		return "Dokumen"
	case strings.HasPrefix(path, "todos"):
		return "To-do List"
	case strings.HasPrefix(path, "calendar-events"):
		return "Kalender"
	case strings.HasPrefix(path, "activity-logs"):
		return "Activity Log"
	}
	return fullPath
}
