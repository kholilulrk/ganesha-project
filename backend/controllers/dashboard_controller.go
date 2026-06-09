package controllers

import (
	"net/http"
	"strconv"
	"time"
	"website-backend/models"

	"github.com/gin-gonic/gin"
)

func GetDashboardStats(c *gin.Context) {
	role, _ := c.Get("role")
	userID, _ := c.Get("user_id")
	roleStr, _ := role.(string)
	currentUserID, _ := userID.(uint)

	isAdmin := roleStr == "Super Admin" || roleStr == "Administrasi" || roleStr == "Logistic"

	var pendingJobs int64
	jobQuery := models.DB.Model(&models.Job{}).Where("status = ?", "pending")

	if !isAdmin {
		jobQuery = jobQuery.Where(
			"? = ANY(string_to_array(share, ',')) AND ? = ANY(string_to_array(assigned_to, ','))",
			roleStr, strconv.FormatUint(uint64(currentUserID), 10),
		)
	}
	jobQuery.Count(&pendingJobs)

	userIDStr := strconv.FormatUint(uint64(currentUserID), 10)

	var uncompletedTeknisi int64
	teknisiQuery := models.DB.Model(&models.Job{}).
		Where("id IN (SELECT DISTINCT job_id FROM task_checklists WHERE role = ? AND completed = ?)", "Teknisi", false)
	if !isAdmin {
		teknisiQuery = teknisiQuery.Where(
			"? = ANY(string_to_array(share, ',')) AND ? = ANY(string_to_array(assigned_to, ','))",
			roleStr, strconv.FormatUint(uint64(currentUserID), 10),
		)
	}
	teknisiQuery.Count(&uncompletedTeknisi)

	var uncompletedLogistic int64
	logisticQuery := models.DB.Model(&models.Job{}).
		Where("id IN (SELECT DISTINCT job_id FROM task_checklists WHERE role = ? AND completed = ?)", "Logistic", false)
	if !isAdmin {
		logisticQuery = logisticQuery.Where(
			"? = ANY(string_to_array(share, ',')) AND ? = ANY(string_to_array(assigned_to, ','))",
			roleStr, strconv.FormatUint(uint64(currentUserID), 10),
		)
	}
	logisticQuery.Count(&uncompletedLogistic)

	var pendingJobsList []models.Job
	jobListQuery := models.DB.Where("status = ?", "pending").Order("created_at DESC")
	if !isAdmin {
		jobListQuery = jobListQuery.Where(
			"? = ANY(string_to_array(share, ',')) AND ? = ANY(string_to_array(assigned_to, ','))",
			roleStr, userIDStr,
		)
	}
	jobListQuery.Limit(5).Find(&pendingJobsList)

	var expiringSurats []models.Surat
	now := time.Now()
	oneWeek := now.AddDate(0, 0, 7)
	models.DB.Where("masa_berlaku BETWEEN ? AND ?", now, oneWeek).Order("masa_berlaku ASC").Find(&expiringSurats)

	var uncompletedJobs int64
	uncompletedQuery := models.DB.Model(&models.Job{}).
		Where("status != ? AND id IN (SELECT DISTINCT job_id FROM task_checklists WHERE completed = ?)", "done", false)
	if !isAdmin {
		uncompletedQuery = uncompletedQuery.Where(
			"? = ANY(string_to_array(share, ',')) AND ? = ANY(string_to_array(assigned_to, ','))",
			roleStr, strconv.FormatUint(uint64(currentUserID), 10),
		)
	}
	uncompletedQuery.Count(&uncompletedJobs)

	var totalJobs int64
	totalQuery := models.DB.Model(&models.Job{})
	if !isAdmin {
		totalQuery = totalQuery.Where(
			"? = ANY(string_to_array(share, ',')) AND ? = ANY(string_to_array(assigned_to, ','))",
			roleStr, strconv.FormatUint(uint64(currentUserID), 10),
		)
	}
	totalQuery.Count(&totalJobs)

	var completedJobs int64
	completedQuery := models.DB.Model(&models.Job{}).Where("status = ?", "done")
	if !isAdmin {
		completedQuery = completedQuery.Where(
			"? = ANY(string_to_array(share, ',')) AND ? = ANY(string_to_array(assigned_to, ','))",
			roleStr, strconv.FormatUint(uint64(currentUserID), 10),
		)
	}
	completedQuery.Count(&completedJobs)

	c.JSON(http.StatusOK, gin.H{
		"pending_jobs":         pendingJobs,
		"total_jobs":           totalJobs,
		"completed_jobs":       completedJobs,
		"uncompleted_teknisi":  uncompletedTeknisi,
		"uncompleted_logistic": uncompletedLogistic,
		"uncompleted_jobs":     uncompletedJobs,
		"recent_pending":       pendingJobsList,
		"expiring_surats":      expiringSurats,
	})
}
