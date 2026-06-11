package controllers

import (
	"fmt"
	"html"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"website-backend/config"
	"website-backend/middleware"
	"website-backend/models"
	"website-backend/services"
)

type JobInput struct {
	Name         string `json:"name" binding:"required"`
	Description  string `json:"description"`
	Value        string `json:"value"`
	ContractDate string `json:"contract_date"`
	Share        string `json:"share"`
	Status       string `json:"status"`
	Dateline     string `json:"dateline"`
	AssignedTo   string `json:"assigned_to"`
	Spektek      string `json:"spektek"`
}

func parseDate(s string) (time.Time, error) {
	if s == "" {
		return time.Time{}, nil
	}
	return time.Parse("2006-01-02", s)
}

func parseJobInput(input JobInput) (models.Job, error) {
	var value float64
	if input.Value != "" {
		v, err := strconv.ParseFloat(input.Value, 64)
		if err != nil {
			return models.Job{}, err
		}
		value = v
	}
	var contractDate time.Time
	if input.ContractDate != "" {
		d, err := time.Parse("2006-01-02", input.ContractDate)
		if err != nil {
			return models.Job{}, err
		}
		contractDate = d
	}
	dateline, err := parseDate(input.Dateline)
	if err != nil {
		return models.Job{}, err
	}
	status := input.Status
	if status == "" {
		status = "pending"
	}
	return models.Job{
		Name:         input.Name,
		Description:  input.Description,
		Value:        value,
		ContractDate: contractDate,
		Share:        input.Share,
		Status:       status,
		Dateline:     dateline,
		AssignedTo:   input.AssignedTo,
		Spektek:      input.Spektek,
	}, nil
}

func GetJobs(c *gin.Context) {
	role, _ := c.Get("role")
	userID, _ := c.Get("user_id")
	roleStr, _ := role.(string)
	currentUserID, _ := userID.(uint)

	var jobs []models.Job
	query := models.DB.Order("created_at DESC")

	if roleStr != "Super Admin" && roleStr != "Administrasi" && roleStr != "Logistic" {
		query = query.Where(
			"? = ANY(string_to_array(share, ',')) AND ? = ANY(string_to_array(assigned_to, ','))",
			roleStr, strconv.FormatUint(uint64(currentUserID), 10),
		)
	}

	status := c.Query("status")
	if status != "" {
		query = query.Where("status = ?", status)
	}

	share := c.Query("share")
	if share != "" {
		query = query.Where("? = ANY(string_to_array(share, ','))", share)
	}

	search := c.Query("search")
	if search != "" {
		query = query.Where("name LIKE ? OR description LIKE ?", "%"+search+"%", "%"+search+"%")
	}

	checklistIncomplete := c.Query("checklist_incomplete")
	if checklistIncomplete == "true" {
		query = query.Where("id IN (SELECT DISTINCT job_id FROM task_checklists WHERE completed = ?)", false)
	} else if checklistIncomplete != "" {
		query = query.Where("id IN (SELECT DISTINCT job_id FROM task_checklists WHERE role = ? AND completed = ?)", checklistIncomplete, false)
	}

	if err := query.Find(&jobs).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if len(jobs) > 0 {
		jobIDs := make([]uint, len(jobs))
		for i, j := range jobs {
			jobIDs[i] = j.ID
		}

		type CountResult struct {
			JobID uint
			Count int64
		}

		var logisticCounts []CountResult
		models.DB.Model(&models.TaskChecklist{}).
			Select("job_id, COUNT(*) as count").
			Where("job_id IN ? AND role = ? AND completed = ?", jobIDs, "Logistic", false).
			Group("job_id").
			Find(&logisticCounts)

		var teknisiCounts []CountResult
		models.DB.Model(&models.TaskChecklist{}).
			Select("job_id, COUNT(*) as count").
			Where("job_id IN ? AND role = ? AND completed = ?", jobIDs, "Teknisi", false).
			Group("job_id").
			Find(&teknisiCounts)

		logisticMap := make(map[uint]int64, len(logisticCounts))
		for _, lc := range logisticCounts {
			logisticMap[lc.JobID] = lc.Count
		}
		teknisiMap := make(map[uint]int64, len(teknisiCounts))
		for _, tc := range teknisiCounts {
			teknisiMap[tc.JobID] = tc.Count
		}

		for i := range jobs {
			jobs[i].UncompletedLogisticCount = logisticMap[jobs[i].ID]
			jobs[i].UncompletedTeknisiCount = teknisiMap[jobs[i].ID]
		}
	}

	c.JSON(http.StatusOK, gin.H{"jobs": jobs})
}

