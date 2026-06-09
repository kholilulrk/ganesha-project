package controllers

import (
	"net/http"
	"strconv"
	"website-backend/models"

	"github.com/gin-gonic/gin"
)

func GetSphs(c *gin.Context) {
	var sphs []models.Sph
	if err := models.DB.Preload("Teknisi").Preload("Job").Order("created_at DESC").Find(&sphs).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"sphs": sphs})
}

func GetSph(c *gin.Context) {
	id := c.Param("id")
	var sph models.Sph
	if err := models.DB.Preload("Teknisi").Preload("Job").First(&sph, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "SPH not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"sph": sph})
}

func CreateSph(c *gin.Context) {
	currentUserID := getCurrentUserID(c)

	var input struct {
		JobID               uint                `json:"job_id" binding:"required"`
		NomorSph            string              `json:"nomor_sph"`
		TanggalSph          string              `json:"tanggal_sph"`
		Jenis               string              `json:"jenis"`
		NilaiJasa           float64             `json:"nilai_jasa"`
		NilaiMaterial       float64             `json:"nilai_material"`
		TransportPerHari    float64             `json:"transport_per_hari"`
		UangMakanPerHari    float64             `json:"uang_makan_per_hari"`
		JumlahHari          int                 `json:"jumlah_hari"`
		Akomodasi           float64             `json:"akomodasi"`
		BiayaLain           float64             `json:"biaya_lain"`
		KeteranganBiayaLain string              `json:"keterangan_biaya_lain"`
		Overhead            float64             `json:"overhead"`
		MarginKeuntungan    float64             `json:"margin_keuntungan"`
		Catatan             string              `json:"catatan"`
		Teknisi             []models.SphTeknisi `json:"teknisi"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	jenis := input.Jenis
	if jenis == "" {
		jenis = "dalam_kota"
	}

	sph := models.Sph{
		JobID:               input.JobID,
		NomorSph:            input.NomorSph,
		TanggalSph:          input.TanggalSph,
		Jenis:               jenis,
		NilaiJasa:           input.NilaiJasa,
		NilaiMaterial:       input.NilaiMaterial,
		TransportPerHari:    input.TransportPerHari,
		UangMakanPerHari:    input.UangMakanPerHari,
		JumlahHari:          input.JumlahHari,
		Akomodasi:           input.Akomodasi,
		BiayaLain:           input.BiayaLain,
		KeteranganBiayaLain: input.KeteranganBiayaLain,
		Overhead:            input.Overhead,
		MarginKeuntungan:    input.MarginKeuntungan,
		Catatan:             input.Catatan,
		CreatedBy:           currentUserID,
	}

	tx := models.DB.Begin()
	if err := tx.Create(&sph).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	for i := range input.Teknisi {
		input.Teknisi[i].SphID = sph.ID
	}

	if len(input.Teknisi) > 0 {
		if err := tx.Create(&input.Teknisi).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	}

	tx.Commit()

	models.DB.Preload("Teknisi").Preload("Job").First(&sph, sph.ID)
	c.JSON(http.StatusCreated, gin.H{"sph": sph})
}

func UpdateSph(c *gin.Context) {
	id := c.Param("id")
	var sph models.Sph
	if err := models.DB.First(&sph, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "SPH not found"})
		return
	}

	var input struct {
		JobID               uint                `json:"job_id"`
		NomorSph            string              `json:"nomor_sph"`
		TanggalSph          string              `json:"tanggal_sph"`
		Jenis               string              `json:"jenis"`
		NilaiJasa           float64             `json:"nilai_jasa"`
		NilaiMaterial       float64             `json:"nilai_material"`
		TransportPerHari    float64             `json:"transport_per_hari"`
		UangMakanPerHari    float64             `json:"uang_makan_per_hari"`
		JumlahHari          int                 `json:"jumlah_hari"`
		Akomodasi           float64             `json:"akomodasi"`
		BiayaLain           float64             `json:"biaya_lain"`
		KeteranganBiayaLain string              `json:"keterangan_biaya_lain"`
		Overhead            float64             `json:"overhead"`
		MarginKeuntungan    float64             `json:"margin_keuntungan"`
		Catatan             string              `json:"catatan"`
		Teknisi             []models.SphTeknisi `json:"teknisi"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tx := models.DB.Begin()

	updates := map[string]interface{}{}
	if input.JobID != 0 {
		updates["job_id"] = input.JobID
	}
	updates["nomor_sph"] = input.NomorSph
	updates["tanggal_sph"] = input.TanggalSph
	if input.Jenis != "" {
		updates["jenis"] = input.Jenis
	}
	updates["nilai_jasa"] = input.NilaiJasa
	updates["nilai_material"] = input.NilaiMaterial
	updates["transport_per_hari"] = input.TransportPerHari
	updates["uang_makan_per_hari"] = input.UangMakanPerHari
	updates["jumlah_hari"] = input.JumlahHari
	updates["akomodasi"] = input.Akomodasi
	updates["biaya_lain"] = input.BiayaLain
	updates["keterangan_biaya_lain"] = input.KeteranganBiayaLain
	updates["overhead"] = input.Overhead
	updates["margin_keuntungan"] = input.MarginKeuntungan
	updates["catatan"] = input.Catatan

	if err := tx.Model(&sph).Updates(updates).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if input.Teknisi != nil {
		if err := tx.Where("sph_id = ?", sph.ID).Delete(&models.SphTeknisi{}).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		for i := range input.Teknisi {
			input.Teknisi[i].SphID = sph.ID
		}
		if len(input.Teknisi) > 0 {
			if err := tx.Create(&input.Teknisi).Error; err != nil {
				tx.Rollback()
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
		}
	}

	tx.Commit()

	models.DB.Preload("Teknisi").Preload("Job").First(&sph, sph.ID)
	c.JSON(http.StatusOK, gin.H{"sph": sph})
}

func DeleteSph(c *gin.Context) {
	id := c.Param("id")
	idUint, err := strconv.ParseUint(id, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	tx := models.DB.Begin()
	if err := tx.Where("sph_id = ?", idUint).Delete(&models.SphTeknisi{}).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if err := tx.Delete(&models.Sph{}, idUint).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	tx.Commit()

	c.JSON(http.StatusOK, gin.H{"message": "SPH deleted"})
}
