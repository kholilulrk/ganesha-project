package controllers

import (
	"net/http"
	"time"
	"website-backend/models"

	"github.com/gin-gonic/gin"
)

type SuratInput struct {
	NamaSurat  string `json:"nama_surat" binding:"required"`
	StartAktif string `json:"start_aktif" binding:"required"`
	JenisSurat string `json:"jenis_surat" binding:"required"`
}

func GetSurats(c *gin.Context) {
	var surats []models.Surat
	if err := models.DB.Order("created_at DESC").Find(&surats).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"surats": surats})
}

func GetSurat(c *gin.Context) {
	id := c.Param("id")
	var surat models.Surat
	if err := models.DB.First(&surat, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Surat not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"surat": surat})
}

func CreateSurat(c *gin.Context) {
	var input SuratInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	startAktif, err := time.Parse("2006-01-02", input.StartAktif)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Format tanggal tidak valid"})
		return
	}

	var masaBerlaku time.Time
	switch input.JenisSurat {
	case "SIK":
		masaBerlaku = startAktif.AddDate(0, 1, 0)
	case "SC":
		masaBerlaku = startAktif.AddDate(0, 3, 0)
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "Jenis surat tidak valid"})
		return
	}

	surat := models.Surat{
		NamaSurat:   input.NamaSurat,
		StartAktif:  startAktif,
		JenisSurat:  input.JenisSurat,
		MasaBerlaku: masaBerlaku,
	}

	if err := models.DB.Create(&surat).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"surat": surat})
}

func UpdateSurat(c *gin.Context) {
	id := c.Param("id")
	var surat models.Surat
	if err := models.DB.First(&surat, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Surat not found"})
		return
	}

	var input SuratInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	startAktif, err := time.Parse("2006-01-02", input.StartAktif)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Format tanggal tidak valid"})
		return
	}

	var masaBerlaku time.Time
	switch input.JenisSurat {
	case "SIK":
		masaBerlaku = startAktif.AddDate(0, 1, 0)
	case "SC":
		masaBerlaku = startAktif.AddDate(0, 3, 0)
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "Jenis surat tidak valid"})
		return
	}

	surat.NamaSurat = input.NamaSurat
	surat.StartAktif = startAktif
	surat.JenisSurat = input.JenisSurat
	surat.MasaBerlaku = masaBerlaku

	if err := models.DB.Save(&surat).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"surat": surat})
}

func DeleteSurat(c *gin.Context) {
	id := c.Param("id")
	var surat models.Surat
	if err := models.DB.First(&surat, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Surat not found"})
		return
	}

	if err := models.DB.Delete(&surat).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Surat deleted"})
}

func GetExpiringSurats(c *gin.Context) {
	now := time.Now()
	oneWeek := now.AddDate(0, 0, 7)

	var surats []models.Surat
	if err := models.DB.Where("masa_berlaku BETWEEN ? AND ?", now, oneWeek).Order("masa_berlaku ASC").Find(&surats).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"surats": surats})
}