func GetJob(c *gin.Context) {
	id := c.Param("id")
	var job models.Job
	if err := models.DB.First(&job, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Job not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"job": job})
}

func CreateJob(c *gin.Context) {
	role, _ := c.Get("role")
	roleStr, _ := role.(string)
	if !middleware.HasPermission(models.DB, roleStr, "pekerjaan", "create") {
		c.JSON(http.StatusForbidden, gin.H{"error": "Anda tidak memiliki izin untuk membuat pekerjaan"})
		return
	}

	var input JobInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	job, err := parseJobInput(input)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid value or date format"})
		return
	}
	allRoles := []string{"Logistic", "Administrasi"}
	formRoles := splitCSV(job.Share)
	for _, r := range formRoles {
		if r == "Teknisi" {
			allRoles = append([]string{"Teknisi"}, allRoles...)
			break
		}
	}
	job.Share = joinCSV(allRoles)
	if job.AssignedTo == "" && job.Share != "" {
		var users []models.User
		models.DB.Where("role IN (?)", allRoles).Find(&users)
		ids := make([]string, len(users))
		for i, u := range users {
			ids[i] = strconv.FormatUint(uint64(u.ID), 10)
		}
		job.AssignedTo = joinCSV(ids)
	}
	job.GenerateShareToken()
	if err := models.DB.Create(&job).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"job": job})

	services.SendPushToRoles([]string{"Administrasi", "Logistic"},
		"Pekerjaan Baru",
		"Pekerjaan \""+job.Name+"\" telah dibuat",
		"new_job", job.ID, "job",
	)

	if job.AssignedTo != "" {
		assignedIDs := strings.Split(job.AssignedTo, ",")
		for _, idStr := range assignedIDs {
			id, err := strconv.ParseUint(strings.TrimSpace(idStr), 10, 64)
			if err != nil {
				continue
			}
			go services.SendPushToUser(uint(id),
				"Pekerjaan Baru",
				"Pekerjaan \""+job.Name+"\" telah dibuat",
				"new_job", job.ID, "job",
			)
		}
	}
}

func UpdateJob(c *gin.Context) {
	role, _ := c.Get("role")
	roleStr, _ := role.(string)
	if !middleware.HasPermission(models.DB, roleStr, "pekerjaan", "edit") {
		c.JSON(http.StatusForbidden, gin.H{"error": "Anda tidak memiliki izin untuk mengedit pekerjaan"})
		return
	}

	id := c.Param("id")
	var job models.Job
	if err := models.DB.First(&job, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Job not found"})
		return
	}
	var input JobInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	updated, err := parseJobInput(input)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid value or date format"})
		return
	}
	job.Name = updated.Name
	job.Description = updated.Description
	job.Value = updated.Value
	job.ContractDate = updated.ContractDate
	allRoles := []string{"Logistic", "Administrasi"}
	formRoles := splitCSV(updated.Share)
	for _, r := range formRoles {
		if r == "Teknisi" {
			allRoles = append([]string{"Teknisi"}, allRoles...)
			break
		}
	}
	job.Share = joinCSV(allRoles)
	job.Status = updated.Status
	job.Dateline = updated.Dateline
	if updated.AssignedTo == "" {
		var users []models.User
		models.DB.Where("role IN (?)", allRoles).Find(&users)
		ids := make([]string, len(users))
		for i, u := range users {
			ids[i] = strconv.FormatUint(uint64(u.ID), 10)
		}
		job.AssignedTo = joinCSV(ids)
	} else {
		job.AssignedTo = updated.AssignedTo
	}
	job.Spektek = updated.Spektek
	if err := models.DB.Save(&job).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"job": job})
}

func GenerateShareLink(c *gin.Context) {
	id := c.Param("id")
	var job models.Job
	if err := models.DB.First(&job, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Job not found"})
		return
	}
	if job.ShareToken != "" {
		c.JSON(http.StatusOK, gin.H{"share_token": job.ShareToken})
		return
	}
	token := job.GenerateShareToken()
	if err := models.DB.Save(&job).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"share_token": token})
}

