package controllers

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
	"website-backend/models"
	"website-backend/services"

	"github.com/gin-gonic/gin"
)

var allowedExtensions = map[string][]string{
	"PDF":   {".pdf"},
	"Excel": {".xls", ".xlsx"},
	"Word":  {".doc", ".docx"},
	"JPG":   {".jpg", ".jpeg"},
	"PNG":   {".png"},
}

type DocumentInput struct {
	NamaDokumen string `json:"nama_dokumen" binding:"required"`
	TipeDokumen string `json:"tipe_dokumen" binding:"required"`
	Deskripsi   string `json:"deskripsi"`
	ShareMode   string `json:"share_mode"`
	SharedTo    string `json:"shared_to"`
}

func GetDocuments(c *gin.Context) {
	userID, _ := c.Get("user_id")
	role, _ := c.Get("role")
	roleStr, _ := role.(string)
	currentUserID, _ := userID.(uint)

	var documents []models.Document
	query := models.DB.Order("created_at DESC")

	if roleStr != "Super Admin" && roleStr != "Administrasi" {
		userIDStr := strconv.FormatUint(uint64(currentUserID), 10)
		query = query.Where(
			"(share_mode = ? OR (share_mode = ? AND ? = ANY(string_to_array(shared_to, ','))))",
			"all", "specific", userIDStr,
		)
	}

	if err := query.Find(&documents).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"documents": documents})
}

func GetDocument(c *gin.Context) {
	id := c.Param("id")
	var doc models.Document
	if err := models.DB.First(&doc, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Document not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"document": doc})
}

func CreateDocument(c *gin.Context) {
	userID, _ := c.Get("user_id")
	currentUserID, _ := userID.(uint)

	namaDokumen := c.PostForm("nama_dokumen")
	tipeDokumen := c.PostForm("tipe_dokumen")
	deskripsi := c.PostForm("deskripsi")
	shareMode := c.PostForm("share_mode")
	sharedTo := c.PostForm("shared_to")

	if namaDokumen == "" || tipeDokumen == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "nama_dokumen and tipe_dokumen required"})
		return
	}

	exts, ok := allowedExtensions[tipeDokumen]
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Tipe dokumen tidak valid"})
		return
	}

	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "File required"})
		return
	}

	ext := strings.ToLower(filepath.Ext(file.Filename))
	valid := false
	for _, e := range exts {
		if ext == e {
			valid = true
			break
		}
	}
	if !valid {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("File harus bertipe %s", tipeDokumen)})
		return
	}

	if shareMode == "" {
		shareMode = "all"
	}

	uploadDir := "uploads/documents"
	if err := os.MkdirAll(uploadDir, os.ModePerm); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upload directory"})
		return
	}

	filename := fmt.Sprintf("%d_%s", time.Now().UnixMilli(), file.Filename)
	dst := filepath.Join(uploadDir, filename)

	if err := c.SaveUploadedFile(file, dst); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
		return
	}

	doc := models.Document{
		NamaDokumen: namaDokumen,
		TipeDokumen: tipeDokumen,
		FilePath:    dst,
		Deskripsi:   deskripsi,
		ShareMode:   shareMode,
		SharedTo:    sharedTo,
		UploadedBy:  currentUserID,
	}

	if err := models.DB.Create(&doc).Error; err != nil {
		os.Remove(dst)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"document": doc})

	go services.SendPushToAllUsers(
		"Dokumen Baru",
		"Dokumen \""+doc.NamaDokumen+"\" telah diupload",
		"new_document", doc.ID, "document",
	)
}

func UpdateDocument(c *gin.Context) {
	id := c.Param("id")
	var doc models.Document
	if err := models.DB.First(&doc, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Document not found"})
		return
	}

	var input DocumentInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	doc.NamaDokumen = input.NamaDokumen
	doc.TipeDokumen = input.TipeDokumen
	doc.Deskripsi = input.Deskripsi
	if input.ShareMode != "" {
		doc.ShareMode = input.ShareMode
	}
	doc.SharedTo = input.SharedTo

	if err := models.DB.Save(&doc).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"document": doc})
}

func DeleteDocument(c *gin.Context) {
	id := c.Param("id")
	var doc models.Document
	if err := models.DB.First(&doc, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Document not found"})
		return
	}

	os.Remove(doc.FilePath)
	models.DB.Delete(&doc)

	c.JSON(http.StatusOK, gin.H{"message": "Document deleted"})
}
