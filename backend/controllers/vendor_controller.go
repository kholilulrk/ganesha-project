package controllers

import (
	"net/http"
	"strconv"
	"website-backend/models"

	"github.com/gin-gonic/gin"
)

type VendorInput struct {
	Name          string  `json:"name" binding:"required"`
	ContactPerson string  `json:"contact_person"`
	Phone         string  `json:"phone"`
	Email         string  `json:"email"`
	Address       string  `json:"address"`
	Description   string  `json:"description"`
	JobID         *uint   `json:"job_id"`
}

type PaymentTermInput struct {
	TermNumber  int     `json:"term_number" binding:"required"`
	Percentage  float64 `json:"percentage"`
	Amount      float64 `json:"amount"`
	DueDate     string  `json:"due_date"`
	Description string  `json:"description"`
}

func GetVendors(c *gin.Context) {
	var vendors []models.Vendor
	if err := models.DB.Preload("Job").Order("created_at DESC").Find(&vendors).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"vendors": vendors})
}

func GetVendor(c *gin.Context) {
	id := c.Param("id")
	var vendor models.Vendor
	if err := models.DB.Preload("Job").Preload("PaymentTerms").First(&vendor, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Vendor not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"vendor": vendor})
}

func CreateVendor(c *gin.Context) {
	var input VendorInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	vendor := models.Vendor{
		Name:          input.Name,
		ContactPerson: input.ContactPerson,
		Phone:         input.Phone,
		Email:         input.Email,
		Address:       input.Address,
		Description:   input.Description,
		JobID:         input.JobID,
	}

	if err := models.DB.Create(&vendor).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	models.DB.Preload("Job").First(&vendor, vendor.ID)
	c.JSON(http.StatusCreated, gin.H{"vendor": vendor})
}

func UpdateVendor(c *gin.Context) {
	id := c.Param("id")
	var vendor models.Vendor
	if err := models.DB.First(&vendor, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Vendor not found"})
		return
	}

	var input VendorInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	vendor.Name = input.Name
	vendor.ContactPerson = input.ContactPerson
	vendor.Phone = input.Phone
	vendor.Email = input.Email
	vendor.Address = input.Address
	vendor.Description = input.Description
	vendor.JobID = input.JobID

	if err := models.DB.Save(&vendor).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	models.DB.Preload("Job").First(&vendor, vendor.ID)
	c.JSON(http.StatusOK, gin.H{"vendor": vendor})
}

func DeleteVendor(c *gin.Context) {
	id := c.Param("id")
	var vendor models.Vendor
	if err := models.DB.First(&vendor, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Vendor not found"})
		return
	}

	if err := models.DB.Delete(&vendor).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Vendor deleted"})
}

func GetVendorPaymentTerms(c *gin.Context) {
	vendorID := c.Param("id")
	var terms []models.PaymentTerm
	if err := models.DB.Where("vendor_id = ?", vendorID).Order("term_number ASC").Find(&terms).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"payment_terms": terms})
}

func CreatePaymentTerm(c *gin.Context) {
	vendorID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vendor ID"})
		return
	}

	var vendor models.Vendor
	if err := models.DB.First(&vendor, vendorID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Vendor not found"})
		return
	}

	var input PaymentTermInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	term := models.PaymentTerm{
		VendorID:    uint(vendorID),
		TermNumber:  input.TermNumber,
		Percentage:  input.Percentage,
		Amount:      input.Amount,
		DueDate:     input.DueDate,
		Description: input.Description,
	}

	if err := models.DB.Create(&term).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"payment_term": term})
}

func UpdatePaymentTerm(c *gin.Context) {
	termID := c.Param("termId")
	var term models.PaymentTerm
	if err := models.DB.First(&term, termID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Payment term not found"})
		return
	}

	var input PaymentTermInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	term.TermNumber = input.TermNumber
	term.Percentage = input.Percentage
	term.Amount = input.Amount
	term.DueDate = input.DueDate
	term.Description = input.Description

	if err := models.DB.Save(&term).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"payment_term": term})
}

func DeletePaymentTerm(c *gin.Context) {
	termID := c.Param("termId")
	var term models.PaymentTerm
	if err := models.DB.First(&term, termID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Payment term not found"})
		return
	}

	if err := models.DB.Delete(&term).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Payment term deleted"})
}
