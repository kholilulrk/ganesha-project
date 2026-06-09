package controllers

import (
	"net/http"
	"website-backend/models"

	"github.com/gin-gonic/gin"
)

func GetComments(c *gin.Context) {
	jobID := c.Param("id")
	var comments []models.Comment
	if err := models.DB.Where("job_id = ?", jobID).Order("created_at ASC").Find(&comments).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"comments": comments})
}

func AddComment(c *gin.Context) {
	jobID := c.Param("id")
	userID, _ := c.Get("user_id")

	var input struct {
		Text     string `json:"text" binding:"required"`
		ParentID *uint  `json:"parent_id"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	if err := models.DB.First(&user, userID.(uint)).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "User not found"})
		return
	}

	comment := models.Comment{
		JobID:    parseUint(jobID),
		UserID:   userID.(uint),
		Name:     user.Name,
		Text:     input.Text,
		ParentID: input.ParentID,
	}
	if err := models.DB.Create(&comment).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"comment": comment})
}

func StoreSharedComment(c *gin.Context) {
	token := c.Param("token")
	var job models.Job
	if err := models.DB.Where("share_token = ?", token).First(&job).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Link tidak valid"})
		return
	}

	var input struct {
		Name     string `json:"name" binding:"required"`
		Text     string `json:"text" binding:"required"`
		ParentID *uint  `json:"parent_id"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	comment := models.Comment{
		JobID:    job.ID,
		Name:     input.Name,
		Text:     input.Text,
		ParentID: input.ParentID,
	}
	if err := models.DB.Create(&comment).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"comment": comment})
}

func DeleteComment(c *gin.Context) {
	commentID := c.Param("commentId")
	userID, _ := c.Get("user_id")

	var comment models.Comment
	if err := models.DB.First(&comment, commentID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Comment not found"})
		return
	}
	if comment.UserID != userID.(uint) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Tidak bisa menghapus komentar orang lain"})
		return
	}
	if err := models.DB.Delete(&comment).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Comment deleted"})
}