func ShowSharedJob(c *gin.Context) {
	token := c.Param("token")
	var job models.Job
	if err := models.DB.Unscoped().Where("share_token = ?", token).First(&job).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Link tidak valid atau sudah tidak berlaku"})
		return
	}

	var teknisiItems []models.TaskChecklist
	models.DB.Where("job_id = ? AND role = ?", job.ID, "Teknisi").Order("created_at ASC").Find(&teknisiItems)

	var logisticItems []models.TaskChecklist
	models.DB.Where("job_id = ? AND role = ?", job.ID, "Logistic").Order("created_at ASC").Find(&logisticItems)

	var comments []models.Comment
	models.DB.Where("job_id = ?", job.ID).Order("created_at ASC").Find(&comments)

	var assignedUsers []models.User
	if job.AssignedTo != "" {
		ids := strings.Split(job.AssignedTo, ",")
		var idsInt []uint
		for _, id := range ids {
			if uid, err := strconv.ParseUint(strings.TrimSpace(id), 10, 64); err == nil {
				idsInt = append(idsInt, uint(uid))
			}
		}
		if len(idsInt) > 0 {
			models.DB.Where("id IN ? AND role = ?", idsInt, "Teknisi").Find(&assignedUsers)
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"job":            job,
		"teknisi_items":  teknisiItems,
		"logistic_items": logisticItems,
		"comments":       comments,
		"assigned_users": assignedUsers,
	})
}

func UpdateJobStatus(c *gin.Context) {
	id := c.Param("id")
	var job models.Job
	if err := models.DB.First(&job, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Job not found"})
		return
	}
	var input struct {
		Status string `json:"status"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	job.Status = input.Status
	if err := models.DB.Save(&job).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"job": job})
}

func CompleteJob(c *gin.Context) {
	id := c.Param("id")
	var job models.Job
	if err := models.DB.First(&job, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Job not found"})
		return
	}
	job.Status = "done"
	if err := models.DB.Save(&job).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"job": job})
}

func DeleteJob(c *gin.Context) {
	role, _ := c.Get("role")
	roleStr, _ := role.(string)
	if !middleware.HasPermission(models.DB, roleStr, "pekerjaan", "delete") {
		c.JSON(http.StatusForbidden, gin.H{"error": "Anda tidak memiliki izin untuk menghapus pekerjaan"})
		return
	}

	id := c.Param("id")
	var job models.Job
	if err := models.DB.First(&job, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Job not found"})
		return
	}
	if err := models.DB.Delete(&job).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Job deleted"})
}

func splitCSV(s string) []string {
	if s == "" {
		return nil
	}
	parts := strings.Split(s, ",")
	result := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			result = append(result, p)
		}
	}
	return result
}

func SharedJobPreview(c *gin.Context) {
	token := c.Param("token")
	var job models.Job
	if err := models.DB.Unscoped().Where("share_token = ?", token).First(&job).Error; err != nil {
		c.Data(http.StatusNotFound, "text/html; charset=utf-8", []byte("<html><head><title>Link Tidak Valid</title></head><body><h2>Link tidak valid atau sudah tidak berlaku</h2></body></html>"))
		return
	}

	appURL := config.AppConfig.AppURL
	title := html.EscapeString(job.Name)
	description := html.EscapeString(job.Description)
	if description == "" {
		description = "Lihat detail pekerjaan"
	}
	if len(description) > 200 {
		description = description[:200]
	}
	frontendURL := fmt.Sprintf("%s/pekerjaan/shared/%s", appURL, token)

	html := fmt.Sprintf(`<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>%s - Ganesha Project</title>
<meta property="og:title" content="%s">
<meta property="og:description" content="%s">
<meta property="og:url" content="%s">
<meta property="og:type" content="website">
<meta property="og:site_name" content="Ganesha Project">
<meta name="twitter:card" content="summary">
<meta http-equiv="refresh" content="0;url=%s">
<link rel="canonical" href="%s">
</head>
<body>
<script>window.location.replace("%s");</script>
</body>
</html>`, title, title, description, frontendURL, frontendURL, frontendURL, frontendURL)

	c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(html))
}

func joinCSV(parts []string) string {
	return strings.Join(parts, ",")
}
