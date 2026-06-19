package controllers

import (
	"net/http"

	"website-backend/middleware"
	"website-backend/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func GetCompanyProfile(c *gin.Context) {
	var profile models.CompanyProfile
	result := models.DB.Preload("Services", func(db *gorm.DB) *gorm.DB {
		return db.Order("sort_order ASC")
	}).Preload("Partners", func(db *gorm.DB) *gorm.DB {
		return db.Order("sort_order ASC")
	}).First(&profile)
	if result.Error != nil {
		profile = models.CompanyProfile{
			CompanyName: "Perusahaan Saya",
			Tagline:     "Tagline perusahaan",
			AboutTitle:  "Tentang Kami",
			AboutDesc:   "Deskripsi perusahaan...",
		}
		models.DB.Create(&profile)
	}
	c.JSON(http.StatusOK, gin.H{"profile": profile})
}

func UpdateCompanyProfile(c *gin.Context) {
	role, _ := c.Get("role")
	roleStr, _ := role.(string)
	if roleStr != "Super Admin" && roleStr != "Administrasi" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Akses ditolak"})
		return
	}

	var input struct {
		CompanyName string `json:"company_name"`
		Tagline     string `json:"tagline"`
		HeroImage   string `json:"hero_image"`
		AboutTitle  string `json:"about_title"`
		AboutDesc   string `json:"about_desc"`
		AboutImage  string `json:"about_image"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var profile models.CompanyProfile
	result := models.DB.First(&profile)
	if result.Error != nil {
		profile = models.CompanyProfile{
			CompanyName: input.CompanyName,
			Tagline:     input.Tagline,
			HeroImage:   input.HeroImage,
			AboutTitle:  input.AboutTitle,
			AboutDesc:   input.AboutDesc,
			AboutImage:  input.AboutImage,
		}
		models.DB.Create(&profile)
	} else {
		profile.CompanyName = input.CompanyName
		profile.Tagline = input.Tagline
		profile.HeroImage = input.HeroImage
		profile.AboutTitle = input.AboutTitle
		profile.AboutDesc = input.AboutDesc
		profile.AboutImage = input.AboutImage
		models.DB.Save(&profile)
	}
	c.JSON(http.StatusOK, gin.H{"profile": profile})
}

// --- Services ---

func CreateCompanyService(c *gin.Context) {
	role, _ := c.Get("role")
	roleStr, _ := role.(string)
	if !middleware.HasPermission(models.DB, roleStr, "company", "manage") {
		c.JSON(http.StatusForbidden, gin.H{"error": "Akses ditolak"})
		return
	}

	var input struct {
		Title       string `json:"title" binding:"required"`
		Description string `json:"description"`
		Icon        string `json:"icon"`
		SortOrder   int    `json:"sort_order"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	service := models.CompanyService{
		Title:       input.Title,
		Description: input.Description,
		Icon:        input.Icon,
		SortOrder:   input.SortOrder,
	}
	if err := models.DB.Create(&service).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"service": service})
}

func UpdateCompanyService(c *gin.Context) {
	role, _ := c.Get("role")
	roleStr, _ := role.(string)
	if !middleware.HasPermission(models.DB, roleStr, "company", "manage") {
		c.JSON(http.StatusForbidden, gin.H{"error": "Akses ditolak"})
		return
	}

	id := c.Param("id")
	var service models.CompanyService
	if err := models.DB.First(&service, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Service not found"})
		return
	}

	var input struct {
		Title       string `json:"title"`
		Description string `json:"description"`
		Icon        string `json:"icon"`
		SortOrder   int    `json:"sort_order"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	service.Title = input.Title
	service.Description = input.Description
	service.Icon = input.Icon
	service.SortOrder = input.SortOrder
	models.DB.Save(&service)
	c.JSON(http.StatusOK, gin.H{"service": service})
}

func DeleteCompanyService(c *gin.Context) {
	role, _ := c.Get("role")
	roleStr, _ := role.(string)
	if !middleware.HasPermission(models.DB, roleStr, "company", "manage") {
		c.JSON(http.StatusForbidden, gin.H{"error": "Akses ditolak"})
		return
	}

	id := c.Param("id")
	var service models.CompanyService
	if err := models.DB.First(&service, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Service not found"})
		return
	}
	models.DB.Delete(&service)
	c.JSON(http.StatusOK, gin.H{"message": "Service deleted"})
}

// --- Partners ---

func CreateCompanyPartner(c *gin.Context) {
	role, _ := c.Get("role")
	roleStr, _ := role.(string)
	if !middleware.HasPermission(models.DB, roleStr, "company", "manage") {
		c.JSON(http.StatusForbidden, gin.H{"error": "Akses ditolak"})
		return
	}

	var input struct {
		Name        string `json:"name" binding:"required"`
		Logo        string `json:"logo"`
		Description string `json:"description"`
		Website     string `json:"website"`
		SortOrder   int    `json:"sort_order"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	partner := models.CompanyPartner{
		Name:        input.Name,
		Logo:        input.Logo,
		Description: input.Description,
		Website:     input.Website,
		SortOrder:   input.SortOrder,
	}
	if err := models.DB.Create(&partner).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"partner": partner})
}

func UpdateCompanyPartner(c *gin.Context) {
	role, _ := c.Get("role")
	roleStr, _ := role.(string)
	if !middleware.HasPermission(models.DB, roleStr, "company", "manage") {
		c.JSON(http.StatusForbidden, gin.H{"error": "Akses ditolak"})
		return
	}

	id := c.Param("id")
	var partner models.CompanyPartner
	if err := models.DB.First(&partner, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Partner not found"})
		return
	}

	var input struct {
		Name        string `json:"name"`
		Logo        string `json:"logo"`
		Description string `json:"description"`
		Website     string `json:"website"`
		SortOrder   int    `json:"sort_order"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	partner.Name = input.Name
	partner.Logo = input.Logo
	partner.Description = input.Description
	partner.Website = input.Website
	partner.SortOrder = input.SortOrder
	models.DB.Save(&partner)
	c.JSON(http.StatusOK, gin.H{"partner": partner})
}

func DeleteCompanyPartner(c *gin.Context) {
	role, _ := c.Get("role")
	roleStr, _ := role.(string)
	if !middleware.HasPermission(models.DB, roleStr, "company", "manage") {
		c.JSON(http.StatusForbidden, gin.H{"error": "Akses ditolak"})
		return
	}

	id := c.Param("id")
	var partner models.CompanyPartner
	if err := models.DB.First(&partner, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Partner not found"})
		return
	}
	models.DB.Delete(&partner)
	c.JSON(http.StatusOK, gin.H{"message": "Partner deleted"})
}
