package controllers

import (
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"
	"website-backend/models"

	"github.com/gin-gonic/gin"
)

func GetJobDocuments(c *gin.Context) {
	jobID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid job ID"})
		return
	}

	var documents []models.JobDocument
	models.DB.Where("job_id = ?", jobID).Find(&documents)

	var verifications []models.JobVerification
	models.DB.Where("job_id = ?", jobID).Find(&verifications)

	var job models.Job
	if err := models.DB.First(&job, jobID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Job not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"documents":     documents,
		"verifications": verifications,
		"progress":      job.Progress,
		"tdm":           job.TDM,
		"tds":           job.TDS,
	})
}

func UploadJobDocument(c *gin.Context) {
	jobID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid job ID"})
		return
	}

	docType := c.PostForm("doc_type")
	if docType == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "doc_type required"})
		return
	}

	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "file required"})
		return
	}

	ext := filepath.Ext(file.Filename)
	dir := filepath.Join("uploads", "documents", strconv.FormatUint(jobID, 10))
	os.MkdirAll(dir, 0755)

	filename := docType + "_" + strconv.FormatInt(time.Now().Unix(), 10) + ext
	savePath := filepath.Join(dir, filename)

	if err := c.SaveUploadedFile(file, savePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
		return
	}

	models.DB.Where("job_id = ? AND doc_type = ?", jobID, docType).Delete(&models.JobDocument{})

	doc := models.JobDocument{
		JobID:    uint(jobID),
		DocType:  docType,
		FileName: file.Filename,
		FilePath: savePath,
	}
	if err := models.DB.Create(&doc).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"document": doc})
}

func DeleteJobDocument(c *gin.Context) {
	docID, err := strconv.ParseUint(c.Param("docId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid document ID"})
		return
	}

	var doc models.JobDocument
	if err := models.DB.First(&doc, docID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Document not found"})
		return
	}

	os.Remove(doc.FilePath)
	models.DB.Delete(&doc)

	c.JSON(http.StatusOK, gin.H{"message": "Document deleted"})
}

func UpdateJobDocDates(c *gin.Context) {
	jobID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid job ID"})
		return
	}

	var input struct {
		TDM string `json:"tdm"`
		TDS string `json:"tds"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updates := map[string]interface{}{}
	if input.TDM != "" {
		updates["tdm"] = input.TDM
	}
	if input.TDS != "" {
		updates["tds"] = input.TDS
	}

	if len(updates) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "no fields to update"})
		return
	}

	if err := models.DB.Model(&models.Job{}).Where("id = ?", jobID).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "updated"})
}

func UpdateJobVerification(c *gin.Context) {
	jobID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid job ID"})
		return
	}

	var input struct {
		Step    string `json:"step" binding:"required"`
		Checked bool   `json:"checked"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var verif models.JobVerification
	result := models.DB.Where("job_id = ? AND step = ?", jobID, input.Step).First(&verif)
	if result.Error != nil {
		verif = models.JobVerification{
			JobID:   uint(jobID),
			Step:    input.Step,
			Checked: input.Checked,
		}
		models.DB.Create(&verif)
	} else {
		models.DB.Model(&verif).Update("checked", input.Checked)
	}

	c.JSON(http.StatusOK, gin.H{"verification": verif})
}

func UpdateJobProgress(c *gin.Context) {
	jobID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid job ID"})
		return
	}

	var input struct {
		Progress string `json:"progress"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	models.DB.Model(&models.Job{}).Where("id = ?", jobID).Update("progress", input.Progress)

	c.JSON(http.StatusOK, gin.H{"progress": input.Progress})
}
